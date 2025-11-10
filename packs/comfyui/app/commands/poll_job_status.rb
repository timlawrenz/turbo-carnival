class PollJobStatus < GLCommand::Callable
  requires :comfyui_job

  returns :status, :needs_processing

  def call
    job = context.comfyui_job

    response = ComfyuiClient.new.get_job_status(job.comfyui_job_id)

    case response[:status]
    when "running"
      job.update!(status: "running")
      context.status = "running"
      context.needs_processing = false

    when "completed"
      job.update!(
        status: "completed",
        completed_at: Time.current,
        result_metadata: response[:output]
      )
      context.status = "completed"
      context.needs_processing = true

    when "failed"
      job.update!(
        status: "failed",
        error_message: response[:error]
      )
      context.status = "failed"
      context.needs_processing = false
    end
  rescue StandardError => e
    # Log error but re-raise for caller to handle
    Rails.logger.error("PollJobStatus failed for job #{job.id}: #{e.message}")
    raise
  end
end
