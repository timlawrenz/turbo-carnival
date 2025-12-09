# frozen_string_literal: true

class Scheduling::PostsController < ApplicationController
  before_action :set_photo, only: [:new, :create, :suggest_caption]

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

  def new
    @post = Scheduling::Post.new(photo: @photo, persona: @photo.persona)
    @suggested_caption = nil
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

    result = CaptionGeneration::Generator.generate(
      photo: @photo,
      persona: @photo.persona,
      cluster: @photo.cluster
    )

    if result.success?
      render turbo_stream: turbo_stream.update(
        'caption_suggestion',
        partial: 'scheduling/posts/caption_suggestion',
        locals: { caption: result.text, metadata: result.metadata }
      )
    else
      render turbo_stream: turbo_stream.update(
        'caption_suggestion',
        partial: 'scheduling/posts/caption_error',
        locals: { error: result.metadata[:error] }
      )
    end
  end

  private

  def set_photo
    @photo = Clustering::Photo.find(params[:photo_id] || params[:id])
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
