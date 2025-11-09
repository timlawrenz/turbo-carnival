class ImageCandidate < ApplicationRecord
  belongs_to :pipeline_step
  belongs_to :parent, class_name: "ImageCandidate", optional: true, counter_cache: :child_count
  has_many :children, class_name: "ImageCandidate", foreign_key: :parent_id, dependent: :nullify

  validates :elo_score, numericality: { only_integer: true }
  validates :status, inclusion: { in: %w[active rejected] }
  validates :child_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  state_machine :status, initial: :active do
    state :active
    state :rejected

    event :reject do
      transition active: :rejected
    end
  end
end
