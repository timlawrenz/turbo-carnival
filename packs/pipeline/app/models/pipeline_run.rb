class PipelineRun < ApplicationRecord
  include Turbo::Broadcastable
  
  belongs_to :pipeline
  has_many :image_candidates, dependent: :destroy

  validates :pipeline, presence: true
  validates :status, inclusion: { in: %w[pending running completed failed] }
  
  # Broadcast updates to the run card when the run changes
  after_update_commit :broadcast_run_update
  
  def broadcast_run_update
    broadcast_replace_to "runs",
      partial: "runs/run_card",
      locals: { run: self },
      target: "run_#{id}"
  end
  
  def broadcast_refresh
    broadcast_replace_to "runs",
      partial: "runs/run_card",
      locals: { run: self },
      target: "run_#{id}"
  end
end
