# frozen_string_literal: true

# Displays an image with fallback support when image is missing.
class ImageDisplayComponent < ApplicationComponent
  def initialize(image_path:, fallback_text: "No image", classes: "", container_classes: "")
    @image_path = image_path
    @fallback_text = fallback_text
    @classes = classes
    @container_classes = container_classes
  end

  def has_image?
    @image_path.present?
  end
end
