# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.on(:startup) do
    Rails.logger.info "Starting ComfyUI background workers..."
    JobPollerWorker.perform_async
    JobSubmitterWorker.perform_async
  end
end
