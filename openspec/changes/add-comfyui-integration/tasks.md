## 1. Setup
- [x] 1.1 Create Packwerk pack structure at `packs/comfyui/`
- [x] 1.2 Create pack configuration file `packs/comfyui/package.yml`
- [x] 1.3 Add dependencies on job_orchestration and pipeline packs
- [x] 1.4 Run `bin/packwerk validate` to ensure pack setup is correct

## 2. ComfyUI API Client
- [x] 2.1 Create `ComfyuiClient` class for HTTP communication
- [x] 2.2 Implement `submit_workflow` method
- [x] 2.3 Implement `get_job_status` method
- [x] 2.4 Implement `download_image` method
- [x] 2.5 Add configuration for ComfyUI base URL
- [ ] 2.6 Write unit tests with HTTP mocking

## 3. Job Tracking
- [x] 3.1 Create migration for `comfyui_jobs` table
- [x] 3.2 Create `ComfyuiJob` model
- [x] 3.3 Add status tracking: pending, submitted, running, completed, failed
- [x] 3.4 Store ComfyUI job ID and metadata
- [x] 3.5 Associate with ImageCandidate and PipelineRun
- [x] 3.6 Write model tests

## 4. SubmitJob Command
- [ ] 4.1 Create `SubmitJob` GLCommand
- [ ] 4.2 Accept job_payload from BuildJobPayload
- [ ] 4.3 Call ComfyUI API to submit workflow
- [ ] 4.4 Create ComfyuiJob record
- [ ] 4.5 Handle API errors and retries
- [ ] 4.6 Write comprehensive tests

## 5. PollJobStatus Command
- [ ] 5.1 Create `PollJobStatus` GLCommand
- [ ] 5.2 Query ComfyUI API for job status
- [ ] 5.3 Update ComfyuiJob record
- [ ] 5.4 Detect completion and failure
- [ ] 5.5 Handle API timeouts
- [ ] 5.6 Write tests for all status transitions

## 6. ProcessJobResult Command
- [ ] 6.1 Create `ProcessJobResult` GLCommand
- [ ] 6.2 Download generated image from ComfyUI
- [ ] 6.3 Store image file in target_folder
- [ ] 6.4 Create ImageCandidate record
- [ ] 6.5 Link to parent candidate and pipeline_run
- [ ] 6.6 Update parent child_count
- [ ] 6.7 Write tests for result processing

## 7. Background Workers
- [ ] 7.1 Create `JobSubmitterWorker` for continuous job submission
- [ ] 7.2 Create `JobPollerWorker` for status polling
- [ ] 7.3 Configure polling interval
- [ ] 7.4 Handle worker errors and restarts
- [ ] 7.5 Write worker tests

## 8. End-to-End Integration
- [ ] 8.1 Create orchestration service combining all commands
- [ ] 8.2 Implement full job lifecycle: select → submit → poll → process
- [ ] 8.3 Handle the complete loop
- [ ] 8.4 Add logging and monitoring
- [ ] 8.5 Write integration tests

## 9. Configuration
- [x] 9.1 Add COMFYUI_BASE_URL environment variable
- [x] 9.2 Add COMFYUI_POLL_INTERVAL configuration
- [x] 9.3 Add COMFYUI_TIMEOUT configuration
- [x] 9.4 Add COMFYUI_MAX_RETRIES configuration
- [ ] 9.5 Document all configuration options

## 10. Validation
- [x] 10.1 Run `bin/packwerk check` to verify pack boundaries
- [x] 10.2 Run `bin/packwerk validate` to verify pack configuration
- [x] 10.3 Run `bin/rspec` to ensure all tests pass (93 specs passing)
- [x] 10.4 Run `bin/rubocop` to ensure code style compliance
- [ ] 10.5 Test with actual ComfyUI instance (optional for MVP)
