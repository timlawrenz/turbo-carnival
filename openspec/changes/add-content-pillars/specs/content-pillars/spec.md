## ADDED Requirements

### Requirement: Content Pillar Definition and Management

System SHALL allow creation and management of content pillars with strategic attributes for persona-based content planning.

**Acceptance Criteria:**
- Pillar has name (unique per persona), description, weight (%), active status
- Pillar can have optional date range (start_date, end_date) for temporal themes
- Pillar stores guidelines (tone, topics, avoid_topics, style_notes) in JSONB
- Pillar belongs to exactly one persona
- Can create, read, update, deactivate pillars via web UI
- Weight validation: all active pillar weights sum to ≤100% per persona
- Priority field (1-5) for importance ranking

#### Scenario: Create seasonal pillar

- **GIVEN** Sarah persona exists
- **WHEN** I create a pillar with name "Thanksgiving 2024", weight 30%, dates Nov 7-Dec 5
- **THEN** pillar is created with strategic attributes
- **AND** pillar.weight == 30.0
- **AND** pillar.active == true
- **AND** pillar can store guidelines in JSONB

#### Scenario: Weight validation prevents exceeding 100%

- **GIVEN** Sarah has existing pillars totaling 80% weight
- **WHEN** I try to create pillar with weight 25%
- **THEN** validation fails (total would exceed 100%)
- **AND** error message indicates "total weight for persona would exceed 100%"

#### Scenario: Unique names per persona

- **GIVEN** Sarah has a pillar named "Fitness"
- **AND** Emma persona exists
- **WHEN** I create a pillar named "Fitness" for Emma
- **THEN** pillar is created successfully (different persona)
- **WHEN** I try to create another "Fitness" pillar for Sarah
- **THEN** validation fails with "Name has already been taken"

---

### Requirement: Temporal Pillar Management

System SHALL support time-bounded content pillars for seasonal or campaign-based content.

**Acceptance Criteria:**
- Pillars can have start_date and/or end_date (both optional)
- end_date must be after start_date if both present
- Scopes: active (active=true), current (active and within date range)
- Instance methods: current?, expired?
- UI shows date range when present

#### Scenario: Current pillar identification

- **GIVEN** "Thanksgiving 2024" pillar with dates Nov 7 - Dec 5
- **WHEN** current date is Nov 15
- **THEN** pillar.current? == true
- **WHEN** current date is Dec 10
- **THEN** pillar.current? == false
- **AND** pillar.expired? == true

#### Scenario: Date validation

- **GIVEN** I am creating a pillar
- **WHEN** I set start_date to Dec 1 and end_date to Nov 1
- **THEN** validation fails with "end_date must be after start date"

---

### Requirement: Pillar Cluster Assignments (Week 2)

System SHALL support many-to-many relationships between pillars and clusters through a join table.

**Acceptance Criteria:**
- PillarClusterAssignment join model with pillar_id and cluster_id
- Table created but unused until clustering pack is integrated (Week 2)
- Validation: pillar and cluster must belong to same persona
- Assignment can be marked as "primary"
- Unique constraint on [pillar_id, cluster_id]

#### Scenario: Create assignment table (stub)

- **GIVEN** content_pillars table exists
- **WHEN** running migrations
- **THEN** pillar_cluster_assignments table is created
- **AND** has foreign keys to content_pillars and clusters
- **AND** has primary flag (default false)
- **NOTE**: Actual usage deferred to Week 2 when clustering pack is added

---

### Requirement: Basic Gap Analysis Service

System SHALL provide gap analysis showing content needs per pillar.

**Acceptance Criteria:**
- GapAnalysisService.calculate_gaps(persona, lookahead_days: 30)
- Returns hash: { pillar => { target, available, gap, status } }
- target = posts needed based on weight and lookahead
- available = 0 (no clusters yet - Week 2)
- gap = target - available
- status = :ready, :low, :critical, :exhausted
- Basic implementation until clustering integrated

#### Scenario: Calculate basic gap

- **GIVEN** Sarah has "Fitness" pillar with weight 30%
- **AND** lookahead is 30 days, target is 30 posts
- **WHEN** running gap analysis
- **THEN** Fitness target = 9 posts (30% of 30)
- **AND** Fitness available = 0 (no clusters yet)
- **AND** Fitness gap = 9
- **AND** Fitness status = :exhausted

#### Scenario: Gap analysis respects temporal boundaries

- **GIVEN** "Thanksgiving" pillar with end_date Dec 5
- **AND** current date is Dec 10
- **WHEN** running gap analysis
- **THEN** "Thanksgiving" pillar is NOT included (expired)

---

### Requirement: Web UI for Pillar Management

System SHALL provide web interface for managing content pillars.

**Acceptance Criteria:**
- Pillars section on persona show page
- List all pillars with weight, dates, status
- Create new pillar form
- Edit existing pillar form
- Delete pillar with confirmation
- Visual gap indicators (🔴 critical, ⚠️ low, ✅ ready)
- Nested routes: /personas/:persona_id/content_pillars

#### Scenario: View pillars on persona page

- **GIVEN** Sarah has 3 content pillars
- **WHEN** I visit /personas/3
- **THEN** I see "Content Pillars" section
- **AND** I see all 3 pillars listed
- **AND** each shows name, weight, dates, status
- **AND** I see "New Pillar" button

#### Scenario: Create pillar via web form

- **GIVEN** I am on Sarah's persona page
- **WHEN** I click "New Pillar"
- **AND** I fill in name "Travel", weight 25%, priority 4
- **AND** I submit the form
- **THEN** pillar is created
- **AND** I am redirected to persona page
- **AND** I see "Travel" in the pillars list

---

### Requirement: Public API Module

System SHALL provide module-based public API for content pillar operations.

**Acceptance Criteria:**
- ContentPillars module is the only public interface
- ContentPillars.for_persona(persona) returns active pillars
- ContentPillars.create(attrs) creates pillar
- ContentPillars.gap_analysis(persona, lookahead: 30) runs analysis
- Public API documented in packs/content_pillars/README.md

#### Scenario: Use public API from other packs

- **GIVEN** another pack needs pillar information
- **WHEN** code calls ContentPillars.for_persona(sarah)
- **THEN** returns Sarah's active content pillars
- **AND** does not require direct model access

---

### Requirement: Packwerk Compliance

System SHALL follow Packwerk modular architecture.

**Acceptance Criteria:**
- Pack located at packs/content_pillars/
- package.yml with enforce_dependencies: true
- Dependencies: personas (clustering added Week 2)
- All inter-pack access through app/public/content_pillars.rb
- Models and services are private
- No packwerk violations

#### Scenario: Packwerk validation passes

- **GIVEN** content_pillars pack is implemented
- **WHEN** running bin/packwerk check
- **THEN** no new violations are introduced
- **AND** bin/packwerk validate passes

---

### Requirement: Import from Fluffy-Train

System SHALL provide import capability for existing content pillars from fluffy-train.

**Acceptance Criteria:**
- Rake task: personas:import_pillars
- Connects to fluffy-train database
- Imports pillars for Sarah persona
- Preserves weights, dates, guidelines
- Falls back gracefully if DB not accessible

#### Scenario: Import Sarah's pillars

- **GIVEN** fluffy-train database is accessible
- **AND** Sarah has 3 pillars in fluffy-train
- **WHEN** running rails personas:import_pillars
- **THEN** 3 pillars are created in turbo-carnival
- **AND** weights and dates are preserved
- **AND** guidelines JSONB is copied

---

