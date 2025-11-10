class BuildJobPayload < GLCommand::Callable
  requires :pipeline_step, :pipeline_run
  allows :parent_candidate

  returns :job_payload

  def call
    workflow = JSON.parse(context.pipeline_step.comfy_workflow_json)

    payload = {
      workflow: workflow,
      variables: {},
      output_folder: build_output_folder
    }

    # Add run prompt if needed
    if context.pipeline_step.needs_run_prompt
      payload[:variables][:prompt] = context.pipeline_run.variables["prompt"]
    end

    # Add parent image path if needed
    if context.pipeline_step.needs_parent_image_path && context.parent_candidate
      payload[:variables][:parent_image] = context.parent_candidate.image_path
    end

    # Add all run variables if needed
    if context.pipeline_step.needs_run_variables
      payload[:variables].merge!(context.pipeline_run.variables.symbolize_keys)
    end

    context.job_payload = payload
  end

  private

  def build_output_folder
    step_name = context.pipeline_step.name.parameterize
    File.join(context.pipeline_run.target_folder || "", step_name)
  end
end
