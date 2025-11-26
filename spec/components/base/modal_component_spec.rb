# frozen_string_literal: true

require "rails_helper"

RSpec.describe Base::ModalComponent, type: :component do
  it "renders a modal with default size" do
    render_inline(described_class.new(id: "test-modal", title: "Test")) { "Content" }

    expect(page).to have_css('[role="dialog"]')
    expect(page).to have_text("Test")
    expect(page).to have_text("Content")
  end

  it "renders a modal with custom size" do
    render_inline(described_class.new(id: "test-modal", size: :lg)) { "Content" }

    expect(page).to have_css(".max-w-2xl")
  end

  it "renders close button" do
    render_inline(described_class.new(id: "test-modal", title: "Test")) { "Content" }

    expect(page).to have_css('button[type="button"]')
    expect(page).to have_text("Close")
  end
end
