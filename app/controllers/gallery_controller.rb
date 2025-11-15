class GalleryController < ApplicationController
  before_action :load_run

  def index
    @pipeline = @run.pipeline
    
    # If no step specified, find the latest step with images
    if params[:step].blank?
      latest_step = @pipeline.pipeline_steps.order(order: :desc).find do |step|
        ImageCandidate.where(pipeline_step: step, status: 'active', pipeline_run: @run).exists?
      end
      @selected_step = latest_step || @pipeline.pipeline_steps.order(:order).last
    else
      @selected_step = @pipeline.pipeline_steps.find_by(order: params[:step].to_i)
    end
    
    @candidates = ImageCandidate
      .where(pipeline_step: @selected_step, status: 'active', pipeline_run: @run)
      .order(elo_score: :desc)
      .limit(50)
  end

  def reject
    candidate = ImageCandidate.find(params[:id])
    RejectImageBranch.call!(image_candidate: candidate)
    
    redirect_to run_gallery_path(@run, step: params[:step]), notice: "Candidate rejected"
  end

  private

  def load_run
    @run = PipelineRun.find(params[:run_id])
  end
end
