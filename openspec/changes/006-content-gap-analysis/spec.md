# Content Gap Analysis & AI Suggestions

**Status**: Draft  
**Created**: 2025-12-03  
**Updated**: 2025-12-03

## Problem Statement

We need to identify content gaps and generate intelligent, context-aware suggestions for new content creation. The current fluffy-train implementation has a gap analyzer but the AI suggestions lack context, resulting in repetitive recommendations like "coffee in Brooklyn" or "walk in the park" every time.

## Goals

1. **Content Gap Analysis**: Identify which pillars/clusters need more content based on:
   - Target posting frequency (e.g., 3 posts/week)
   - Pillar weights/distribution
   - Available unpublished photos
   - Scheduled/published content

2. **Context-Aware AI Suggestions**: Generate intelligent content ideas that:
   - Consider existing clusters and their themes
   - Avoid suggesting duplicate/similar content
   - Reference existing photos to avoid repetition
   - Align with persona characteristics
   - Prioritize gaps

3. **Actionable Workflow**: Enable users to:
   - View gap analysis dashboard
   - Request AI suggestions for specific pillars
   - Create new clusters directly from suggestions
   - Generate runs from suggestions

## Current State (fluffy-train)

### Gap Analyzer
- Located: `packs/content_pillars/app/services/content_pillars/gap_analyzer.rb`
- Calculates:
  - Posts needed over next 30 days (default: 3/week)
  - Photos available (unpublished)
  - Gap = needed - available
  - Status: exhausted, critical, low, ready, minimal
  - Priority: high, medium, low, normal

### Limitations
1. No AI suggestion integration
2. No context about existing content passed to AI
3. Repetitive suggestions
4. No way to act on gap analysis

## Proposed Solution

### Phase 1: Import & Enhance Gap Analysis

#### 1.1 Gap Analyzer Service
```ruby
# packs/personas/app/services/personas/gap_analyzer.rb
module Personas
  class GapAnalyzer
    def initialize(persona:)
      @persona = persona
    end

    def analyze(days_ahead: 30)
      # Imported from fluffy-train with enhancements
      pillars = @persona.content_pillars.includes(:clusters).order(priority: :asc)
      
      pillars.map do |pillar|
        analyze_pillar(pillar, days_ahead)
      end.sort_by { |result| [-result[:gap], -result[:pillar].priority] }
    end

    private

    def analyze_pillar(pillar, days_ahead)
      posts_needed = calculate_posts_needed(pillar, days_ahead)
      photos_available = count_available_photos(pillar)
      gap = posts_needed - photos_available
      
      {
        pillar: pillar,
        posts_needed: posts_needed,
        photos_available: photos_available,
        gap: gap,
        status: determine_status(gap, photos_available),
        priority_level: determine_priority(gap, photos_available)
      }
    end

    def calculate_posts_needed(pillar, days_ahead)
      # Use pillar weight % of total posting frequency
      posts_per_week = 3 # Could be persona.posting_frequency
      weeks = days_ahead.to_f / 7.0
      total_posts = (posts_per_week * weeks).ceil
      (total_posts * pillar.weight / 100.0).ceil
    end

    def count_available_photos(pillar)
      # Count photos that:
      # - Belong to this pillar's clusters
      # - Haven't been picked as winners yet (no Photo record)
      # OR
      # - Have Photo records but aren't published/scheduled
      
      pillar.clusters
        .joins(:runs)
        .where.not(runs: { winner_candidate_id: nil })
        .where.not(
          id: Photo.where(persona: @persona)
                   .joins(:cluster)
                   .select(:cluster_id)
        ).count
    end

    def determine_status(gap, photos_available)
      return :exhausted if photos_available == 0
      return :critical if gap > 5
      return :low if gap > 0
      return :ready if gap <= 0 && photos_available >= 3
      :minimal
    end

    def determine_priority(gap, photos_available)
      return :high if gap > 5 || photos_available == 0
      return :medium if gap > 0
      return :low if gap <= 0 && photos_available >= 5
      :normal
    end
  end
end
```

#### 1.2 Gap Analysis Dashboard UI

Add to Persona show page (`/personas/:id`):

```erb
<div class="mb-6">
  <h2 class="text-xl font-bold mb-4">Content Gap Analysis</h2>
  
  <% @gap_analysis.each do |result| %>
    <div class="card mb-3 <%= status_color_class(result[:status]) %>">
      <div class="flex justify-between items-start">
        <div>
          <h3 class="font-bold"><%= result[:pillar].name %></h3>
          <p class="text-sm text-gray-400">
            Weight: <%= result[:pillar].weight %>% | Priority: <%= result[:pillar].priority %>
          </p>
        </div>
        
        <div class="text-right">
          <div class="text-2xl font-bold">
            <%= result[:gap] > 0 ? "+#{result[:gap]}" : result[:gap] %>
          </div>
          <div class="text-xs uppercase <%= priority_badge_class(result[:priority_level]) %>">
            <%= result[:priority_level] %>
          </div>
        </div>
      </div>
      
      <div class="mt-3 grid grid-cols-2 gap-4 text-sm">
        <div>
          <span class="text-gray-400">Posts Needed:</span>
          <span class="font-bold"><%= result[:posts_needed] %></span>
        </div>
        <div>
          <span class="text-gray-400">Photos Available:</span>
          <span class="font-bold"><%= result[:photos_available] %></span>
        </div>
      </div>
      
      <% if result[:gap] > 0 %>
        <div class="mt-4 flex gap-2">
          <%= link_to "View Clusters", 
                      persona_content_pillar_path(@persona, result[:pillar]),
                      class: "btn-secondary" %>
          <%= link_to "Get AI Suggestions", 
                      suggest_persona_content_pillar_path(@persona, result[:pillar]),
                      method: :post,
                      class: "btn-primary" %>
        </div>
      <% end %>
    </div>
  <% end %>
</div>
```

### Phase 2: Context-Aware AI Suggestions

#### 2.1 Suggestion Model & Context Builder

```ruby
# packs/personas/app/models/personas/content_suggestion.rb
module Personas
  class ContentSuggestion < ApplicationRecord
    belongs_to :persona
    belongs_to :content_pillar
    
    enum status: { pending: 0, accepted: 1, rejected: 2, implemented: 3 }
    
    # suggestion_data: JSON array with AI-generated cluster ideas
    # context_snapshot: JSON with context used for generation
  end
end
```

```ruby
# packs/personas/app/services/personas/suggestion_context_builder.rb
module Personas
  class SuggestionContextBuilder
    def initialize(persona:, pillar:)
      @persona = persona
      @pillar = pillar
    end

    def build
      {
        persona: persona_context,
        pillar: pillar_context,
        existing_clusters: cluster_context,
        existing_photos: photo_context,
        gaps: gap_context
      }
    end

    private

    def persona_context
      {
        name: @persona.name,
        caption_config: @persona.caption_config,
        hashtag_strategy: @persona.hashtag_strategy,
        tone: @persona.caption_config&.dig("tone"),
        topics: @persona.caption_config&.dig("topics"),
        avoid_topics: @persona.caption_config&.dig("avoid_topics")
      }
    end

    def pillar_context
      {
        name: @pillar.name,
        description: @pillar.description,
        weight: @pillar.weight,
        priority: @pillar.priority
      }
    end

    def cluster_context
      # List existing clusters to avoid duplication
      @pillar.clusters.map do |cluster|
        {
          name: cluster.name,
          theme: cluster.theme,
          photo_count: cluster.runs.where.not(winner_candidate_id: nil).count
        }
      end
    end

    def photo_context
      # Sample existing photo prompts/descriptions to show what's already created
      @pillar.clusters
        .joins(:runs)
        .where.not(runs: { winner_candidate_id: nil })
        .limit(20)
        .pluck('runs.base_prompt')
        .compact
        .uniq
    end

    def gap_context
      analyzer = GapAnalyzer.new(persona: @persona)
      result = analyzer.analyze.find { |r| r[:pillar].id == @pillar.id }
      
      {
        posts_needed: result[:posts_needed],
        photos_available: result[:photos_available],
        gap: result[:gap],
        status: result[:status]
      }
    end
  end
end
```

#### 2.2 AI Suggestion Generator

```ruby
# packs/personas/app/services/personas/ai_suggestion_generator.rb
module Personas
  class AiSuggestionGenerator
    def initialize(persona:, pillar:)
      @persona = persona
      @pillar = pillar
      @context_builder = SuggestionContextBuilder.new(persona: persona, pillar: pillar)
    end

    def generate(count: 5)
      context = @context_builder.build
      
      prompt = build_prompt(context, count)
      response = call_llm(prompt)
      suggestions = parse_response(response)
      
      # Save suggestion record
      ContentSuggestion.create!(
        persona: @persona,
        content_pillar: @pillar,
        status: :pending,
        suggestion_data: suggestions,
        context_snapshot: context
      )
      
      suggestions
    end

    private

    def build_prompt(context, count)
      <<~PROMPT
        You are a content strategist for Instagram persona "#{context[:persona][:name]}".
        
        PERSONA CHARACTERISTICS:
        - Tone: #{context[:persona][:tone]}
        - Topics: #{context[:persona][:topics]&.join(', ')}
        - Avoid: #{context[:persona][:avoid_topics]&.join(', ')}
        
        CONTENT PILLAR: #{context[:pillar][:name]}
        Description: #{context[:pillar][:description]}
        Priority: #{context[:pillar][:priority]}, Weight: #{context[:pillar][:weight]}%
        
        EXISTING CLUSTERS (avoid duplication):
        #{context[:existing_clusters].map { |c| "- #{c[:name]}: #{c[:theme]} (#{c[:photo_count]} photos)" }.join("\n")}
        
        EXISTING PHOTO THEMES (avoid similar concepts):
        #{context[:existing_photos].take(10).map { |p| "- #{p}" }.join("\n")}
        
        CONTENT GAP:
        Need #{context[:gaps][:gap]} more photos for this pillar.
        Status: #{context[:gaps][:status]}
        
        Generate #{count} NEW, DISTINCT content cluster ideas that:
        1. Fit the pillar theme "#{context[:pillar][:name]}"
        2. Are DIFFERENT from existing clusters
        3. Avoid repeating existing photo concepts
        4. Match the persona's tone and topics
        5. Could generate 3-5 photo variations each
        
        For each suggestion, provide:
        - Cluster Name (2-4 words)
        - Theme Description (1 sentence)
        - 3 Example Photo Concepts (each different, specific scenes/moments)
        
        Return as JSON array:
        [
          {
            "cluster_name": "...",
            "theme": "...",
            "example_concepts": ["...", "...", "..."]
          }
        ]
      PROMPT
    end

    def call_llm(prompt)
      # Use existing LLM infrastructure (OpenAI, Anthropic, etc.)
      client = OpenAI::Client.new
      response = client.chat(
        parameters: {
          model: "gpt-4o",
          messages: [{ role: "user", content: prompt }],
          response_format: { type: "json_object" },
          temperature: 0.8 # Higher for creativity
        }
      )
      
      response.dig("choices", 0, "message", "content")
    end

    def parse_response(response)
      JSON.parse(response)
    rescue JSON::ParserError
      # Fallback or error handling
      []
    end
  end
end
```

#### 2.3 Suggestions UI

```ruby
# app/controllers/personas/content_pillars_controller.rb
def suggest
  @pillar = @persona.content_pillars.find(params[:id])
  generator = Personas::AiSuggestionGenerator.new(persona: @persona, pillar: @pillar)
  @suggestions = generator.generate(count: 5)
  
  redirect_to persona_content_pillar_suggestions_path(@persona, @pillar),
              notice: "Generated #{@suggestions.size} new suggestions"
end

def suggestions
  @pillar = @persona.content_pillars.find(params[:content_pillar_id])
  @suggestion = @pillar.content_suggestions.pending.order(created_at: :desc).first
end
```

```erb
<!-- app/views/personas/content_pillars/suggestions.html.erb -->
<%= render 'shared/back_button', path: persona_path(@persona), text: 'Back to Persona' %>

<h1 class="text-2xl font-bold mb-6">
  AI Suggestions for <%= @pillar.name %>
</h1>

<% if @suggestion %>
  <div class="mb-6">
    <div class="text-sm text-gray-400 mb-4">
      Generated <%= time_ago_in_words(@suggestion.created_at) %> ago
      based on <%= @suggestion.context_snapshot['existing_clusters'].size %> existing clusters
    </div>
    
    <% @suggestion.suggestion_data.each_with_index do |suggestion, index| %>
      <div class="card mb-4">
        <div class="flex justify-between items-start mb-3">
          <div>
            <h3 class="font-bold text-lg"><%= suggestion['cluster_name'] %></h3>
            <p class="text-sm text-gray-400"><%= suggestion['theme'] %></p>
          </div>
          
          <div class="flex gap-2">
            <%= button_to "Create Cluster",
                          persona_content_pillar_content_clusters_path(@persona, @pillar),
                          params: { 
                            content_cluster: {
                              name: suggestion['cluster_name'],
                              theme: suggestion['theme']
                            }
                          },
                          class: "btn-primary text-sm" %>
          </div>
        </div>
        
        <div class="mt-3">
          <div class="text-xs text-gray-500 mb-2">Example Concepts:</div>
          <ul class="text-sm space-y-1">
            <% suggestion['example_concepts'].each do |concept| %>
              <li class="flex items-start">
                <span class="text-blue-400 mr-2">→</span>
                <%= concept %>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    <% end %>
    
    <div class="mt-6 flex gap-3">
      <%= button_to "Generate New Suggestions",
                    suggest_persona_content_pillar_path(@persona, @pillar),
                    class: "btn-secondary" %>
      <%= button_to "Mark All as Reviewed",
                    persona_content_pillar_suggestion_path(@persona, @pillar, @suggestion),
                    method: :patch,
                    params: { status: 'rejected' },
                    class: "btn-outline" %>
    </div>
  </div>
<% else %>
  <div class="card text-center py-8">
    <p class="text-gray-400 mb-4">No suggestions yet</p>
    <%= button_to "Generate AI Suggestions",
                  suggest_persona_content_pillar_path(@persona, @pillar),
                  class: "btn-primary" %>
  </div>
<% end %>
```

### Phase 3: Integration with Run Generation

When creating a cluster from a suggestion, automatically:

1. Create the cluster
2. Mark suggestion as "accepted"
3. Optionally: Create initial run(s) using the example concepts as prompts

```ruby
# Enhancement to content_clusters_controller.rb
def create
  @cluster = @pillar.content_clusters.build(cluster_params)
  
  if @cluster.save
    # If created from suggestion, mark it
    if params[:suggestion_id]
      suggestion = Personas::ContentSuggestion.find(params[:suggestion_id])
      suggestion.update(status: :accepted)
    end
    
    # Optional: Create initial runs
    if params[:create_runs] && params[:example_concepts]
      params[:example_concepts].each do |concept|
        @cluster.runs.create!(
          persona: @persona,
          base_prompt: concept,
          status: :pending
        )
      end
    end
    
    redirect_to persona_content_pillar_content_cluster_path(@persona, @pillar, @cluster)
  else
    render :new
  end
end
```

## Database Changes

```ruby
class CreatePersonasContentSuggestions < ActiveRecord::Migration[7.1]
  def change
    create_table :personas_content_suggestions do |t|
      t.references :persona, null: false, foreign_key: true
      t.references :content_pillar, null: false
      t.integer :status, default: 0, null: false # pending, accepted, rejected, implemented
      t.jsonb :suggestion_data, default: [], null: false
      t.jsonb :context_snapshot, default: {}, null: false
      
      t.timestamps
    end
    
    add_index :personas_content_suggestions, [:persona_id, :status]
    add_index :personas_content_suggestions, [:content_pillar_id, :status]
  end
end
```

## Implementation Checklist

### Phase 1: Gap Analysis (Week 2, Day 1-2)
- [ ] Create `Personas::GapAnalyzer` service
- [ ] Add gap analysis to PersonasController#show
- [ ] Create gap analysis UI component
- [ ] Add status/priority badge helpers
- [ ] Manual testing with Sarah's data

### Phase 2: AI Suggestions (Week 2, Day 3-4)
- [ ] Create `ContentSuggestion` model & migration
- [ ] Create `SuggestionContextBuilder` service
- [ ] Create `AiSuggestionGenerator` service
- [ ] Add routes for suggestions
- [ ] Create suggestions controller & views
- [ ] Configure LLM credentials
- [ ] Test suggestion generation

### Phase 3: Integration (Week 2, Day 5)
- [ ] Add "Create from Suggestion" flow
- [ ] Auto-mark suggestions when used
- [ ] Add optional run generation
- [ ] Full workflow testing
- [ ] Documentation

## Success Metrics

1. **Gap Analysis**: Correctly identifies pillars needing content
2. **AI Quality**: Suggestions are distinct and contextual (no "coffee in Brooklyn" repetition)
3. **Workflow**: Users can go from gap → suggestion → cluster → runs seamlessly
4. **Performance**: Suggestion generation completes in < 10 seconds

## Future Enhancements

- Bulk suggestion generation for all high-gap pillars
- Suggestion history/versioning
- Learn from rejected vs. accepted suggestions
- Seasonal/trending topic integration
- Multi-cluster suggestion campaigns
