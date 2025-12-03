FactoryBot.define do
  factory :content_suggestion do
    gap_analysis { nil }
    content_pillar { nil }
    title { "MyString" }
    description { "MyText" }
    prompt_data { "" }
    status { "MyString" }
    used_at { "2025-12-03 18:46:50" }
  end
end
