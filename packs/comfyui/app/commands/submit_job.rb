class SubmitJob < GLCommand::Callable
  requires :job_payload, :pipeline_step, :pipeline_run
  allows :parent_candidate

  returns :comfyui_job

  def call
    # Create pending job record
    job = ComfyuiJob.create!(
      pipeline_step: context.pipeline_step,
      pipeline_run: context.pipeline_run,
      parent_candidate: context.parent_candidate,
      job_payload: context.job_payload,
      status: "pending"
    )

    # Submit to ComfyUI
    response = ComfyuiClient.new.submit_workflow(
      context.job_payload[:workflow]
    )

    # Update job with ComfyUI ID
    job.update!(
      comfyui_job_id: response[:job_id],
      status: "submitted",
      submitted_at: Time.current
    )

    context.comfyui_job = job
  rescue StandardError => e
    job&.update(status: "failed", error_message: e.message)
    raise
  end
end
