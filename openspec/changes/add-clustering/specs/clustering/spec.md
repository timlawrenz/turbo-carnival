## ADDED Requirements

### Requirement: Cluster Definition and Management

System SHALL allow creation and management of content clusters for organizing generated images by theme or purpose.

**Acceptance Criteria:**
- Cluster has name (required), persona_id (required), status (enum), ai_prompt (optional)
- Cluster belongs to exactly one persona
- Cluster can be assigned to multiple pillars (through pillar_cluster_assignments)
- Can create, read, update clusters via web UI
- Clusters are namespaced (Clustering::Cluster model)

#### Scenario: Create cluster for persona

- **GIVEN** Sarah persona exists
- **WHEN** I create a cluster with name "Morning Coffee Moments"
- **THEN** cluster is created
- **AND** cluster.persona == Sarah
- **AND** cluster.status == "active"

#### Scenario: Cluster belongs to persona

- **GIVEN** Sarah and Emma personas exist
- **WHEN** I query clusters for Sarah
- **THEN** only Sarah's clusters are returned
- **AND** Emma's clusters are not included

---

### Requirement: Pipeline Run Integration

System SHALL link pipeline runs to clusters to organize generated content.

**Acceptance Criteria:**
- PipelineRun has optional cluster_id foreign key
- PipelineRun.belongs_to :cluster (optional: true)
- Cluster.has_many :pipeline_runs
- Can create run with cluster assignment
- Can view cluster's runs

#### Scenario: Create run assigned to cluster

- **GIVEN** cluster "Morning Coffee" exists
- **WHEN** I create a pipeline run with cluster_id = cluster.id
- **THEN** run is created
- **AND** run.cluster == cluster
- **AND** cluster.pipeline_runs includes run

#### Scenario: Run without cluster (backward compatible)

- **GIVEN** I am creating a pipeline run
- **WHEN** I do not assign a cluster
- **THEN** run is created
- **AND** run.cluster_id == nil
- **AND** run works normally

---

### Requirement: Auto-link Winner to Cluster

System SHALL automatically link winning image candidate to cluster when run completes.

**Acceptance Criteria:**
- When run with cluster_id completes, find winner
- Winner ImageCandidate is associated with cluster
- Service: LinkWinnerToCluster
- Callback: after_transition to: :completed on PipelineRun
- Only links if run has cluster_id

#### Scenario: Winner auto-linked on completion

- **GIVEN** run assigned to "Morning Coffee" cluster
- **AND** run has 4 image candidates
- **AND** candidate #2 is marked as winner
- **WHEN** run completes
- **THEN** LinkWinnerToCluster service is called
- **AND** candidate #2 is linked to cluster
- **NOTE**: Linking mechanism TBD (could be through join table or field)

#### Scenario: No linking if no cluster

- **GIVEN** run without cluster_id
- **WHEN** run completes
- **THEN** no auto-linking occurs
- **AND** winner remains unlinked

---

### Requirement: Pillar-Cluster Assignments

System SHALL enable many-to-many relationships between pillars and clusters.

**Acceptance Criteria:**
- PillarClusterAssignment updated with cluster FK
- Cluster.has_many :pillars, through: :pillar_cluster_assignments
- ContentPillar.has_many :clusters, through: :pillar_cluster_assignments
- Can assign cluster to multiple pillars
- Can mark one assignment as "primary"

#### Scenario: Assign cluster to pillar

- **GIVEN** cluster "Morning Coffee" exists
- **AND** pillar "Lifestyle & Daily Living" exists
- **WHEN** I assign cluster to pillar
- **THEN** assignment is created
- **AND** cluster.pillars includes pillar
- **AND** pillar.clusters includes cluster

#### Scenario: Cluster serves multiple pillars

- **GIVEN** cluster "Urban Fashion" exists
- **WHEN** I assign it to "Fashion & Style" pillar
- **AND** I assign it to "Lifestyle & Daily Living" pillar
- **THEN** cluster.pillars.count == 2
- **AND** both pillars list the cluster

---

### Requirement: Basic Cluster UI

System SHALL provide web interface for cluster management.

**Acceptance Criteria:**
- Clusters index page (nested under persona)
- Cluster show page (displays winners/candidates)
- Create cluster form
- Edit cluster form
- Assign to pillar UI
- Nested routes: /personas/:persona_id/clusters

#### Scenario: View persona's clusters

- **GIVEN** Sarah has 3 clusters
- **WHEN** I visit /personas/3/clusters
- **THEN** I see all 3 clusters listed
- **AND** each shows name, pillar assignments, winner count

#### Scenario: Create cluster from pillar page

- **GIVEN** I am viewing "Lifestyle & Daily Living" pillar
- **WHEN** I click "New Cluster"
- **THEN** cluster form opens
- **AND** pillar is pre-selected for assignment
- **WHEN** I submit form
- **THEN** cluster is created and assigned to pillar

---

### Requirement: Cluster Content Display

System SHALL display winning image candidates associated with cluster.

**Acceptance Criteria:**
- Cluster show page displays linked winners
- Shows image thumbnail and metadata
- Shows which run generated the winner
- Basic grid layout

#### Scenario: View cluster winners

- **GIVEN** cluster "Morning Coffee" has 3 linked winners
- **WHEN** I visit cluster show page
- **THEN** I see 3 winner thumbnails
- **AND** each shows the run name that generated it
- **AND** clicking thumbnail shows full image

---

### Requirement: Public API Module

System SHALL provide module-based public API for clustering operations.

**Acceptance Criteria:**
- Clustering module is the only public interface
- Clustering.create_cluster(persona:, name:, pillar: nil)
- Clustering.for_persona(persona)
- Clustering.assign_to_pillar(cluster, pillar, primary: false)
- Public API documented in packs/clustering/README.md

#### Scenario: Create cluster via public API

- **GIVEN** Sarah persona exists
- **WHEN** code calls Clustering.create_cluster(persona: sarah, name: "Test")
- **THEN** cluster is created
- **AND** cluster belongs to Sarah

---

### Requirement: Packwerk Compliance

System SHALL follow Packwerk modular architecture.

**Acceptance Criteria:**
- Pack located at packs/clustering/
- package.yml with enforce_dependencies: true
- Dependencies: personas, content_pillars
- Models namespaced (Clustering::Cluster)
- All inter-pack access through app/public/clustering.rb
- No packwerk violations

#### Scenario: Packwerk validation passes

- **GIVEN** clustering pack is implemented
- **WHEN** running bin/packwerk check
- **THEN** no new violations are introduced

---

### Requirement: End-to-End Workflow

System SHALL support complete workflow from gap analysis to scheduled content.

**Acceptance Criteria:**
- Can identify gap in pillar
- Can create cluster for pillar
- Can create run for cluster
- Winner auto-links to cluster on completion
- Cluster has content ready for scheduling

#### Scenario: Complete content generation workflow

- **GIVEN** "Lifestyle & Daily Living" pillar needs content
- **WHEN** I create cluster "Morning Routine"
- **AND** I assign cluster to pillar
- **AND** I create pipeline run for cluster
- **AND** run completes with winner
- **THEN** winner is auto-linked to cluster
- **AND** cluster.pipeline_runs.count == 1
- **AND** cluster shows winner on show page
- **AND** cluster is ready for post scheduling (future feature)

---

