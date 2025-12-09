# Implementation Tasks

## 1. Caption Generation Service ✅
- [x] 1.1 Create caption_generation pack structure
- [x] 1.2 Create Ollama client for Gemma3:27b integration
- [x] 1.3 Create CaptionGenerator service class
- [x] 1.4 Create PromptBuilder with persona/cluster context
- [x] 1.5 Create ContextBuilder for extracting photo/cluster data
- [x] 1.6 Create PostProcessor for formatting and validation
- [x] 1.7 Create RepetitionChecker for avoiding recent phrases
- [ ] 1.8 Write service specs

## 2. Controller and Routes ✅
- [x] 2.1 Create Scheduling::PostsController
- [x] 2.2 Add routes for new, create, and suggest_caption
- [x] 2.3 Add before_action for photo selection
- [x] 2.4 Implement suggest_caption action (AJAX endpoint)
- [ ] 2.5 Write controller specs

## 3. Photo Selection Interface ✅
- [x] 3.1 Create photo index view with filtering
- [x] 3.2 Add filters for persona, cluster, unposted status
- [x] 3.3 Create photo card component with preview
- [x] 3.4 Add "Create Post" button per photo
- [ ] 3.5 Write component previews

## 4. Post Creation Form ✅
- [x] 4.1 Create new post form view
- [x] 4.2 Add photo preview section
- [x] 4.3 Add caption textarea (with character count)
- [x] 4.4 Add hashtags input field
- [x] 4.5 Add "Get AI Suggestions" button
- [x] 4.6 Add schedule datetime picker
- [x] 4.7 Add submit button (Post Now / Schedule)
- [x] 4.8 Style with Tailwind CSS

## 5. AI Suggestion Integration ✅
- [x] 5.1 Create Turbo Frame for AI suggestions
- [x] 5.2 Wire "Get AI Suggestions" button to AJAX call
- [x] 5.3 Show loading state during generation
- [x] 5.4 Prefill textarea with AI suggestion
- [x] 5.5 Handle errors gracefully
- [x] 5.6 Add regenerate option

## 6. Form Submission ✅
- [x] 6.1 Handle immediate posting (calls SchedulePost command)
- [x] 6.2 Handle scheduled posting (creates draft with scheduled_at)
- [x] 6.3 Add validations (photo, persona, caption)
- [x] 6.4 Show success/error messages
- [x] 6.5 Redirect to posts index or photo list

## 7. Ollama Setup ✅
- [x] 7.1 Document Ollama remote connection (192.168.86.137)
- [x] 7.2 Document Gemma3:27b model availability check
- [x] 7.3 Create Ollama client wrapper with remote endpoint
- [x] 7.4 Add error handling for Ollama unavailable
- [x] 7.5 Handle first-time model loading delay (30-60s)
- [ ] 7.6 Add loading UI with appropriate timeout
- [x] 7.7 Test caption generation with remote Ollama

## 8. Metadata Display ✅
- [x] 8.1 Show photo cluster assignment
- [x] 8.2 Show detected objects/labels
- [x] 8.3 Show persona configuration preview
- [ ] 8.4 Display recent hashtags used
- [ ] 8.5 Show posting statistics

## 9. Testing
- [ ] 9.1 Write caption generation specs
- [ ] 9.2 Write controller request specs
- [ ] 9.3 Write integration specs for full flow
- [ ] 9.4 Test with multiple personas
- [ ] 9.5 Test repetition avoidance

## 10. Documentation ✅
- [x] 10.1 Document caption generation workflow
- [x] 10.2 Document Ollama setup
- [x] 10.3 Add usage examples
- [x] 10.4 Document prompt engineering
