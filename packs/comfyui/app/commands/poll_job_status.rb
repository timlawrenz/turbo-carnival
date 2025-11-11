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
      
      # Track failure on parent and auto-reject if threshold reached
      if job.parent_candidate
        parent = job.parent_candidate
        parent.update!(failure_count: parent.failure_count + 1)
        
        max_failures = ENV.fetch("MAX_PARENT_FAILURES", 3).to_i
        if parent.failure_count >= max_failures
          Rails.logger.warn("Parent #{parent.id} reached #{parent.failure_count} failures - auto-rejecting")
          RejectImageBranch.call(image_candidate: parent)
        end
      end
    end
  rescue StandardError => e
    # Log error but re-raise for caller to handle
    Rails.logger.error("PollJobStatus failed for job #{job.id}: #{e.message}")
    raise
  end
end
