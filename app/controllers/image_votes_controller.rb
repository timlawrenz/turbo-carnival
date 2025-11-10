class ImageVotesController < ApplicationController
  def show
    @pair = fetch_next_pair

    if @pair.nil?
      @message = "All images have been reviewed!"
    else
      @candidate_a, @candidate_b = @pair
    end
  end

  def vote
    winner = ImageCandidate.find(params[:winner_id])
    loser = ImageCandidate.find(params[:loser_id])

    RecordVote.call!(winner: winner, loser: loser)

    redirect_to vote_path
  end

  def reject
    candidate = ImageCandidate.find(params[:id])
    result = RejectImageBranch.call!(image_candidate: candidate)

    # Navigate to parent's step if available
    if result.parent_navigation && result.parent_navigation[:parent]
      parent = result.parent_navigation[:parent]
      sibling = result.parent_navigation[:sibling]
      
      # Store in session for next page load
      session[:kill_navigation] = {
        parent_id: parent.id,
        sibling_id: sibling&.id
      }
    end

    redirect_to vote_path
  end

  private

  def fetch_next_pair
    # Check if we're navigating from a kill action
    if session[:kill_navigation]
      nav = session.delete(:kill_navigation) # Use once then clear
      parent = ImageCandidate.find_by(id: nav['parent_id'], status: 'active')
      
      if parent
        # Find another candidate in the same step as the parent
        candidates = ImageCandidate.where(
          pipeline_step_id: parent.pipeline_step_id,
          status: 'active'
        ).where.not(id: parent.id)
        
        other = candidates.sample
        return [parent, other] if other
      end
    end

    # Triage-right: prioritize rightmost pipeline steps
    pipeline_steps = PipelineStep.order(order: :desc)

    pipeline_steps.each do |step|
      pairs = ImageCandidate.unvoted_pairs(step)
      return pairs.sample if pairs.any?  # Use .sample instead of .first for random selection
    end

    nil
  end
end
