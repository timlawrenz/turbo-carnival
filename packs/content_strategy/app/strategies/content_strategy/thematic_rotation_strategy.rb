# frozen_string_literal: true

module ContentStrategy
  class ThematicRotationStrategy < BaseStrategy
    def select_next_photo
      # Get clusters with variety enforcement
      eligible_clusters = enforce_variety_rules(context.clusters.to_a)

      raise NoAvailableClustersError.new(context.persona.id) if eligible_clusters.empty?

      # Get rotation index from state
      rotation_index = context.state.get_state(:rotation_index) || 0
      
      # Select cluster at index (with wrapping)
      cluster = eligible_clusters[rotation_index % eligible_clusters.size]

      # Get unposted photos from this cluster
      unposted_photos = cluster.photos.unposted.to_a

      raise NoUnpostedPhotosError.new("in cluster #{cluster.name}") if unposted_photos.empty?

      # Select random photo from cluster
      photo = unposted_photos.sample

      # Update rotation index
      new_index = (rotation_index + 1) % eligible_clusters.size
      context.state.set_state(:rotation_index, new_index)

      # Build result
      {
        photo: photo,
        cluster: cluster,
        optimal_time: get_optimal_posting_time(photo: photo),
        hashtags: select_hashtags(photo: photo, cluster: cluster),
        format: recommend_format(photo: photo, config: context.config)
      }
    end
  end
end
