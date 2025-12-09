# Change: Add Content Strategy Engine

## Why
We currently have a manual post creation interface that requires users to browse and select photos one-by-one. Users need an intelligent automated system that suggests the next best photo to post based on posting strategy, content variety rules, optimal timing, and persona-specific patterns. The external fluffy-train project has this capability in its `content_strategy` pack, and we need to migrate and integrate it into turbo-carnival.

**Business Value:**
- Reduces content planning effort from hours to minutes
- Ensures consistent posting cadence (3-5 posts/week)
- Maximizes engagement through optimal timing (5-8am peak window)
- Prevents content fatigue via variety enforcement (2-day gaps between similar themes)
- Automates hashtag generation based on cluster themes and persona strategy
- Maintains brand voice consistency across all automated suggestions

## What Changes
- **ADDED**: Content Strategy pack at `packs/content_strategy/`
- **ADDED**: `ContentStrategy::SelectNextPost` command to intelligently select next photo
- **ADDED**: Strategy registry system with pluggable posting strategies
- **ADDED**: `ThematicRotationStrategy` - PRIMARY STRATEGY: rotates through clusters with variety rules
- **ADDED**: `ThemeOfWeekStrategy` - focuses on one cluster theme per week (secondary option)
- **ADDED**: `ContentStrategy::StrategyState` model to persist strategy state per persona (one active strategy)
- **ADDED**: `ContentStrategy::HistoryRecord` model to audit posting decisions
- **ADDED**: Timing optimization concern for calculating optimal posting times (system timezone)
- **ADDED**: Variety enforcement concern for content diversity rules
- **ADDED**: Hashtag engine for intelligent hashtag generation
- **ADDED**: Strategy configuration via YAML (`config/content_strategy.yml`)
- **ADDED**: `ContentStrategy::StateCache` using Solid Cache with 5-minute TTL
- **ADDED**: UI button in post creation to "Get Next Suggested Post"
- **MODIFIED**: `Scheduling::Post` model to track `cluster_id`, `strategy_name`, `optimal_time_calculated`, `hashtags`
- **MODIFIED**: Posts controller to support strategy-driven suggestions
- **MODIFIED**: `post-creation` spec to include automated content suggestion requirements

## Impact
- Affected specs: `post-creation` (modified - adds automated suggestion), `content-strategy` (new)
- Affected code:
  - New pack: `packs/content_strategy/`
  - Modified: `packs/scheduling/app/models/scheduling/post.rb`
  - Modified: `app/controllers/scheduling/posts_controller.rb`
  - Modified views: post creation UI with "Suggest Next" button
  - New migration: Add `cluster_id`, `strategy_name`, `optimal_time_calculated`, `hashtags` to `scheduling_posts`
- External dependencies:
  - PostgreSQL JSONB for strategy state and config storage
  - Solid Cache for state caching (5-minute TTL)
- Breaking changes: None (additive only)
- Performance considerations:
  - Strategy selection queries optimized with DB indexes
  - State caching reduces repeated persona/cluster queries
  - History lookups limited to recent 30 days

## Architecture Decisions

### Why Packwerk Pack
Following project conventions, business logic is organized into domain-specific packs. Content strategy is a distinct domain concern separate from scheduling, clustering, and personas.

### Why One Strategy Per Persona
Each persona needs a consistent posting pattern to maintain brand identity. Supporting one active strategy simplifies UI and avoids conflicts. ThematicRotationStrategy is the primary/default choice for content variety.

### Why State Persistence
Strategies like "theme of week" need to remember which cluster/week they're on. Stateless approaches would cause random selection, defeating the purpose of structured posting patterns.

### Why JSONB for Config
Posting rules (frequency, timing windows, variety gaps) vary by environment and persona. JSONB provides flexible storage without schema migrations for config tweaks.

### Why Solid Cache
Project already uses Solid Cache for database-backed caching. No need for additional Redis dependency. 5-minute TTL provides good balance between freshness and performance.

## Migration Strategy
1. Create content_strategy pack structure
2. Copy and adapt models, commands, strategies from fluffy-train
3. Update references from fluffy-train structure to turbo-carnival (e.g., `Photo` → `Clustering::Photo`)
4. Add database migrations for state and history tables
5. Migrate configuration from fluffy-train YAML to turbo-carnival config
6. Add UI integration in posts controller and views
7. Write specs following turbo-carnival conventions
8. Test with existing persona/cluster data

## Resolved Questions
1. **Caching**: Use Solid Cache for all caching needs (state, config lookups)
2. **Strategy per persona**: One active strategy per persona. Primary strategy is Thematic Rotation.
3. **Timezone**: Use system default timezone for optimal time calculations
4. **Exhausted photos**: When no photos available, return error. Frontend will later suggest new content creation (future enhancement).

## Related Changes
- Builds on: `add-scheduling` (needs scheduling_posts table)
- Builds on: `add-clustering` (needs clusters and photos)
- Builds on: `add-personas` (needs persona config)
- May integrate with: `add-content-pillars` (pillar-based rotation)
