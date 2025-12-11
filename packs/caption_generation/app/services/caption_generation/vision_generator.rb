# frozen_string_literal: true

require 'base64'

module CaptionGeneration
  class VisionGenerator
    def self.generate(photo:, persona:, content_pillar: nil)
      new(photo: photo, persona: persona, content_pillar: content_pillar).generate
    end

    def initialize(photo:, persona:, content_pillar: nil)
      @photo = photo
      @persona = persona
      @content_pillar = content_pillar
    end

    def generate
      raise ArgumentError, 'Persona caption_config is required' unless @persona.caption_config
      raise ArgumentError, 'Photo must have attached image' unless @photo.image.attached?

      # Get image as base64
      image_base64 = encode_image

      # Build vision prompt
      prompt = build_vision_prompt

      # Call Ollama with vision
      client = AI::OllamaClient.new(model: 'gemma3:27b', timeout: 120)  # Use vision model
      
      result = client.chat(
        messages: [
          {
            role: 'user',
            content: prompt,
            images: [image_base64]
          }
        ],
        temperature: 0.7
      )

      # Process the generated caption
      caption_text = result[:text]
      processed = PostProcessor.process(caption_text, @persona.caption_config)

      Result.new(
        text: processed[:text],
        metadata: build_metadata(processed, result),
        success: processed[:compliant]
      )
    rescue StandardError => e
      Result.new(
        text: '',
        metadata: { error: e.message, vision: true },
        success: false
      )
    end

    private

    def encode_image
      # Download the image and encode to base64
      image_data = @photo.image.download
      Base64.strict_encode64(image_data)
    end

    def build_vision_prompt
      style = @persona.caption_config.style || 'casual'
      tone = @persona.caption_config.tone || 'friendly'
      voice = @persona.caption_config.voice || 'authentic'
      max_length = @persona.caption_config.max_length || 150

      pillar_context = if @content_pillar
        "\n\nContent Theme: #{@content_pillar.name}"
        if @content_pillar.ai_prompt.present?
          pillar_context += "\nGuidelines: #{@content_pillar.ai_prompt}"
        end
        pillar_context
      else
        ""
      end

      <<~PROMPT
        You are writing an Instagram caption for #{@persona.name}.

        Writing Style Guide:
        - Style: #{style}
        - Tone: #{tone}
        - Voice: #{voice}
        - Maximum length: #{max_length} words
        #{pillar_context}

        Instructions:
        1. Analyze the image carefully
        2. Write a caption that describes what you see
        3. Match the personality and style specified above
        4. Keep it under #{max_length} words
        5. Make it engaging and authentic
        6. Do NOT include hashtags (they will be added separately)
        7. Return ONLY the caption text, no explanations

        Write the Instagram caption now:
      PROMPT
    end

    def build_metadata(processed, ai_result)
      {
        model: ai_result[:model] || 'gemma3:27b',
        generator: 'vision',
        word_count: processed[:text].split.size,
        char_count: processed[:text].length,
        compliant: processed[:compliant],
        warnings: processed[:warnings] || []
      }
    end
  end
end
