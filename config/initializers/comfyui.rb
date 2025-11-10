# frozen_string_literal: true

Rails.application.config.comfyui = ActiveSupport::OrderedOptions.new
Rails.application.config.comfyui.base_url = ENV.fetch("COMFYUI_BASE_URL", "http://localhost:8188")
Rails.application.config.comfyui.poll_interval = ENV.fetch("COMFYUI_POLL_INTERVAL", "5").to_i
Rails.application.config.comfyui.submit_interval = ENV.fetch("COMFYUI_SUBMIT_INTERVAL", "10").to_i
Rails.application.config.comfyui.timeout = ENV.fetch("COMFYUI_TIMEOUT", "300").to_i
Rails.application.config.comfyui.max_retries = ENV.fetch("COMFYUI_MAX_RETRIES", "3").to_i
