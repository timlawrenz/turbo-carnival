class ProcessJobResult < GLCommand::Callable
  requires :comfyui_job

  returns :image_candidate

  def call
    job = context.comfyui_job

    # Download image from ComfyUI
    image_url = job.result_metadata["images"].first["url"]
    image_data = ComfyuiClient.new.download_image(image_url)

    # Construct file path
    step_folder = job.pipeline_step.name.parameterize
    filename = "#{SecureRandom.hex(8)}_#{Time.current.to_i}.png"
    full_path = File.join(
      job.pipeline_run.target_folder,
      step_folder,
      filename
    )

    # Save image
    FileUtils.mkdir_p(File.dirname(full_path))
    File.binwrite(full_path, image_data)

    # Create ImageCandidate
    candidate = ImageCandidate.create!(
      pipeline_step: job.pipeline_step,
      pipeline_run: job.pipeline_run,
      parent: job.parent_candidate,
      image_path: full_path,
      status: "active"
    )

    # Counter cache on parent association will automatically increment child_count

    # Link the job to the created candidate
    job.update!(image_candidate: candidate)

    context.image_candidate = candidate
  end
end
