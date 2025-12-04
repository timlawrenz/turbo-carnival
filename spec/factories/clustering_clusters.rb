# frozen_string_literal: true

FactoryBot.define do
  factory :clustering_cluster, class: "Clustering::Cluster" do
    association :persona
    name { "Cluster #{rand(1000)}" }
    description { "A test cluster" }
    
    # Create pillar association after cluster is created
    after(:create) do |cluster, evaluator|
      if evaluator.respond_to?(:pillar) && evaluator.pillar
        PillarClusterAssignment.create!(
          pillar: evaluator.pillar,
          cluster: cluster,
          primary: true
        )
      end
    end
    
    # Allow passing pillar as a transient attribute
    transient do
      pillar { nil }
    end
  end
end
