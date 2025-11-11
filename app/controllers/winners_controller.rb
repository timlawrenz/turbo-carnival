class WinnersController < ApplicationController
  def index
    # Get the rightmost pipeline step (highest order)
    rightmost_step = PipelineStep.order(order: :desc).first
    
    if rightmost_step
      # Get top 3 active candidates from rightmost step, ordered by ELO
      @winners = ImageCandidate.where(
        pipeline_step: rightmost_step,
        status: 'active'
      ).order(elo_score: :desc).limit(3)
      
      @step = rightmost_step
    else
      @winners = []
      @step = nil
    end
  end
end
