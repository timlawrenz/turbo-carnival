class Pipeline < ApplicationRecord
  has_many :pipeline_steps, -> { order(:order) }, dependent: :destroy

  validates :name, presence: true
end
