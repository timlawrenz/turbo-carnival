require "rails_helper"

RSpec.describe ProcessJobResult do
  let(:pipeline) { FactoryBot.create(:pipeline) }
  let(:pipeline_run) { FactoryBot.create(:pipeline_run, pipeline: pipeline, target_folder: "/tmp/test-run") }
  let(:pipeline_step) { FactoryBot.create(:pipeline_step, pipeline: pipeline, name: "Face Fix") }
  let(:parent_candidate) { FactoryBot.create(:image_candidate, pipeline_step: pipeline_step, pipeline_run: pipeline_run, child_count: 2) }

  let(:comfyui_job) do
    FactoryBot.create(
      :comfyui_job,
      :completed,
      pipeline_run: pipeline_run,
      pipeline_step: pipeline_step,
      parent_candidate: parent_candidate,
      result_metadata: {
        images: [ { url: "/view/output_123.png", filename: "output_123.png" } ]
      }
    )
  end

  let(:image_data) { "fake_image_binary_data" }

  before do
    allow_any_instance_of(ComfyuiClient).to receive(:download_image).and_return(image_data)
    allow(FileUtils).to receive(:mkdir_p)
    allow(File).to receive(:binwrite)
  end

  describe "#call" do
    it "downloads image from ComfyUI" do
      client = instance_double(ComfyuiClient)
      allow(ComfyuiClient).to receive(:new).and_return(client)
      expect(client).to receive(:download_image).with("/view/output_123.png").and_return(image_data)

      described_class.call(comfyui_job: comfyui_job)
    end

    it "creates target directory" do
      expect(FileUtils).to receive(:mkdir_p).with(%r{/tmp/test-run/face-fix})

      described_class.call(comfyui_job: comfyui_job)
    end

    it "saves image to filesystem" do
      expect(File).to receive(:binwrite).with(
        a_string_matching(%r{/tmp/test-run/face-fix/.*\.png}),
        image_data
      )

      described_class.call(comfyui_job: comfyui_job)
    end

    it "creates ImageCandidate with correct associations" do
      described_class.call(comfyui_job: comfyui_job)

      # The new candidate is the last one created (parent_candidate was created earlier)
      candidate = ImageCandidate.where.not(id: parent_candidate.id).last

      expect(candidate).to be_present
      expect(candidate.pipeline_step).to eq(pipeline_step)
      expect(candidate.pipeline_run).to eq(pipeline_run)
      expect(candidate.parent).to eq(parent_candidate)
      expect(candidate.status).to eq("active")
    end

    it "sets image_path on ImageCandidate" do
      result = described_class.call(comfyui_job: comfyui_job)

      expect(result.image_candidate.image_path).to match(%r{/tmp/test-run/face-fix/.*\.png})
    end

    it "increments parent child_count" do
      initial_count = parent_candidate.child_count

      described_class.call(comfyui_job: comfyui_job)

      expect(parent_candidate.reload.child_count).to eq(initial_count + 1)
    end

    it "links job to created ImageCandidate" do
      result = described_class.call(comfyui_job: comfyui_job)

      expect(comfyui_job.reload.image_candidate).to eq(result.image_candidate)
    end

    it "returns the created ImageCandidate" do
      result = described_class.call(comfyui_job: comfyui_job)

      expect(result).to be_success
      expect(result.image_candidate).to be_a(ImageCandidate)
    end

    context "when job has no parent_candidate" do
      let(:comfyui_job_without_parent) do
        FactoryBot.create(
          :comfyui_job,
          :completed,
          pipeline_run: pipeline_run,
          pipeline_step: pipeline_step,
          parent_candidate: nil,
          result_metadata: {
            images: [ { url: "/view/output_base.png", filename: "output_base.png" } ]
          }
        )
      end

      it "creates ImageCandidate without parent" do
        result = described_class.call(comfyui_job: comfyui_job_without_parent)

        expect(result.image_candidate.parent).to be_nil
      end

      it "does not try to increment parent child_count" do
        expect do
          described_class.call(comfyui_job: comfyui_job_without_parent)
        end.not_to raise_error
      end
    end

    context "when result_metadata has no images" do
      before do
        comfyui_job.update!(result_metadata: { images: [] })
      end

      it "returns failure" do
        result = described_class.call(comfyui_job: comfyui_job)

        expect(result).to be_failure
      end
    end

    context "when download fails" do
      it "returns failure" do
        client = instance_double(ComfyuiClient)
        allow(ComfyuiClient).to receive(:new).and_return(client)
        allow(client).to receive(:download_image).and_raise(ComfyuiClient::ConnectionError)

        result = described_class.call(comfyui_job: comfyui_job)

        expect(result).to be_failure
      end
    end

    context "when file write fails" do
      it "returns failure" do
        allow(File).to receive(:binwrite).and_raise(Errno::EACCES, "Permission denied")

        result = described_class.call(comfyui_job: comfyui_job)

        expect(result).to be_failure
      end
    end

    context "file path construction" do
      it "uses parameterized step name for folder" do
        result = described_class.call(comfyui_job: comfyui_job)

        expect(result.image_candidate.image_path).to include("face-fix")
      end

      it "generates unique filename with timestamp" do
        result = described_class.call(comfyui_job: comfyui_job)
        timestamp = Time.current.to_i

        expect(result.image_candidate.image_path).to match(/#{timestamp}\.png$/)
      end

      it "includes random hex in filename" do
        result = described_class.call(comfyui_job: comfyui_job)

        expect(result.image_candidate.image_path).to match(%r{/[a-f0-9]{16}_\d+\.png$})
      end
    end
  end
end
