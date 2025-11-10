FactoryBot.define do
  factory :comfyui_job do
    pipeline_run
    pipeline_step
    image_candidate { nil }

    status { "pending" }
    job_payload { { workflow: { nodes: [] }, variables: {}, output_folder: "/tmp/test" } }
    retry_count { 0 }

    trait :submitted do
      status { "submitted" }
      comfyui_job_id { SecureRandom.uuid }
      submitted_at { Time.current }
    end

    trait :running do
      status { "running" }
      comfyui_job_id { SecureRandom.uuid }
      submitted_at { 1.minute.ago }
    end

    trait :completed do
      status { "completed" }
      comfyui_job_id { SecureRandom.uuid }
      submitted_at { 2.minutes.ago }
      completed_at { Time.current }
      result_metadata { { images: [ { url: "/view/output.png", filename: "output.png" } ] } }
    end

    trait :failed do
      status { "failed" }
      comfyui_job_id { SecureRandom.uuid }
      submitted_at { 2.minutes.ago }
      error_message { "Job failed in ComfyUI" }
    end
  end
end
