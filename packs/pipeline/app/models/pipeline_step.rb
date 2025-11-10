class PipelineStep < ApplicationRecord
  belongs_to :pipeline
  has_many :image_candidates, dependent: :destroy
  has_many :comfyui_jobs, dependent: :destroy

  validates :name, presence: true
  validates :order, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :comfy_workflow_json, presence: true
  validates :order, uniqueness: { scope: :pipeline_id }
end
