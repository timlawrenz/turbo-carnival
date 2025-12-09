# frozen_string_literal: true

module ContentStrategy
  class HistoryRecord < ApplicationRecord
    self.table_name = 'content_strategy_histories'

    belongs_to :persona
    belongs_to :post, class_name: 'Scheduling::Post', optional: true
    belongs_to :cluster, class_name: 'Clustering::Cluster', optional: true

    validates :persona, presence: true
    validates :strategy_name, presence: true
    validates :created_at, presence: true

    scope :for_persona, ->(persona_id) { where(persona_id: persona_id) }
    scope :for_cluster, ->(cluster_id) { where(cluster_id: cluster_id) }
    scope :recent_days, ->(days) { where('created_at >= ?', days.days.ago) }
    scope :recent, -> { order(created_at: :desc) }
  end
end
