module Clustering
  class ClustersController < ApplicationController
    before_action :set_persona
    before_action :set_pillar, only: [:new, :create]
    before_action :set_cluster, only: [:show, :edit, :update, :destroy]

    def new
      @cluster = Clustering::Cluster.new(persona: @persona)
    end

    def create
      @cluster = Clustering::Cluster.new(cluster_params.merge(persona: @persona))
      
      if @cluster.save
        # Link to pillar if specified
        if params[:pillar_id].present?
          PillarClusterAssignment.create!(
            pillar: @pillar,
            cluster: @cluster,
            primary: true
          )
        end
        
        redirect_to persona_pillar_cluster_path(@persona, @pillar, @cluster), 
                    notice: "Cluster created successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @pillar = @cluster.pillars.first # Get primary pillar
      @runs = PipelineRun.where(cluster: @cluster).order(created_at: :desc)
    end

    def edit
    end

    def update
      if @cluster.update(cluster_params)
        redirect_to persona_pillar_cluster_path(@persona, @pillar, @cluster), 
                    notice: "Cluster updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @cluster.destroy
      redirect_to persona_pillar_path(@persona, @pillar), 
                  notice: "Cluster deleted"
    end

    private

    def set_persona
      @persona = Persona.find(params[:persona_id])
    end

    def set_pillar
      @pillar = ContentPillar.find(params[:pillar_id]) if params[:pillar_id].present?
    end

    def set_cluster
      @cluster = Clustering::Cluster.find(params[:id])
      @pillar = @cluster.pillars.first
    end

    def cluster_params
      params.require(:clustering_cluster).permit(:name, :ai_prompt, :status)
    end
  end
end
