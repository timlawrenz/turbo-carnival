# frozen_string_literal: true

module Growth
  # Periodic review: measure growth vs. the goal trajectory and adjust strategy.
  #
  # Decision rules (recorded in Growth::Decision for auditability):
  # - ratio < 0.75          → escalate: raise posts_per_day (up to max), then hashtags
  # - ratio > 1.5           → cut back cadence to conserve photo inventory
  # - < 2 snapshots         → defer, noting we need data
  # - interval not elapsed  → skip, report next due date
  class StrategyBrain
    ESCALATE_THRESHOLD = 0.75
    CUTBACK_THRESHOLD  = 1.5

    attr_reader :goal

    def initialize(goal:)
      @goal = goal
    end

    def review(force: false)
      return skip_report unless force || review_due?

      ratio = goal.traj_ratio

      if ratio.nil?
        return { status: 'need_data', snapshot_count: goal.snapshots.count }
      end

      decide(ratio)
    end

    private

    def decide(ratio)
      if ratio < ESCALATE_THRESHOLD
        escalate(ratio)
      elsif ratio > CUTBACK_THRESHOLD
        cut_back(ratio)
      else
        hold(ratio)
      end
    end

    def escalate(ratio)
      from = { posts_per_day: goal.posts_per_day, hashtag_count: goal.hashtag_count }

      if goal.posts_per_day < goal.max_posts_per_day
        goal.update!(posts_per_day: goal.posts_per_day + 1, last_reviewed_at: Time.current)
      elsif goal.hashtag_count < 30
        goal.update!(hashtag_count: goal.hashtag_count + 5, last_reviewed_at: Time.current)
      else
        return hold_declared(ratio, 'at max effort')
      end

      log_decision(:escalate_cadence, from, reason_text(ratio, ahead: false))
    end

    def cut_back(ratio)
      return hold_declared(ratio, 'already minimal') if goal.posts_per_day <= 1

      from = { posts_per_day: goal.posts_per_day, hashtag_count: goal.hashtag_count }
      goal.update!(posts_per_day: goal.posts_per_day - 1, last_reviewed_at: Time.current)
      log_decision(:reduce_cadence, from, reason_text(ratio, ahead: true))
    end

    def hold(ratio)
      goal.touch(:last_reviewed_at)
      { view: 'hold', ratio: ratio.round(2), note: 'on trajectory' }
    end

    def hold_declared(ratio, note)
      goal.touch(:last_reviewed_at)
      { view: 'hold', ratio: ratio.round(2), note: note }
    end

    def log_decision(action, from, reason)
      Growth::Decision.create!(
        goal: goal,
        snapshot: goal.latest_snapshot,
        action: action.to_s,
        reason: reason,
        from_values: from,
        to_values: to_values_hash,
        decided_at: Time.current
      )
      { view: action.to_s, ratio: goal.traj_ratio&.round(2), to: to_values_hash }
    end

    def reason_text(ratio, ahead: false)
      direction = ahead ? 'ahead of' : 'behind'
      "measured/required ratio #{ratio.round(3)} (#{direction} trajectory); adjusted cadence"
    end

    def to_values_hash
      { posts_per_day: goal.posts_per_day, hashtag_count: goal.hashtag_count }
    end

    def review_due?
      return true if goal.last_reviewed_at.nil?

      goal.last_reviewed_at < goal.review_interval_days.days.ago
    end

    def skip_report
      { view: 'skip', next_review_at: (goal.last_reviewed_at || Time.current) + goal.review_interval_days.days }
    end
  end
end