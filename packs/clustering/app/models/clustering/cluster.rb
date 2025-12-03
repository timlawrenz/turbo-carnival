# frozen_string_literal: true

module Clustering
  class Cluster < ApplicationRecord
    self.table_name = 'clusters'

    belongs_to :persona
    has_many :pipeline_runs, class_name: 'PipelineRun', foreign_key: :cluster_id, dependent: :nullify
    has_many :photos, class_name: 'Clustering::Photo', foreign_key: :cluster_id, dependent: :nullify
    has_many :pillar_cluster_assignments, foreign_key: :cluster_id, dependent: :destroy
    has_many :pillars, through: :pillar_cluster_assignments, source: :pillar, class_name: 'ContentPillar'

    attribute :status, :integer, default: 0

    validates :persona, presence: true
    validates :name, presence: true, uniqueness: { scope: :persona_id }

    enum :status, { active: 0, archived: 1, draft: 2 }

    scope :for_persona, ->(persona_id) { where(persona_id: persona_id) }
    scope :for_pillar, ->(pillar) { joins(:pillar_cluster_assignments).where(pillar_cluster_assignments: { pillar_id: pillar.id }) }

    def winners
      pipeline_runs.joins(:image_candidates).where(image_candidates: { winner: true }).distinct
    end

    def winner_count
      winners.count
    end

    def primary_pillar
      pillar_cluster_assignments.find_by(primary: true)&.pillar
    end

    def pillar_names
      pillars.pluck(:name)
    end

    # Convenience method for breadcrumb navigation
    # Returns primary pillar if set, otherwise first pillar
    def content_pillar
      primary_pillar || pillars.first
    end
  end
end
