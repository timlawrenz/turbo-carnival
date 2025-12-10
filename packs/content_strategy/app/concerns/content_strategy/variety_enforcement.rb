# frozen_string_literal: true

module ContentStrategy
  module VarietyEnforcement
    def enforce_variety_rules(clusters)
      config = context.config
      eligible = clusters.dup

      # Filter out clusters used within min days gap
      recent_cluster_ids = context.history
        .where('created_at >= ?', config.variety_min_days_gap.days.ago)
        .pluck(:cluster_id)
        .compact
        .uniq

      eligible = eligible.reject { |c| recent_cluster_ids.include?(c.id) }

      # Filter out clusters exceeding max same cluster per week
      week_start = 1.week.ago
      overused_cluster_ids = context.history
        .where('created_at >= ?', week_start)
        .group(:cluster_id)
        .having('COUNT(*) >= ?', config.variety_max_same_cluster)
        .pluck(:cluster_id)
        .compact

      eligible = eligible.reject { |c| overused_cluster_ids.include?(c.id) }

      # If all filtered out, use least recently used as fallback
      if eligible.empty?
        Rails.logger.warn("All clusters filtered by variety rules, using fallback")
        eligible = [least_recently_used_cluster(clusters)]
      end

      eligible
    end

    private

    def least_recently_used_cluster(clusters)
      cluster_last_used = context.history
        .where(cluster_id: clusters.map(&:id))
        .group(:cluster_id)
        .maximum(:created_at)

      # Find cluster with oldest last_used time, or never used
      clusters.min_by do |cluster|
        cluster_last_used[cluster.id] || Time.at(0)
      end
    end
  end
end
