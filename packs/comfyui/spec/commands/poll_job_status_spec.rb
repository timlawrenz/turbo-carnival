require "rails_helper"

RSpec.describe PollJobStatus do
  let(:comfyui_job) { FactoryBot.create(:comfyui_job, :submitted) }

  describe "#call" do
    context "when job is running" do
      let(:api_response) { { status: "running" } }

      before do
        allow_any_instance_of(ComfyuiClient).to receive(:get_job_status).and_return(api_response)
      end

      it "updates job status to running" do
        described_class.call(comfyui_job: comfyui_job)

        expect(comfyui_job.reload.status).to eq("running")
      end

      it "returns status as running" do
        result = described_class.call(comfyui_job: comfyui_job)

        expect(result.status).to eq("running")
      end

      it "sets needs_processing to false" do
        result = described_class.call(comfyui_job: comfyui_job)

        expect(result.needs_processing).to be false
      end

      it "calls ComfyUI API with job ID" do
        client = instance_double(ComfyuiClient)
        allow(ComfyuiClient).to receive(:new).and_return(client)
        expect(client).to receive(:get_job_status).with(comfyui_job.comfyui_job_id).and_return(api_response)

        described_class.call(comfyui_job: comfyui_job)
      end
    end

    context "when job is completed" do
      let(:api_response) do
        {
          status: "completed",
          output: {
            images: [ { url: "/view/output.png", filename: "output.png" } ]
          }
        }
      end

      before do
        allow_any_instance_of(ComfyuiClient).to receive(:get_job_status).and_return(api_response)
      end

      it "updates job status to completed" do
        described_class.call(comfyui_job: comfyui_job)

        expect(comfyui_job.reload.status).to eq("completed")
      end

      it "stores result metadata" do
        described_class.call(comfyui_job: comfyui_job)

        expect(comfyui_job.reload.result_metadata).to eq(api_response[:output].deep_stringify_keys)
      end

      it "sets completed_at timestamp" do
        described_class.call(comfyui_job: comfyui_job)

        expect(comfyui_job.reload.completed_at).to be_within(1.second).of(Time.current)
      end

      it "returns status as completed" do
        result = described_class.call(comfyui_job: comfyui_job)

        expect(result.status).to eq("completed")
      end

      it "sets needs_processing to true" do
        result = described_class.call(comfyui_job: comfyui_job)

        expect(result.needs_processing).to be true
      end
    end

    context "when job has failed" do
      let(:api_response) do
        {
          status: "failed",
          error: "Job execution failed"
        }
      end

      before do
        allow_any_instance_of(ComfyuiClient).to receive(:get_job_status).and_return(api_response)
      end

      it "updates job status to failed" do
        described_class.call(comfyui_job: comfyui_job)

        expect(comfyui_job.reload.status).to eq("failed")
      end

      it "stores error message" do
        described_class.call(comfyui_job: comfyui_job)

        expect(comfyui_job.reload.error_message).to eq("Job execution failed")
      end

      it "returns status as failed" do
        result = described_class.call(comfyui_job: comfyui_job)

        expect(result.status).to eq("failed")
      end

      it "sets needs_processing to false" do
        result = described_class.call(comfyui_job: comfyui_job)

        expect(result.needs_processing).to be false
      end
    end
  end
end
