# frozen_string_literal: true

module CaptionGeneration
  class PostProcessor
    MAX_LENGTH = 2200 # Instagram caption limit

    def self.process(text, caption_config = nil)
      new(text, caption_config).process
    end

    def initialize(text, caption_config = nil)
      @text = text
      @config = caption_config
    end

    def process
      processed = @text.strip

      # Remove any hashtags (they'll be added separately)
      processed = processed.gsub(/#\w+/, '').strip

      # Trim to max length if needed
      processed = processed[0...MAX_LENGTH] if processed.length > MAX_LENGTH

      {
        text: processed,
        length: processed.length,
        compliant: compliant?(processed)
      }
    end

    private

    def compliant?(text)
      return false if text.length > MAX_LENGTH
      return false if text.empty?
      
      true
    end
  end
end
