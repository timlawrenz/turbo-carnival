class PipelineRun < ApplicationRecord
  include Turbo::Broadcastable

  belongs_to :pipeline, touch: true
  has_many :image_candidates, dependent: :destroy
  has_many :pipeline_run_steps, dependent: :destroy

  validates :pipeline, presence: true
  validates :status, inclusion: { in: %w[pending running completed failed] }

  after_create :create_pipeline_run_steps
  after_update_commit :broadcast_run_update

  def step_approved?(step)
    pipeline_run_steps.find_by(pipeline_step: step)&.approved? || false
  end

  def approve_step!(step, top_k: 3)
    prs = pipeline_run_steps.find_or_create_by(pipeline_step: step)
    raise "Step already approved" if prs.approved?

    prs.update!(
      approved: true,
      approved_at: Time.current,
      top_k_count: top_k
    )
  end

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

  private

  def create_pipeline_run_steps
    pipeline.pipeline_steps.each do |step|
      pipeline_run_steps.create!(
        pipeline_step: step,
        approved: false,
        approved_at: nil,
        top_k_count: JobOrchestrationConfig.max_children_per_node
      )
    end
  end
end
