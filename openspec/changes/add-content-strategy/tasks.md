# Tasks: Add Content Strategy Engine

## Database Setup
- [ ] Create migration for `content_strategy_states` table
  - [ ] Add `persona_id` (bigint, foreign key, unique index)
  - [ ] Add `active_strategy` (string)
  - [ ] Add `strategy_config` (jsonb, default: {})
  - [ ] Add `state_data` (jsonb, default: {})
  - [ ] Add `started_at` (datetime)
  - [ ] Add timestamps
- [ ] Create migration for `content_strategy_histories` table
  - [ ] Add `persona_id` (bigint, foreign key, index)
  - [ ] Add `post_id` (bigint, foreign key, nullable)
  - [ ] Add `cluster_id` (bigint, foreign key, nullable, index)
  - [ ] Add `strategy_name` (string, index)
  - [ ] Add `decision_context` (jsonb)
  - [ ] Add `created_at` (datetime, index)
- [ ] Add columns to `scheduling_posts` table
  - [ ] Add `cluster_id` (bigint, foreign key, nullable)
  - [ ] Add `strategy_name` (string, nullable)
  - [ ] Add `optimal_time_calculated` (datetime, nullable)
  - [ ] Add `hashtags` (jsonb, nullable)

## Pack Structure
- [ ] Create pack directory at `packs/content_strategy/`
- [ ] Create pack.yml with dependencies
- [ ] Create standard Rails directories (models, commands, services, concerns, specs)
- [ ] Add pack README documenting usage and architecture

## Models
- [ ] Create `ContentStrategy::StrategyState` model
  - [ ] Add associations (belongs_to :persona)
  - [ ] Add validation (persona uniqueness - one strategy per persona)
  - [ ] Add `get_state(key)` method
  - [ ] Add `set_state(key, value)` method
  - [ ] Add `update_state(updates_hash)` method
  - [ ] Add `reset_state!` method
  - [ ] Default active_strategy to 'thematic_rotation_strategy'
- [ ] Create `ContentStrategy::HistoryRecord` model
  - [ ] Add associations (belongs_to :persona, :post, :cluster)
  - [ ] Add scopes: `for_persona`, `for_cluster`, `recent_days(n)`, `recent`
  - [ ] Add validation (persona presence, created_at presence)
- [ ] Update `Scheduling::Post` model
  - [ ] Add association `belongs_to :cluster` (optional)
  - [ ] Add scopes: `with_strategy(name)`, `from_cluster(id)`
  - [ ] Add validation for cluster existence if cluster_id present

## Configuration
- [ ] Create `config/content_strategy.yml`
  - [ ] Add development config (posting frequency, timing, variety, hashtags)
  - [ ] Add test config (similar to development)
  - [ ] Add production config
  - [ ] Set default strategy to 'thematic_rotation_strategy'
  - [ ] Use system timezone for all environments
- [ ] Create `ContentStrategy::ConfigLoader` service
  - [ ] Load YAML config for current environment
  - [ ] Provide getter methods for all config values
  - [ ] Implement `reload!` method
  - [ ] Add validation for required config keys
  - [ ] Default to system timezone (Time.zone)

## Core Commands
- [ ] Create `ContentStrategy::SelectNextPost` command
  - [ ] Accept `persona` and optional `strategy_name` parameters
  - [ ] Validate strategy exists in registry
  - [ ] Build context with persona, history, clusters
  - [ ] Execute selected strategy
  - [ ] Return result hash with photo, cluster, time, hashtags
  - [ ] Handle errors gracefully (no clusters, no photos, etc.)

## Strategy Registry
- [ ] Create `ContentStrategy::StrategyRegistry` singleton
  - [ ] Implement `register(name, strategy_class)` method
  - [ ] Implement `get(name)` method
  - [ ] Implement `exists?(name)` method
  - [ ] Implement `all` method returning strategy names
- [ ] Create `ContentStrategy::UnknownStrategyError` exception
- [ ] Create `ContentStrategy::NoAvailableClustersError` exception
- [ ] Create `ContentStrategy::NoUnpostedPhotosError` exception

## Strategy Context
- [ ] Create `ContentStrategy::Context` class
  - [ ] Accept persona, optional pillar
  - [ ] Load clusters with unposted photos
  - [ ] Load posting history for persona (last 30 days)
  - [ ] Load strategy state
  - [ ] Load configuration
  - [ ] Memoize all queries
  - [ ] Provide getter methods for all context data

## Base Strategy
- [ ] Create `ContentStrategy::BaseStrategy` abstract class
  - [ ] Accept context in initialize
  - [ ] Define abstract `select_next_photo` method
  - [ ] Provide helper methods from concerns (timing, variety, hashtags)
  - [ ] Define `name` method returning strategy identifier

## Concrete Strategies
- [ ] Create `ContentStrategy::ThemeOfWeekStrategy`
  - [ ] Implement `select_next_photo` logic
  - [ ] Track current week number in state
  - [ ] Select cluster for week (round-robin)
  - [ ] Select unposted photo from week's cluster
  - [ ] Advance week when cluster exhausted
  - [ ] Return photo, cluster, time, hashtags
- [ ] Create `ContentStrategy::ThematicRotationStrategy`
  - [ ] Implement `select_next_photo` logic
  - [ ] Track rotation index in state
  - [ ] Enforce variety rules (min days gap between same cluster)
  - [ ] Select next cluster with available photos
  - [ ] Rotate to next cluster after selection
  - [ ] Return photo, cluster, time, hashtags

## Timing Optimization Concern
- [ ] Create `ContentStrategy::TimingOptimization` concern
  - [ ] Implement `get_optimal_posting_time(photo:)` method
  - [ ] Check config for optimal time windows
  - [ ] Calculate next available time in optimal window
  - [ ] Fall back to alternative window if optimal is too soon
  - [ ] Respect `posting_days_gap` config
  - [ ] Return datetime

## Variety Enforcement Concern
- [ ] Create `ContentStrategy::VarietyEnforcement` concern
  - [ ] Implement `enforce_variety_rules(clusters)` method
  - [ ] Filter out clusters used within `variety_min_days_gap`
  - [ ] Filter out clusters exceeding `variety_max_same_cluster` per week
  - [ ] Return eligible clusters array

## Hashtag Engine
- [ ] Create `ContentStrategy::HashtagEngine` service
  - [ ] Implement `generate(photo:, cluster:, count:)` method
  - [ ] Extract themes from cluster name/description
  - [ ] Include persona hashtag strategy
  - [ ] Mix popular, medium, niche hashtags
  - [ ] Respect `hashtag_count_min` and `hashtag_count_max` config
  - [ ] Return array of hashtag strings

## Controller Integration
- [ ] Update `Scheduling::PostsController`
  - [ ] Add `suggest_next` action
  - [ ] Call `ContentStrategy::SelectNextPost` command
  - [ ] Handle success: redirect to new post form with suggested photo
  - [ ] Handle errors: show flash message, redirect to index
- [ ] Update posts index view
  - [ ] Add "Get Next Suggested Post" button
  - [ ] Show current strategy name if persona has active strategy
  - [ ] Link to strategy configuration (future enhancement)

## State Caching (Using Solid Cache)
- [ ] Create `ContentStrategy::StateCache` wrapper
  - [ ] Implement `fetch(persona_id, &block)` method using Solid Cache
  - [ ] Set 5-minute TTL for cached data
  - [ ] Implement `invalidate(persona_id)` method
  - [ ] Use in Context for state/config queries

## Error Handling
- [ ] Add error handling in SelectNextPost
  - [ ] Catch UnknownStrategyError, return helpful message
  - [ ] Catch NoAvailableClustersError, suggest creating clusters
  - [ ] Catch NoUnpostedPhotosError, return error message (no suggestions for new content in this phase)
  - [ ] Log all errors with context for debugging

## Specs - Models
- [ ] Write specs for `ContentStrategy::StrategyState`
  - [ ] Test state persistence
  - [ ] Test get/set/update/reset methods
  - [ ] Test persona uniqueness validation
- [ ] Write specs for `ContentStrategy::HistoryRecord`
  - [ ] Test associations
  - [ ] Test scopes (for_persona, recent_days, etc.)
- [ ] Write specs for updated `Scheduling::Post` model
  - [ ] Test cluster association
  - [ ] Test strategy-related scopes

## Specs - Commands
- [ ] Write specs for `ContentStrategy::SelectNextPost`
  - [ ] Test successful photo selection
  - [ ] Test with different strategies
  - [ ] Test error cases (no clusters, no photos)
  - [ ] Test returned data structure (photo, cluster, time, hashtags)

## Specs - Strategies
- [ ] Write specs for `ThemeOfWeekStrategy`
  - [ ] Test weekly rotation
  - [ ] Test state persistence
  - [ ] Test cluster exhaustion handling
- [ ] Write specs for `ThematicRotationStrategy`
  - [ ] Test rotation logic
  - [ ] Test variety enforcement
  - [ ] Test wrapping around cluster list

## Specs - Services
- [ ] Write specs for `HashtagEngine`
  - [ ] Test hashtag generation
  - [ ] Test count constraints
  - [ ] Test mix of popular/medium/niche tags
- [ ] Write specs for `ConfigLoader`
  - [ ] Test loading environment-specific config
  - [ ] Test validation of required keys
  - [ ] Test reload functionality

## Specs - Concerns
- [ ] Write specs for `TimingOptimization`
  - [ ] Test optimal window calculation
  - [ ] Test alternative window fallback
  - [ ] Test days gap enforcement
- [ ] Write specs for `VarietyEnforcement`
  - [ ] Test filtering by recent usage
  - [ ] Test max same cluster per week
  - [ ] Test eligible cluster selection

## Specs - Request
- [ ] Write request specs for posts controller suggest_next action
  - [ ] Test successful suggestion redirect
  - [ ] Test error handling
  - [ ] Test flash messages

## Spec Deltas
- [ ] Create `specs/post-creation.delta.md` with MODIFIED requirements
  - [ ] Add requirement for automated suggestion button
  - [ ] Add scenarios for strategy-driven selection
- [ ] Create `specs/content-strategy.spec.md` with full new capability spec
  - [ ] Document all requirements for strategy system
  - [ ] Include scenarios for each strategy
  - [ ] Document configuration options
  - [ ] Document error states

## Documentation
- [ ] Update pack README with usage examples
- [ ] Document strategy selection algorithm
- [ ] Document configuration reference
- [ ] Add troubleshooting guide
- [ ] Document how to add custom strategies

## Testing & Validation
- [ ] Run all specs: `bundle exec rspec packs/content_strategy/spec`
- [ ] Run packwerk validation: `bin/packwerk check`
- [ ] Test with real persona/cluster data
- [ ] Validate optimal time calculations
- [ ] Verify hashtag generation quality
- [ ] Test strategy state persistence across requests

## OpenSpec Validation
- [ ] Run `openspec validate add-content-strategy --strict`
- [ ] Fix any validation errors
- [ ] Ensure all delta specs reference existing requirements
