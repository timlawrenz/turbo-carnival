require "rails_helper"

RSpec.describe Pipeline, type: :model do
  describe "associations" do
    it { should have_many(:pipeline_steps).dependent(:destroy) }
    it { should have_many(:pipeline_runs).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "ordered steps" do
    it "returns steps in ascending order" do
      pipeline = FactoryBot.create(:pipeline)
      step3 = FactoryBot.create(:pipeline_step, pipeline: pipeline, order: 3)
      step1 = FactoryBot.create(:pipeline_step, pipeline: pipeline, order: 1)
      step2 = FactoryBot.create(:pipeline_step, pipeline: pipeline, order: 2)

      expect(pipeline.pipeline_steps).to eq([ step1, step2, step3 ])
    end
  end

  describe "multiple runs" do
    it "allows creating multiple runs for the same pipeline" do
      pipeline = FactoryBot.create(:pipeline)
      run1 = FactoryBot.create(:pipeline_run, pipeline: pipeline)
      run2 = FactoryBot.create(:pipeline_run, pipeline: pipeline)
      run3 = FactoryBot.create(:pipeline_run, pipeline: pipeline)

      expect(pipeline.pipeline_runs).to contain_exactly(run1, run2, run3)
    end
  end
end
