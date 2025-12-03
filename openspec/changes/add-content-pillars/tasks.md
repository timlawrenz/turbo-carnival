# Content Pillars Implementation Tasks

## 1. Database Schema (Day 1, Morning)
- [ ] 1.1 Create content_pillars migration
- [ ] 1.2 Create pillar_cluster_assignments migration (stub for Week 2)
- [ ] 1.3 Run migrations
- [ ] 1.4 Verify schema in db/schema.rb

## 2. Pack Structure (Day 1, Morning)
- [ ] 2.1 Create packs/content_pillars/ directory structure
- [ ] 2.2 Create package.yml with dependencies (personas only for now)
- [ ] 2.3 Create app/{models,services,public} directories

## 3. Models (Day 1, Afternoon)
- [ ] 3.1 Create ContentPillar model
- [ ] 3.2 Add validations (name, weight, priority, dates)
- [ ] 3.3 Add scopes (active, current, by_priority)
- [ ] 3.4 Add instance methods (current?, expired?)
- [ ] 3.5 Create PillarClusterAssignment model (stub for Week 2)
- [ ] 3.6 Update Persona model (has_many :content_pillars)

## 4. Services (Day 1, Afternoon)
- [ ] 4.1 Create GapAnalysisService (basic version)
- [ ] 4.2 Implement calculate_gaps_for_persona method
- [ ] 4.3 Return structure: { pillar => { target, available, gap, status } }
- [ ] 4.4 Test with sample data

## 5. Controller & Routes (Day 2, Morning)
- [ ] 5.1 Create ContentPillarsController (nested under personas)
- [ ] 5.2 Implement index action
- [ ] 5.3 Implement show action
- [ ] 5.4 Implement new/create actions
- [ ] 5.5 Implement edit/update actions
- [ ] 5.6 Implement destroy action
- [ ] 5.7 Add nested routes under personas

## 6. Views (Day 2, Afternoon)
- [ ] 6.1 Update persona show page with pillars section
- [ ] 6.2 Create pillars/_list.html.erb partial
- [ ] 6.3 Create pillars/_pillar_card.html.erb component
- [ ] 6.4 Create pillars/new.html.erb form
- [ ] 6.5 Create pillars/edit.html.erb form
- [ ] 6.6 Create pillars/_form.html.erb partial
- [ ] 6.7 Add gap analysis visualization (basic)
- [ ] 6.8 Style with Tailwind CSS

## 7. Public API (Day 2, Afternoon)
- [ ] 7.1 Create ContentPillars module in app/public/
- [ ] 7.2 Implement ContentPillars.for_persona(persona)
- [ ] 7.3 Implement ContentPillars.create(attrs)
- [ ] 7.4 Implement ContentPillars.gap_analysis(persona)
- [ ] 7.5 Document in README.md

## 8. Testing (Day 2, Evening)
- [ ] 8.1 Create content_pillar factory
- [ ] 8.2 Write model specs (validations, scopes, methods)
- [ ] 8.3 Write service specs (gap analysis)
- [ ] 8.4 Write controller specs (CRUD operations)
- [ ] 8.5 Write request specs (full workflow)
- [ ] 8.6 Test weight validation (total ≤ 100%)

## 9. Integration (Day 2, Evening)
- [ ] 9.1 Import Sarah's pillars from fluffy-train (rake task)
- [ ] 9.2 Test gap analysis with Sarah's data
- [ ] 9.3 Verify UI shows pillars correctly
- [ ] 9.4 Test create/edit/delete workflows

## 10. Packwerk Validation (Day 2, Evening)
- [ ] 10.1 Run bin/packwerk check
- [ ] 10.2 Run bin/packwerk validate
- [ ] 10.3 Ensure no new violations
- [ ] 10.4 Verify dependency declarations

## 11. Documentation (Day 2, Evening)
- [ ] 11.1 Create packs/content_pillars/README.md
- [ ] 11.2 Document public API
- [ ] 11.3 Add usage examples
- [ ] 11.4 Update main README

## 12. OpenSpec (Day 2, Evening)
- [ ] 12.1 Validate with openspec validate add-content-pillars --strict
- [ ] 12.2 Fix any validation errors
- [ ] 12.3 Mark all tasks complete
- [ ] 12.4 Commit with spec reference

## Notes
- Clustering integration deferred to Week 2
- Gap analysis basic until clusters exist
- PillarClusterAssignment table created but unused until Week 2
