FactoryBot.define do
  factory :pipeline do
    sequence(:name) { |n| "Pipeline #{n}" }
    description { "A test pipeline for image generation" }
  end
end
