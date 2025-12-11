# frozen_string_literal: true

module PostAutomation
  # Step 2: Generate AI caption for the selected photo
  class GenerateCaption < GLCommand::Callable
    requires photo: ContentPillars::Photo, persona: Persona
    allows pillar: ContentPillar

    returns :caption, :caption_metadata

    def call
      load_caption_services

      result = if photo.image.attached?
        CaptionGeneration::VisionGenerator.generate(
          photo: photo,
          persona: persona,
          content_pillar: pillar
        )
      else
        CaptionGeneration::Generator.generate(
          photo: photo,
          persona: persona,
          cluster: pillar
        )
      end

      if result.success?
        context.caption = result.text
        context.caption_metadata = result.metadata
      else
        stop_and_fail!("Caption generation failed: #{result.metadata[:error]}")
      end
    end

    private

    def load_caption_services
      Dir['packs/caption_generation/app/services/caption_generation/*.rb'].sort.each { |f| load f }
      load 'lib/ai/ollama_client.rb' unless defined?(AI::OllamaClient)
    end
  end
end
