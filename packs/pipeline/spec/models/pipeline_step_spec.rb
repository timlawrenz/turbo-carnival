require "rails_helper"

RSpec.describe PipelineStep, type: :model do
  describe "associations" do
    it { should belong_to(:pipeline) }
    it { should have_many(:image_candidates).dependent(:destroy) }
  end

  describe "validations" do
    subject { FactoryBot.build(:pipeline_step) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:order) }
    it { should validate_presence_of(:comfy_workflow_json) }
    it { should validate_numericality_of(:order).only_integer.is_greater_than_or_equal_to(1) }
    it { should validate_uniqueness_of(:order).scoped_to(:pipeline_id) }
  end

  describe "order constraint" do
    it "prevents duplicate order values within the same pipeline" do
      pipeline = FactoryBot.create(:pipeline)
      FactoryBot.create(:pipeline_step, pipeline: pipeline, order: 1)
      duplicate_step = FactoryBot.build(:pipeline_step, pipeline: pipeline, order: 1)

      expect(duplicate_step).not_to be_valid
      expect(duplicate_step.errors[:order]).to be_present
    end

    it "allows same order value in different pipelines" do
      pipeline1 = FactoryBot.create(:pipeline)
      pipeline2 = FactoryBot.create(:pipeline)
      FactoryBot.create(:pipeline_step, pipeline: pipeline1, order: 1)
      step2 = FactoryBot.build(:pipeline_step, pipeline: pipeline2, order: 1)

      expect(step2).to be_valid
    end
  end

  describe "order validation" do
    it "rejects order values less than 1" do
      step = FactoryBot.build(:pipeline_step, order: 0)
      expect(step).not_to be_valid
      expect(step.errors[:order]).to be_present
    end

    it "rejects negative order values" do
      step = FactoryBot.build(:pipeline_step, order: -1)
      expect(step).not_to be_valid
      expect(step.errors[:order]).to be_present
    end
  end

  describe "variable requirement flags" do
    it "defaults all flags to false" do
      step = FactoryBot.create(:pipeline_step)
      expect(step.needs_run_prompt).to be false
      expect(step.needs_parent_image_path).to be false
      expect(step.needs_run_variables).to be false
    end

    it "allows setting needs_run_prompt" do
      step = FactoryBot.create(:pipeline_step, needs_run_prompt: true)
      expect(step.needs_run_prompt).to be true
    end

    it "allows setting needs_parent_image_path" do
      step = FactoryBot.create(:pipeline_step, needs_parent_image_path: true)
      expect(step.needs_parent_image_path).to be true
    end

    it "allows setting needs_run_variables" do
      step = FactoryBot.create(:pipeline_step, needs_run_variables: true)
      expect(step.needs_run_variables).to be true
    end

    it "allows setting multiple flags" do
      step = FactoryBot.create(:pipeline_step,
        needs_run_prompt: true,
        needs_parent_image_path: true)

      expect(step.needs_run_prompt).to be true
      expect(step.needs_parent_image_path).to be true
    end
  end
end
