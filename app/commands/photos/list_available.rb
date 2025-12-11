# frozen_string_literal: true

module Photos
  # Get available (unposted) photos with attached images for a persona
  class ListAvailable < GLCommand::Callable
    requires persona: Persona
    allows pillar_id: Integer

    returns :photos

    def call
      # Get photos not used in any posts for this persona
      # Note: Can't use .joins(:image_attachment) due to old records with different record_type
      all_photos = ContentPillars::Photo
        .where(persona_id: persona.id)
        .where.not(id: Scheduling::Post.where(persona_id: persona.id).select(:photo_id))
        .order(created_at: :desc)

      # Filter by pillar if specified
      all_photos = all_photos.where(content_pillar_id: pillar_id) if pillar_id.present?
      
      # Filter to only photos with attached images
      context.photos = all_photos.select { |photo| photo.image.attached? }
    end
  end
end
