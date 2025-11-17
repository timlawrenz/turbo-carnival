# Implementation Tasks

## 1. Database Changes
- [ ] 1.1 Create migration to add `prompt` column to `pipeline_runs`
- [ ] 1.2 Create Rake task to backfill `prompt` from `variables['prompt']`
- [ ] 1.3 Run backfill task
- [ ] 1.4 Create migration to remove `prompt` and `run_name` keys from variables JSONB

## 2. Model Updates
- [ ] 2.1 Update PipelineRun model (no changes needed, column automatically accessible)
- [ ] 2.2 Update PipelineRun validations if needed

## 3. Command Updates
- [ ] 3.1 Update CreatePipelineRun to set `prompt` column instead of `variables['prompt']`
- [ ] 3.2 Update BuildJobPayload to merge `prompt` from column into variables hash for ComfyUI
- [ ] 3.3 Update any other commands accessing `variables['prompt']`

## 4. View Updates
- [ ] 4.1 Replace `run.variables['run_name']` with `run.name` in all views
- [ ] 4.2 Replace `run.variables['prompt']` with `run.prompt` in all views
- [ ] 4.3 Update new.html.erb form to use `prompt` field instead of variables JSON

## 5. Testing
- [ ] 5.1 Update PipelineRun model specs
- [ ] 5.2 Update CreatePipelineRun command specs
- [ ] 5.3 Update BuildJobPayload command specs
- [ ] 5.4 Update request specs for run creation
- [ ] 5.5 Add integration test for prompt in job payload

## 6. Cleanup
- [ ] 6.1 Remove any fallback logic for `variables['run_name']`
- [ ] 6.2 Remove any fallback logic for `variables['prompt']`
- [ ] 6.3 Update documentation referencing variables hash
