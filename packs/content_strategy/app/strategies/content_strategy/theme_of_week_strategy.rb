# frozen_string_literal: true

module ContentStrategy
  class ThemeOfWeekStrategy < BaseStrategy
    def select_next_photo
      # Get current week number
      current_week = Date.current.cweek
      state_week = context.state.get_state(:week_number)

      # If new week or no state, select new cluster
      if state_week.nil? || current_week != state_week
        select_cluster_for_new_week(current_week)
      end

      # Get cluster from state
      cluster_id = context.state.get_state(:cluster_id)
      cluster = context.clusters.find { |c| c.id == cluster_id }

      # If cluster exhausted or not found, advance to next
      if cluster.nil? || cluster.photos.unposted.empty?
        select_cluster_for_new_week(current_week)
        cluster_id = context.state.get_state(:cluster_id)
        cluster = context.clusters.find { |c| c.id == cluster_id }
      end

      raise NoAvailableClustersError.new(context.persona.id) if cluster.nil?

      # Get unposted photos from this week's cluster
      unposted_photos = cluster.photos.unposted.to_a

      raise NoUnpostedPhotosError.new("in cluster #{cluster.name}") if unposted_photos.empty?

      # Select random photo from cluster
      photo = unposted_photos.sample

      # Build result
      {
        photo: photo,
        cluster: cluster,
        optimal_time: get_optimal_posting_time(photo: photo),
        hashtags: select_hashtags(photo: photo, cluster: cluster),
        format: recommend_format(photo: photo, config: context.config)
      }
    end

    private

    def select_cluster_for_new_week(week_number)
      all_clusters = context.clusters.to_a
      raise NoAvailableClustersError.new(context.persona.id) if all_clusters.empty?

      # Get last used cluster index
      last_index = context.state.get_state(:last_cluster_index) || -1
      
      # Select next cluster (round-robin)
      new_index = (last_index + 1) % all_clusters.size
      cluster = all_clusters[new_index]

      # Update state
      context.state.update_state(
        week_number: week_number,
        cluster_id: cluster.id,
        last_cluster_index: new_index
      )
    end
  end
end
