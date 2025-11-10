require "rails_helper"

RSpec.describe "ImageVotes", type: :request do
  describe "GET /vote" do
    context "when pairs exist" do
      it "renders the voting interface" do
        pipeline = FactoryBot.create(:pipeline)
        step = FactoryBot.create(:pipeline_step, pipeline: pipeline, order: 1)
        FactoryBot.create(:image_candidate, pipeline_step: step)
        FactoryBot.create(:image_candidate, pipeline_step: step)

        get vote_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Vote for the Better Image")
      end
    end

    context "when no pairs exist" do
      it "shows completion message" do
        get vote_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("All Done")
      end
    end
  end

  describe "POST /vote" do
    it "records the vote and redirects" do
      pipeline = FactoryBot.create(:pipeline)
      step = FactoryBot.create(:pipeline_step, pipeline: pipeline, order: 1)
      winner = FactoryBot.create(:image_candidate, pipeline_step: step, elo_score: 1000)
      loser = FactoryBot.create(:image_candidate, pipeline_step: step, elo_score: 1000)

      post vote_path, params: { winner_id: winner.id, loser_id: loser.id }

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(vote_path)
      expect(winner.reload.elo_score).to eq(1016)
      expect(loser.reload.elo_score).to eq(984)
    end

    it "calls RecordVote command" do
      pipeline = FactoryBot.create(:pipeline)
      step = FactoryBot.create(:pipeline_step, pipeline: pipeline, order: 1)
      winner = FactoryBot.create(:image_candidate, pipeline_step: step)
      loser = FactoryBot.create(:image_candidate, pipeline_step: step)

      expect(RecordVote).to receive(:call!).with(winner: winner, loser: loser)

      post vote_path, params: { winner_id: winner.id, loser_id: loser.id }
    end
  end

  describe "POST /vote/reject/:id" do
    it "rejects the candidate" do
      pipeline = FactoryBot.create(:pipeline)
      step = FactoryBot.create(:pipeline_step, pipeline: pipeline, order: 1)
      candidate = FactoryBot.create(:image_candidate, pipeline_step: step, status: "active")

      post reject_vote_path(candidate)

      expect(response).to have_http_status(:redirect)
      expect(candidate.reload.status).to eq("rejected")
    end

    it "calls RejectImageBranch command" do
      pipeline = FactoryBot.create(:pipeline)
      step = FactoryBot.create(:pipeline_step, pipeline: pipeline, order: 1)
      candidate = FactoryBot.create(:image_candidate, pipeline_step: step)

      expect(RejectImageBranch).to receive(:call!).with(image_candidate: candidate).and_call_original

      post reject_vote_path(candidate)
    end
  end
end
