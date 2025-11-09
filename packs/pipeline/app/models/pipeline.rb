class Pipeline < ApplicationRecord
  has_many :pipeline_steps, -> { order(:order) }, dependent: :destroy
  has_many :pipeline_runs, dependent: :destroy

  validates :name, presence: true
end
