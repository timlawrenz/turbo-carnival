# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Growth::CadenceEngine do
  subject(:engine) { described_class.new(goal: goal) }

  let(:persona) { create(:persona) }
  let!(:pillar_a) { create(:content_pillar, persona: persona, name: 'Fashion & Style', weight: 20) }
  let!(:pillar_b) { create(:content_pillar, persona: persona, name: 'Food & Cooking', weight: 10) }
  let(:goal) { create(:growth_goal, persona: persona, posts_per_day: 1, max_posts_per_day: 3) }

  before do
    # posts_target = 1*7 = 7; existing 6 => shortfall 1 (single slot).
    allow(engine).to receive(:scheduled_posts_count).and_return(6)
  end

  describe '#sync' do
    it 'moves ON to another pillar when the first is NSFW-rejected, and records a pillar_shift' do
      rejected = { success: false, error: 'nsfw_rejected (label=lingerie score=0.97)', run_id: 1 }
      accepted = {
        success: true, post_id: 10, photo_id: 20, run_id: 2,
        image_path: '/mnt/fscache/essdee/ComfyUI/output/fresh_x.png'
      }

      calls = []
      allow(engine).to receive(:generate_fresh) do |_offset, pillar|
        calls << pillar&.name
        calls.size == 1 ? rejected : accepted
      end

      result = engine.sync

      # The slot was filled despite the first pillar being rejected.
      expect(result[:created]).to eq(1)
      expect(calls.size).to eq(2)
      # Only the rejection should be recorded as a pillar shift (no hard block).
      expect(result[:failures]).to be_empty
      expect(Growth::Decision.where(action: 'pillar_shift').count).to eq(1)
    end

    it 'hard-stalls only when EVERY pillar is rejected' do
      allow(engine).to receive(:generate_fresh) do |_offset, _pillar|
        { success: false, error: 'nsfw_rejected (label=lingerie score=0.99)', run_id: 1 }
      end

      result = engine.sync

      expect(result[:created]).to eq(0)
      expect(result[:failures]).not_to be_empty
      # cadence_blocked is recorded because the WHOLE pool was exhausted.
      expect(Growth::Decision.where(action: 'cadence_blocked').count).to eq(1)
    end

    it 'does not try to move on when the failure is NOT an NSFW rejection' do
      allow(engine).to receive(:generate_fresh) do
        { success: false, error: 'render timed out or produced no image', run_id: 3 }
      end

      result = engine.sync

      expect(result[:created]).to eq(0)
      expect(Growth::Decision.where(action: 'pillar_shift').count).to eq(0)
      expect(Growth::Decision.where(action: 'cadence_blocked').count).to eq(1)
    end
  end
end