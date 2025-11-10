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
    RejectImageBranch.call!(image_candidate: candidate)

    redirect_to vote_path
  end

  private

  def fetch_next_pair
    # Triage-right: prioritize rightmost pipeline steps
    pipeline_steps = PipelineStep.order(order: :desc)

    pipeline_steps.each do |step|
      pairs = ImageCandidate.unvoted_pairs(step)
      return pairs.first if pairs.any?
    end

    nil
  end
end
