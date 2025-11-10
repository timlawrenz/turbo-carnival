class ProcessJobResult < GLCommand::Callable
  requires :comfyui_job

  returns :image_candidate

  def call
    job = context.comfyui_job

    # Extract image info from result metadata
    # Structure: {"node_id" => {"images" => [{filename, subfolder, type}]}}
    output_node = job.result_metadata.values.first
    image_info = output_node["images"].first
    
    # Build ComfyUI output path
    filename = image_info["filename"]
    subfolder = image_info["subfolder"]
    
    # ComfyUI saves to: /path/to/ComfyUI/output/{subfolder}/{filename}
    comfyui_output_dir = "/mnt/essdee/ComfyUI/output"
    image_path = File.join(comfyui_output_dir, subfolder, filename)

    # Create ImageCandidate
    candidate = ImageCandidate.create!(
      pipeline_step: job.pipeline_step,
      pipeline_run: job.pipeline_run,
      parent: job.parent_candidate,
      image_path: image_path,
      status: "active"
    )

    # Link the job to the created candidate (if column exists)
    # job.update!(image_candidate: candidate) rescue nil

    context.image_candidate = candidate
  end
end
