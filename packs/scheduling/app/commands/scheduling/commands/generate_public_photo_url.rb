# frozen_string_literal: true

module Scheduling
  module Commands
    class GeneratePublicPhotoUrl < GLCommand::Callable
      requires photo: ContentPillars::Photo
      returns public_photo_url: String

      def call
        unless photo.image.attached?
          stop_and_fail!('Photo must have an attached image')
          return
        end

        context.public_photo_url = photo.image.url
      end
    end
  end
end
