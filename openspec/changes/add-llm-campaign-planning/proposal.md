# Proposal: LLM-Driven Campaign Planning with MCP Tools

## Summary
Enable LLMs (via Ollama MCP) to act as strategic content planners by creating multi-week content campaigns consisting of `ContentSuggestion` and `Scheduling::Post` records. Humans retain full control over prompt refinement and execution triggers, while the LLM provides the strategic planning framework.

## Motivation
Currently, content creation is tactical (one image/post at a time). Users want to:
1. Plan cohesive multi-week campaigns (e.g., "Holiday Season 2025 Strategy")
2. Generate 5-20 coordinated post ideas with dates, themes, and draft captions
3. Review and refine prompts before committing resources to image generation
4. Schedule posts in advance, even before images exist

This mirrors how professional content strategists work: plan the calendar, then execute tactically.

## Goals
- **Strategic Planning**: LLM creates campaign blueprints (dates, themes, prompts, captions)
- **Human Control**: Users review/edit prompts and explicitly trigger pipeline runs
- **Deferred Execution**: Schedule posts before images exist ("image promises")
- **Seamless Integration**: Works with existing Pipeline/ComfyUI/Scheduling infrastructure

## Non-Goals
- Autonomous posting (humans approve everything)
- Replacing existing single-post workflow
- Complex campaign analytics (future work)

## User Stories

### Story 1: Campaign Creation
**As a** content manager  
**I want to** ask an LLM to create a holiday campaign strategy  
**So that** I get 10-15 coordinated post ideas with dates and prompts

**Acceptance:**
- LLM receives persona context (caption_config, hashtag_strategy, pillars)
- LLM creates GapAnalysis with campaign metadata
- LLM creates ContentSuggestion records (title, description, image prompt)
- LLM creates draft Scheduling::Post records (scheduled_at, caption, hashtags)
- Posts are created WITHOUT photos (photo_id: nil)

### Story 2: Prompt Refinement
**As a** content creator  
**I want to** review and edit AI-generated image prompts  
**So that** I maintain creative control before spending GPU resources

**Acceptance:**
- View list of ContentSuggestions from campaign
- Edit prompt inline
- See linked draft post details (date, caption)
- Trigger pipeline run when satisfied

### Story 3: Image Promise Fulfillment
**As the** system  
**I want to** automatically link completed images to awaiting posts  
**So that** campaigns execute seamlessly after generation

**Acceptance:**
- PipelineRun completes and selects winner
- System finds Scheduling::Posts with matching pipeline_run_id
- System updates post with photo_id
- Post status changes from `awaiting_image` → `ready`

## Technical Approach

### Phase 1: Schema Changes
Make `Scheduling::Post.photo_id` nullable and add linkage:

```ruby
# Migration
change_column_null :scheduling_posts, :photo_id, true
add_reference :scheduling_posts, :content_suggestion
add_reference :scheduling_posts, :pipeline_run
add_index :scheduling_posts, :photo_id, where: "photo_id IS NULL"
```

### Phase 2: MCP Tool Definition
Create RESTful API endpoint for LLM to call:

**Endpoint:** `POST /api/campaigns`

**Payload:**
```json
{
  "persona_id": 1,
  "campaign_name": "Holiday Season 2025",
  "strategy_metadata": { "theme": "...", "tone": "..." },
  "posts": [
    {
      "title": "Grandma's Cookie Recipe",
      "description": "Personal story about learning to bake",
      "content_pillar_name": "Holiday Traditions",
      "image_prompt": "cozy kitchen, warm lighting, cookies...",
      "scheduled_at": "2025-12-15T14:00:00Z",
      "caption_draft": "I still remember the crackle...",
      "hashtags": ["#HolidayMemories", "#CozyVibes"],
      "format": "reel"
    }
  ]
}
```

### Phase 3: Command Implementation
```ruby
module CampaignPlanning
  class CreateFromLLM
    # Creates GapAnalysis, ContentSuggestions, Scheduling::Posts atomically
  end
end
```

### Phase 4: Auto-linking Logic
Enhance `PipelineRun#link_winner_to_pillar_if_completed`:
- Find awaiting Scheduling::Posts
- Link winner photo
- Transition status to `ready`

## Dependencies
- Existing: GapAnalysis, ContentSuggestion, PipelineRun, Scheduling::Post
- New: API controller for MCP tool
- External: Ollama with MCP server

## Design Decisions

### 1. Use GapAnalysis (No Campaign Model)
**Decision:** Reuse existing `GapAnalysis` model to represent campaigns.

**Rationale:**
- Semantic fit: Campaigns ARE gap analyses (identifying missing content)
- Already has `has_many :content_suggestions` relationship
- `recommendations` jsonb field perfect for campaign metadata
- Less code, natural evolution of existing pattern
- Can distinguish via `recommendations[:created_by] = 'llm'`

**Future:** If we need versioning, multi-persona campaigns, or complex campaign state, we can extract to dedicated `Campaign` model later.

### 2. Auto-Schedule When Image Ready
**Decision:** Posts with `content_suggestion_id` and `scheduled_at` automatically transition to `scheduled` state when image is linked.

**Rationale:**
- User already approved by: (a) creating campaign, (b) reviewing prompts, (c) triggering generation
- LLM-provided schedule is part of the approved plan
- User retains control: can edit caption/date before scheduled_at
- Matches workflow intent: "Create campaign → Review → Generate → Auto-post"

**Implementation:**
```ruby
if post.content_suggestion_id.present? && post.scheduled_at.present?
  post.schedule!  # Auto-schedule for LLM campaigns
else
  post.image_ready!  # Manual review for standalone posts
end
```

### 3. Campaign Editing Strategy
**Decision:** Phase 1 - no editing. Delete/recreate if changes needed.

**Future:** Add versioning or update-in-place if editing becomes frequent use case.

## Success Metrics
- LLM successfully creates 10+ post campaign in single API call
- User can edit prompts before triggering runs
- Image completion automatically links to posts
- Zero manual data entry for campaigns

## Risks & Mitigations
| Risk | Mitigation |
|------|-----------|
| LLM generates invalid dates | Validate dates server-side |
| ContentPillar doesn't exist | Create missing pillars automatically |
| PipelineRun fails | Post remains in `awaiting_image`, user can retry |
| Caption quality varies | User edits before approval |

## Timeline Estimate
- Schema changes: 2 hours
- API endpoint: 3 hours
- Command implementation: 4 hours
- Auto-linking logic: 2 hours
- Testing & refinement: 4 hours
- **Total: ~15 hours (2 days)**
