# frozen_string_literal: true

class PillarClusterAssignment < ApplicationRecord
  belongs_to :pillar, class_name: 'ContentPillar'

  validates :pillar, presence: true
  validates :cluster_id, uniqueness: { scope: :pillar_id, message: 'already assigned to this pillar' }, allow_nil: true
end
