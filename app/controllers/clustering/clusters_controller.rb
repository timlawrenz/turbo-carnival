module Clustering
  class ClustersController < ApplicationController
    before_action :set_persona
    before_action :set_pillar, only: [:new, :create]
    before_action :set_cluster, only: [:show, :upload_photos]

    def index
      @clusters = @persona.clusters.includes(:pillars, :photos).order(created_at: :desc)
    end

    def show
      @runs = @cluster.pipeline_runs.includes(:image_candidates).order(created_at: :desc)
      @photos = @cluster.photos.order(created_at: :desc)
    end

    def new
      @cluster = @persona.clusters.build
    end

    def create
      @cluster = @persona.clusters.build(cluster_params)
      
      if @cluster.save
        # Assign to pillar if provided
        if @pillar
          PillarClusterAssignment.create!(
            cluster: @cluster,
            pillar: @pillar,
            primary: true
          )
        end
        
        redirect_to persona_pillar_cluster_path(@persona, @pillar, @cluster), 
                    notice: "Cluster created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def upload_photos
      return render json: { error: 'No photos provided' }, status: :bad_request unless params[:photos]

      uploaded_photos = []
      failed_uploads = []

      Array(params[:photos]).each do |photo_file|
        # Validate file format
        unless valid_photo_format?(photo_file)
          failed_uploads << { 
            file: photo_file.original_filename, 
            error: "Invalid file type. Accepted: JPG, PNG, WEBP" 
          }
          next
        end

        # Validate file size
        unless valid_photo_size?(photo_file)
          failed_uploads << { 
            file: photo_file.original_filename, 
            error: "File too large. Maximum size: 10MB" 
          }
          next
        end

        begin
          # Create photo record
          photo = Clustering::Photo.create!(
            persona: @cluster.persona,
            cluster: @cluster,
            path: generate_upload_path(photo_file)
          )

          # Attach file via ActiveStorage
          photo.image.attach(photo_file)
          uploaded_photos << photo
        rescue => e
          failed_uploads << { 
            file: photo_file.original_filename, 
            error: e.message 
          }
        end
      end

      render json: {
        success: uploaded_photos.count,
        failed: failed_uploads.count,
        photos: uploaded_photos.map(&:id),
        errors: failed_uploads,
        message: upload_message(uploaded_photos.count, failed_uploads.count)
      }
    end

    private

    def set_persona
      @persona = Persona.find(params[:persona_id])
    end

    def set_pillar
      @pillar = @persona.content_pillars.find(params[:pillar_id]) if params[:pillar_id]
    end

    def set_cluster
      if params[:pillar_id]
        @pillar = @persona.content_pillars.find(params[:pillar_id])
        @cluster = @pillar.clusters.find(params[:id])
      else
        @cluster = @persona.clusters.find(params[:id])
      end
    end

    def cluster_params
      params.require(:cluster).permit(:name, :ai_prompt, :status)
    end

    def valid_photo_format?(file)
      return false unless file.respond_to?(:original_filename)
      allowed_formats = %w[.jpg .jpeg .png .webp]
      extension = File.extname(file.original_filename).downcase
      allowed_formats.include?(extension)
    end

    def valid_photo_size?(file)
      return false unless file.respond_to?(:size)
      max_size = 10.megabytes
      file.size <= max_size
    end

    def generate_upload_path(file)
      timestamp = Time.current.to_i
      ext = File.extname(file.original_filename)
      "uploads/cluster_#{@cluster.id}/photo_#{timestamp}#{ext}"
    end

    def upload_message(success_count, failed_count)
      if failed_count.zero?
        "#{success_count} #{'photo'.pluralize(success_count)} uploaded successfully"
      elsif success_count.zero?
        "All uploads failed"
      else
        "#{success_count} #{'photo'.pluralize(success_count)} uploaded, #{failed_count} failed"
      end
    end
  end
end
