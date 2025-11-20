# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImageDisplayComponent, type: :component do
  it "displays image when path exists" do
    result = render_inline(ImageDisplayComponent.new(image_path: "/test.jpg"))
    expect(result.to_html).to include("/test.jpg")
    expect(result.to_html).to include("<img")
  end

  it "displays fallback when path is blank" do
    result = render_inline(ImageDisplayComponent.new(image_path: ""))
    expect(result.to_html).to include("No image")
    expect(result.to_html).not_to include("<img")
  end
end
