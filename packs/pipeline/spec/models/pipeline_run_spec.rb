require "rails_helper"

RSpec.describe PipelineRun, type: :model do
  describe "associations" do
    it { should belong_to(:pipeline) }
    it { should have_many(:image_candidates).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:pipeline) }
    it { should validate_inclusion_of(:status).in_array(%w[pending running completed failed]) }
  end

  describe "defaults" do
    it "sets default status to pending" do
      run = FactoryBot.create(:pipeline_run)
      expect(run.status).to eq("pending")
    end

    it "sets default variables to empty hash" do
      run = FactoryBot.create(:pipeline_run, variables: {})
      expect(run.variables).to eq({})
    end
  end

  describe "variable storage" do
    it "stores prompt variable" do
      run = FactoryBot.create(:pipeline_run, variables: { prompt: "at home" })
      expect(run.variables["prompt"]).to eq("at home")
    end

    it "stores multiple variables" do
      run = FactoryBot.create(:pipeline_run,
        variables: { prompt: "at the gym", persona_id: 456, style: "realistic" })

      expect(run.variables["prompt"]).to eq("at the gym")
      expect(run.variables["persona_id"]).to eq(456)
      expect(run.variables["style"]).to eq("realistic")
    end
  end

  describe "target folder" do
    it "stores target folder path" do
      run = FactoryBot.create(:pipeline_run, target_folder: "/storage/runs/gym-shoot")
      expect(run.target_folder).to eq("/storage/runs/gym-shoot")
    end
  end

  describe "multiple runs per pipeline" do
    it "allows creating multiple runs for same pipeline" do
      pipeline = FactoryBot.create(:pipeline)

      run1 = FactoryBot.create(:pipeline_run, pipeline: pipeline, variables: { prompt: "at gym" })
      run2 = FactoryBot.create(:pipeline_run, pipeline: pipeline, variables: { prompt: "at home" })
      run3 = FactoryBot.create(:pipeline_run, pipeline: pipeline, variables: { prompt: "at café" })

      expect(pipeline.pipeline_runs).to contain_exactly(run1, run2, run3)
    end
  end

  describe "many candidates per run" do
    it "links multiple image candidates to one run" do
      run = FactoryBot.create(:pipeline_run)
      step1 = FactoryBot.create(:pipeline_step, pipeline: run.pipeline, order: 1)
      step2 = FactoryBot.create(:pipeline_step, pipeline: run.pipeline, order: 2)

      candidate1 = FactoryBot.create(:image_candidate, pipeline_step: step1, pipeline_run: run)
      candidate2 = FactoryBot.create(:image_candidate, pipeline_step: step1, pipeline_run: run)
      candidate3 = FactoryBot.create(:image_candidate, pipeline_step: step2, pipeline_run: run)

      expect(run.image_candidates).to contain_exactly(candidate1, candidate2, candidate3)
    end
  end
end
