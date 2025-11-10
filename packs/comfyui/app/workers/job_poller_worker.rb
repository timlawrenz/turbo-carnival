class JobPollerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :job_polling, retry: 3

  def perform
    in_flight_jobs = ComfyuiJob.in_flight

    in_flight_jobs.find_each do |job|
      poll_and_process(job)
    end

    schedule_next_run
  end

  private

  def poll_and_process(job)
    result = PollJobStatus.call(comfyui_job: job)

    return unless result.success?

    if result.needs_processing
      ProcessJobResult.call(comfyui_job: job)
    end
  rescue => e
    Rails.logger.error("JobPollerWorker failed for job #{job.id}: #{e.message}")
    Rails.logger.error(e.backtrace.first(5).join("\n"))
  end

  def schedule_next_run
    interval = ENV.fetch("COMFYUI_POLL_INTERVAL", 5).to_i
    self.class.perform_in(interval.seconds)
  end
end
