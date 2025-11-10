class JobSubmitterWorker
  include Sidekiq::Worker

  sidekiq_options queue: :job_submission, retry: 3

  def perform
    result = SelectNextJob.call

    case result.mode
    when :child_generation, :base_generation
      submit_job(result)
      schedule_next_run
    when :no_work
      schedule_next_run
    end
  end

  private

  def submit_job(select_result)
    # Determine the pipeline_run
    pipeline_run = if select_result.parent_candidate
                     select_result.parent_candidate.pipeline_run
    else
                     # For base generation, use the first active run or create one
                     PipelineRun.last || create_default_run(select_result.next_step.pipeline)
    end

    payload_result = BuildJobPayload.call(
      pipeline_step: select_result.next_step,
      pipeline_run: pipeline_run,
      parent_candidate: select_result.parent_candidate
    )

    return unless payload_result.success?

    SubmitJob.call(
      job_payload: payload_result.job_payload,
      pipeline_step: select_result.next_step,
      pipeline_run: pipeline_run,
      parent_candidate: select_result.parent_candidate
    )
  end

  def create_default_run(pipeline)
    PipelineRun.create!(
      pipeline: pipeline,
      variables: { prompt: "default prompt" },
      target_folder: Rails.root.join("storage", "pipeline_runs", Time.current.to_i.to_s).to_s
    )
  end

  def schedule_next_run
    interval = ENV.fetch("COMFYUI_SUBMIT_INTERVAL", 10).to_i
    self.class.perform_in(interval.seconds)
  end
end
