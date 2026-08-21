# frozen_string_literal: true

module Scheduling
  module Commands
    class GeneratePublicPhotoUrl < GLCommand::Callable
      requires photo: ContentPillars::Photo
      returns public_photo_url: String

      def call
        # Preferred: serve from this app over the tunnel (no B2). Requires the
        # photo to have a servable local/NAS file and a configured public base.
        if app_public_base.present? && photo.servable?
          context.public_photo_url = "#{app_public_base}/media/photos/#{photo.id}"
          return
        end

        # Fallback: ActiveStorage URL (B2) when the photo has an attached blob
        unless photo.image.attached?
          stop_and_fail!('Photo has no servable file and no attached image')
          return
        end

        context.public_photo_url = photo.image.url
      end

      private

      def app_public_base
        ENV['TURBO_CARNIVAL_PUBLIC_URL'].presence ||
          Rails.application.credentials.dig(:app, :public_url).to_s.presence
      end
    end
  end
end