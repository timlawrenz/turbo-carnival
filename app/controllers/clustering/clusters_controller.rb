module Clustering
  class ClustersController < ApplicationController
    before_action :set_persona
    before_action :set_pillar, only: [:new, :create]
    before_action :set_cluster, only: [:show]

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
  end
end
