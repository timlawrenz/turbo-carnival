# Design: LLM-Driven Campaign Planning

## Architecture Overview

```
┌─────────────────┐
│  Ollama + MCP   │
│   LLM Agent     │
└────────┬────────┘
         │ POST /api/campaigns
         ▼
┌─────────────────────────────────────┐
│  Api::CampaignsController           │
│  - Validates request                │
│  - Calls CreateFromLLM command      │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  CampaignPlanning::CreateFromLLM    │
│  Transaction:                       │
│    1. Create/Find GapAnalysis       │
│    2. Create ContentSuggestions     │
│    3. Create Draft Scheduling::Posts│
└────────┬────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────┐
│  Database State                            │
│  ┌──────────────────┐  ┌─────────────────┐│
│  │ ContentSuggestion├──┤Scheduling::Post ││
│  │ - prompt_data    │  │ - photo: nil    ││
│  │ - status: pending│  │ - status: draft ││
│  └──────────────────┘  └─────────────────┘│
└────────────────────────────────────────────┘
         │
         │ [User reviews, edits prompts]
         ▼
┌─────────────────────────────────────┐
│  ContentSuggestionsController       │
│  - generate_image action            │
│  - Creates PipelineRun              │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  PipelineRun                        │
│  - status: pending → running        │
│  - Generates images via ComfyUI     │
│  - User selects winner              │
│  - status: completed                │
└────────┬────────────────────────────┘
         │
         │ after_update callback
         ▼
┌─────────────────────────────────────┐
│  PipelineRun#link_to_awaiting_posts │
│  - Finds posts with pipeline_run_id │
│  - Links winner photo               │
│  - Transitions to 'ready' state     │
└────────┬────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────┐
│  Scheduling::Post                          │
│  - photo: <Photo object>                   │
│  - status: ready                           │
│  - Ready for user to schedule/post         │
└────────────────────────────────────────────┘
```

## Database Schema Changes

### Before (Current)
```ruby
create_table :scheduling_posts do |t|
  t.references :photo, null: false, foreign_key: true  # ❌ Required
  t.references :persona, null: false, foreign_key: true
  t.text :caption
  t.string :status, null: false, default: 'draft'
  # ...
end
```

### After (Proposed)
```ruby
create_table :scheduling_posts do |t|
  t.references :photo, null: true, foreign_key: true  # ✅ Optional
  t.references :persona, null: false, foreign_key: true
  t.references :content_suggestion, foreign_key: true  # ✅ New
  t.references :pipeline_run, foreign_key: true       # ✅ New
  t.text :caption
  t.string :status, null: false, default: 'draft'
  # ...
end

# Index for finding unfulfilled promises
add_index :scheduling_posts, :photo_id, where: "photo_id IS NULL"
```

## State Machine Extension

### Current States
```ruby
state_machine :status, initial: :draft do
  state :draft
  state :scheduled
  state :posting
  state :posted
  state :failed
end
```

### Proposed States
```ruby
state_machine :status, initial: :draft do
  state :draft           # Created, no image
  state :awaiting_image  # PipelineRun in progress
  state :ready           # Image linked, ready to schedule
  state :scheduled       # Scheduled for future posting
  state :posting         # Currently posting
  state :posted          # Successfully posted
  state :failed          # Posting failed
  
  event :start_image_generation do
    transition draft: :awaiting_image
  end
  
  event :image_ready do
    transition awaiting_image: :ready
  end
  
  event :schedule do
    transition ready: :scheduled
  end
  
  # ... existing events
end
```

## API Contract

### Request: POST /api/campaigns

```json
{
  "persona_id": 1,
  "campaign_name": "Holiday Season 2025",
  "strategy_metadata": {
    "theme": "Cozy holiday traditions",
    "tone": "warm, nostalgic",
    "target_audience": "women 25-45"
  },
  "posts": [
    {
      "title": "Grandma's Cookie Recipe",
      "description": "Personal story about learning family baking traditions during the holidays",
      "content_pillar_name": "Holiday Traditions",
      "image_prompt": "cozy kitchen scene, golden hour lighting, freshly baked cookies cooling on wooden counter, warm steam rising, grandmother's hands in frame, vintage mixing bowl, cinnamon and flour dusted on marble surface",
      "scheduled_at": "2025-12-15T14:00:00Z",
      "caption_draft": "I still remember the crackle of the fireplace that snowy December evening when grandma taught me her secret cookie recipe. The smell of cinnamon still takes me back to that moment. What's your favorite holiday memory? ✨",
      "hashtags": ["#HolidayMemories", "#CozyVibes", "#FamilyTraditions", "#HolidayBaking"],
      "format": "reel"
    },
    {
      "title": "Gift Guide Day 1: Self-Care",
      "description": "First in 12-day gift guide series focusing on self-care items",
      "content_pillar_name": "Seasonal Style",
      "image_prompt": "luxurious self-care flatlay, lavender candles, silk eye mask, natural skincare products, soft neutral tones, minimalist aesthetic, marble background",
      "scheduled_at": "2025-12-08T10:00:00Z",
      "caption_draft": "Day 1 of my 12-Day Gift Guide: Self-Care 💆‍♀️ I was skeptical about these lavender candles until a stressful week turned them into my nightly ritual. Swipe to see why they're a lifesaver & where to grab yours (link in bio!) 🌿",
      "hashtags": ["#GiftGuide", "#SelfCare", "#HolidayGifts"],
      "format": "carousel"
    }
  ]
}
```

### Response: 201 Created

```json
{
  "campaign": {
    "id": 42,
    "persona_id": 1,
    "name": "Holiday Season 2025",
    "created_at": "2025-12-10T18:00:00Z",
    "gap_analysis_id": 15
  },
  "suggestions": [
    {
      "id": 101,
      "title": "Grandma's Cookie Recipe",
      "content_pillar_id": 8,
      "status": "pending",
      "draft_post_id": 201
    },
    {
      "id": 102,
      "title": "Gift Guide Day 1: Self-Care",
      "content_pillar_id": 9,
      "status": "pending",
      "draft_post_id": 202
    }
  ],
  "posts": [
    {
      "id": 201,
      "scheduled_at": "2025-12-15T14:00:00Z",
      "status": "draft",
      "has_photo": false,
      "content_suggestion_id": 101
    },
    {
      "id": 202,
      "scheduled_at": "2025-12-08T10:00:00Z",
      "status": "draft",
      "has_photo": false,
      "content_suggestion_id": 102
    }
  ]
}
```

### Error Response: 422 Unprocessable Entity

```json
{
  "error": "Validation failed",
  "details": [
    "Persona with id 999 not found",
    "Post #2: scheduled_at must be in the future",
    "Post #3: image_prompt cannot be blank"
  ]
}
```

## Command Implementation

```ruby
module CampaignPlanning
  class CreateFromLLM
    def initialize(params)
      @params = params
      @persona = Persona.find(params[:persona_id])
      @errors = []
    end
    
    def call
      ActiveRecord::Base.transaction do
        validate!
        create_gap_analysis
        create_content_suggestions_and_posts
        
        {
          campaign: @gap_analysis,
          suggestions: @suggestions,
          posts: @posts
        }
      end
    rescue ActiveRecord::RecordInvalid => e
      raise ValidationError, e.message
    end
    
    private
    
    def validate!
      raise ValidationError, "Persona not found" unless @persona
      raise ValidationError, "Posts array required" if @params[:posts].blank?
      
      @params[:posts].each_with_index do |post_spec, idx|
        if post_spec[:scheduled_at].to_datetime < Time.current
          @errors << "Post ##{idx + 1}: scheduled_at must be in the future"
        end
        
        if post_spec[:image_prompt].blank?
          @errors << "Post ##{idx + 1}: image_prompt cannot be blank"
        end
      end
      
      raise ValidationError, @errors.join("; ") if @errors.any?
    end
    
    def create_gap_analysis
      @gap_analysis = GapAnalysis.create!(
        persona: @persona,
        analyzed_at: Time.current,
        recommendations: {
          campaign_name: @params[:campaign_name],
          strategy_metadata: @params[:strategy_metadata],
          created_by: 'llm',
          model: 'ollama/gpt-oss:120b'
        }
      )
    end
    
    def create_content_suggestions_and_posts
      @suggestions = []
      @posts = []
      
      @params[:posts].each do |post_spec|
        pillar = find_or_create_pillar(post_spec[:content_pillar_name])
        
        suggestion = ContentSuggestion.create!(
          gap_analysis: @gap_analysis,
          content_pillar: pillar,
          title: post_spec[:title],
          description: post_spec[:description],
          prompt_data: {
            prompt: post_spec[:image_prompt],
            llm_metadata: {
              scheduled_at: post_spec[:scheduled_at],
              caption_draft: post_spec[:caption_draft],
              hashtags: post_spec[:hashtags],
              format: post_spec[:format],
              created_by_llm: true
            }
          },
          status: 'pending'
        )
        
        post = Scheduling::Post.create!(
          persona: @persona,
          content_suggestion: suggestion,
          status: 'draft',
          scheduled_at: post_spec[:scheduled_at],
          caption: post_spec[:caption_draft],
          hashtags: post_spec[:hashtags] || [],
          caption_metadata: {
            format: post_spec[:format],
            generated_by: 'llm'
          },
          strategy_name: 'llm_campaign'
        )
        
        @suggestions << suggestion
        @posts << post
      end
    end
    
    def find_or_create_pillar(name)
      @persona.content_pillars.find_or_create_by!(name: name) do |pillar|
        pillar.description = "Auto-created by LLM campaign"
        pillar.weight = 10.0
        pillar.priority = 3
        pillar.active = true
      end
    end
  end
  
  class ValidationError < StandardError; end
end
```

## Auto-linking Implementation

```ruby
# In packs/pipeline/app/models/pipeline_run.rb

def link_winner_to_pillar_if_completed
  return unless status == 'completed'
  return unless content_pillar_id.present?
  
  # Existing logic
  ContentPillars::LinkWinnerToPillar.call(self)
  
  # NEW: Link to awaiting posts
  link_to_awaiting_posts
rescue StandardError => e
  Rails.logger.error("Failed to auto-link for run #{id}: #{e.message}")
end

def link_to_awaiting_posts
  # Find all posts waiting for this pipeline run
  awaiting_posts = Scheduling::Post.where(
    pipeline_run_id: id,
    photo_id: nil
  )
  
  return if awaiting_posts.empty?
  
  # Find the winner image
  winner = image_candidates.find_by(winner: true)
  return unless winner&.photo
  
  # Link and transition
  awaiting_posts.each do |post|
    post.update!(photo: winner.photo)
    
    # Auto-schedule LLM campaigns, manual review for others
    if post.content_suggestion_id.present? && post.scheduled_at.present?
      post.schedule! if post.may_schedule?  # Auto-schedule LLM campaigns
    else
      post.image_ready! if post.may_image_ready?  # Manual review
    end
  end
  
  Rails.logger.info("Linked #{awaiting_posts.count} posts to winner #{winner.id}")
end
```

## Ollama MCP Tool Configuration

```javascript
// mcp-server.js
const express = require('express');
const app = express();

app.post('/tools/create_campaign', async (req, res) => {
  try {
    const response = await fetch('http://localhost:3000/api/campaigns', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(req.body)
    });
    
    const data = await response.json();
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/tools/get_persona_context', async (req, res) => {
  const { persona_id } = req.body;
  
  const response = await fetch(`http://localhost:3000/api/personas/${persona_id}`);
  const persona = await response.json();
  
  res.json({
    name: persona.name,
    caption_config: persona.caption_config,
    hashtag_strategy: persona.hashtag_strategy,
    content_pillars: persona.content_pillars
  });
});

app.listen(3001, () => {
  console.log('MCP server running on port 3001');
});
```

## Security Considerations

1. **Authentication**: Add API token validation before public deployment
2. **Rate Limiting**: Prevent abuse of campaign creation endpoint
3. **Input Validation**: Sanitize all LLM-provided text (SQL injection, XSS)
4. **Date Validation**: Ensure scheduled dates are reasonable (not 10 years in future)
5. **Resource Limits**: Cap maximum posts per campaign (e.g., 50)

## Performance Considerations

1. **Batch Inserts**: Use `insert_all` for large campaigns (future optimization)
2. **Background Processing**: Move API call to Sidekiq if campaigns > 20 posts
3. **Caching**: Cache persona context for repeated LLM requests
4. **Indexes**: Partial index on `photo_id IS NULL` prevents full table scans

## Testing Strategy

1. **Unit Tests**: Command validation, pillar creation, error handling
2. **Integration Tests**: Full API → Database flow
3. **Feature Tests**: UI workflow with Capybara
4. **Contract Tests**: Validate API request/response schemas
5. **Performance Tests**: 50-post campaign creation time < 2 seconds
