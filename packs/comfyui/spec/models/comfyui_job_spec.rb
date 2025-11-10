require "rails_helper"

RSpec.describe ComfyuiJob, type: :model do
  describe "associations" do
    it { should belong_to(:pipeline_run) }
    it { should belong_to(:pipeline_step) }
    it { should belong_to(:image_candidate).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:job_payload) }
  end

  describe "scopes" do
    let!(:pending_job) { FactoryBot.create(:comfyui_job, status: "pending") }
    let!(:submitted_job) { FactoryBot.create(:comfyui_job, :submitted) }
    let!(:running_job) { FactoryBot.create(:comfyui_job, :running) }
    let!(:completed_job) { FactoryBot.create(:comfyui_job, :completed) }
    let!(:failed_job) { FactoryBot.create(:comfyui_job, :failed) }

    describe ".pending" do
      it "returns only pending jobs" do
        expect(described_class.pending).to contain_exactly(pending_job)
      end
    end

    describe ".submitted" do
      it "returns only submitted jobs" do
        expect(described_class.submitted).to contain_exactly(submitted_job)
      end
    end

    describe ".running" do
      it "returns only running jobs" do
        expect(described_class.running).to contain_exactly(running_job)
      end
    end

    describe ".completed" do
      it "returns only completed jobs" do
        expect(described_class.completed).to contain_exactly(completed_job)
      end
    end

    describe ".failed" do
      it "returns only failed jobs" do
        expect(described_class.failed).to contain_exactly(failed_job)
      end
    end

    describe ".in_flight" do
      it "returns submitted and running jobs" do
        expect(described_class.in_flight).to contain_exactly(submitted_job, running_job)
      end
    end
  end

  describe "attributes" do
    it "has default status of pending" do
      job = described_class.new(
        pipeline_run: FactoryBot.create(:pipeline_run),
        pipeline_step: FactoryBot.create(:pipeline_step),
        job_payload: {}
      )
      expect(job.status).to eq("pending")
    end

    it "has default retry_count of 0" do
      job = described_class.new(
        pipeline_run: FactoryBot.create(:pipeline_run),
        pipeline_step: FactoryBot.create(:pipeline_step),
        job_payload: {}
      )
      expect(job.retry_count).to eq(0)
    end
  end
end
