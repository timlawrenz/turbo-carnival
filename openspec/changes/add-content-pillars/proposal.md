# Change: Add Content Pillars Capability

## Why

Personas need strategic content planning to ensure balanced, themed content creation. Content Pillars provide:

1. **Strategic themes** with weights (e.g., "Fitness 30%", "Travel 40%")
2. **Gap analysis** showing which themes need more content  
3. **Temporal planning** with start/end dates for seasonal content
4. **Guidelines** for tone, topics, and style per pillar

This is Week 1, Day 3-4 of the integration roadmap. Content Pillars are the foundation for AI-driven content generation and automated posting strategies.

## What Changes

- **NEW**: Content Pillars pack from fluffy-train
- **NEW**: Database tables (content_pillars, pillar_cluster_assignments)
- **NEW**: Gap analysis service
- **NEW**: Web UI for pillar management
- **FUTURE**: Integration with clusters (Week 2)
- **FUTURE**: AI content generation based on gaps (Week 3)

**No Breaking Changes** - Purely additive. Personas can exist without pillars.

## Impact

**Affected Specs:**
- NEW spec: `content-pillars` (copied from fluffy-train)

**Affected Code:**
- NEW pack: `packs/content_pillars/`
- NEW migrations: content_pillars, pillar_cluster_assignments  
- UPDATED: Persona model (has_many :content_pillars)
- NEW views: pillars management on persona show page

**Dependencies:**
- Requires: Personas pack (✅ already exists)
- Required by: Clustering (Week 2), AI Services (Week 3)

## Migration Strategy

Since we're importing from fluffy-train:

1. **Copy pack structure** from fluffy-train repository
2. **Copy migrations** with updated timestamps
3. **Adapt for web UI** (fluffy-train is TUI-only)
4. **Test with Sarah persona** using existing data if available
5. **Gap analysis** works but shows no clusters yet (Week 2)

## Notes

- Based on fluffy-train's `packs/content_pillars/` implementation
- Simplified for initial import (no clustering yet - that's Week 2)
- Gap analysis will be basic until clusters are integrated
- Web UI replaces TUI commands from fluffy-train
