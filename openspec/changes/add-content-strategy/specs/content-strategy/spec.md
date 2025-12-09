# content-strategy Specification

## Purpose
Provides intelligent automated photo selection for Instagram posting based on configurable posting strategies, content variety rules, optimal timing algorithms, and persona-specific patterns. The system maintains consistent brand voice while maximizing engagement through data-driven content planning and hashtag generation.

## ADDED Requirements

### Requirement: Intelligent Photo Selection
The system SHALL automatically select the next best photo to post using pluggable strategy algorithms.

#### Scenario: Select next photo with default strategy
- **WHEN** user requests next suggested post without specifying strategy
- **THEN** use persona's active strategy (or default to Theme of Week)
- **AND** apply variety enforcement rules
- **AND** select unposted photo from eligible cluster
- **AND** calculate optimal posting time
- **AND** generate hashtags
- **AND** return photo with metadata

#### Scenario: Select photo with specific strategy
- **WHEN** user specifies strategy name in request
- **THEN** override persona's active strategy for this request
- **AND** execute specified strategy selection logic
- **AND** return photo with strategy-specific metadata

#### Scenario: No eligible photos available
- **WHEN** all photos in all clusters have been posted
- **THEN** raise NoUnpostedPhotosError
- **AND** return error message suggesting photo upload

#### Scenario: No clusters available
- **WHEN** persona has no clusters with photos
- **THEN** raise NoAvailableClustersError
- **AND** return error message suggesting cluster creation

### Requirement: Theme of Week Strategy
The system SHALL implement a weekly theme-focused posting strategy that concentrates on one cluster per week.

#### Scenario: Select cluster for new week
- **WHEN** starting a new week or strategy has no state
- **THEN** determine current week number
- **AND** select next cluster in round-robin order
- **AND** store week number and cluster_id in state

#### Scenario: Select photo from current week's cluster
- **WHEN** week's cluster has unposted photos
- **THEN** select random unposted photo from cluster
- **AND** maintain week number and cluster in state
- **AND** return photo with cluster context

#### Scenario: Advance week when cluster exhausted
- **WHEN** current week's cluster has no unposted photos
- **THEN** increment week number
- **AND** select next cluster in rotation
- **AND** select photo from new cluster
- **AND** update state with new week and cluster

#### Scenario: Handle all clusters exhausted
- **WHEN** all clusters have zero unposted photos
- **THEN** raise NoUnpostedPhotosError
- **AND** suggest uploading more photos or resetting post history

### Requirement: Thematic Rotation Strategy
The system SHALL implement rotating posting strategy that cycles through clusters with variety enforcement.

#### Scenario: Select next cluster in rotation
- **WHEN** selecting photo for rotation strategy
- **THEN** get next cluster index from state
- **AND** filter clusters by variety rules (min days gap)
- **AND** select cluster at current index from eligible clusters
- **AND** increment index for next request

#### Scenario: Enforce variety rules
- **WHEN** filtering clusters for selection
- **THEN** exclude clusters posted within `variety_min_days_gap` days
- **AND** exclude clusters exceeding `variety_max_same_cluster` per week
- **AND** return only eligible clusters

#### Scenario: Wrap rotation index
- **WHEN** rotation index exceeds cluster count
- **THEN** wrap index back to 0
- **AND** continue rotation from beginning
- **AND** re-apply variety filters

#### Scenario: All clusters violate variety rules
- **WHEN** all clusters are filtered out by variety enforcement
- **THEN** relax variety rules temporarily
- **AND** select least recently used cluster
- **AND** log variety rule violation

### Requirement: Optimal Posting Time Calculation
The system SHALL calculate optimal posting times based on Instagram best practices and configuration.

#### Scenario: Calculate time in optimal window
- **WHEN** calculating optimal posting time
- **THEN** check config for optimal_time_start_hour and optimal_time_end_hour
- **AND** find next available datetime within optimal window
- **AND** respect `posting_days_gap` minimum between posts
- **AND** return datetime in optimal window

#### Scenario: Use alternative window when optimal too soon
- **WHEN** next optimal window is within posting_days_gap
- **THEN** check alternative_time_start_hour and alternative_time_end_hour
- **AND** calculate next available alternative time
- **AND** return datetime in alternative window

#### Scenario: Respect timezone configuration
- **WHEN** calculating posting time
- **THEN** use timezone from persona config (if available)
- **AND** fall back to config/content_strategy.yml timezone
- **AND** return time in configured timezone

#### Scenario: Avoid posting too frequently
- **WHEN** last post was within `posting_days_gap` days
- **THEN** calculate minimum next allowed time
- **AND** find next optimal window after minimum time
- **AND** ensure at least `posting_days_gap` days between posts

### Requirement: Hashtag Generation
The system SHALL generate relevant hashtags based on cluster themes, photo content, and persona strategy.

#### Scenario: Generate hashtags from cluster theme
- **WHEN** generating hashtags for photo
- **THEN** extract keywords from cluster name
- **AND** extract keywords from cluster description
- **AND** convert to hashtag format (#keyword)
- **AND** include in generated list

#### Scenario: Mix hashtag popularity levels
- **WHEN** generating hashtag set
- **THEN** include mix per persona hashtag_strategy
- **AND** aim for 2 popular, 3 medium, 3 niche tags
- **AND** respect `hashtag_count_min` and `hashtag_count_max` from config

#### Scenario: Include persona hashtag strategy
- **WHEN** persona has custom hashtag_strategy config
- **THEN** include persona-specific hashtags
- **AND** merge with cluster-derived hashtags
- **AND** limit total to configured maximum

#### Scenario: Avoid hashtag over-use
- **WHEN** generating hashtags
- **THEN** check recent posting history (last 10 posts)
- **AND** reduce frequency of overused hashtags
- **AND** favor less recently used hashtags

### Requirement: Strategy State Management
The system SHALL persist and manage strategy state per persona across sessions.

#### Scenario: Initialize strategy state for persona
- **WHEN** persona uses strategy for first time
- **THEN** create StrategyState record with default values
- **AND** set active_strategy to default
- **AND** set started_at to current time
- **AND** initialize empty state_data

#### Scenario: Retrieve existing strategy state
- **WHEN** persona has existing strategy state
- **THEN** load StrategyState record from database
- **AND** parse state_data JSONB
- **AND** provide state values to strategy

#### Scenario: Update strategy state after selection
- **WHEN** strategy selects photo
- **THEN** update state_data with new values (week, index, cluster)
- **AND** persist to database
- **AND** invalidate cache if caching enabled

#### Scenario: Reset strategy state
- **WHEN** user switches strategies or resets
- **THEN** clear state_data to empty hash
- **AND** set new started_at timestamp
- **AND** update active_strategy name

### Requirement: Posting History Audit Trail
The system SHALL record all strategy decisions in an audit log for analysis and debugging.

#### Scenario: Record history on photo selection
- **WHEN** strategy selects photo successfully
- **THEN** create HistoryRecord with persona, cluster, strategy_name
- **AND** store full decision context (available clusters, variety filters applied)
- **AND** set created_at to selection time

#### Scenario: Link history to actual post
- **WHEN** user creates post from suggested photo
- **THEN** update HistoryRecord with post_id
- **AND** allow tracking from suggestion to published post

#### Scenario: Query recent posting history
- **WHEN** strategy needs recent history for variety rules
- **THEN** query HistoryRecords for persona in last 30 days
- **AND** use indexed created_at for performance
- **AND** return ordered by recency

#### Scenario: Analyze strategy performance
- **WHEN** user views posting analytics
- **THEN** group posts by strategy_name
- **AND** show engagement metrics per strategy
- **AND** show cluster usage distribution

### Requirement: Strategy Registry and Plugins
The system SHALL support registering and managing multiple posting strategies.

#### Scenario: Register strategy at boot
- **WHEN** application boots
- **THEN** register all built-in strategies (ThemeOfWeek, ThematicRotation)
- **AND** make available via StrategyRegistry
- **AND** validate each strategy implements required interface

#### Scenario: Lookup strategy by name
- **WHEN** command needs to instantiate strategy
- **THEN** lookup strategy class from registry by name
- **AND** return strategy class if exists
- **AND** raise UnknownStrategyError if not found

#### Scenario: List available strategies
- **WHEN** user views strategy selection UI
- **THEN** call StrategyRegistry.all
- **AND** return array of registered strategy names
- **AND** display to user for selection

#### Scenario: Validate unknown strategy
- **WHEN** user specifies invalid strategy name
- **THEN** check StrategyRegistry.exists?(name)
- **AND** raise UnknownStrategyError with helpful message
- **AND** list available strategies in error

### Requirement: YAML Configuration Management
The system SHALL load posting rules from YAML configuration with environment-specific overrides.

#### Scenario: Load environment-specific config
- **WHEN** application boots
- **THEN** load config/content_strategy.yml
- **AND** parse current environment section (development, test, production)
- **AND** make config available via ConfigLoader singleton

#### Scenario: Access configuration values
- **WHEN** strategy needs config value
- **THEN** call ConfigLoader.get(key) or specific getter method
- **AND** return configured value
- **AND** provide sensible default if key missing

#### Scenario: Validate required config keys
- **WHEN** loading configuration
- **THEN** ensure all required keys present
- **AND** validate value types (integers, strings, datetimes)
- **AND** raise ConfigError if validation fails

#### Scenario: Reload configuration
- **WHEN** config file changes in development
- **THEN** call ConfigLoader.reload!
- **AND** re-parse YAML file
- **AND** update singleton instance

### Requirement: Variety Enforcement Rules
The system SHALL enforce content diversity rules to prevent repetitive posting patterns.

#### Scenario: Enforce minimum days gap between cluster reuse
- **WHEN** filtering clusters for selection
- **THEN** check posting history for each cluster
- **AND** exclude clusters posted within `variety_min_days_gap` days
- **AND** return only clusters outside minimum gap

#### Scenario: Enforce maximum cluster use per week
- **WHEN** filtering clusters for selection
- **THEN** count posts from each cluster in current week
- **AND** exclude clusters exceeding `variety_max_same_cluster` threshold
- **AND** return only clusters below maximum

#### Scenario: Handle all clusters filtered out
- **WHEN** variety rules exclude all clusters
- **THEN** log warning about overly strict rules
- **AND** select least recently used cluster as fallback
- **AND** allow posting despite variety violation

### Requirement: Strategy Context Building
The system SHALL provide strategies with rich context including persona data, clusters, and history.

#### Scenario: Build context with persona
- **WHEN** strategy is instantiated
- **THEN** load persona record
- **AND** load persona's clusters with unposted photo counts
- **AND** load posting history (last 30 days)
- **AND** load strategy state
- **AND** load configuration

#### Scenario: Filter clusters with unposted photos
- **WHEN** building context
- **THEN** query clusters for persona
- **AND** join with photos table
- **AND** filter to clusters having unposted photos
- **AND** order by created_at or name

#### Scenario: Memoize context queries
- **WHEN** context is built once per strategy execution
- **THEN** memoize all database queries
- **AND** reuse cached results for repeated access
- **AND** avoid N+1 queries

#### Scenario: Include pillar if persona uses pillars
- **WHEN** building context and persona has content pillars
- **THEN** select next pillar via rotation service
- **AND** include pillar in context
- **AND** filter clusters to pillar's assigned clusters

### Requirement: Error Handling and Recovery
The system SHALL handle error conditions gracefully with helpful user feedback.

#### Scenario: Handle unknown strategy error
- **WHEN** SelectNextPost receives invalid strategy name
- **THEN** raise UnknownStrategyError with strategy name
- **AND** include list of available strategies in error
- **AND** return 422 status with error message

#### Scenario: Handle no clusters error
- **WHEN** persona has no clusters with photos
- **THEN** raise NoAvailableClustersError with persona id
- **AND** suggest creating clusters via UI
- **AND** return 404 status with helpful message

#### Scenario: Handle no unposted photos error
- **WHEN** all photos exhausted across all clusters
- **THEN** raise NoUnpostedPhotosError with details
- **AND** suggest uploading more photos or resetting history
- **AND** return 404 status with suggestions

#### Scenario: Log errors for debugging
- **WHEN** any error occurs in strategy execution
- **THEN** log error with full context (persona, strategy, state)
- **AND** include stack trace for unexpected errors
- **AND** preserve error for user feedback

### Requirement: Performance Optimization
The system SHALL optimize database queries and use caching to minimize latency.

#### Scenario: Use indexed queries for history lookups
- **WHEN** querying posting history
- **THEN** use index on (persona_id, created_at)
- **AND** use index on cluster_id for cluster-specific history
- **AND** limit to recent records (30 days)

#### Scenario: Cache strategy state
- **WHEN** using Solid Cache
- **THEN** cache StrategyState by persona_id with 5-minute TTL
- **AND** invalidate cache on state update
- **AND** reduce database hits for repeated requests

#### Scenario: Batch load associations
- **WHEN** loading clusters and photos
- **THEN** eager load associations (photos, pillars)
- **AND** use includes/preload to avoid N+1
- **AND** select only needed columns

#### Scenario: Monitor query performance
- **WHEN** running in development
- **THEN** use n_plus_one_control gem to detect N+1 queries
- **AND** log slow queries (>100ms)
- **AND** add indexes as needed
