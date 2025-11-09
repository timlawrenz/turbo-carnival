class PipelineRun < ApplicationRecord
  belongs_to :pipeline
  has_many :image_candidates, dependent: :destroy

  validates :pipeline, presence: true
  validates :status, inclusion: { in: %w[pending running completed failed] }
end
