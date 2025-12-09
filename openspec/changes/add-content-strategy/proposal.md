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
- **ADDED**: `ThemeOfWeekStrategy` - focuses on one cluster theme per week
- **ADDED**: `ThematicRotationStrategy` - rotates through clusters with variety rules
- **ADDED**: `ContentStrategy::StrategyState` model to persist strategy state per persona
- **ADDED**: `ContentStrategy::HistoryRecord` model to audit posting decisions
- **ADDED**: Timing optimization concern for calculating optimal posting times
- **ADDED**: Variety enforcement concern for content diversity rules
- **ADDED**: Hashtag engine for intelligent hashtag generation
- **ADDED**: Strategy configuration via YAML (`config/content_strategy.yml`)
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
  - Redis (optional) for state caching
- Breaking changes: None (additive only)
- Performance considerations:
  - Strategy selection queries optimized with DB indexes
  - State caching reduces repeated persona/cluster queries
  - History lookups limited to recent 30 days

## Architecture Decisions

### Why Packwerk Pack
Following project conventions, business logic is organized into domain-specific packs. Content strategy is a distinct domain concern separate from scheduling, clustering, and personas.

### Why Strategy Pattern
Different personas may need different posting approaches (theme-focused vs. rotation). The strategy pattern allows pluggable algorithms while keeping the selection interface consistent.

### Why State Persistence
Strategies like "theme of week" need to remember which cluster/week they're on. Stateless approaches would cause random selection, defeating the purpose of structured posting patterns.

### Why JSONB for Config
Posting rules (frequency, timing windows, variety gaps) vary by environment and persona. JSONB provides flexible storage without schema migrations for config tweaks.

### Why Separate History Table
Audit trail of "why this photo was selected" is critical for debugging strategy behavior and analyzing posting patterns over time. Separating from posts table keeps scheduling concerns isolated.

## Migration Strategy
1. Create content_strategy pack structure
2. Copy and adapt models, commands, strategies from fluffy-train
3. Update references from fluffy-train structure to turbo-carnival (e.g., `Photo` → `Clustering::Photo`)
4. Add database migrations for state and history tables
5. Migrate configuration from fluffy-train YAML to turbo-carnival config
6. Add UI integration in posts controller and views
7. Write specs following turbo-carnival conventions
8. Test with existing persona/cluster data

## Open Questions
1. Should we support Redis caching or use Solid Cache?
2. Do we need to support multiple simultaneous strategies per persona, or just one active strategy?
3. Should optimal time calculation respect timezone from persona config or use system default?
4. How should we handle the case where all photos in a cluster are posted?

## Related Changes
- Builds on: `add-scheduling` (needs scheduling_posts table)
- Builds on: `add-clustering` (needs clusters and photos)
- Builds on: `add-personas` (needs persona config)
- May integrate with: `add-content-pillars` (pillar-based rotation)
