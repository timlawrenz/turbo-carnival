require "rails_helper"

RSpec.describe RecordVote do
  describe "#call" do
    it "updates ELO scores for both candidates" do
      winner = FactoryBot.create(:image_candidate, elo_score: 1000, vote_count: 0)
      loser = FactoryBot.create(:image_candidate, elo_score: 1000, vote_count: 0)

      described_class.call!(winner: winner, loser: loser)

      expect(winner.reload.elo_score).to eq(1016)
      expect(loser.reload.elo_score).to eq(984)
    end

    it "increments vote_count for both candidates" do
      winner = FactoryBot.create(:image_candidate, vote_count: 0)
      loser = FactoryBot.create(:image_candidate, vote_count: 0)

      described_class.call!(winner: winner, loser: loser)

      expect(winner.reload.vote_count).to eq(1)
      expect(loser.reload.vote_count).to eq(1)
    end

    it "increments vote_count from existing values" do
      winner = FactoryBot.create(:image_candidate, vote_count: 5)
      loser = FactoryBot.create(:image_candidate, vote_count: 3)

      described_class.call!(winner: winner, loser: loser)

      expect(winner.reload.vote_count).to eq(6)
      expect(loser.reload.vote_count).to eq(4)
    end

    it "gives larger ELO gain to underdog winner" do
      underdog = FactoryBot.create(:image_candidate, elo_score: 800)
      favorite = FactoryBot.create(:image_candidate, elo_score: 1200)

      described_class.call!(winner: underdog, loser: favorite)

      expect(underdog.reload.elo_score).to be > 816
      expect(favorite.reload.elo_score).to be < 1184
    end

    it "gives smaller ELO gain to favorite winner" do
      favorite = FactoryBot.create(:image_candidate, elo_score: 1200)
      underdog = FactoryBot.create(:image_candidate, elo_score: 800)

      described_class.call!(winner: favorite, loser: underdog)

      expect(favorite.reload.elo_score).to be < 1216
      expect(underdog.reload.elo_score).to be > 784
    end

    it "runs in a transaction" do
      winner = FactoryBot.create(:image_candidate, elo_score: 1000)
      loser = FactoryBot.create(:image_candidate, elo_score: 1000)

      # Stub update to raise error for loser
      allow(loser).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      allow(ImageCandidate).to receive(:find).with(loser.id).and_return(loser)

      expect {
        described_class.call!(winner: winner, loser: loser)
      }.to raise_error(ActiveRecord::RecordInvalid)

      # Winner's score should also be rolled back
      expect(winner.reload.elo_score).to eq(1000)
      expect(winner.reload.vote_count).to eq(0)
    end
  end
end
