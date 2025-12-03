# Clustering Implementation Tasks (Option B - Essential Integration)

## 1. Database Schema (2 hours)
- [ ] 1.1 Create clusters migration (name, persona_id, status, ai_prompt, photos_count)
- [ ] 1.2 Add cluster_id to pipeline_runs migration
- [ ] 1.3 Add FK constraint pipeline_runs.cluster_id → clusters.id
- [ ] 1.4 Run migrations
- [ ] 1.5 Verify schema

## 2. Pack Structure (30 min)
- [ ] 2.1 Create packs/clustering/ directory structure
- [ ] 2.2 Create package.yml with dependencies (personas, content_pillars)
- [ ] 2.3 Create app/{models,services,public} directories

## 3. Models (2 hours)
- [ ] 3.1 Create Cluster model (clustering/cluster.rb namespaced)
- [ ] 3.2 Add validations (name presence, persona presence)
- [ ] 3.3 Add scopes (active, by_persona)
- [ ] 3.4 Add status enum (active, archived, draft)
- [ ] 3.5 Update PipelineRun (belongs_to :cluster, optional: true)
- [ ] 3.6 Update Persona (has_many :clusters)
- [ ] 3.7 Update ContentPillar (has_many :clusters, through: :pillar_cluster_assignments)
- [ ] 3.8 Update PillarClusterAssignment (belongs_to :cluster)

## 4. Auto-linking (1.5 hours)
- [ ] 4.1 Create LinkWinnerToCluster service
- [ ] 4.2 Add after_complete callback to PipelineRun
- [ ] 4.3 Find winner ImageCandidate
- [ ] 4.4 Link winner to run.cluster
- [ ] 4.5 Test auto-linking with sample data

## 5. Controller & Routes (1.5 hours)
- [ ] 5.1 Create ClustersController (nested under personas)
- [ ] 5.2 Implement index action
- [ ] 5.3 Implement show action (with image candidates)
- [ ] 5.4 Implement new/create actions
- [ ] 5.5 Implement edit/update actions
- [ ] 5.6 Add routes: /personas/:persona_id/clusters

## 6. Views (2 hours)
- [ ] 6.1 Create clusters/index.html.erb (list for persona)
- [ ] 6.2 Create clusters/show.html.erb (cluster detail + winners)
- [ ] 6.3 Create clusters/new.html.erb (create form)
- [ ] 6.4 Create clusters/_form.html.erb partial
- [ ] 6.5 Add clusters section to persona show page
- [ ] 6.6 Show cluster on run show page (if assigned)
- [ ] 6.7 Style with Tailwind CSS

## 7. Public API (1 hour)
- [ ] 7.1 Create Clustering module in app/public/
- [ ] 7.2 Implement Clustering.create_cluster(persona:, name:)
- [ ] 7.3 Implement Clustering.for_persona(persona)
- [ ] 7.4 Implement Clustering.assign_to_pillar(cluster, pillar)
- [ ] 7.5 Document in README

## 8. Integration with Pillars (1 hour)
- [ ] 8.1 Add "Create Cluster" button to pillar show page
- [ ] 8.2 Pre-fill cluster with pillar assignment
- [ ] 8.3 Show clusters on pillar show page
- [ ] 8.4 Enable assign/unassign clusters to pillars

## 9. Pipeline Integration (1 hour)
- [ ] 9.1 Add cluster_id field to run creation form
- [ ] 9.2 Add cluster selector dropdown (persona's clusters)
- [ ] 9.3 Display cluster on run show page
- [ ] 9.4 Test: create run with cluster → complete → verify winner linked

## 10. Testing (2 hours)
- [ ] 10.1 Create cluster factory
- [ ] 10.2 Write model specs (validations, associations)
- [ ] 10.3 Write service specs (auto-linking)
- [ ] 10.4 Write controller specs (CRUD)
- [ ] 10.5 Write integration spec (full workflow)
- [ ] 10.6 Test with Sarah's real data

## 11. Packwerk Validation (30 min)
- [ ] 11.1 Run bin/packwerk check
- [ ] 11.2 Run bin/packwerk validate
- [ ] 11.3 Fix any violations
- [ ] 11.4 Ensure dependencies are declared

## 12. End-to-End Workflow Test (1 hour)
- [ ] 12.1 Create cluster for "Lifestyle & Daily Living"
- [ ] 12.2 Create run assigned to cluster
- [ ] 12.3 Complete run and vote for winner
- [ ] 12.4 Verify winner auto-linked to cluster
- [ ] 12.5 Verify cluster shows winner in UI
- [ ] 12.6 Document workflow in README

## 13. Documentation (30 min)
- [ ] 13.1 Create packs/clustering/README.md
- [ ] 13.2 Document the workflow
- [ ] 13.3 Add usage examples
- [ ] 13.4 Update main README

## 14. Import Sample Data (30 min)
- [ ] 14.1 Create clusters for Sarah's pillars
- [ ] 14.2 Assign clusters to appropriate pillars
- [ ] 14.3 Link some existing winners to clusters (manual)

## 15. OpenSpec (30 min)
- [ ] 15.1 Validate with openspec validate add-clustering --strict
- [ ] 15.2 Fix validation errors
- [ ] 15.3 Mark tasks complete
- [ ] 15.4 Commit with spec reference

## Notes
- Photos/Active Storage deferred to Week 3
- Focus on ImageCandidates as content for now
- Keep it simple - complete workflow > feature completeness
- Total: ~18 hours (2-3 days)

## 16. Photo Model (4 hours) - NEW SECTION
- [ ] 16.1 Create photos migration (cluster_id, persona_id, path)
- [ ] 16.2 Add has_one_attached :image to Photo
- [ ] 16.3 Create Photo model with validations
- [ ] 16.4 Add belongs_to :cluster, :persona
- [ ] 16.5 Add scopes (unposted, in_cluster)
- [ ] 16.6 Add posted? method
- [ ] 16.7 Update Cluster (has_many :photos)
- [ ] 16.8 Update Persona (has_many :photos)

## 17. Photo Creation Service (2 hours) - NEW SECTION
- [ ] 17.1 Create CreatePhotoFromCandidate service
- [ ] 17.2 Validate winner and image_path exist
- [ ] 17.3 Create Photo record
- [ ] 17.4 Attach image from winner.image_path
- [ ] 17.5 Handle file not found errors
- [ ] 17.6 Handle upload errors
- [ ] 17.7 Log successful creation
- [ ] 17.8 Test with sample data

## 18. Update Auto-linking (1 hour) - MODIFIED
- [ ] 18.1 Update LinkWinnerToCluster service
- [ ] 18.2 Call CreatePhotoFromCandidate
- [ ] 18.3 Increment cluster.photos_count
- [ ] 18.4 Log Photo creation
- [ ] 18.5 Handle errors gracefully

