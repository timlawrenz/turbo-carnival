# frozen_string_literal: true

require 'faraday'
require 'json'

module Instagram
  class Client
    class Error < StandardError; end

    BASE_URL = 'https://graph.facebook.com/v20.0'

    def initialize
      @app_id = Rails.application.credentials.dig(:instagram, :app_id)
      @app_secret = Rails.application.credentials.dig(:instagram, :app_secret)
      @access_token = Rails.application.credentials.dig(:instagram, :access_token)
      @account_id = Rails.application.credentials.dig(:instagram, :account_id)

      raise ArgumentError, 'Instagram credentials are required' if [@app_id, @app_secret, @access_token,
                                                                    @account_id].any?(&:blank?)
    end

    def create_post(image_url:, caption:)
      creation_id = create_media_container(image_url, caption)
      publish_media_container(creation_id)
    rescue Faraday::Error => e
      raise Error, "Request failed: #{e.message}"
    end

    private

    def connection
      Faraday.new(url: BASE_URL) do |conn|
        conn.request :url_encoded
        conn.response :json
        conn.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      raise Error, "API Error: #{response.status} - #{response.body}" unless response.success?

      response.body
    end

    def create_media_container(image_url, caption)
      response = connection.post("#{@account_id}/media") do |req|
        req.params['image_url'] = image_url
        req.params['caption'] = caption
        req.params['access_token'] = @access_token
      end
      handle_response(response)['id']
    end

    def publish_media_container(creation_id)
      response = connection.post("#{@account_id}/media_publish") do |req|
        req.params['creation_id'] = creation_id
        req.params['access_token'] = @access_token
      end
      handle_response(response)
    end
  end
end
