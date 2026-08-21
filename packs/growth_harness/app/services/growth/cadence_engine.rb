# frozen_string_literal: true

module Growth
  # Keep the scheduled-post queue full enough to hit the goal's cadence.
  class CadenceEngine
    LOOKAHEAD_DAYS = 7

    attr_reader :goal

    def initialize(goal:)
      @goal = goal
    end

    def sync
      target = posts_target
      existing = scheduled_posts_count
      shortfall = [target - existing, 0].max

      return { created: 0, target: target, existing: existing, shortfall: 0 } if shortfall.zero?

      created = 0
      failures = []
      shortfall.times do
        result = PostAutomation::AutoCreateNextPost.call(persona: goal.persona)
        unless result.success?
          failures << result.full_error_message
          break
        end

        created += 1
      end

      log_blockage(failures.first) if failures.any?

      {
        created: created,
        target: target,
        existing: existing + created,
        shortfall: shortfall,
        failures: failures
      }
    end

    private

    # How many scheduled+draft posts should be in the future queue.
    def posts_target
      (goal.effective_posts_per_day * LOOKAHEAD_DAYS).ceil
    end

    def scheduled_posts_count
      Scheduling::Post
        .where(persona: goal.persona)
        .where(status: %w[draft scheduled])
        .where('scheduled_at > ? OR optimal_time_calculated > ?', Time.current, Time.current)
        .count
    end

    def log_blockage(error_message)
      Growth::Decision.create!(
        goal: goal,
        action: 'cadence_blocked',
        reason: "Could not top up queue: #{error_message}",
        decided_at: Time.current
      )
      Rails.logger.warn("Growth::CadenceEngine: #{error_message}")
    end
  end
end