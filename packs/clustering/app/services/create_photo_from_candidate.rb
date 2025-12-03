# frozen_string_literal: true

class CreatePhotoFromCandidate
  def self.call(candidate, cluster)
    new(candidate, cluster).call
  end

  def initialize(candidate, cluster)
    @candidate = candidate
    @cluster = cluster
  end

  def call
    return nil unless valid?

    create_photo
  rescue StandardError => e
    Rails.logger.error("Failed to create photo from candidate #{@candidate.id}: #{e.message}")
    nil
  end

  private

  def valid?
    unless @candidate
      Rails.logger.warn("No candidate provided")
      return false
    end

    unless @cluster
      Rails.logger.warn("No cluster provided")
      return false
    end

    unless File.exist?(@candidate.image_path)
      Rails.logger.warn("Image file not found: #{@candidate.image_path}")
      return false
    end

    true
  end

  def create_photo
    photo = Clustering::Photo.create!(
      persona: @cluster.persona,
      cluster: @cluster,
      path: @candidate.image_path
    )

    attach_image(photo)

    Rails.logger.info("Created photo #{photo.id} from candidate #{@candidate.id}")
    photo
  end

  def attach_image(photo)
    photo.image.attach(
      io: File.open(@candidate.image_path),
      filename: File.basename(@candidate.image_path),
      content_type: content_type
    )
  end

  def content_type
    case File.extname(@candidate.image_path).downcase
    when '.png' then 'image/png'
    when '.jpg', '.jpeg' then 'image/jpeg'
    when '.webp' then 'image/webp'
    else 'image/png'
    end
  end
end
