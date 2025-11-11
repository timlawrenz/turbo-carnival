class WinnersController < ApplicationController
  def index
    @winners = ImageCandidate.where(winner: true).order(winner_at: :desc)
  end
end
