require "rails_helper"

RSpec.describe ImageCandidate, type: :model do
  describe "associations" do
    it { should belong_to(:pipeline_step) }
    it { should belong_to(:pipeline_run).optional }
    it { should belong_to(:parent).class_name("ImageCandidate").optional }
    it { should have_many(:children).class_name("ImageCandidate").with_foreign_key(:parent_id).dependent(:nullify) }
  end

  describe "validations" do
    it { should validate_numericality_of(:elo_score).only_integer }
    it { should validate_numericality_of(:child_count).only_integer.is_greater_than_or_equal_to(0) }
    it { should validate_inclusion_of(:status).in_array(%w[active rejected]) }
  end

  describe "defaults" do
    it "sets default elo_score to 1000" do
      candidate = FactoryBot.create(:image_candidate)
      expect(candidate.elo_score).to eq(1000)
    end

    it "sets default status to active" do
      candidate = FactoryBot.create(:image_candidate)
      expect(candidate.status).to eq("active")
    end

    it "sets default child_count to 0" do
      candidate = FactoryBot.create(:image_candidate)
      expect(candidate.child_count).to eq(0)
    end
  end

  describe "tree structure" do
    it "creates root candidate without parent" do
      candidate = FactoryBot.create(:image_candidate, parent: nil)
      expect(candidate.parent_id).to be_nil
    end

    it "creates child candidate with parent reference" do
      parent = FactoryBot.create(:image_candidate)
      child = FactoryBot.create(:image_candidate, parent: parent)

      expect(child.parent).to eq(parent)
    end

    it "links multiple children to same parent" do
      parent = FactoryBot.create(:image_candidate)
      child1 = FactoryBot.create(:image_candidate, parent: parent)
      child2 = FactoryBot.create(:image_candidate, parent: parent)

      expect(parent.children).to contain_exactly(child1, child2)
    end
  end

  describe "counter cache" do
    it "increments parent child_count when child is created" do
      parent = FactoryBot.create(:image_candidate)
      expect { FactoryBot.create(:image_candidate, parent: parent) }
        .to change { parent.reload.child_count }.from(0).to(1)
    end

    it "decrements parent child_count when child is destroyed" do
      parent = FactoryBot.create(:image_candidate)
      child = FactoryBot.create(:image_candidate, parent: parent)

      expect { child.destroy }
        .to change { parent.reload.child_count }.from(1).to(0)
    end
  end

  describe "state machine" do
    it "starts in active state" do
      candidate = FactoryBot.create(:image_candidate)
      expect(candidate.status).to eq("active")
    end

    it "transitions from active to rejected" do
      candidate = FactoryBot.create(:image_candidate)
      candidate.reject

      expect(candidate.status).to eq("rejected")
    end

    it "does not allow transition from rejected to active" do
      candidate = FactoryBot.create(:image_candidate)
      candidate.reject

      expect(candidate).not_to respond_to(:activate)
    end
  end

  describe "status validation" do
    it "rejects invalid status values" do
      candidate = FactoryBot.build(:image_candidate, status: "invalid")
      expect(candidate).not_to be_valid
      expect(candidate.errors[:status]).to be_present
    end
  end

  describe "child_count validation" do
    it "rejects negative child_count" do
      candidate = FactoryBot.build(:image_candidate, child_count: -1)
      expect(candidate).not_to be_valid
      expect(candidate.errors[:child_count]).to be_present
    end
  end

  describe "pipeline run association" do
    it "allows candidate to belong to a pipeline run" do
      run = FactoryBot.create(:pipeline_run)
      step = FactoryBot.create(:pipeline_step, pipeline: run.pipeline)
      candidate = FactoryBot.create(:image_candidate, pipeline_step: step, pipeline_run: run)

      expect(candidate.pipeline_run).to eq(run)
    end

    it "allows backwards compatibility with nil pipeline_run" do
      candidate = FactoryBot.create(:image_candidate, pipeline_run: nil)
      expect(candidate.pipeline_run).to be_nil
      expect(candidate).to be_valid
    end

    it "allows multiple candidates for same run" do
      run = FactoryBot.create(:pipeline_run)
      step = FactoryBot.create(:pipeline_step, pipeline: run.pipeline)

      candidate1 = FactoryBot.create(:image_candidate, pipeline_step: step, pipeline_run: run)
      candidate2 = FactoryBot.create(:image_candidate, pipeline_step: step, pipeline_run: run)

      expect(run.image_candidates).to contain_exactly(candidate1, candidate2)
    end
  end
end
