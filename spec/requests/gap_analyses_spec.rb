require 'rails_helper'

RSpec.describe "GapAnalyses", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/gap_analyses/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/gap_analyses/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/gap_analyses/create"
      expect(response).to have_http_status(:success)
    end
  end

end
