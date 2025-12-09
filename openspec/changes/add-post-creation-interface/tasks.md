# Implementation Tasks

## 1. Caption Generation Service
- [ ] 1.1 Create caption_generation pack structure
- [ ] 1.2 Create Ollama client for Gemma3:27b integration
- [ ] 1.3 Create CaptionGenerator service class
- [ ] 1.4 Create PromptBuilder with persona/cluster context
- [ ] 1.5 Create ContextBuilder for extracting photo/cluster data
- [ ] 1.6 Create PostProcessor for formatting and validation
- [ ] 1.7 Create RepetitionChecker for avoiding recent phrases
- [ ] 1.8 Write service specs

## 2. Controller and Routes
- [ ] 2.1 Create Scheduling::PostsController
- [ ] 2.2 Add routes for new, create, and suggest_caption
- [ ] 2.3 Add before_action for photo selection
- [ ] 2.4 Implement suggest_caption action (AJAX endpoint)
- [ ] 2.5 Write controller specs

## 3. Photo Selection Interface
- [ ] 3.1 Create photo index view with filtering
- [ ] 3.2 Add filters for persona, cluster, unposted status
- [ ] 3.3 Create photo card component with preview
- [ ] 3.4 Add "Create Post" button per photo
- [ ] 3.5 Write component previews

## 4. Post Creation Form
- [ ] 4.1 Create new post form view
- [ ] 4.2 Add photo preview section
- [ ] 4.3 Add caption textarea (with character count)
- [ ] 4.4 Add hashtags input field
- [ ] 4.5 Add "Get AI Suggestions" button
- [ ] 4.6 Add schedule datetime picker
- [ ] 4.7 Add submit button (Post Now / Schedule)
- [ ] 4.8 Style with Tailwind CSS

## 5. AI Suggestion Integration
- [ ] 5.1 Create Turbo Frame for AI suggestions
- [ ] 5.2 Wire "Get AI Suggestions" button to AJAX call
- [ ] 5.3 Show loading state during generation
- [ ] 5.4 Prefill textarea with AI suggestion
- [ ] 5.5 Handle errors gracefully
- [ ] 5.6 Add regenerate option

## 6. Form Submission
- [ ] 6.1 Handle immediate posting (calls SchedulePost command)
- [ ] 6.2 Handle scheduled posting (creates draft with scheduled_at)
- [ ] 6.3 Add validations (photo, persona, caption)
- [ ] 6.4 Show success/error messages
- [ ] 6.5 Redirect to posts index or photo list

## 7. Ollama Setup
- [ ] 7.1 Document Ollama installation
- [ ] 7.2 Document Gemma3:27b model pull
- [ ] 7.3 Create Ollama client wrapper
- [ ] 7.4 Add error handling for Ollama unavailable
- [ ] 7.5 Test caption generation locally

## 8. Metadata Display
- [ ] 8.1 Show photo cluster assignment
- [ ] 8.2 Show detected objects/labels
- [ ] 8.3 Show persona configuration preview
- [ ] 8.4 Display recent hashtags used
- [ ] 8.5 Show posting statistics

## 9. Testing
- [ ] 9.1 Write caption generation specs
- [ ] 9.2 Write controller request specs
- [ ] 9.3 Write integration specs for full flow
- [ ] 9.4 Test with multiple personas
- [ ] 9.5 Test repetition avoidance

## 10. Documentation
- [ ] 10.1 Document caption generation workflow
- [ ] 10.2 Document Ollama setup
- [ ] 10.3 Add usage examples
- [ ] 10.4 Document prompt engineering
