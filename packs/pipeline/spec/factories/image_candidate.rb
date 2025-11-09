FactoryBot.define do
  factory :image_candidate do
    association :pipeline_step
    parent { nil }
    image_path { "/tmp/images/test_#{SecureRandom.hex(8)}.png" }
    elo_score { 1000 }
    status { "active" }
    child_count { 0 }
  end
end
