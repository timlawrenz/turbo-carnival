## MODIFIED Requirements

### Requirement: Default Run Settings
The system SHALL apply sensible defaults when creating runs.

#### Scenario: Run created with default status
- **WHEN** a run is created without specifying status
- **THEN** the status is set to "pending"

#### Scenario: Run created with default variables
- **WHEN** a run is created without specifying variables
- **THEN** the variables column is set to an empty JSON object {}

#### Scenario: Run created with generated target folder
- **WHEN** a run is created without specifying a target folder
- **THEN** a target folder is auto-generated based on run name and timestamp

#### Scenario: Run associated with content pillar
- **WHEN** a run is created for a specific content pillar
- **THEN** the content_pillar_id is set on the run
- **AND** the run can be queried by pillar association

## ADDED Requirements

### Requirement: Pillar Association
The system SHALL support associating pipeline runs with content pillars.

#### Scenario: Create run for pillar
- **WHEN** a user creates a run and selects a content pillar
- **THEN** the run's content_pillar_id is set
- **AND** the pillar is accessible via run.content_pillar

#### Scenario: Filter runs by pillar
- **WHEN** querying runs for a specific pillar
- **THEN** all runs associated with that pillar are returned

#### Scenario: Winner creates photo in pillar
- **WHEN** a run with content_pillar_id completes successfully
- **THEN** the winner image creates a photo in the associated pillar
- **AND** the photo.content_pillar_id matches run.content_pillar_id

## REMOVED Requirements

### Requirement: Cluster Association
**Reason:** Clustering layer being removed in favor of direct pillar association  
**Migration:** All runs with cluster_id will be migrated to content_pillar_id based on cluster's primary pillar assignment
