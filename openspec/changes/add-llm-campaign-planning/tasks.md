# Tasks: LLM-Driven Campaign Planning

## Phase 1: Schema & Model Changes
- [ ] Create migration to make `scheduling_posts.photo_id` nullable
- [ ] Add `content_suggestion_id` reference to `scheduling_posts`
- [ ] Add `pipeline_run_id` reference to `scheduling_posts`
- [ ] Add partial index for `photo_id IS NULL` on `scheduling_posts`
- [ ] Update `Scheduling::Post` model to accept optional `photo`
- [ ] Add `belongs_to :content_suggestion, optional: true`
- [ ] Add `belongs_to :pipeline_run, optional: true`
- [ ] Add `awaiting_image` state to state machine
- [ ] Add `ready` state to state machine
- [ ] Add state transition `start_image_generation` (draft → awaiting_image)
- [ ] Add state transition `image_ready` (awaiting_image → ready)
- [ ] Add validation: photo required only for posting states
- [ ] Add scope `awaiting_photo` for posts without images
- [ ] Add scope `with_photo` for posts with images
- [ ] Add method `image_promise_fulfilled?`
- [ ] Run migration
- [ ] Update tests for nullable photo_id

## Phase 2: Campaign Command Layer
- [ ] Create `app/commands/campaign_planning/` directory
- [ ] Create `CreateFromLLM` command class
- [ ] Implement atomic transaction wrapper
- [ ] Create or find GapAnalysis record
- [ ] Store campaign metadata in `recommendations` jsonb
- [ ] Loop through post specifications
- [ ] Find or create ContentPillar by name
- [ ] Create ContentSuggestion with title, description, prompt
- [ ] Store LLM metadata (caption, hashtags, format) in `prompt_data`
- [ ] Create draft Scheduling::Post with nullable photo
- [ ] Link post to content_suggestion
- [ ] Set scheduled_at from LLM-provided date
- [ ] Set caption_draft and hashtags
- [ ] Return array of created suggestions
- [ ] Add error handling for invalid dates
- [ ] Add error handling for missing persona
- [ ] Add validation for required fields
- [ ] Write unit tests for CreateFromLLM

## Phase 3: API Endpoint
- [ ] Create `app/controllers/api/` directory (if not exists)
- [ ] Create `Api::CampaignsController`
- [ ] Add `create` action
- [ ] Parse JSON request body
- [ ] Validate persona_id exists
- [ ] Validate posts array is present
- [ ] Call `CampaignPlanning::CreateFromLLM`
- [ ] Return JSON with created suggestions and posts
- [ ] Handle validation errors (422 status)
- [ ] Handle server errors (500 status)
- [ ] Add route: `post 'api/campaigns', to: 'api/campaigns#create'`
- [ ] Add authentication/authorization (future: API tokens)
- [ ] Write controller tests
- [ ] Write integration tests for full flow

## Phase 4: PipelineRun Auto-linking
- [ ] Open `PipelineRun` model
- [ ] Create method `link_to_awaiting_posts`
- [ ] Query for posts with matching `pipeline_run_id` and `photo_id: nil`
- [ ] Find winner ImageCandidate with `winner: true`
- [ ] Verify winner has associated Photo
- [ ] Update each awaiting post with `photo_id`
- [ ] Trigger state transition `image_ready`
- [ ] Call new method from existing `link_winner_to_pillar_if_completed` callback
- [ ] Add error handling for missing winner
- [ ] Add error handling for missing photo
- [ ] Write tests for auto-linking logic
- [ ] Test edge case: multiple awaiting posts
- [ ] Test edge case: no awaiting posts

## Phase 5: UI Updates
- [ ] Update ContentSuggestions index view
- [ ] Show linked draft post info (if exists)
- [ ] Add "Create Draft Post" button
- [ ] Add "Generate Image" button that creates PipelineRun
- [ ] Create action `create_draft_post` in ContentSuggestionsController
- [ ] Extract LLM metadata from prompt_data
- [ ] Create Scheduling::Post record
- [ ] Link to content_suggestion
- [ ] Set status to 'draft'
- [ ] Update action `generate_image` to link pipeline_run
- [ ] Find or create associated draft post
- [ ] Update post with pipeline_run_id
- [ ] Transition post to `awaiting_image` state
- [ ] Add visual indicators for post status in UI
- [ ] Show "Image Pending" badge for awaiting_image posts
- [ ] Show "Ready to Schedule" badge for ready posts
- [ ] Write feature tests for UI workflow

## Phase 6: Documentation & Polish
- [ ] Add API documentation for `/api/campaigns` endpoint
- [ ] Document MCP tool schema for Ollama integration
- [ ] Add example request/response payloads
- [ ] Update README with campaign planning workflow
- [ ] Add comments to CreateFromLLM command
- [ ] Add comments to auto-linking logic
- [ ] Create database diagram showing new relationships
- [ ] Write user guide for LLM-driven campaigns
- [ ] Add example Ollama MCP server configuration

## Phase 7: Testing & Validation
- [ ] Run full test suite
- [ ] Test end-to-end: API call → suggestions → posts → images → ready
- [ ] Test error cases: invalid persona, invalid dates
- [ ] Test state transitions manually
- [ ] Test with actual Ollama MCP tool
- [ ] Verify no N+1 queries
- [ ] Check performance with 20+ post campaigns
- [ ] Validate database constraints work correctly
