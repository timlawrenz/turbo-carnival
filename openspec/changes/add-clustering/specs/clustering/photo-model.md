## ADDED Requirements

### Requirement: Photo Model for Instagram-Ready Content

System SHALL create Photo model for storing Instagram-ready images uploaded to cloud storage.

**Acceptance Criteria:**
- Photo has_one_attached :image (ActiveStorage)
- Photo belongs_to :cluster
- Photo belongs_to :persona
- Photo validates :path, presence and uniqueness
- Photos are created from winning ImageCandidates
- Photo.image.url returns public HTTPS URL

#### Scenario: Create Photo from winning candidate

- **GIVEN** a pipeline run with cluster assigned
- **AND** run has completed with a winner ImageCandidate
- **WHEN** auto-linking service runs
- **THEN** a Photo is created
- **AND** Photo.image is attached from winner.image_path
- **AND** Photo belongs to the run's cluster
- **AND** Photo belongs to the persona
- **AND** Photo.path equals winner.image_path

#### Scenario: Photo is publicly accessible

- **GIVEN** a Photo with attached image
- **WHEN** I call Photo.image.url
- **THEN** I receive a public HTTPS URL
- **AND** the URL is accessible from the internet
- **AND** Instagram API can access the URL

---

### Requirement: Separation of Candidates and Photos

System SHALL maintain clear separation between generation candidates (local) and postable photos (cloud).

**Acceptance Criteria:**
- ImageCandidates remain local-only (image_path)
- Photos are created only from winners
- ImageCandidates can be deleted after Photo creation
- Photos persist for scheduling and posting
- Counter: cluster.photos_count tracks Photos (not candidates)

#### Scenario: ImageCandidate vs Photo lifecycle

- **GIVEN** a pipeline run generates 4 ImageCandidates
- **AND** user selects candidate #2 as winner
- **WHEN** run completes
- **THEN** 1 Photo is created from candidate #2
- **AND** 4 ImageCandidates remain in database (for history)
- **AND** Photo.image is uploaded to cloud storage
- **AND** cluster.photos_count increments by 1

#### Scenario: Query cluster's postable content

- **GIVEN** cluster has 3 completed runs with winners
- **WHEN** I query cluster.photos
- **THEN** I receive 3 Photo records
- **AND** each Photo has attached image
- **AND** each Photo.image.url is accessible
- **AND** ImageCandidates are not included

---

### Requirement: Photo Scopes and Queries

System SHALL provide scopes for finding unposted photos and photos in clusters.

**Acceptance Criteria:**
- Scope: Photo.unposted returns photos not yet posted to Instagram
- Scope: Photo.in_cluster(cluster_id) returns photos for cluster
- Method: photo.posted? returns true if photo is scheduled/posted
- Photos are ordered by creation date by default

#### Scenario: Find unposted photos for scheduling

- **GIVEN** cluster has 5 photos
- **AND** 2 photos are already posted to Instagram
- **WHEN** I query Photo.unposted.in_cluster(cluster.id)
- **THEN** I receive 3 photos
- **AND** none are already posted

---

### Requirement: Photo Creation Service

System SHALL provide service for creating Photos from ImageCandidates.

**Acceptance Criteria:**
- Service: CreatePhotoFromCandidate
- Validates winner exists and has image_path
- Creates Photo with persona and cluster
- Attaches image using ActiveStorage
- Handles upload errors gracefully
- Returns created Photo or nil

#### Scenario: Service creates Photo successfully

- **GIVEN** a winning ImageCandidate with valid image_path
- **WHEN** CreatePhotoFromCandidate.call(candidate, cluster)
- **THEN** Photo is created
- **AND** Photo.cluster equals provided cluster
- **AND** Photo.persona equals cluster.persona
- **AND** Photo.image is attached
- **AND** service returns the Photo

#### Scenario: Service handles missing file

- **GIVEN** a winning ImageCandidate
- **AND** the image_path file does not exist
- **WHEN** CreatePhotoFromCandidate.call(candidate, cluster)
- **THEN** no Photo is created
- **AND** error is logged
- **AND** service returns nil

---

