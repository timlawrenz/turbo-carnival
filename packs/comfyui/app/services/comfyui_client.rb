class ComfyuiClient
  class Error < StandardError; end
  class ConnectionError < Error; end
  class APIError < Error; end

  def initialize(base_url: nil)
    @base_url = base_url || Rails.application.config.comfyui.base_url
  end

  def submit_workflow(workflow_json)
    response = connection.post("/prompt") do |req|
      req.body = { prompt: workflow_json }.to_json
      req.headers["Content-Type"] = "application/json"
    end

    parse_response(response)
  rescue Faraday::Error => e
    raise ConnectionError, "Failed to connect to ComfyUI: #{e.message}"
  end

  def get_job_status(job_id)
    response = connection.get("/history/#{job_id}")
    parse_response(response)
  rescue Faraday::Error => e
    raise ConnectionError, "Failed to get job status: #{e.message}"
  end

  def download_image(image_url)
    response = connection.get(image_url)

    if response.success?
      response.body
    else
      raise APIError, "Failed to download image: HTTP #{response.status}"
    end
  rescue Faraday::Error => e
    raise ConnectionError, "Failed to download image: #{e.message}"
  end

  private

  def connection
    @connection ||= Faraday.new(url: @base_url) do |f|
      f.request :json
      f.request :retry, max: 3, interval: 0.5, backoff_factor: 2
      f.response :json, content_type: /\bjson$/
      f.adapter Faraday.default_adapter
      f.options.timeout = Rails.application.config.comfyui.timeout
    end
  end

  def parse_response(response)
    if response.success?
      response.body.is_a?(Hash) ? response.body.deep_symbolize_keys : response.body
    else
      raise APIError, "ComfyUI API error: HTTP #{response.status}"
    end
  end
end
