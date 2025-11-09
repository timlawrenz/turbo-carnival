## 1. Database Schema
- [x] 1.1 Create migration for `pipeline_runs` table
- [x] 1.2 Create migration to add variable flags to `pipeline_steps` table
- [x] 1.3 Create migration to add `pipeline_run_id` to `image_candidates` table
- [x] 1.4 Run migrations in development

## 2. Models
- [x] 2.1 Create `PipelineRun` model in `packs/pipeline/app/models/pipeline_run.rb`
- [x] 2.2 Update `PipelineStep` model with variable requirement columns
- [x] 2.3 Update `ImageCandidate` model to belong to `PipelineRun`
- [x] 2.4 Add associations between models
- [x] 2.5 Add validations

## 3. Testing
- [x] 3.1 Create FactoryBot factory for `PipelineRun`
- [x] 3.2 Write unit tests for `PipelineRun` model
- [x] 3.3 Update tests for `PipelineStep` model
- [x] 3.4 Update tests for `ImageCandidate` model
- [x] 3.5 Test variable templating scenarios

## 4. Validation
- [x] 4.1 Run `bin/packwerk check` to verify pack boundaries
- [x] 4.2 Run `bin/packwerk validate` to verify pack configuration
- [x] 4.3 Run `bin/rspec` to ensure all tests pass
- [x] 4.4 Run `bin/rubocop` to ensure code style compliance
