# frozen_string_literal: true

require "rails_helper"

RSpec.describe Base::TooltipComponent, type: :component do
  it "renders tooltip with text" do
    render_inline(described_class.new(text: "Helpful tip")) { "Hover me" }

    expect(page).to have_text("Hover me")
    expect(page).to have_css('[role="tooltip"]', text: "Helpful tip")
  end

  it "positions tooltip at top by default" do
    render_inline(described_class.new(text: "Tip")) { "Content" }

    expect(page).to have_css('.bottom-full')
  end

  it "positions tooltip at specified location" do
    render_inline(described_class.new(text: "Tip", position: :right)) { "Content" }

    expect(page).to have_css('.left-full')
  end
end
