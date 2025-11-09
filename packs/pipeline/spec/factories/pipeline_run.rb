FactoryBot.define do
  factory :pipeline_run do
    association :pipeline
    sequence(:name) { |n| "Run #{n}" }
    target_folder { "/tmp/runs/#{SecureRandom.hex(8)}" }
    variables { { prompt: "test prompt", persona_id: 123 } }
    status { "pending" }
  end
end
