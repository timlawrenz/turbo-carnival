# frozen_string_literal: true

require "rails_helper"

RSpec.describe CardComponent, type: :component do
  describe "rendering" do
    it "renders a card with body content" do
      result = render_inline(CardComponent.new) do |c|
        c.with_body { "Card content" }
      end
      expect(result.to_html).to include("Card content")
    end
  end
end
