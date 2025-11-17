require "rails_helper"

RSpec.describe BuildJobPayload do
  let(:pipeline) { FactoryBot.create(:pipeline) }
  let(:pipeline_run) do
    FactoryBot.create(:pipeline_run,
      pipeline: pipeline,
      prompt: "at the gym",
      target_folder: "/storage/runs/test-run",
      variables: { persona_id: 123, style: "realistic" })
  end

  describe "#call" do
    context "with workflow JSON" do
      it "includes workflow from step" do
        step = FactoryBot.create(:pipeline_step,
          pipeline: pipeline,
          comfy_workflow_json: '{"nodes": ["a", "b"]}')

        result = described_class.call(
          pipeline_step: step,
          pipeline_run: pipeline_run
        )

        expect(result).to be_success
        expect(result.job_payload[:workflow]).to eq({ "nodes" => [ "a", "b" ] })
      end
    end

    context "template variable substitution" do
      it "replaces {{prompt}} in workflow JSON" do
        step = FactoryBot.create(:pipeline_step,
          pipeline: pipeline,
          comfy_workflow_json: '{"prompt": "{{prompt}}"}')

        result = described_class.call(
          pipeline_step: step,
          pipeline_run: pipeline_run
        )

        expect(result).to be_success
        expect(result.job_payload[:workflow]).to eq({ "prompt" => "at the gym" })
      end

      it "replaces {{run_name}} in workflow JSON" do
        run_with_name = FactoryBot.create(:pipeline_run,
          pipeline: pipeline,
          name: "Test Run 123")
        step = FactoryBot.create(:pipeline_step,
          pipeline: pipeline,
          comfy_workflow_json: '{"path": "/output/{{run_name}}/image.png"}')

        result = described_class.call(
          pipeline_step: step,
          pipeline_run: run_with_name
        )

        expect(result).to be_success
        expect(result.job_payload[:workflow]).to eq({ "path" => "/output/Test Run 123/image.png" })
      end
    end

    context "with needs_run_prompt" do
      it "includes prompt from run column" do
        step = FactoryBot.create(:pipeline_step,
          pipeline: pipeline,
          needs_run_prompt: true,
          comfy_workflow_json: '{}')

        result = described_class.call(
          pipeline_step: step,
          pipeline_run: pipeline_run
        )

        expect(result.job_payload[:variables][:prompt]).to eq("at the gym")
      end

      it "does not include prompt when flag is false" do
        step = FactoryBot.create(:pipeline_step,
          pipeline: pipeline,
          needs_run_prompt: false,
          comfy_workflow_json: '{}')

        result = described_class.call(
          pipeline_step: step,
          pipeline_run: pipeline_run
        )

        expect(result.job_payload[:variables][:prompt]).to be_nil
      end
    end

    context "with needs_parent_image_path" do
      it "includes parent image path" do
        step = FactoryBot.create(:pipeline_step,
          pipeline: pipeline,
          needs_parent_image_path: true,
          comfy_workflow_json: '{}')
        parent = FactoryBot.create(:image_candidate, image_path: "/images/parent.png")

        result = described_class.call(
          pipeline_step: step,
          pipeline_run: pipeline_run,
          parent_candidate: parent
        )

        expect(result.job_payload[:variables][:parent_image]).to eq("/images/parent.png")
      end

      it "does not include parent path when no parent provided" do
        step = FactoryBot.create(:pipeline_step,
          pipeline: pipeline,
          needs_parent_image_path: true,
          comfy_workflow_json: '{}')

        result = described_class.call(
          pipeline_step: step,
          pipeline_run: pipeline_run
        )

        expect(result.job_payload[:variables][:parent_image]).to be_nil
      end
    end

    context "with needs_run_variables" do
      it "includes all run variables plus prompt" do
        step = FactoryBot.create(:pipeline_step,
          pipeline: pipeline,
          needs_run_variables: true,
          comfy_workflow_json: '{}')

        result = described_class.call(
          pipeline_step: step,
          pipeline_run: pipeline_run
        )

        expect(result.job_payload[:variables][:prompt]).to eq("at the gym")
        expect(result.job_payload[:variables][:persona_id]).to eq(123)
        expect(result.job_payload[:variables][:style]).to eq("realistic")
      end
    end

    context "output folder" do
      it "combines run target_folder with step name" do
        step = FactoryBot.create(:pipeline_step,
          pipeline: pipeline,
          name: "Face Fix",
          comfy_workflow_json: '{}')

        result = described_class.call(
          pipeline_step: step,
          pipeline_run: pipeline_run
        )

        expect(result.job_payload[:output_folder]).to eq("/storage/runs/test-run/face-fix")
      end

      it "handles nil target_folder" do
        run_no_folder = FactoryBot.create(:pipeline_run,
          pipeline: pipeline,
          target_folder: nil,
          variables: {})
        step = FactoryBot.create(:pipeline_step,
          pipeline: pipeline,
          name: "Base",
          comfy_workflow_json: '{}')

        result = described_class.call(
          pipeline_step: step,
          pipeline_run: run_no_folder
        )

        expect(result.job_payload[:output_folder]).to eq("/base")
      end
    end

    context "combined variable requirements" do
      it "includes both prompt and parent when needed" do
        step = FactoryBot.create(:pipeline_step,
          pipeline: pipeline,
          needs_run_prompt: true,
          needs_parent_image_path: true,
          comfy_workflow_json: '{}')
        parent = FactoryBot.create(:image_candidate, image_path: "/images/parent.png")

        result = described_class.call(
          pipeline_step: step,
          pipeline_run: pipeline_run,
          parent_candidate: parent
        )

        expect(result.job_payload[:variables][:prompt]).to eq("at the gym")
        expect(result.job_payload[:variables][:parent_image]).to eq("/images/parent.png")
      end
    end
  end
end
