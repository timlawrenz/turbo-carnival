# frozen_string_literal: true

module Growth
  # Point-in-time follower count for a goal.
  class Snapshot < ApplicationRecord
    self.table_name = 'growth_snapshots'

    belongs_to :goal, class_name: 'Growth::Goal'

    validates :followers, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :taken_at, presence: true
  end
end