## ADDED Requirements

### Requirement: ComfyUI API Client
The system SHALL provide a client for communicating with ComfyUI API.

#### Scenario: Submit workflow
- **WHEN** submitting a workflow JSON to ComfyUI
- **THEN** return a job ID from ComfyUI

#### Scenario: Check job status
- **WHEN** querying job status with a job ID
- **THEN** return current status (running, completed, failed)

#### Scenario: Download image
- **WHEN** downloading a generated image
- **THEN** return binary image data

#### Scenario: Handle connection errors
- **WHEN** ComfyUI is unreachable
- **THEN** raise a clear error with retry guidance

#### Scenario: Configuration
- **WHEN** ComfyUI client is initialized
- **THEN** use COMFYUI_BASE_URL from environment

### Requirement: Job Tracking Model
The system SHALL track submitted jobs in the database.

#### Scenario: Create job record
- **WHEN** creating a ComfyuiJob
- **THEN** store pipeline_step, pipeline_run, parent_candidate, job_payload

#### Scenario: Status transitions
- **WHEN** job progresses through lifecycle
- **THEN** status transitions: pending → submitted → running → completed/failed

#### Scenario: Store ComfyUI job ID
- **WHEN** job is submitted to ComfyUI
- **THEN** save the returned job ID for tracking

#### Scenario: Store result metadata
- **WHEN** job completes
- **THEN** save ComfyUI response for later processing

#### Scenario: Track retry count
- **WHEN** job fails and retries
- **THEN** increment retry_count

#### Scenario: Timestamp tracking
- **WHEN** job is submitted and completed
- **THEN** record submitted_at and completed_at timestamps

### Requirement: SubmitJob Command
The system SHALL submit jobs to ComfyUI API.

#### Scenario: Create pending job
- **WHEN** SubmitJob is called
- **THEN** create ComfyuiJob with status pending

#### Scenario: Call ComfyUI API
- **WHEN** submitting workflow
- **THEN** POST to ComfyUI /prompt endpoint

#### Scenario: Update job with ID
- **WHEN** ComfyUI returns job ID
- **THEN** update ComfyuiJob with comfyui_job_id and status submitted

#### Scenario: Handle API errors
- **WHEN** ComfyUI API returns error
- **THEN** mark job as failed with error message

#### Scenario: Command returns job
- **WHEN** SubmitJob succeeds
- **THEN** return the created ComfyuiJob

#### Scenario: Link to parent candidate
- **WHEN** submitting child generation job
- **THEN** store parent_candidate reference

### Requirement: PollJobStatus Command
The system SHALL poll ComfyUI for job status updates.

#### Scenario: Query running job
- **WHEN** polling a submitted job
- **THEN** call ComfyUI API to get current status

#### Scenario: Update to running status
- **WHEN** ComfyUI reports job is running
- **THEN** update ComfyuiJob status to running

#### Scenario: Update to completed status
- **WHEN** ComfyUI reports job is completed
- **THEN** update status to completed and store result_metadata

#### Scenario: Update to failed status
- **WHEN** ComfyUI reports job failed
- **THEN** update status to failed and store error message

#### Scenario: Return processing flag
- **WHEN** job is completed
- **THEN** return needs_processing = true

#### Scenario: Don't process running jobs
- **WHEN** job is still running
- **THEN** return needs_processing = false

### Requirement: ProcessJobResult Command
The system SHALL process completed jobs and save results.

#### Scenario: Download image
- **WHEN** processing completed job
- **THEN** download image data from ComfyUI

#### Scenario: Save image to filesystem
- **WHEN** image data is downloaded
- **THEN** save to target_folder/step-name/filename.png

#### Scenario: Create ImageCandidate
- **WHEN** image is saved
- **THEN** create ImageCandidate with image_path

#### Scenario: Link to pipeline_run
- **WHEN** creating ImageCandidate
- **THEN** associate with job's pipeline_run

#### Scenario: Link to parent
- **WHEN** job has parent_candidate
- **THEN** set parent relationship on ImageCandidate

#### Scenario: Update parent child_count
- **WHEN** ImageCandidate is created with parent
- **THEN** increment parent's child_count

#### Scenario: Handle missing image
- **WHEN** ComfyUI result has no image
- **THEN** mark job as failed

### Requirement: Background Workers
The system SHALL process jobs in background workers.

#### Scenario: JobSubmitterWorker runs periodically
- **WHEN** JobSubmitterWorker executes
- **THEN** call SelectNextJob and submit if work available

#### Scenario: Submit interval
- **WHEN** JobSubmitterWorker completes
- **THEN** schedule next run after COMFYUI_SUBMIT_INTERVAL seconds

#### Scenario: JobPollerWorker runs periodically
- **WHEN** JobPollerWorker executes
- **THEN** poll all in-flight jobs

#### Scenario: Poll interval
- **WHEN** JobPollerWorker completes
- **THEN** schedule next run after COMFYUI_POLL_INTERVAL seconds

#### Scenario: Process completed jobs
- **WHEN** polling finds completed job
- **THEN** call ProcessJobResult automatically

#### Scenario: Worker error handling
- **WHEN** worker encounters error
- **THEN** log error and retry up to 3 times

### Requirement: Configuration
The system SHALL provide configuration for ComfyUI integration.

#### Scenario: Base URL configuration
- **WHEN** accessing ComfyUI base URL
- **THEN** use COMFYUI_BASE_URL environment variable

#### Scenario: Default base URL
- **WHEN** COMFYUI_BASE_URL not set
- **THEN** default to http://localhost:8188

#### Scenario: Poll interval configuration
- **WHEN** accessing poll interval
- **THEN** use COMFYUI_POLL_INTERVAL (default 5 seconds)

#### Scenario: Submit interval configuration
- **WHEN** accessing submit interval
- **THEN** use COMFYUI_SUBMIT_INTERVAL (default 10 seconds)

#### Scenario: Timeout configuration
- **WHEN** accessing API timeout
- **THEN** use COMFYUI_TIMEOUT (default 300 seconds)

#### Scenario: Max retries configuration
- **WHEN** accessing max retries
- **THEN** use COMFYUI_MAX_RETRIES (default 3)

### Requirement: Error Handling
The system SHALL handle errors gracefully throughout job lifecycle.

#### Scenario: API connection failure
- **WHEN** cannot connect to ComfyUI
- **THEN** retry up to max_retries times

#### Scenario: Job submission failure
- **WHEN** ComfyUI rejects workflow
- **THEN** mark job as failed with error message

#### Scenario: Polling timeout
- **WHEN** job runs longer than timeout
- **THEN** mark job as failed with timeout error

#### Scenario: Image download failure
- **WHEN** cannot download generated image
- **THEN** mark job as failed, allow manual retry

#### Scenario: Worker crash recovery
- **WHEN** worker crashes during processing
- **THEN** jobs remain in submitted/running state for retry

### Requirement: File Storage
The system SHALL store generated images on filesystem.

#### Scenario: Construct file path
- **WHEN** saving image
- **THEN** use pattern: target_folder/step-name/hash_timestamp.png

#### Scenario: Create directories
- **WHEN** target directory doesn't exist
- **THEN** create all parent directories automatically

#### Scenario: Unique filenames
- **WHEN** generating filename
- **THEN** use random hash + timestamp to avoid collisions

#### Scenario: Store path in database
- **WHEN** ImageCandidate is created
- **THEN** save full file path in image_path column

### Requirement: Job Lifecycle Tracking
The system SHALL track jobs through complete lifecycle.

#### Scenario: Pending to submitted
- **WHEN** job is created and sent to API
- **THEN** transition pending → submitted

#### Scenario: Submitted to running
- **WHEN** ComfyUI starts processing
- **THEN** transition submitted → running

#### Scenario: Running to completed
- **WHEN** ComfyUI finishes successfully
- **THEN** transition running → completed

#### Scenario: Any to failed
- **WHEN** error occurs at any stage
- **THEN** transition to failed status

#### Scenario: Record timestamps
- **WHEN** status changes
- **THEN** update submitted_at and completed_at

#### Scenario: Query in-flight jobs
- **WHEN** finding jobs to poll
- **THEN** return all with status submitted or running

### Requirement: Integration with Job Orchestration
The system SHALL integrate with existing job orchestration.

#### Scenario: Use SelectNextJob
- **WHEN** JobSubmitterWorker runs
- **THEN** call SelectNextJob from job_orchestration pack

#### Scenario: Use BuildJobPayload
- **WHEN** submitting job
- **THEN** call BuildJobPayload to construct workflow

#### Scenario: Respect job modes
- **WHEN** SelectNextJob returns :no_work
- **THEN** don't submit any jobs

#### Scenario: Handle child generation
- **WHEN** mode is :child_generation
- **THEN** submit job with parent_candidate

#### Scenario: Handle base generation
- **WHEN** mode is :base_generation
- **THEN** submit job without parent_candidate

### Requirement: Retry Logic
The system SHALL implement retry logic for transient failures.

#### Scenario: API retry with backoff
- **WHEN** API call fails
- **THEN** retry with exponential backoff

#### Scenario: Max retries
- **WHEN** retried max_retries times
- **THEN** mark as permanently failed

#### Scenario: Track retry count
- **WHEN** retrying job
- **THEN** increment retry_count in database

#### Scenario: Don't retry successful jobs
- **WHEN** job completes successfully
- **THEN** don't retry

### Requirement: ComfyUI Pack
The system SHALL organize ComfyUI integration in dedicated pack.

#### Scenario: Pack exists
- **WHEN** running packwerk
- **THEN** comfyui pack is recognized

#### Scenario: Pack dependencies
- **WHEN** checking dependencies
- **THEN** depends on job_orchestration and pipeline packs

#### Scenario: Pack validation
- **WHEN** running packwerk validate
- **THEN** no errors for comfyui pack

### Requirement: HTTP Client
The system SHALL use robust HTTP client for API calls.

#### Scenario: Use Faraday
- **WHEN** making HTTP requests
- **THEN** use Faraday gem

#### Scenario: Set timeout
- **WHEN** making request
- **THEN** apply configured timeout

#### Scenario: Parse JSON responses
- **WHEN** receiving response
- **THEN** automatically parse JSON

#### Scenario: Handle HTTP errors
- **WHEN** receiving 4xx or 5xx
- **THEN** raise clear error with status code

### Requirement: Monitoring and Logging
The system SHALL provide visibility into job processing.

#### Scenario: Log job submissions
- **WHEN** submitting job
- **THEN** log job ID and payload summary

#### Scenario: Log status checks
- **WHEN** polling job status
- **THEN** log status and timing

#### Scenario: Log completions
- **WHEN** job completes
- **THEN** log success and image path

#### Scenario: Log failures
- **WHEN** job fails
- **THEN** log error details with context

#### Scenario: Track metrics
- **WHEN** processing jobs
- **THEN** track success rate, duration, queue depth
