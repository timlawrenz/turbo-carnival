# frozen_string_literal: true

module ContentStrategy
  class HashtagEngine
    class << self
      def generate(photo:, pillar:, count: 10)
        hashtags = []

        # Extract from pillar name and description
        hashtags += extract_from_pillar(pillar)

        # Add persona-specific hashtags if available
        if photo.persona.respond_to?(:hashtag_strategy) && photo.persona.hashtag_strategy.present?
          strategy = photo.persona.hashtag_strategy
          if strategy.respond_to?(:tags)
            hashtags += Array(strategy.tags)
          elsif strategy.is_a?(Hash)
            hashtags += Array(strategy['tags'] || strategy[:tags])
          end
        end

        # Ensure uniqueness and format
        hashtags = hashtags
          .compact
          .map { |tag| format_hashtag(tag) }
          .uniq
          .first(count)

        # If we don't have enough, add generic defaults
        if hashtags.size < ConfigLoader.hashtag_count_min
          hashtags += default_hashtags
          hashtags = hashtags.uniq.first(count)
        end

        hashtags
      end

      private

      def extract_from_pillar(pillar)
        tags = []
        
        # From name
        if pillar.name.present?
          words = pillar.name.split(/[\s_-]+/)
          tags += words.select { |w| w.length > 3 }
        end

        # From description if available
        if pillar.respond_to?(:description) && pillar.description.present?
          # Extract key words (simple approach)
          words = pillar.description.split(/[\s_-]+/)
          tags += words.select { |w| w.length > 4 }.first(3)
        end

        tags
      end

      def format_hashtag(tag)
        # Remove non-alphanumeric, ensure starts with #
        cleaned = tag.to_s.gsub(/[^a-zA-Z0-9]/, '')
        return nil if cleaned.empty?
        "##{cleaned.downcase}"
      end

      def default_hashtags
        %w[#photography #instagram #instagood #photooftheday #art]
      end
    end
  end
end
