# frozen_string_literal: true

FactoryBot.define do
  factory :clustering_cluster, class: "Clustering::Cluster" do
    association :pillar, factory: :content_pillar
    name { "Cluster #{rand(1000)}" }
    description { "A test cluster" }
  end
end
