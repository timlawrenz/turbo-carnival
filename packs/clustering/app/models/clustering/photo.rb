# frozen_string_literal: true

module Clustering
  class Photo < ApplicationRecord
    self.table_name = 'photos'

    has_one_attached :image

    belongs_to :persona
    belongs_to :cluster, class_name: 'Clustering::Cluster', optional: true, counter_cache: true

    validates :path, presence: true, uniqueness: true
    validates :persona, presence: true

    scope :unposted, -> {
      where.not(id: select(:id).where('EXISTS (SELECT 1 FROM scheduling_posts WHERE photo_id = photos.id)'))
    }
    scope :in_cluster, ->(cluster_id) { where(cluster_id: cluster_id) }

    def posted?
      # Will be true when scheduling pack exists
      # For now, always false
      false
    end
  end
end
