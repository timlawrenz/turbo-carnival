# frozen_string_literal: true

class Scheduling::PostsController < ApplicationController
  before_action :set_photo, only: [:new, :create, :suggest_caption]
  before_action :set_persona, only: [:suggest_next]

  def index
    @photos = Clustering::Photo
      .joins(:image_attachment)
      .where.not(id: Scheduling::Post.select(:photo_id))
      .order(created_at: :desc)

    @photos = @photos.where(persona_id: params[:persona_id]) if params[:persona_id].present?
    @photos = @photos.where(cluster_id: params[:cluster_id]) if params[:cluster_id].present?

    @personas = Persona.order(:name)
    @clusters = Clustering::Cluster.order(:name)
  end

  def suggest_next
    if params[:persona_id].blank?
      redirect_to scheduling_posts_path, alert: "Please select a persona first"
      return
    end

    result = ContentStrategy::SelectNextPost.new(persona: @persona).call

    if result[:success]
      # Redirect to new post form with suggested photo and strategy metadata
      redirect_to new_scheduling_post_path(
        photo_id: result[:photo].id,
        strategy_name: result[:strategy_name],
        cluster_id: result[:cluster].id,
        optimal_time: result[:optimal_time],
        suggested_hashtags: result[:hashtags].join(' ')
      ), notice: "Photo suggested by #{result[:strategy_name].humanize} strategy"
    else
      redirect_to scheduling_posts_path, alert: result[:error]
    end
  end

  def new
    @post = Scheduling::Post.new(photo: @photo, persona: @photo.persona)
    @suggested_caption = params[:suggested_caption]
    
    # Strategy metadata if coming from suggest_next
    @strategy_name = params[:strategy_name]
    @cluster_id = params[:cluster_id]
    @optimal_time = params[:optimal_time]
    @suggested_hashtags = params[:suggested_hashtags]
  end

  def create
    @post = Scheduling::Post.new(post_params)
    @post.photo = @photo
    @post.persona = @photo.persona

    if params[:commit] == 'Post Now'
      create_and_post_now
    else
      create_and_schedule
    end
  end

  def suggest_caption
    load_caption_services

    start_time = Time.current
    result = CaptionGeneration::Generator.generate(
      photo: @photo,
      persona: @photo.persona,
      cluster: @photo.cluster
    )
    generation_time = (Time.current - start_time).round(1)

    if result.success?
      @suggested_caption = result.text
      @suggestion_metadata = result.metadata.merge(
        generation_time: generation_time,
        word_count: result.text.split.size
      )
      redirect_to new_scheduling_post_path(photo_id: @photo.id, suggested_caption: @suggested_caption)
    else
      redirect_to new_scheduling_post_path(photo_id: @photo.id), alert: "Caption generation failed: #{result.metadata[:error]}"
    end
  end

  private

  def set_persona
    @persona = Persona.find(params[:persona_id])
  end

  def set_photo
    photo_id = params[:photo_id] || params[:id] || params.dig(:scheduling_post, :photo_id)
    @photo = Clustering::Photo.find(photo_id)
  end

  def post_params
    params.require(:scheduling_post).permit(:caption, :scheduled_at, :status)
  end

  def create_and_post_now
    result = Scheduling::SchedulePost.call(
      photo: @photo,
      persona: @photo.persona,
      caption: post_params[:caption]
    )

    if result.success?
      redirect_to scheduling_posts_path, notice: "Post published to Instagram! ID: #{result.post.provider_post_id}"
    else
      @post.errors.add(:base, result.errors.join(', '))
      render :new, status: :unprocessable_entity
    end
  end

  def create_and_schedule
    @post.status = 'draft'
    @post.scheduled_at = post_params[:scheduled_at] || 1.hour.from_now

    if @post.save
      redirect_to scheduling_posts_path, notice: "Post scheduled for #{@post.scheduled_at.strftime('%b %d at %I:%M %p')}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def load_caption_services
    Dir['packs/caption_generation/app/services/caption_generation/*.rb'].sort.each { |f| load f }
    load 'lib/ai/ollama_client.rb' unless defined?(AI::OllamaClient)
  end
end
