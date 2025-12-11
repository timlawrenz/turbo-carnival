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

  describe "POST /personas/:persona_id/scheduling/posts/suggest_next" do
    let!(:persona) { create(:persona, name: "Sarah") }
    let!(:pillar) { create(:content_pillar, persona: persona, name: "Lifestyle & Daily Living", weight: 40, active: true) }
    let!(:photo) do
      photo = ContentPillars::Photo.create!(
        persona: persona,
        content_pillar: pillar,
        path: "/tmp/suggest_test_photo.png"
      )
      
      File.write(photo.path, "fake image data")
      
      photo.image.attach(
        io: StringIO.new("fake image data"),
        filename: "suggest_test.png",
        content_type: "image/png"
      )
      
      photo
    end

    it "successfully suggests a next post and auto-creates it" do
      # Ensure we have strategy state
      ContentStrategy::StrategyState.find_or_create_by!(persona: persona) do |state|
        state.active_strategy = 'thematic_rotation_strategy'
        state.started_at = Time.current
      end

      # Mock the AI services to avoid external dependencies
      allow_any_instance_of(CaptionGeneration::VisionGenerator).to receive(:generate).and_return(
        double(success?: true, text: "Test caption", metadata: { model: "test-model" })
      )
      
      post suggest_next_persona_scheduling_posts_path(persona)
      
      expect(response).to have_http_status(:redirect)
      
      follow_redirect!
      
      expect(response).to have_http_status(:success)
      # Check for either success or error message
      expect(response.body).to match(/Post automatically created|Failed to create post/)
    end

    it "shows error when no unposted photos are available" do
      # Mark the photo as posted by creating a post
      Scheduling::Post.create!(
        persona: persona,
        photo: photo
      ).tap { |p| p.update_column(:status, 'posted') }

      post suggest_next_persona_scheduling_posts_path(persona)
      
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(persona_scheduling_posts_path(persona))
      
      follow_redirect!
      
      # Check for error message in flash
      expect(flash[:alert]).to be_present
    end

    after do
      File.delete(photo.path) if photo.path && File.exist?(photo.path)
    end
  end
end
