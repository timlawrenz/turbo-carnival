# frozen_string_literal: true

# Component for displaying a single image candidate with vote button
class VotingCardComponent < ApplicationComponent
  def initialize(candidate:, opponent:, run:, position: :left)
    @candidate = candidate
    @opponent = opponent
    @run = run
    @position = position
  end

  attr_reader :candidate, :opponent, :run, :position
end
