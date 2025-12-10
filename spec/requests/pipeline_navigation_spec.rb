# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pipeline Happy Path", type: :request do
  describe "Full pipeline flow: Dashboard → Persona → Pillar → Cluster → Run" do
    let!(:persona) { create(:persona, name: "Test Persona") }
    let!(:pillar) { create(:content_pillar, persona: persona, name: "Test Pillar") }
    let!(:cluster) { create(:clustering_cluster, pillar: pillar, name: "Test Cluster") }
    let!(:pipeline) { create(:pipeline, name: "Test Pipeline") }
    let!(:run) { create(:pipeline_run, pipeline: pipeline, cluster: cluster, status: "pending") }

    context "Dashboard" do
      it "shows dashboard with personas" do
        get root_path
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Dashboard")
        expect(response.body).to include("Test Persona")
      end

      it "shows stats cards" do
        get root_path
        
        expect(response.body).to include("Personas")
        expect(response.body).to include("Content Pillars")
        expect(response.body).to include("Clusters")
        expect(response.body).to include("Total Runs")
      end
    end

    context "Persona navigation" do
      it "shows persona detail page" do
        get persona_path(persona)
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Test Persona")
      end

      it "shows content pillars in sidebar" do
        get persona_path(persona)
        
        expect(response.body).to include("Test Pillar")
        expect(response.body).to include("Content Pillars")
      end

      it "shows back to dashboard link in sidebar" do
        get persona_path(persona)
        
        expect(response.body).to include("← Dashboard")
      end
    end

    context "Content Pillar navigation" do
      it "shows pillar detail page" do
        get persona_pillar_path(persona, pillar)
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Test Pillar")
      end

      it "shows clusters in sidebar" do
        get persona_pillar_path(persona, pillar)
        
        expect(response.body).to include("Test Cluster")
        expect(response.body).to include("Clusters")
      end

      it "shows back to persona link in sidebar" do
        get persona_pillar_path(persona, pillar)
        
        expect(response.body).to include("← Test Persona")
      end
    end

    context "Cluster navigation" do
      it "shows cluster detail page" do
        get persona_pillar_cluster_path(persona, pillar, cluster)
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Test Cluster")
      end

      it "shows recent runs in sidebar" do
        get persona_pillar_cluster_path(persona, pillar, cluster)
        
        expect(response.body).to include("Recent Runs")
      end

      it "shows back to pillar link in sidebar" do
        get persona_pillar_cluster_path(persona, pillar, cluster)
        
        expect(response.body).to include("← Test Pillar")
      end
    end

    context "Run navigation" do
      it "shows run detail page" do
        get run_path(run)
        
        expect(response).to have_http_status(:success)
      end

      it "shows back to cluster link in sidebar" do
        get run_path(run)
        
        expect(response.body).to include("← Test Cluster")
      end
    end
  end

  describe "Creating resources through the hierarchy" do
    let!(:persona) { create(:persona, name: "New Persona") }

    context "Creating a persona" do
      it "allows creating a new persona from dashboard" do
        get new_persona_path
        
        expect(response).to have_http_status(:success)
      end

      it "creates persona and redirects" do
        post personas_path, params: {
          persona: {
            name: "Created Persona",
            caption_config: { tone: "professional" },
            hashtag_strategy: { max_count: 5 }
          }
        }
        
        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response.body).to include("Created Persona")
      end
    end

    context "Creating a cluster" do
      let!(:pillar) { create(:content_pillar, persona: persona) }

      it "allows creating cluster under pillar" do
        get new_persona_pillar_cluster_path(persona, pillar)
        
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "Sidebar navigation context" do
    let!(:persona) { create(:persona, name: "Context Persona") }
    let!(:pillar) { create(:content_pillar, persona: persona, name: "Context Pillar") }
    let!(:cluster) { create(:clustering_cluster, pillar: pillar, name: "Context Cluster") }

    it "shows personas when on dashboard" do
      get root_path
      
      expect(response.body).to include("Personas")
      expect(response.body).to include("Context Persona")
    end

    it "shows content pillars when viewing persona" do
      get persona_path(persona)
      
      expect(response.body).to include("Content Pillars")
      expect(response.body).to include("Context Pillar")
    end

    it "shows clusters when viewing pillar" do
      get persona_pillar_path(persona, pillar)
      
      expect(response.body).to include("Clusters")
      expect(response.body).to include("Context Cluster")
    end

    it "shows recent runs when viewing cluster" do
      pipeline = create(:pipeline)
      create(:pipeline_run, pipeline: pipeline, cluster: cluster, status: "completed")
      
      get persona_pillar_cluster_path(persona, pillar, cluster)
      
      expect(response.body).to include("Recent Runs")
    end
  end

  describe "Breadcrumb navigation" do
    let!(:persona) { create(:persona, name: "Breadcrumb Persona") }
    let!(:pillar) { create(:content_pillar, persona: persona, name: "Breadcrumb Pillar") }
    let!(:cluster) { create(:clustering_cluster, pillar: pillar, name: "Breadcrumb Cluster") }

    it "has no breadcrumbs on dashboard" do
      get root_path
      
      expect(response.body).not_to include("← ")
    end

    it "has dashboard breadcrumb on persona page" do
      get persona_path(persona)
      
      expect(response.body).to include("← Dashboard")
    end

    it "has persona breadcrumb on pillar page" do
      get persona_pillar_path(persona, pillar)
      
      expect(response.body).to include("← Breadcrumb Persona")
    end

    it "has pillar breadcrumb on cluster page" do
      get persona_pillar_cluster_path(persona, pillar, cluster)
      
      expect(response.body).to include("← Breadcrumb Pillar")
    end
  end
end
