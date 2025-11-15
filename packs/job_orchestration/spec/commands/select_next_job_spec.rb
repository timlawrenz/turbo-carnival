require "rails_helper"

RSpec.describe SelectNextJob do
  let(:pipeline) { FactoryBot.create(:pipeline) }
  let!(:pipeline_run) { FactoryBot.create(:pipeline_run, pipeline: pipeline, status: 'running') }
  let!(:step1) { FactoryBot.create(:pipeline_step, pipeline: pipeline, order: 1) }
  let!(:step2) { FactoryBot.create(:pipeline_step, pipeline: pipeline, order: 2) }
  let!(:step3) { FactoryBot.create(:pipeline_step, pipeline: pipeline, order: 3) }

  describe "#call" do
    context "when eligible parents exist" do
      it "selects parents to fill out steps with < 2 candidates first (breadth-first)" do
        # Need 2 step 1 candidates to pass the base image check
        2.times { FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 2) }
        candidate_step1 = FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 1, elo_score: 1500)
        candidate_step2 = FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step2, child_count: 0, elo_score: 800)

        result = described_class.call

        expect(result).to be_success
        expect(result.mode).to eq(:child_generation)
        # Should select step1 candidate to create a 2nd step2 candidate (breadth-first)
        expect(result.parent_candidate).to eq(candidate_step1)
        expect(result.next_step).to eq(step2)
      end
      
      it "returns no_work when all steps have >= 2 candidates" do
        ClimateControl.modify TARGET_LEAF_NODES: "2" do
          # Create 2 candidates in each step - breadth-first is complete
          2.times { FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 2) }
          2.times { FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step2, child_count: 2, elo_score: 1500) }
          2.times { FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step3, child_count: 2) }

          result = described_class.call

          expect(result).to be_success
          expect(result.mode).to eq(:no_work)
          # Strict breadth-first: all steps filled, no more work
          expect(result.parent_candidate).to be_nil
          expect(result.next_step).to be_nil
        end
      end

      it "excludes rejected candidates" do
        # Create 2 active step1 candidates + 1 rejected
        2.times { FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 2) }
        FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 0, status: "rejected")
        candidate_active = FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 0, status: "active")

        result = described_class.call

        expect(result).to be_success
        expect(result.parent_candidate).to eq(candidate_active)
        expect(result.next_step).to eq(step2)
      end

      it "excludes candidates with max children" do
        ClimateControl.modify MAX_CHILDREN_PER_NODE: "5" do
          # Need 5 step1 candidates (breadth-first with N=5)
          4.times { FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 5) }
          FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 5)
          candidate_eligible = FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 4)

          result = described_class.call

          expect(result.parent_candidate).to eq(candidate_eligible)
          expect(result.next_step).to eq(step2)
        end
      end

      it "excludes candidates at final step" do
        # Create 2 step1, 2 step2 (breadth filled)
        2.times { FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 2) }
        candidate_step2 = FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step2, child_count: 0)
        FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step2, child_count: 2)
        # Only 1 step3 candidate - needs filling to reach 2
        FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step3, child_count: 0)

        result = described_class.call

        # Should select step2 parent to fill step3 to 2 candidates
        expect(result.parent_candidate).to eq(candidate_step2)
        expect(result.next_step).to eq(step3)
      end
    end

    context "ELO-weighted raffle" do
      it "selects from candidates at same step" do
        # Create 2 step1 candidates to satisfy breadth-first
        2.times { FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 2) }
        # Create 2 step2 candidates with different ELO - need to fill step3
        candidate_a = FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 0, elo_score: 1200)
        candidate_b = FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 0, elo_score: 800)

        # Run multiple times to test distribution (need step2 to have < 2)
        results = 100.times.map { described_class.call.parent_candidate }

        expect(results).to include(candidate_a)
        expect(results).to include(candidate_b)
        # A should be selected more often (60% vs 40%)
        a_count = results.count(candidate_a)
        expect(a_count).to be > 40
      end

      it "handles single candidate" do
        # Create 2 step1 candidates (satisfy breadth-first)
        2.times { FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 2) }
        # Single eligible candidate at step1 for creating step2
        candidate = FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 0)

        result = described_class.call

        expect(result.parent_candidate).to eq(candidate)
        expect(result.next_step).to eq(step2)
      end

      it "handles zero ELO scores" do
        candidate_a = FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 0, elo_score: 0)
        candidate_b = FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 0, elo_score: 0)

        result = described_class.call

        expect(result.parent_candidate).to be_in([ candidate_a, candidate_b ])
        expect(result.next_step).to eq(step2)
      end
    end

    context "when no eligible parents exist" do
      context "deficit mode" do
        it "triggers base generation when final step has too few candidates" do
          ClimateControl.modify TARGET_LEAF_NODES: "10" do
            # Create 7 candidates in final step (less than target of 10)
            7.times { FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step3, child_count: 5) }

            result = described_class.call

            expect(result).to be_success
            expect(result.mode).to eq(:base_generation)
            expect(result.parent_candidate).to be_nil
            expect(result.next_step).to eq(step1)
          end
        end

        it "does not trigger when final step meets target AND all steps have >= 2 candidates" do
          ClimateControl.modify TARGET_LEAF_NODES: "10" do
            # Create at least 2 in each step, all with max children
            2.times { FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 5) }
            2.times { FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step2, child_count: 5) }
            12.times { FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step3, child_count: 5) }

            result = described_class.call

            expect(result.mode).to eq(:no_work)
          end
        end
      end

      context "no work mode" do
        it "returns no work when no deficit and all steps have min candidates" do
          ClimateControl.modify TARGET_LEAF_NODES: "10" do
            2.times { FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step1, child_count: 5) }
            15.times { FactoryBot.create(:image_candidate, pipeline_run: pipeline_run, pipeline_step: step3, child_count: 5) }

            result = described_class.call

            expect(result).to be_success
            expect(result.mode).to eq(:no_work)
            expect(result.parent_candidate).to be_nil
            expect(result.next_step).to be_nil
          end
        end
      end
    end

    context "edge cases" do
      # Clear the eager-loaded steps for these edge case tests
      before do
        PipelineRun.delete_all
        PipelineStep.delete_all
        Pipeline.delete_all
      end

      it "handles no pipelines" do
        # Don't reference any pipeline/steps to keep DB empty
        result = described_class.call

        expect(result).to be_success
        expect(result.mode).to eq(:no_work)
      end

      it "handles pipeline with no steps" do
        FactoryBot.create(:pipeline) # Create pipeline without steps

        result = described_class.call

        expect(result).to be_success
        expect(result.mode).to eq(:no_work)
      end
    end
  end
end
