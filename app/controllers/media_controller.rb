# frozen_string_literal: true

# Serves photo image bytes from local/NAS files (no B2 required).
# Used by Instagram publishing (public URL) and by the caption vision pipeline.
class MediaController < ApplicationController
  def photo
    photo = ContentPillars::Photo.find(params[:id])
    file = photo.servable_file_path

    unless file
      head :not_found
      return
    end

    send_file file,
              type: 'image/png',
              disposition: 'inline',
              cache_control: 'public, max-age=86400'
  end
end