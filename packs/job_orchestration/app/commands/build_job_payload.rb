class BuildJobPayload < GLCommand::Callable
  requires :pipeline_step, :pipeline_run
  allows :parent_candidate

  returns :job_payload

  def call
    workflow_json = context.pipeline_step.comfy_workflow_json
    
    # Replace template variables before parsing
    workflow_json = replace_template_variables(workflow_json)
    
    workflow = JSON.parse(workflow_json)

    payload = {
      workflow: workflow,
      variables: {},
      output_folder: build_output_folder
    }

    # Add run prompt if needed
    if context.pipeline_step.needs_run_prompt
      payload[:variables][:prompt] = context.pipeline_run&.prompt || "default prompt"
    end

    # Add parent image path if needed
    if context.pipeline_step.needs_parent_image_path && context.parent_candidate
      payload[:variables][:parent_image] = context.parent_candidate.image_path
    end

    # Add all run variables if needed
    if context.pipeline_step.needs_run_variables
      run_vars = context.pipeline_run&.variables || {}
      payload[:variables].merge!(run_vars.symbolize_keys)
      
      # Also add prompt if present
      if context.pipeline_run&.prompt.present?
        payload[:variables][:prompt] = context.pipeline_run.prompt
      end
    end

    context.job_payload = payload
  end

  private

  def replace_template_variables(workflow_json)
    variables = build_variable_map
    
    variables.each do |key, value|
      workflow_json = workflow_json.gsub("{{#{key}}}", value.to_s)
    end
    
    workflow_json
  end

  def build_variable_map
    variables = (context.pipeline_run&.variables || {}).dup
    
    # Add prompt from column if present
    if context.pipeline_run&.prompt.present?
      variables["prompt"] = context.pipeline_run.prompt
    end
    
    # Add run_name from name column if present
    if context.pipeline_run&.name.present?
      variables["run_name"] = context.pipeline_run.name
    end
    
    # Add dynamic system variables
    variables["timestamp"] = Time.now.to_i
    variables["timestamp_ms"] = (Time.now.to_f * 1000).to_i
    variables["random"] = rand(1_000_000_000)
    
    # Add parent image path if available
    if context.parent_candidate
      variables["parent_image_path"] = context.parent_candidate.image_path
    end
    
    variables
  end

  def build_output_folder
    step_name = context.pipeline_step.name.parameterize
    File.join(context.pipeline_run.target_folder || "", step_name)
  end
end
