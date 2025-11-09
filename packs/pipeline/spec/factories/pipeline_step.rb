FactoryBot.define do
  factory :pipeline_step do
    association :pipeline
    sequence(:name) { |n| "Step #{n}" }
    sequence(:order)
    comfy_workflow_json { '{"workflow": "test"}' }
  end
end
