require "rails_helper"

RSpec.describe RejectImageBranch do
  describe "#call" do
    it "marks candidate as rejected" do
      candidate = FactoryBot.create(:image_candidate, status: "active")

      described_class.call!(image_candidate: candidate)

      expect(candidate.reload.status).to eq("rejected")
    end

    it "returns nil parent_navigation for root candidate" do
      root = FactoryBot.create(:image_candidate, parent: nil)

      result = described_class.call!(image_candidate: root)

      expect(result.parent_navigation).to be_nil
    end

    it "returns parent and sibling for candidate with siblings" do
      parent = FactoryBot.create(:image_candidate)
      child1 = FactoryBot.create(:image_candidate, parent: parent)
      child2 = FactoryBot.create(:image_candidate, parent: parent)

      result = described_class.call!(image_candidate: child1)

      expect(result.parent_navigation[:parent]).to eq(parent)
      expect(result.parent_navigation[:sibling]).to eq(child2)
    end

    it "returns parent with nil sibling when no siblings exist" do
      parent = FactoryBot.create(:image_candidate)
      only_child = FactoryBot.create(:image_candidate, parent: parent)

      result = described_class.call!(image_candidate: only_child)

      expect(result.parent_navigation[:parent]).to eq(parent)
      expect(result.parent_navigation[:sibling]).to be_nil
    end
  end
end
