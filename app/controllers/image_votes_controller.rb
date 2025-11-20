class ImageVotesController < ApplicationController
  before_action :load_run

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

    redirect_to run_vote_path(@run)
  end

  def reject
    candidate = ImageCandidate.find(params[:id])
    RejectImageBranch.call!(image_candidate: candidate)

    redirect_to run_vote_path(@run), notice: "Candidate rejected"
  end

  private

  def load_run
    @run = PipelineRun.find(params[:run_id])
  end

  def fetch_next_pair
    # Triage-right: prioritize rightmost pipeline steps
    pipeline_steps = @run.pipeline.pipeline_steps.reorder(order: :desc)

    pipeline_steps.each do |step|
      pairs = ImageCandidate.unvoted_pairs(step).select do |a, b|
        a.pipeline_run_id == @run.id && b.pipeline_run_id == @run.id
      end
      return pairs.sample if pairs.any?
    end

    nil
  end
end
