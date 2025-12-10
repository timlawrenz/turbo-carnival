# frozen_string_literal: true

module ContentPillars
  class Photo < ApplicationRecord
    self.table_name = 'photos'

    has_one_attached :image

    belongs_to :persona
    belongs_to :content_pillar, class_name: 'ContentPillar'
    belongs_to :image_candidate, class_name: 'ImageCandidate', optional: true

    validates :path, presence: true, uniqueness: true
    validates :persona, presence: true

    scope :unposted, -> {
      where.not(id: select(:id).where('EXISTS (SELECT 1 FROM scheduling_posts WHERE photo_id = photos.id)'))
    }

    def posted?
      # Will be true when scheduling pack exists
      # For now, always false
      false
    end
  end
end
