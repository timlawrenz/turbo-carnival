class ImageCandidate < ApplicationRecord
  belongs_to :pipeline_step
  belongs_to :pipeline_run, optional: true
  belongs_to :parent, class_name: "ImageCandidate", optional: true, counter_cache: :child_count
  has_many :children, class_name: "ImageCandidate", foreign_key: :parent_id, dependent: :nullify

  validates :elo_score, numericality: { only_integer: true }
  validates :status, inclusion: { in: %w[active rejected] }
  validates :child_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :vote_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  state_machine :status, initial: :active do
    state :active
    state :rejected

    event :reject do
      transition active: :rejected
    end
  end

  scope :active, -> { where(status: "active") }

  def calculate_elo_change(opponent, won)
    k_factor = 32
    expected_score = 1.0 / (1.0 + 10.0**((opponent.elo_score - elo_score) / 400.0))
    actual_score = won ? 1.0 : 0.0
    (k_factor * (actual_score - expected_score)).round
  end

  def parent_with_sibling
    return nil unless parent

    sibling = parent.children.active.where.not(id: id).first
    { parent: parent, sibling: sibling }
  end

  def self.unvoted_pairs(pipeline_step)
    candidates = where(pipeline_step: pipeline_step, status: "active")
                  .order(:vote_count, :id)
                  .to_a

    return [] if candidates.empty?

    # Generate all possible pairs
    all_pairs = candidates.combination(2).to_a

    # Sort pairs by the sum of vote counts (prioritize pairs with lower total votes)
    all_pairs.sort_by! { |a, b| a.vote_count + b.vote_count }

    all_pairs
  end
end
