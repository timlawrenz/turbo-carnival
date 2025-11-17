require "rails_helper"

RSpec.describe CreatePipelineRun do
  describe "#call" do
    let(:pipeline) { FactoryBot.create(:pipeline, name: "Test Pipeline") }

    it "creates a pipeline run with valid parameters" do
      result = described_class.call(
        pipeline_id: pipeline.id,
        name: "Test Run",
        target_folder: "/storage/test",
        variables: { prompt: "test prompt" }
      )

      expect(result).to be_success
      expect(result.run).to be_a(PipelineRun)
      expect(result.run.name).to eq("Test Run")
      expect(result.run.target_folder).to eq("/storage/test")
      expect(result.run.variables).to eq({ "prompt" => "test prompt" })
      expect(result.run.status).to eq("pending")
    end

    it "generates default name when not provided" do
      result = described_class.call(
        pipeline_id: pipeline.id
      )

      expect(result).to be_success
      expect(result.run.name).to match(/Test Pipeline - \d{8}-\d{6}/)
    end

    it "generates default target folder when not provided" do
      result = described_class.call(
        pipeline_id: pipeline.id,
        name: "My Custom Run"
      )

      expect(result).to be_success
      expect(result.run.target_folder).to match(%r{/storage/runs/my-custom-run-\d{8}-\d{6}})
    end

    it "uses empty hash for variables when not provided" do
      result = described_class.call(
        pipeline_id: pipeline.id
      )

      expect(result).to be_success
      expect(result.run.variables).to eq({})
    end

    it "fails when pipeline_id is not provided" do
      result = described_class.call(
        name: "Test Run"
      )

      expect(result).to be_failure
      expect(result.error).to be_present
    end

    it "fails when pipeline does not exist" do
      result = described_class.call(
        pipeline_id: 999999
      )

      expect(result).to be_failure
      expect(result.full_error_message).to eq("Pipeline not found")
    end

    it "rolls back on failure" do
      # Create a scenario that will fail validation
      allow(PipelineRun).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

      expect {
        described_class.call!(pipeline_id: pipeline.id)
      }.to raise_error(ActiveRecord::RecordInvalid)

      # No run should have been created
      expect(PipelineRun.count).to eq(0)
    end
  end
end
