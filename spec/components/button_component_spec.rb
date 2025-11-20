# frozen_string_literal: true

require "rails_helper"

RSpec.describe ButtonComponent, type: :component do
  describe "rendering" do
    it "renders a button with text" do
      result = render_inline(ButtonComponent.new(text: "Click Me"))
      expect(result.to_html).to include("Click Me")
    end

    it "renders primary variant" do
      result = render_inline(ButtonComponent.new(text: "Submit", variant: :primary))
      expect(result.to_html).to include("bg-blue-600")
    end

    it "renders danger variant" do
      result = render_inline(ButtonComponent.new(text: "Delete", variant: :danger))
      expect(result.to_html).to include("bg-red-600")
    end
  end
end
