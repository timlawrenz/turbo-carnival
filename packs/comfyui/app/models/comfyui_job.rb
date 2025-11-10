class ComfyuiJob < ApplicationRecord
  belongs_to :pipeline_run
  belongs_to :pipeline_step
  belongs_to :image_candidate, optional: true
  belongs_to :parent_candidate, class_name: "ImageCandidate", optional: true

  validates :status, presence: true
  validates :job_payload, presence: true

  # Status values: pending, submitted, running, completed, failed
  scope :pending, -> { where(status: "pending") }
  scope :submitted, -> { where(status: "submitted") }
  scope :running, -> { where(status: "running") }
  scope :completed, -> { where(status: "completed") }
  scope :failed, -> { where(status: "failed") }
  scope :in_flight, -> { where(status: %w[submitted running]) }
end
