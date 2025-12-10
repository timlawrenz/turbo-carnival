# frozen_string_literal: true

FactoryBot.define do
  factory :clustering_cluster, class: "Clustering::Cluster" do
    persona
    name { "Cluster #{rand(1000)}" }
    ai_prompt { "A test cluster prompt" }
    
    # Create pillar association after cluster is created
    after(:build) do |cluster, evaluator|
      # If a pillar is provided, use its persona
      if evaluator.pillar
        cluster.persona = evaluator.pillar.persona
      end
    end
    
    after(:create) do |cluster, evaluator|
      if evaluator.pillar
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
