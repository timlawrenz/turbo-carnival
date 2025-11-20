# Merge Fluffy-Train: Unified Content Creation Platform

**Status:** Proposed  
**Created:** 2025-11-20  
**Effort:** 5 weeks (13 days active development)  
**Risk:** Low (incremental pack-by-pack migration)

---

## Summary

Merge the fluffy-train application into turbo-carnival to create a unified platform for persona-based AI content creation, from image generation through Instagram posting. This combines turbo-carnival's quality-controlled image generation pipeline with fluffy-train's content strategy, AI services, and social media scheduling.

**Key Insight:** Both applications use Packwerk, making this a straightforward pack migration rather than a complex system integration.

---

## Problem

Currently operating two separate applications:
- **Turbo-Carnival:** Image generation with voting, ELO ranking, and approval gates
- **Fluffy-Train:** Persona management, content strategy, AI services, Instagram scheduling (TUI-only, no web interface)

**Current Workflow Issues:**
1. Context switching between two applications
2. Manual export/import of generated images
3. No web interface for fluffy-train features
4. Disconnected data models requiring synchronization
5. Duplicate deployment and maintenance effort

---

## Proposed Solution

Merge fluffy-train INTO turbo-carnival incrementally, pack-by-pack, following OpenSpec documentation:

### Migration Strategy
1. **Use OpenSpec as Blueprint:** Each fluffy-train spec becomes a migration task
2. **Dependency-Sorted Order:** Personas → Pillars → Clustering → AI → Strategy → Scheduling
3. **Adapt Clustering Pack:** Make it work with ImageCandidate instead of Photo
4. **Build Web UI:** Create web interface to replace TUI functionality
5. **Auto-Link Winners:** Connect pipeline completion to content library
6. **Unified Dashboard:** Single interface for entire workflow

### Architecture After Merge

```
Unified Application (turbo-carnival)
├── Personas (identity & content strategy)
│   └── Content Pillars (strategic themes with gap analysis)
├── Pipelines (image generation workflows)
│   ├── Voting & ELO ranking
│   ├── Approval gates
│   └── Auto-link winner to cluster
├── Clusters (content library)
│   ├── Photos (legacy support)
│   └── ImageCandidates (from pipelines)
├── AI Services
│   ├── Content prompt generation
│   ├── Caption generation
│   └── Hashtag generation
├── Content Strategy (smart selection)
└── Scheduling (Instagram posting)
```

---

## Workflow Comparison

### Before (Two Applications)
1. Open fluffy-train TUI → gap analysis identifies content need
2. Generate AI prompt in TUI
3. Copy prompt to clipboard
4. Open turbo-carnival web → create pipeline manually
5. Paste prompt into Step 1 configuration
6. Run pipeline → vote → approve gates
7. Export winners to directory
8. Back to fluffy-train → import to cluster
9. Schedule post via TUI

**Result:** 9 steps, 2 applications, manual data transfer

### After (Unified Application)
1. Open Persona dashboard → see gap warning
2. Click "Generate Content" → AI creates cluster + pipeline + run
3. Vote & approve in same interface
4. Run completes → winner auto-linked to cluster
5. Click "Schedule Post" → done

**Result:** 5 steps, 1 application, fully automated

---

## Benefits

### User Experience
- ✅ Single unified interface (web-based)
- ✅ Seamless workflow from idea to Instagram post
- ✅ No manual export/import
- ✅ Visual pipeline monitoring
- ✅ Integrated content library view

### Technical
- ✅ Single codebase to maintain
- ✅ Shared data model (no sync issues)
- ✅ One deployment
- ✅ Packwerk boundaries maintained
- ✅ OpenSpec documentation preserved
- ✅ Feature parity with both original apps

### Business
- ✅ Reduced operational complexity
- ✅ Faster content creation workflow
- ✅ Better quality control (ELO + strategy)
- ✅ More maintainable long-term

---

## Migration Plan

### Phase 1: Foundation (Week 1)
**Goal:** Core persona infrastructure

#### Migration 1: Personas Pack (1 day)
- Copy `packs/personas/` from fluffy-train
- Migrate database schema
- Create PersonasController for CRUD
- Build personas index/show views
- **Deliverable:** `/personas` route with basic management

**Spec Reference:** `packs/personas/README.md` (fluffy-train)

#### Migration 2: Content Pillars Pack (1 day)
- Copy `packs/content_pillars/` from fluffy-train
- Migrate content_pillars and pillar_cluster_assignments tables
- Add pillars section to persona show page
- Implement gap analysis display
- **Deliverable:** Pillars visible in persona dashboard with gap indicators

**Spec Reference:** `openspec/specs/content-pillars/spec.md` (fluffy-train)

---

### Phase 2: Content Management (Week 2)

#### Migration 3: Clustering Pack - Adapted (2 days)
- Copy `packs/clustering/` from fluffy-train
- **Adapt:** Support both Photo (legacy) AND ImageCandidate
- Create ClusterCandidate join model
- Create cluster management UI
- Test polymorphic image handling
- **Deliverable:** Clusters that can contain turbo-carnival candidates

**Key Adaptation:**
```ruby
class Clustering::Cluster
  has_many :photos, dependent: :nullify  # Legacy
  has_many :cluster_candidates
  has_many :image_candidates, through: :cluster_candidates
  
  def images
    photos.to_a + image_candidates.to_a  # Polymorphic
  end
end
```

**Spec Reference:** `openspec/specs/clustering/spec.md` (fluffy-train, adapted)

#### Migration 4: Pipeline → Cluster Linking (1 day)
- Add `persona_id` and `cluster_id` to pipelines table
- Implement auto-linking on run completion
- Create "Generate Content" workflow
- **Deliverable:** Completed runs automatically add winners to clusters

**Auto-Link Logic:**
```ruby
class PipelineRun
  after_update :link_winner_to_cluster, if: -> { 
    completed? && pipeline.cluster_id.present?
  }
  
  private
  
  def link_winner_to_cluster
    winner = final_step.candidates.order(elo_score: :desc).first
    ClusterCandidate.create!(
      cluster_id: pipeline.cluster_id,
      candidate_id: winner.id,
      metadata: { elo_score: winner.elo_score }
    )
  end
end
```

---

### Phase 3: AI Services (Week 3)

#### Migration 5: AI Content Generation (1 day)
- Copy `lib/ai/` from fluffy-train (Gemini client, prompt generator)
- Add `ruby-openai` gem dependency
- Create CreateContentPipeline service
- Add "Generate Content" button to pillar cards
- **Deliverable:** AI-driven pipeline creation from gap analysis

**Spec Reference:** `openspec/specs/ai-content-generation/spec.md` (fluffy-train)

#### Migration 6: Caption Generation (1 day)
- Copy `packs/caption_generations/` from fluffy-train
- Migrate database schema
- Test with ImageCandidate images
- **Deliverable:** AI captions for candidates

**Spec Reference:** `openspec/specs/caption-generation/spec.md` (fluffy-train)

#### Migration 7: Hashtag Generation (0.5 days)
- Copy `packs/hashtag_generations/` from fluffy-train
- Migrate database schema
- Integrate with caption generation
- **Deliverable:** AI hashtags for posts

**Spec Reference:** `openspec/specs/hashtag-generation/spec.md` (fluffy-train)

---

### Phase 4: Strategy & Scheduling (Week 4)

#### Migration 8: Content Strategy (1.5 days)
- Copy `packs/content_strategy/` from fluffy-train
- Migrate content_strategy_states and content_strategy_histories tables
- Adapt selector to work with ImageCandidates
- Create preview UI for next post selection
- **Deliverable:** Smart content selection respecting pillar weights

**Spec Reference:** `openspec/specs/content-strategy/spec.md` (fluffy-train)

#### Migration 9: Scheduling & Instagram (1 day)
- Copy `packs/scheduling/` and `lib/instagram/` from fluffy-train
- Migrate scheduling_posts table
- Add Instagram API credentials configuration
- Create scheduling UI
- **Deliverable:** Instagram posting from web interface

**Spec Reference:** Scheduling pack documentation (fluffy-train)

---

### Phase 5: UI Integration (Week 5)

#### Migration 10: Unified Dashboard (2 days)
- Build comprehensive persona show page
- Integrate gap analysis with quick actions
- Show active pipelines with status
- Display content library (clusters with images)
- Add upcoming posts schedule
- Create "Generate Content" workflow UI
- **Deliverable:** Complete web-based workflow replacing TUI

**Dashboard Sections:**
1. Content Strategy (pillars with gap indicators)
2. Active Pipelines (monitoring + voting links)
3. Content Library (clusters with preview)
4. Upcoming Posts (schedule view)

#### Polish & Documentation (1 day)
- Navigation improvements
- End-to-end testing
- Update README
- Copy fluffy-train OpenSpecs for reference
- **Deliverable:** Production-ready unified application

---

## Key Technical Decisions

### 1. Turbo-Carnival as Base Application
**Why:** More recently developed, has web UI, voting interface is mature

### 2. Clustering Pack Adaptation
**Change:** Support both Photo (legacy) and ImageCandidate (new)  
**Reason:** Allows gradual migration, maintains backwards compatibility

### 3. Auto-Linking on Completion
**Implementation:** PipelineRun after_update callback  
**Benefit:** Zero manual intervention, automatic content library population

### 4. Web UI Over TUI
**Change:** Build web interface for all fluffy-train functionality  
**Reason:** Better UX, visual feedback, integrated with existing turbo-carnival UI  
**Note:** Can optionally keep TUI for advanced users

### 5. ImageCandidate as Image Source
**Change:** Clusters reference candidates instead of copying images  
**Benefit:** Single source of truth, preserves ELO metadata, no duplication

---

## Migration Checklist

### Week 1: Foundation
- [ ] Copy Personas pack
- [ ] Create PersonasController + views
- [ ] Copy Content Pillars pack
- [ ] Integrate pillars into persona UI
- [ ] Test gap analysis display

### Week 2: Content Management
- [ ] Copy and adapt Clustering pack
- [ ] Create ClusterCandidate join model
- [ ] Add persona/cluster foreign keys to pipelines
- [ ] Implement auto-linking callback
- [ ] Test winner → cluster workflow

### Week 3: AI Services
- [ ] Copy AI libraries (Gemini client)
- [ ] Create CreateContentPipeline service
- [ ] Copy Caption Generation pack
- [ ] Copy Hashtag Generation pack
- [ ] Test AI prompt → pipeline → caption flow

### Week 4: Strategy & Scheduling
- [ ] Copy Content Strategy pack
- [ ] Adapt for ImageCandidate
- [ ] Copy Scheduling pack
- [ ] Add Instagram API integration
- [ ] Test post scheduling

### Week 5: UI & Polish
- [ ] Build unified persona dashboard
- [ ] Add "Generate Content" workflow
- [ ] Create cluster library view
- [ ] Add scheduling interface
- [ ] End-to-end testing
- [ ] Documentation updates

---

## Testing Strategy

After each migration:

1. **Unit Tests:** Run pack-specific tests
   ```bash
   bin/rails test packs/[pack_name]/test/
   ```

2. **Integration Test:** Console validation
   ```bash
   bin/rails runner "validation_script.rb"
   ```

3. **UI Test:** Browser verification
   ```bash
   open http://localhost:3000/personas
   ```

4. **Git Commit:** Clean history with spec reference
   ```bash
   git commit -m "[Pack Name] migration
   
   Spec: openspec/specs/[spec]/spec.md
   Tests: All passing"
   ```

---

## Rollback Strategy

Each migration is a single git commit. Can rollback with:

```bash
# Rollback last migration
git revert HEAD

# Or rollback to specific point
git revert <commit-sha>

# Drop migrated tables if needed
bin/rails db:rollback
```

---

## Dependencies

### New Gems (from fluffy-train)
- `ruby-openai` - AI services
- `instagram_graph_api` - Instagram posting
- `matrix` - Clustering algorithms (if used)
- `concurrent-ruby` - Async operations

### Environment Variables
```bash
# AI Services
GEMINI_API_KEY=your_key

# Instagram Integration
INSTAGRAM_APP_ID=your_app_id
INSTAGRAM_APP_SECRET=your_secret
INSTAGRAM_ACCESS_TOKEN=your_long_lived_token
INSTAGRAM_ACCOUNT_ID=your_account_id

# Application
TURBO_CARNIVAL_HOST=https://your-app.com  # For exportable URLs
```

---

## Risks & Mitigations

### Risk: Schema Conflicts
**Likelihood:** Low  
**Impact:** Medium  
**Mitigation:** Both apps use different table namespaces (no conflicts found)

### Risk: Feature Regression
**Likelihood:** Medium  
**Impact:** High  
**Mitigation:** Pack-by-pack testing, keep fluffy-train running in parallel during migration

### Risk: UI Complexity
**Likelihood:** Medium  
**Impact:** Medium  
**Mitigation:** Incremental UI development, can reuse TUI logic as reference

### Risk: Instagram API Changes
**Likelihood:** Low  
**Impact:** High  
**Mitigation:** Well-tested scheduling pack from fluffy-train, minimal API surface

---

## Success Criteria

### Functional
- [ ] All fluffy-train packs migrated successfully
- [ ] Web UI for all TUI functionality
- [ ] Auto-linking working (run completion → cluster)
- [ ] AI content generation functional
- [ ] Instagram posting working
- [ ] Content strategy selection working

### Technical
- [ ] All tests passing
- [ ] No schema conflicts
- [ ] Clean packwerk boundaries
- [ ] OpenSpec documentation complete
- [ ] Performance acceptable (no regressions)

### User Experience
- [ ] Single login/session
- [ ] Unified navigation
- [ ] No manual export/import needed
- [ ] Workflow 50%+ faster than before
- [ ] Visual feedback throughout

---

## Timeline

**Start Date:** TBD  
**Target Completion:** 5 weeks from start

**Weekly Milestones:**
- Week 1: Personas + Pillars working in UI
- Week 2: Pipelines linked to clusters, auto-linking functional
- Week 3: AI services integrated
- Week 4: Full workflow functional (gap → generate → post)
- Week 5: Polished, production-ready

**Checkpoints:**
- End of Week 2: Demo basic workflow
- End of Week 4: Demo full workflow
- End of Week 5: Production deployment

---

## Post-Migration

### Deprecation
- [ ] Archive fluffy-train repository
- [ ] Update README with migration notice
- [ ] Redirect users to unified app

### Future Enhancements
- [ ] Mobile-responsive UI
- [ ] Real-time notifications (webhooks)
- [ ] Multi-persona batch operations
- [ ] Analytics dashboard
- [ ] A/B testing for content

---

## Open Questions

1. **TUI Preservation:** Keep TUI as alternative interface or deprecate?
   - **Recommendation:** Deprecate initially, can add back if requested

2. **Data Migration:** Migrate existing fluffy-train data or start fresh?
   - **Recommendation:** Start fresh for MVP, add migration script if needed

3. **Deployment:** Single dyno or separate web/worker?
   - **Recommendation:** Single for MVP, split if Instagram posting needs background workers

4. **OpenSpec Location:** Keep fluffy-train specs in separate directory?
   - **Recommendation:** Copy to `openspec/specs/` for unified documentation

---

## References

- Fluffy-Train: https://github.com/timlawrenz/fluffy-train/
- Fluffy-Train OpenSpecs: `fluffy-train/openspec/specs/`
- Turbo-Carnival: `/home/tim/source/activity/turbo-carnival`
- Packwerk: https://github.com/Shopify/packwerk

---

## Appendix: Pack Inventory

### From Turbo-Carnival (Keep)
- `packs/pipeline/` - Pipeline and step management
- `packs/job_orchestration/` - Job selection and execution

### From Fluffy-Train (Migrate)
- `packs/personas/` - ✅ No changes needed
- `packs/content_pillars/` - ✅ No changes needed
- `packs/clustering/` - 🔧 Adapt for ImageCandidate
- `packs/caption_generations/` - ✅ No changes needed
- `packs/hashtag_generations/` - ✅ No changes needed
- `packs/content_strategy/` - 🔧 Adapt for ImageCandidate
- `packs/scheduling/` - ✅ No changes needed

### Libraries (Migrate)
- `lib/ai/` - AI clients and generators
- `lib/instagram/` - Instagram API client
- `lib/tui/` - ⏸️ Optional (may skip)

**Legend:**
- ✅ Direct copy
- 🔧 Requires adaptation
- ⏸️ Optional
