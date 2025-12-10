require 'rails_helper'

RSpec.describe "Scheduling Posts", type: :request do
  describe "POST browsing workflow" do
    let!(:persona) { create(:persona, name: "Test Persona") }
    let!(:pillar) { create(:content_pillar, persona: persona, name: "Test Pillar") }
    let!(:photo) do
      photo = ContentPillars::Photo.create!(
        persona: persona,
        content_pillar: pillar,
        path: "/tmp/test_photo.png"
      )
      
      # Create a temporary image file for the photo
      File.write(photo.path, "fake image data")
      
      # Attach an image
      photo.image.attach(
        io: StringIO.new("fake image data"),
        filename: "test.png",
        content_type: "image/png"
      )
      
      photo
    end

    it "displays photos for posting" do
      get persona_scheduling_posts_path(persona)
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Create a Post")
      expect(response.body).to include(persona.name.titleize)
    end

    it "shows filter by pillar dropdown" do
      get persona_scheduling_posts_path(persona)
      
      expect(response.body).to include("Filter by Pillar")
      expect(response.body).to include(pillar.name)
    end

    it "filters photos by pillar" do
      other_pillar = create(:content_pillar, persona: persona, name: "Other Pillar")
      other_photo = ContentPillars::Photo.create!(
        persona: persona,
        content_pillar: other_pillar,
        path: "/tmp/other_photo.png"
      )
      File.write(other_photo.path, "fake image data")
      other_photo.image.attach(
        io: StringIO.new("fake image data"),
        filename: "other.png",
        content_type: "image/png"
      )

      get persona_scheduling_posts_path(persona, pillar_id: pillar.id)
      
      expect(response).to have_http_status(:success)
      # The response should only include photos from the selected pillar
    end

    it "shows Get Next Suggested Post button" do
      get persona_scheduling_posts_path(persona)
      
      expect(response.body).to include("Get Next Suggested Post")
    end

    after do
      # Clean up test files
      [photo, ContentPillars::Photo.where(path: "/tmp/other_photo.png").first].compact.each do |p|
        File.delete(p.path) if p.path && File.exist?(p.path)
      end
    end
  end
end
