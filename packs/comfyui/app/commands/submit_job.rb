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

    # Apply job-specific variable substitutions
    workflow = apply_job_variables(context.job_payload[:workflow], job)

    # Submit to ComfyUI
    response = ComfyuiClient.new.submit_workflow(workflow)

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

  private

  def apply_job_variables(workflow, job)
    # Convert workflow to JSON string for replacement
    workflow_json = workflow.to_json
    
    # Replace job-specific variables
    workflow_json = workflow_json.gsub('"{{job_id}}"', job.id.to_s)
    
    # If there's a base_seed variable, compute actual seed
    if workflow_json.include?('"{{auto_seed}}"')
      base_seed = context.pipeline_run.variables["seed"] || 1000000
      actual_seed = base_seed + job.id
      workflow_json = workflow_json.gsub('"{{auto_seed}}"', actual_seed.to_s)
    end
    
    # Parse back to hash
    JSON.parse(workflow_json)
  end
end
