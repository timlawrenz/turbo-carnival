# Change: Add Post Creation Interface

## Why
We need a web interface for creating Instagram posts that allows users to select photos, write captions, and get AI-powered caption suggestions. Currently, posts can only be created programmatically. We want a user-friendly form that integrates caption generation using the Gemma3:27b model (migrating from Gemini in fluffy-train) with rich persona/pillar/cluster context.

## What Changes
- **ADDED**: Post creation controller and views
- **ADDED**: Photo selection interface (filter by persona, cluster, unposted status)
- **ADDED**: Caption form with text area and hashtags input
- **ADDED**: AI caption suggestion feature using Gemma3:27b via Ollama
- **ADDED**: Caption generation service with persona context (voice, tone, style)
- **ADDED**: Prompt builder that includes persona config, cluster themes, and repetition avoidance
- **ADDED**: "Get AI Suggestions" button with AJAX/Turbo Frames
- **ADDED**: Preview of selected photo with metadata
- **MIGRATION**: Caption generation logic from fluffy-train (Gemini → Gemma3:27b)

## Impact
- Affected specs: `post-creation` (new), `caption-generation` (new)
- Affected code:
  - New controller: `PostsController` or `Scheduling::PostsController`
  - New views for photo selection and caption form
  - New service: Caption generation with Ollama/Gemma3
  - New pack or expansion of scheduling pack
  - Dependencies on personas (for config), clustering (for photos/clusters), content_pillars
- External dependencies:
  - Ollama running locally with Gemma3:27b model
  - Tailwind CSS for styling (already in project)
  - ViewComponent for reusable UI (already in project)
