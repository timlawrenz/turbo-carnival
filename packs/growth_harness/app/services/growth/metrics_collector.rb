# frozen_string_literal: true

module Growth
  # Capture follower-count snapshots from the connected Instagram account.
  class MetricsCollector
    attr_reader :goal

    def initialize(goal:)
      @goal = goal
    end

    # Fetch current followers and record a snapshot.
    # Returns the snapshot, or nil (with a recorded decision) if the API fails.
    def collect
      count = fetch_followers
      snapshot = goal.snapshots.create!(followers: count, taken_at: Time.current)
      update_start_followers(count)
      snapshot
    rescue Instagram::Client::Error, ArgumentError => e
      record_skip(e.message)
      nil
    end

    private

    def fetch_followers
      Instagram::Client.new.followers_count
    rescue ::Instagram::Client::Error => e
      raise e
    end

    def update_start_followers(count)
      return unless goal.snapshots.count == 1 && goal.start_followers.zero?

      goal.update!(start_followers: count)
    end

    def record_skip(error_message)
      Growth::Decision.create!(
        goal: goal,
        action: 'skip_data',
        reason: "Follower snapshot failed: #{error_message}",
        decided_at: Time.current
      )
      Rails.logger.warn("Growth::MetricsCollector: #{error_message}")
    end
  end
end