# frozen_string_literal: true

require 'faraday'
require 'json'

module AI
  class OllamaClient
    class Error < StandardError; end
    class TimeoutError < Error; end
    class ModelNotFoundError < Error; end

    ENDPOINT = 'http://192.168.86.137:11434'
    DEFAULT_MODEL = 'gemma3:27b'
    DEFAULT_TIMEOUT = 90 # Increased for first-time model loading

    def initialize(endpoint: ENDPOINT, model: DEFAULT_MODEL, timeout: DEFAULT_TIMEOUT)
      @endpoint = endpoint
      @model = model
      @timeout = timeout
    end

    def generate(prompt:, system_prompt: nil, temperature: 0.7)
      full_prompt = build_full_prompt(prompt, system_prompt)
      
      response = connection.post('/api/generate') do |req|
        req.options.timeout = @timeout
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          model: @model,
          prompt: full_prompt,
          temperature: temperature,
          stream: false
        }.to_json
      end

      handle_response(response)
    rescue Faraday::TimeoutError => e
      raise TimeoutError, "Ollama request timed out after #{@timeout}s. This may happen on first model load (30-60s). Try again."
    rescue Faraday::ConnectionFailed => e
      raise Error, "Cannot connect to Ollama at #{@endpoint}. Is it running?"
    rescue Faraday::Error => e
      raise Error, "Ollama request failed: #{e.message}"
    end

    def chat(messages:, temperature: 0.7, images: nil)
      body = {
        model: @model,
        messages: messages,
        temperature: temperature,
        stream: false
      }
      
      # Add images if provided (for vision models)
      body[:images] = images if images
      
      response = connection.post('/api/chat') do |req|
        req.options.timeout = @timeout
        req.headers['Content-Type'] = 'application/json'
        req.body = body.to_json
      end

      handle_response(response)
    rescue Faraday::TimeoutError => e
      raise TimeoutError, "Ollama request timed out after #{@timeout}s. This may happen on first model load (30-60s). Try again."
    rescue Faraday::ConnectionFailed => e
      raise Error, "Cannot connect to Ollama at #{@endpoint}. Is it running?"
    rescue Faraday::Error => e
      raise Error, "Ollama request failed: #{e.message}"
    end

    def list_models
      response = connection.get('/api/tags')
      JSON.parse(response.body)
    rescue Faraday::Error => e
      raise Error, "Failed to list models: #{e.message}"
    end

    def model_available?
      models = list_models
      models['models']&.any? { |m| m['name'].start_with?(@model) }
    rescue Error
      false
    end

    private

    def connection
      Faraday.new(url: @endpoint) do |conn|
        conn.request :url_encoded
        conn.adapter Faraday.default_adapter
      end
    end

    def build_full_prompt(prompt, system_prompt)
      if system_prompt
        "#{system_prompt}\n\n#{prompt}"
      else
        prompt
      end
    end

    def handle_response(response)
      unless response.success?
        error_body = JSON.parse(response.body) rescue { 'error' => response.body }
        raise Error, "Ollama API error: #{error_body['error'] || response.status}"
      end

      parsed = JSON.parse(response.body)
      
      # Extract text from response (different endpoints have different structures)
      text = parsed['response'] || parsed.dig('message', 'content')
      
      raise Error, 'No response text from Ollama' if text.nil? || text.empty?

      {
        text: text,
        model: parsed['model'],
        done: parsed['done'],
        metadata: parsed
      }
    end
  end
end
