# frozen_string_literal: true

# Component for displaying two candidates side-by-side for comparison
class ComparisonViewComponent < ApplicationComponent
  def initialize(candidate_a:, candidate_b:, run:)
    @candidate_a = candidate_a
    @candidate_b = candidate_b
    @run = run
  end

  attr_reader :candidate_a, :candidate_b, :run
end
