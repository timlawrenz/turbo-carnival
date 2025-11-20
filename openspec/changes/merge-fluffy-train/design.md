# Design: Merge Fluffy-Train

**Date:** 2025-11-20  
**Status:** Proposed

---

## Architecture Overview

### Current State

Two independent Rails applications:

```
┌─────────────────────┐         ┌─────────────────────┐
│   Turbo-Carnival    │         │   Fluffy-Train      │
│                     │         │                     │
│  - Web UI           │         │  - TUI Only         │
│  - Pipelines        │◄────────┤  - Personas         │
│  - Voting/ELO       │ Export/ │  - Content Strategy │
│  - Approval Gates   │ Import  │  - AI Services      │
│  - Image Generation │         │  - Instagram API    │
│                     │         │                     │
│  PostgreSQL DB 1    │         │  PostgreSQL DB 2    │
└─────────────────────┘         └─────────────────────┘
```

### Target State

Single unified application:

```
┌───────────────────────────────────────────────────────┐
│            Unified Application                         │
│            (turbo-carnival)                           │
│                                                       │
│  ┌──────────┐                                        │
│  │ Web UI   │ (existing + new persona mgmt)          │
│  └────┬─────┘                                        │
│       │                                              │
│  ┌────▼──────────────────────────────────┐          │
│  │         Application Layer              │          │
│  │  - PersonasController (new)            │          │
│  │  - PipelinesController (existing)      │          │
│  │  - GalleryController (existing)        │          │
│  │  - ContentStrategyController (new)     │          │
│  └────┬──────────────────────────────────┘          │
│       │                                              │
│  ┌────▼────────────────────────────────────┐        │
│  │         Pack Layer (Packwerk)            │        │
│  │                                          │        │
│  │  Existing:                               │        │
│  │  ├─ pipeline/                            │        │
│  │  └─ job_orchestration/                   │        │
│  │                                          │        │
│  │  Migrated from fluffy-train:             │        │
│  │  ├─ personas/                            │        │
│  │  ├─ content_pillars/                     │        │
│  │  ├─ clustering/ (adapted)                │        │
│  │  ├─ caption_generations/                 │        │
│  │  ├─ hashtag_generations/                 │        │
│  │  ├─ content_strategy/                    │        │
│  │  └─ scheduling/                          │        │
│  └──────────────────────────────────────────┘        │
│                                                       │
│  ┌──────────────────────────────────────────┐        │
│  │         Service Layer                     │        │
│  │  - AI::GeminiClient                       │        │
│  │  - AI::ContentPromptGenerator             │        │
│  │  - Instagram::APIClient                   │        │
│  │  - CreateContentPipeline                  │        │
│  └──────────────────────────────────────────┘        │
│                                                       │
│  ┌──────────────────────────────────────────┐        │
│  │      Single PostgreSQL Database           │        │
│  │                                           │        │
│  │  Turbo-Carnival Tables:                   │        │
│  │  - pipelines                              │        │
│  │  - pipeline_steps                         │        │
│  │  - pipeline_runs                          │        │
│  │  - pipeline_run_steps                     │        │
│  │  - image_candidates                       │        │
│  │  - votes                                  │        │
│  │                                           │        │
│  │  Fluffy-Train Tables (migrated):          │        │
│  │  - personas                               │        │
│  │  - content_pillars                        │        │
│  │  - clusters                               │        │
│  │  - cluster_candidates (join)              │        │
│  │  - pillar_cluster_assignments             │        │
│  │  - scheduling_posts                       │        │
│  │  - content_strategy_states                │        │
│  │  - content_strategy_histories             │        │
│  └───────────────────────────────────────────┘        │
└───────────────────────────────────────────────────────┘
```

---

## Key Design Decisions

### 1. Turbo-Carnival as Base Application

**Decision:** Merge fluffy-train INTO turbo-carnival, not vice versa

**Rationale:**
- Turbo-carnival has mature web UI infrastructure
- More recent development (approval gates just added)
- Voting interface is polished and working well
- ActiveStorage already configured
- ViewComponents framework already in place

**Trade-offs:**
- Need to build web UI for fluffy-train features (currently TUI-only)
- But this is a feature, not a bug (web is better UX)

---

### 2. Clustering Pack Adaptation Strategy

**Decision:** Adapt clustering to support BOTH Photo (legacy) AND ImageCandidate (new)

**Why Not Just ImageCandidate:**
- Allows backwards compatibility if migrating old data
- Provides safety net during migration
- Can deprecate Photo later if not needed

**Implementation:**
```ruby
class Clustering::Cluster < ApplicationRecord
  belongs_to :persona
  
  # Legacy support
  has_many :photos, dependent: :nullify
  
  # New primary model
  has_many :cluster_candidates, dependent: :destroy
  has_many :image_candidates, 
    through: :cluster_candidates,
    source: :candidate
  
  # Polymorphic accessor
  def images
    # Returns unified collection
    photos.to_a + image_candidates.to_a
  end
  
  def image_urls
    photos.map { |p| p.image.url if p.image.attached? }.compact +
    image_candidates.map(&:exportable_url)
  end
end
```

**Benefits:**
- ✅ Clean abstraction
- ✅ Gradual migration path
- ✅ No data loss risk
- ✅ Can mix sources

---

### 3. Auto-Linking Architecture

**Decision:** Use ActiveRecord callback for automatic winner linking

**Implementation:**
```ruby
class PipelineRun < ApplicationRecord
  belongs_to :pipeline
  
  # Trigger auto-linking on completion
  after_update :link_winner_to_cluster, if: -> { 
    saved_change_to_status? && 
    completed? && 
    pipeline.cluster_id.present?
  }
  
  private
  
  def link_winner_to_cluster
    winner = final_step_winner
    return unless winner
    
    # Idempotent create
    Clustering::ClusterCandidate.find_or_create_by!(
      cluster_id: pipeline.cluster_id,
      candidate_id: winner.id
    ) do |cc|
      cc.metadata = {
        elo_score: winner.elo_score,
        run_name: name,
        completed_at: updated_at,
        linked_at: Time.current
      }
    end
    
    Rails.logger.info "✅ Linked candidate #{winner.id} (ELO: #{winner.elo_score}) to cluster #{pipeline.cluster_id}"
  end
  
  def final_step_winner
    final_step = pipeline.pipeline_steps.order(:order).last
    ImageCandidate
      .where(
        pipeline_step: final_step,
        pipeline_run: self,
        status: 'active'
      )
      .order(elo_score: :desc)
      .first
  end
end
```

**Alternatives Considered:**

1. **Manual linking via UI button**
   - ❌ Extra step for user
   - ❌ Easy to forget
   - ✅ More explicit control

2. **Background job**
   - ❌ Overkill for simple operation
   - ❌ Adds complexity
   - ✅ Could handle failures better

3. **Callback (chosen)**
   - ✅ Automatic and immediate
   - ✅ No extra steps
   - ✅ Logged for debugging
   - ❌ Could fail silently (mitigated with logging)

**Why Callback Wins:**
- Simplicity and immediacy
- No user action required
- Easy to test and debug
- Can add retry logic if needed

---

### 4. Pipeline → Cluster Association

**Decision:** Add `persona_id` and `cluster_id` foreign keys to pipelines table

**Schema Change:**
```ruby
add_column :pipelines, :persona_id, :bigint
add_column :pipelines, :cluster_id, :bigint
add_foreign_key :pipelines, :personas
add_foreign_key :pipelines, :clusters
```

**Why This Works:**
```
Persona
  └─ has_many :content_pillars
  └─ has_many :clusters
  └─ has_many :pipelines

ContentPillar
  └─ has_many :pillar_cluster_assignments
  └─ has_many :clusters, through: :pillar_cluster_assignments

Cluster
  ├─ belongs_to :persona
  ├─ has_many :pillar_cluster_assignments
  ├─ has_many :content_pillars, through: :pillar_cluster_assignments
  ├─ has_many :cluster_candidates
  └─ has_many :image_candidates, through: :cluster_candidates

Pipeline
  ├─ belongs_to :persona (optional, for content pipelines)
  ├─ belongs_to :cluster (optional, for content pipelines)
  └─ has_many :pipeline_runs

PipelineRun
  ├─ belongs_to :pipeline
  └─ delegates :persona, :cluster to :pipeline
```

**Content Generation Pipeline:**
```ruby
persona = Persona.find_by(name: 'sarah')
pillar = persona.content_pillars.find_by(name: 'Thanksgiving 2024')

# AI generates prompt
prompt = AI::ContentPromptGenerator.generate(persona: persona, pillar: pillar)

# Create cluster
cluster = Clustering::Cluster.create!(
  persona: persona,
  name: prompt[:scene],
  ai_prompt: prompt[:full_prompt]
)
cluster.pillar_cluster_assignments.create!(pillar: pillar)

# Create pipeline linked to cluster
pipeline = Pipeline.find_by(name: "Default Portrait Pipeline")
run = PipelineRun.create!(
  pipeline: pipeline,
  name: cluster.name.parameterize
)

# Link pipeline to persona and cluster
pipeline.update!(persona: persona, cluster: cluster)

# When run completes → auto-links winner to cluster
```

**Non-Content Pipeline:**
```ruby
# Traditional pipeline (no persona/cluster)
pipeline = Pipeline.create!(name: "General Purpose")
run = PipelineRun.create!(pipeline: pipeline)

# No auto-linking happens (persona_id and cluster_id are nil)
```

---

### 5. Image Storage Strategy

**Decision:** ImageCandidate is the source of truth, no copying

**Flow:**
```
Pipeline generates ImageCandidate
  ↓
ImageCandidate.image (ActiveStorage attachment)
  ↓
ImageCandidate.exportable_url (public URL)
  ↓
ClusterCandidate references ImageCandidate
  ↓
ContentStrategy selects ClusterCandidate
  ↓
Instagram fetches from exportable_url
```

**Why Not Copy Images:**
- ❌ Duplicate storage costs
- ❌ Sync complexity
- ❌ Lose ELO metadata
- ❌ Lose pipeline lineage

**Why Reference Instead:**
- ✅ Single source of truth
- ✅ Zero duplication
- ✅ Full metadata preserved
- ✅ Can navigate candidate tree
- ✅ Lower storage costs

**Implementation:**
```ruby
class ImageCandidate < ApplicationRecord
  has_one_attached :image
  
  # Make URL publicly accessible for Instagram
  def exportable_url
    return unless image.attached?
    
    # Use ActiveStorage public URL
    Rails.application.routes.url_helpers.rails_blob_url(
      image.variant(resize_to_limit: [1080, 1350]),
      host: ENV.fetch('TURBO_CARNIVAL_HOST', 'http://localhost:3000')
    )
  end
  
  # Cache for performance
  def cached_exportable_url
    Rails.cache.fetch("candidate:#{id}:export_url", expires_in: 1.hour) do
      exportable_url
    end
  end
end
```

---

### 6. UI Architecture

**Decision:** Build web UI to replace TUI, optionally keep TUI for advanced users

**Why Web Over TUI:**
- Better visualization (images, galleries, progress)
- More accessible (no terminal knowledge required)
- Easier navigation (links, breadcrumbs)
- Better feedback (loading states, notifications)
- Mobile-friendly potential

**Key UI Components:**

#### Persona Dashboard
```
┌─────────────────────────────────────────────────┐
│ Sarah - Nature Photographer                     │
├─────────────────────────────────────────────────┤
│ Content Strategy                                │
│ ┌──────────────┐  ┌──────────────┐             │
│ │ Thanksgiving │  │ Winter       │             │
│ │ 30% ⚠️ Low   │  │ 25% ✅ Ready │             │
│ │ [Generate]   │  │              │             │
│ └──────────────┘  └──────────────┘             │
├─────────────────────────────────────────────────┤
│ Active Pipelines                                │
│ ┌─────────────────────────────────────────┐    │
│ │ Cozy Fireplace → Step 3 → [Vote]        │    │
│ └─────────────────────────────────────────┘    │
├─────────────────────────────────────────────────┤
│ Content Library (5 clusters, 47 images)         │
│ [Preview] [Schedule Post]                       │
└─────────────────────────────────────────────────┘
```

#### Generate Content Workflow
```
User clicks "Generate" on "Thanksgiving" pillar
  ↓
AI generates prompt: "Cozy fireplace, warm sweater, pumpkins..."
  ↓
Creates cluster "Cozy Thanksgiving Fireplace"
  ↓
Creates pipeline run
  ↓
Redirects to /runs/:id/vote
  ↓
User votes on candidates
  ↓
User approves gates
  ↓
Marks run complete
  ↓
Winner auto-linked to cluster
  ↓
Returns to persona dashboard
  ↓
"Thanksgiving" pillar now shows ✅ Ready
```

---

### 7. Content Strategy Adaptation

**Decision:** Make ContentStrategy selector work with ImageCandidates

**Original (fluffy-train):**
```ruby
# Expects Photo model
class ContentStrategy::Selector
  def select_next_content
    photo = Photo.where(...)
    photo.image.url  # ActiveStorage attachment
  end
end
```

**Adapted (unified):**
```ruby
class ContentStrategy::Selector
  def select_next_content
    # Can return Photo OR ClusterCandidate
    content = select_from_clusters
    
    # Polymorphic handling
    case content
    when Photos::Photo
      content.image.url
    when Clustering::ClusterCandidate
      content.candidate.exportable_url
    else
      raise "Unknown content type: #{content.class}"
    end
  end
  
  private
  
  def select_from_clusters
    # ... existing selection logic ...
    # Now works with clusters that have ImageCandidates
  end
end
```

**Image Wrapper Pattern (cleaner):**
```ruby
class ImageWrapper
  def initialize(source)
    @source = source
  end
  
  def url
    case @source
    when Photos::Photo
      @source.image.url
    when Clustering::ClusterCandidate
      @source.candidate.cached_exportable_url
    when ImageCandidate
      @source.cached_exportable_url
    else
      raise "Unknown source: #{@source.class}"
    end
  end
  
  def metadata
    case @source
    when Photos::Photo
      { aesthetic_score: @source.aesthetic_score }
    when Clustering::ClusterCandidate
      { 
        elo_score: @source.candidate.elo_score,
        pipeline: @source.candidate.pipeline_run.name
      }
    end
  end
end

# Usage
class ContentStrategy::Selector
  def select_next_content
    raw_content = select_from_clusters
    ImageWrapper.new(raw_content)
  end
end
```

---

### 8. Migration Strategy: Pack-by-Pack

**Decision:** Migrate one pack at a time, maintaining working app at each step

**Order (dependency-sorted):**
1. Personas (foundation, no dependencies)
2. Content Pillars (depends on Personas)
3. Clustering (depends on Personas, Pillars)
4. Pipeline Linking (depends on Clustering)
5. AI Generation (depends on Personas, Pillars, Clustering)
6. Captions (depends on nothing, independent)
7. Hashtags (depends on nothing, independent)
8. Content Strategy (depends on Clustering)
9. Scheduling (depends on Content Strategy)
10. UI Dashboard (depends on all above)

**Git Strategy:**
```bash
# Each pack = one commit
git commit -m "Add Personas pack

- Copied packs/personas/ from fluffy-train
- Migrated personas table
- Created PersonasController with CRUD
- Added basic index and show views

Spec: packs/personas/README.md
Tests: 12 passing
Packwerk: No violations"
```

**Validation After Each:**
- Run pack tests
- Console verification
- UI check (if applicable)
- Packwerk validation: `bin/packwerk check`

---

### 9. Database Migration Strategy

**Decision:** Append fluffy-train migrations, don't renumber

**Approach:**
```bash
# Copy migrations with timestamp intact
cp ../fluffy-train/db/migrate/20241101120000_create_personas.rb \
   db/migrate/

# Run migrations normally
bin/rails db:migrate
```

**Benefits:**
- ✅ Preserves migration history
- ✅ No timestamp conflicts (different dates)
- ✅ Can reference original if issues arise

**Schema State After All Migrations:**
```ruby
# db/schema.rb will contain:
# - All turbo-carnival tables
# - All fluffy-train tables
# - No conflicts (different namespaces)
```

---

### 10. Testing Strategy

**Decision:** Maintain test coverage from both projects

**Per Migration:**
```bash
# 1. Run pack-specific tests
bin/rails test packs/personas/test/

# 2. Run integration tests
bin/rails test test/integration/

# 3. Manual validation
bin/rails runner "
  persona = Personas.create(name: 'test')
  puts persona.success? ? '✅' : '❌'
"

# 4. UI validation (if applicable)
open http://localhost:3000/personas
```

**Regression Prevention:**
- Keep all existing turbo-carnival tests passing
- Keep all migrated fluffy-train tests passing
- Add integration tests for new connections (pipeline → cluster)

---

## Non-Goals

### What We're NOT Doing

1. **Not building GraphQL API** - Web UI only for now
2. **Not migrating TUI** - Web UI replaces it (can add later if wanted)
3. **Not supporting multiple databases** - Single database for simplicity
4. **Not adding mobile app** - Web responsive is enough for MVP
5. **Not backward compatibility with old fluffy-train** - Fresh start

---

## Open Questions & Decisions Needed

### 1. Data Migration
**Question:** Migrate existing fluffy-train production data or start fresh?

**Options:**
- A) Start fresh (recommended for MVP)
- B) Write migration script for existing data
- C) Support both (allow import)

**Recommendation:** Start fresh, add import if needed later

---

### 2. TUI Preservation
**Question:** Keep TUI as alternative interface?

**Options:**
- A) Deprecate TUI entirely
- B) Keep TUI for power users
- C) Build new TUI on top of unified backend

**Recommendation:** Deprecate for MVP, revisit if users request

---

### 3. Deployment Strategy
**Question:** How to deploy unified app?

**Options:**
- A) Single dyno (web + worker)
- B) Separate web and worker dynos
- C) Serverless functions for Instagram posting

**Recommendation:** Single dyno for MVP, split if Instagram posting needs background workers

---

### 4. OpenSpec Documentation
**Question:** Where to keep fluffy-train specs?

**Options:**
- A) Copy to `openspec/specs/` (unified documentation)
- B) Keep in separate directory (historical reference)
- C) Link as submodule

**Recommendation:** Copy to `openspec/specs/` for unified docs, keep originals for reference

---

## Performance Considerations

### Database Queries
- **N+1 Risk:** Cluster.images polymorphic query
- **Mitigation:** Eager loading, caching

```ruby
# Bad
clusters.each do |cluster|
  cluster.images.each { |img| img.url }  # N+1
end

# Good
clusters.includes(:photos, :image_candidates).each do |cluster|
  cluster.images.each { |img| img.url }  # 1 query per type
end
```

### Image Loading
- **Risk:** Slow exportable_url generation
- **Mitigation:** Caching, CDN

```ruby
class ImageCandidate
  def cached_exportable_url
    Rails.cache.fetch("candidate:#{id}:url", expires_in: 1.hour) do
      exportable_url
    end
  end
end
```

### Gap Analysis
- **Risk:** Expensive calculation on every page load
- **Mitigation:** Background job, caching

```ruby
# Cache gap analysis results
class Persona
  def gap_analysis
    Rails.cache.fetch("persona:#{id}:gaps", expires_in: 1.hour) do
      ContentPillars::GapAnalyzer.new(persona: self).analyze
    end
  end
end
```

---

## Security Considerations

### Instagram Credentials
- Store in Rails credentials, not ENV
- Rotate regularly
- Use long-lived tokens (60 days)

### Image URLs
- Ensure exportable_url is publicly accessible but not guessable
- Consider signed URLs if needed
- Rate limit image serving endpoint

### User Authentication
- Existing turbo-carnival auth (if any) extends to persona management
- Consider multi-persona access control later

---

## Rollout Plan

### Phase 1: Internal Testing (Week 1-4)
- Migrate packs incrementally
- Test each pack thoroughly
- No production deployment

### Phase 2: Feature Complete (Week 5)
- All packs migrated
- UI complete
- End-to-end testing

### Phase 3: Production Deployment
- Deploy to staging
- Run parallel with fluffy-train (both active)
- Gradual cutover
- Archive fluffy-train when confident

---

## Success Metrics

### Technical
- [ ] All tests passing (turbo-carnival + fluffy-train)
- [ ] No packwerk violations
- [ ] Database migrations clean
- [ ] Performance < 500ms page load
- [ ] Zero downtime deployment

### User Experience
- [ ] Workflow 50%+ faster than two-app flow
- [ ] Zero manual export/import
- [ ] Single authentication session
- [ ] Visual feedback throughout

### Business
- [ ] 1 codebase instead of 2
- [ ] 1 deployment instead of 2
- [ ] Reduced maintenance burden
- [ ] Feature development velocity increased

---

## Conclusion

This design provides a clear, incremental path to merging fluffy-train into turbo-carnival. Key decisions prioritize:

1. **Simplicity:** Leverage existing packwerk structure
2. **Safety:** Pack-by-pack migration with testing
3. **Flexibility:** Polymorphic image handling
4. **Automation:** Auto-linking on completion
5. **User Experience:** Unified web interface

**Estimated effort remains 5 weeks (13 active days)** due to incremental approach and well-defined pack boundaries.
