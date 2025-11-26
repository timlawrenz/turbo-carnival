# frozen_string_literal: true

require "rails_helper"

RSpec.describe Base::TabsComponent, type: :component do
  it "renders tabs" do
    render_inline(described_class.new) do |component|
      component.with_tab(id: "tab1", label: "First", active: true)
      component.with_tab(id: "tab2", label: "Second")
    end

    expect(page).to have_text("First")
    expect(page).to have_text("Second")
    expect(page).to have_css('button[type="button"]', count: 2)
  end

  it "marks active tab" do
    render_inline(described_class.new) do |component|
      component.with_tab(id: "tab1", label: "First", active: true)
      component.with_tab(id: "tab2", label: "Second")
    end

    expect(page).to have_css('.border-blue-600.text-blue-600', text: "First")
    expect(page).to have_css('.border-transparent.text-zinc-600', text: "Second")
  end
end
