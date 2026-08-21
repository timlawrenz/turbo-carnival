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
      wait_for_media_ready(creation_id)
      publish_media_container(creation_id)
    rescue Faraday::Error => e
      raise Error, "Request failed: #{e.message}"
    end

    # Fetch the current follower count for the connected business account.
    # Graph API: GET /{account_id}?fields=followers_count
    def followers_count
      response = connection.get(@account_id) do |req|
        req.params['fields'] = 'followers_count'
        req.params['access_token'] = @access_token
      end

      body = handle_response(response)
      count = body['followers_count'] || body[:followers_count]
      raise Error, "Account response missing followers_count: #{body}" if count.nil?

      count.to_i
    rescue Faraday::Error => e
      raise Error, "Request failed: #{e.message}"
    end

    private

    def wait_for_media_ready(creation_id)
      max_attempts = 10
      delay_seconds = 3

      max_attempts.times do |attempt|
        response = connection.get(creation_id) do |req|
          req.params['fields'] = 'status_code'
          req.params['access_token'] = @access_token
        end

        body = handle_response(response)
        status_code = body['status_code'] || body[:status_code]

        return if status_code == 'FINISHED'
        raise Error, "Media processing failed with status_code=ERROR" if status_code == 'ERROR'

        sleep(delay_seconds) if attempt < max_attempts - 1
      end

      raise Error, 'Media not ready for publishing after waiting'
    end

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
