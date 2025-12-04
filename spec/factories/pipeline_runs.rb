# frozen_string_literal: true

FactoryBot.define do
  factory :pipeline_run do
    association :cluster, factory: :clustering_cluster
    workflow_path { "test_workflow.json" }
    status { "pending" }
  end
end
