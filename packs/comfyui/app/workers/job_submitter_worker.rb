class JobSubmitterWorker
  include Sidekiq::Worker

  sidekiq_options queue: :job_submission, retry: 3

  def perform
    # Only submit if no jobs are currently in flight
    # This ensures we wait for ComfyUI to complete before submitting the next job
    in_flight_count = ComfyuiJob.in_flight.count
    
    if in_flight_count > 0
      Rails.logger.info("JobSubmitterWorker: #{in_flight_count} jobs in flight, waiting...")
      schedule_next_run
      return
    end

    result = SelectNextJob.call

    case result.mode
    when :child_generation, :base_generation
      submit_job(result)
      schedule_next_run
    when :no_work
      schedule_next_run
    end
  rescue StandardError => e
    Rails.logger.error("JobSubmitterWorker failed: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    schedule_next_run
  end

  private

  def submit_job(select_result)
    # Determine the pipeline_run
    pipeline_run = if select_result.parent_candidate&.pipeline_run
                     select_result.parent_candidate.pipeline_run
                   else
                     # For base generation or orphan parents, use the last active run or create one
                     PipelineRun.last || create_default_run(select_result.next_step.pipeline)
                   end

    payload_result = BuildJobPayload.call(
      pipeline_step: select_result.next_step,
      pipeline_run: pipeline_run,
      parent_candidate: select_result.parent_candidate
    )

    unless payload_result.success?
      Rails.logger.error("BuildJobPayload failed for step #{select_result.next_step.id}: #{payload_result.error}")
      return
    end

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
    require 'sidekiq/api'
    
    scheduled_jobs = Sidekiq::ScheduledSet.new.select { |job| job.klass == self.class.name }
    return if scheduled_jobs.any?
    
    interval = ENV.fetch("COMFYUI_SUBMIT_INTERVAL", 10).to_i
    self.class.perform_in(interval.seconds)
  end
end
