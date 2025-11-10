## Context
This change implements the integration with ComfyUI's API to execute AI image generation jobs. ComfyUI provides a REST API for submitting workflows, checking job status, and retrieving generated images. We need to build a robust integration that handles the full job lifecycle, retries, and error scenarios.

## Goals
- Complete the autonomous workflow loop (select → submit → execute → process → repeat)
- Robust error handling and retry logic
- Track job status through the entire lifecycle
- Store generated images and link to data model
- Background processing for continuous operation
- Clear separation between API client and business logic

## Non-Goals
- Real-time streaming of generation progress (future enhancement)
- Advanced queue management (use simple polling for MVP)
- Custom ComfyUI workflow creation UI (workflows defined in code/config)
- Multi-GPU or distributed ComfyUI instances (single instance for MVP)

## Decisions

### Use Separate Pack for External Integration
**Decision**: Create dedicated `comfyui` pack for all ComfyUI-related code.

**Rationale**:
- Clear boundary between internal logic and external API
- Easy to swap ComfyUI for different backend
- Testable with mocked HTTP
- Follows packwerk architecture

### Track Jobs in Database
**Decision**: Create `ComfyuiJob` model to track submitted jobs.

**Rationale**:
- Persist job state across worker restarts
- Audit trail of all job submissions
- Can retry failed jobs
- Query pending/running jobs

**Schema**:
```ruby
create_table :comfyui_jobs do |t|
  t.references :image_candidate, foreign_key: true, index: true
  t.references :pipeline_run, foreign_key: true, index: true
  t.references :pipeline_step, foreign_key: true
  
  t.string :comfyui_job_id # ID from ComfyUI
  t.string :status # pending, submitted, running, completed, failed
  t.jsonb :job_payload # The workflow JSON sent
  t.jsonb :result_metadata # Response from ComfyUI
  t.text :error_message
  t.integer :retry_count, default: 0
  
  t.datetime :submitted_at
  t.datetime :completed_at
  
  t.timestamps
end
```

### Use Background Workers for Polling
**Decision**: Sidekiq workers for continuous job submission and status polling.

**Rationale**:
- Non-blocking operation
- Rails already has Sidekiq configured
- Built-in retry logic
- Easy to scale with more workers

**Alternatives considered**:
- Polling in main thread - Rejected: blocks application
- Webhooks from ComfyUI - Rejected: ComfyUI doesn't support this
- ActiveJob with database backend - Considered but Sidekiq more robust

### Polling Interval
**Decision**: Poll every 5 seconds for running jobs.

**Rationale**:
- Balance between responsiveness and API load
- ComfyUI jobs typically take 10-30 seconds
- Can be configured via ENV variable

### GLCommand Pattern for Business Logic
**Decision**: Implement SubmitJob, PollJobStatus, ProcessJobResult as GLCommands.

**Rationale**:
- Consistent with project conventions
- Testable in isolation
- Can be composed in chains
- Clear inputs/outputs

### File Storage Strategy
**Decision**: Store images in `target_folder` path from PipelineRun.

**Rationale**:
- Already defined in PipelineRun
- Organized by run
- Easy to find images for a specific execution
- Can use filesystem or S3 (future)

**File naming**:
```ruby
"#{run.target_folder}/#{step.name.parameterize}/#{candidate_id}_#{timestamp}.png"
# Example: /storage/runs/gym-shoot/face-fix/123_20251110002345.png
```

## API Design

### ComfyUI API Client

```ruby
class ComfyuiClient
  def initialize(base_url: ENV['COMFYUI_BASE_URL'])
    @base_url = base_url
  end
  
  # Submit a workflow for execution
  # Returns: { job_id: "abc123" }
  def submit_workflow(workflow_json)
    post('/prompt', { prompt: workflow_json })
  end
  
  # Check status of a job
  # Returns: { status: "running"|"completed"|"failed", output: {...} }
  def get_job_status(job_id)
    get("/history/#{job_id}")
  end
  
  # Download generated image
  # Returns: binary image data
  def download_image(image_url)
    get(image_url)
  end
end
```

### SubmitJob Command

```ruby
class SubmitJob < GLCommand::Callable
  requires :job_payload, :pipeline_step, :pipeline_run
  allows :parent_candidate
  
  returns :comfyui_job
  
  def call
    # Create pending job record
    job = ComfyuiJob.create!(
      pipeline_step: context.pipeline_step,
      pipeline_run: context.pipeline_run,
      parent_candidate: context.parent_candidate,
      job_payload: context.job_payload,
      status: 'pending'
    )
    
    # Submit to ComfyUI
    response = ComfyuiClient.new.submit_workflow(
      context.job_payload[:workflow]
    )
    
    # Update job with ComfyUI ID
    job.update!(
      comfyui_job_id: response[:job_id],
      status: 'submitted',
      submitted_at: Time.current
    )
    
    context.comfyui_job = job
  rescue => e
    job&.update(status: 'failed', error_message: e.message)
    raise
  end
end
```

### PollJobStatus Command

```ruby
class PollJobStatus < GLCommand::Callable
  requires :comfyui_job
  
  returns :status, :needs_processing
  
  def call
    job = context.comfyui_job
    
    response = ComfyuiClient.new.get_job_status(job.comfyui_job_id)
    
    case response[:status]
    when 'running'
      job.update!(status: 'running')
      context.status = 'running'
      context.needs_processing = false
      
    when 'completed'
      job.update!(
        status: 'completed',
        completed_at: Time.current,
        result_metadata: response[:output]
      )
      context.status = 'completed'
      context.needs_processing = true
      
    when 'failed'
      job.update!(
        status: 'failed',
        error_message: response[:error]
      )
      context.status = 'failed'
      context.needs_processing = false
    end
  end
end
```

### ProcessJobResult Command

```ruby
class ProcessJobResult < GLCommand::Callable
  requires :comfyui_job
  
  returns :image_candidate
  
  def call
    job = context.comfyui_job
    
    # Download image from ComfyUI
    image_url = job.result_metadata['images'].first['url']
    image_data = ComfyuiClient.new.download_image(image_url)
    
    # Construct file path
    step_folder = job.pipeline_step.name.parameterize
    filename = "#{SecureRandom.hex(8)}_#{Time.current.to_i}.png"
    full_path = File.join(
      job.pipeline_run.target_folder,
      step_folder,
      filename
    )
    
    # Save image
    FileUtils.mkdir_p(File.dirname(full_path))
    File.binwrite(full_path, image_data)
    
    # Create ImageCandidate
    candidate = ImageCandidate.create!(
      pipeline_step: job.pipeline_step,
      pipeline_run: job.pipeline_run,
      parent: job.parent_candidate,
      image_path: full_path,
      status: 'active'
    )
    
    # Update parent's child_count if this is a child
    if job.parent_candidate
      job.parent_candidate.increment!(:child_count)
    end
    
    context.image_candidate = candidate
  end
end
```

## Data Flow

```
JobSubmitterWorker (runs every 10 seconds)
  ↓
SelectNextJob (from job_orchestration pack)
  ↓
BuildJobPayload (from job_orchestration pack)
  ↓
SubmitJob (creates ComfyuiJob, calls API)
  ↓
ComfyuiJob (status: submitted)


JobPollerWorker (runs every 5 seconds)
  ↓
Find all ComfyuiJobs with status: submitted or running
  ↓
For each job:
  PollJobStatus (checks API)
    ↓
    If completed:
      ProcessJobResult (downloads image, creates ImageCandidate)
    If failed:
      Log error, potentially retry
    If running:
      Continue polling
```

## Workers

### JobSubmitterWorker
```ruby
class JobSubmitterWorker
  include Sidekiq::Worker
  
  sidekiq_options queue: :job_submission, retry: 3
  
  def perform
    # Check if we should submit a new job
    # (could limit concurrent jobs here)
    
    result = SelectNextJob.call
    
    case result.mode
    when :child_generation, :base_generation
      payload_result = BuildJobPayload.call(
        pipeline_step: result.next_step,
        pipeline_run: result.parent_candidate&.pipeline_run || PipelineRun.active.first,
        parent_candidate: result.parent_candidate
      )
      
      SubmitJob.call(
        job_payload: payload_result.job_payload,
        pipeline_step: result.next_step,
        pipeline_run: result.parent_candidate&.pipeline_run || PipelineRun.active.first,
        parent_candidate: result.parent_candidate
      )
      
    when :no_work
      # Nothing to do
    end
    
    # Schedule next check
    JobSubmitterWorker.perform_in(10.seconds)
  end
end
```

### JobPollerWorker
```ruby
class JobPollerWorker
  include Sidekiq::Worker
  
  sidekiq_options queue: :job_polling, retry: 3
  
  def perform
    # Find all in-flight jobs
    jobs = ComfyuiJob.where(status: ['submitted', 'running'])
    
    jobs.each do |job|
      result = PollJobStatus.call(comfyui_job: job)
      
      if result.needs_processing
        ProcessJobResult.call(comfyui_job: job)
      end
    end
    
    # Schedule next poll
    JobPollerWorker.perform_in(5.seconds)
  end
end
```

## Configuration

```ruby
# config/initializers/comfyui.rb
Rails.application.config.comfyui = ActiveSupport::OrderedOptions.new
Rails.application.config.comfyui.base_url = ENV.fetch('COMFYUI_BASE_URL', 'http://localhost:8188')
Rails.application.config.comfyui.poll_interval = ENV.fetch('COMFYUI_POLL_INTERVAL', 5).to_i
Rails.application.config.comfyui.submit_interval = ENV.fetch('COMFYUI_SUBMIT_INTERVAL', 10).to_i
Rails.application.config.comfyui.timeout = ENV.fetch('COMFYUI_TIMEOUT', 300).to_i
Rails.application.config.comfyui.max_retries = ENV.fetch('COMFYUI_MAX_RETRIES', 3).to_i
```

## Error Handling

### Retry Strategy
- API connection errors: Retry up to 3 times with exponential backoff
- Job failures: Mark as failed, don't retry automatically (manual intervention)
- Polling errors: Log and continue (don't fail the worker)

### Monitoring
- Log all API calls with timing
- Track success/failure rates
- Alert on high error rates
- Monitor queue depth

## Testing Strategy

### Unit Tests
- Mock HTTP client in all tests
- Test each command in isolation
- Test error scenarios
- Test retry logic

### Integration Tests
- Test full job lifecycle with VCR cassettes
- Test worker scheduling
- Test concurrent job handling

### Manual Testing
- Deploy to staging with real ComfyUI instance
- Submit test workflows
- Verify images are created
- Check error handling

## Pack Structure

```
packs/comfyui/
  package.yml
  app/
    models/
      comfyui_job.rb
    commands/
      submit_job.rb
      poll_job_status.rb
      process_job_result.rb
    services/
      comfyui_client.rb
    workers/
      job_submitter_worker.rb
      job_poller_worker.rb
  spec/
    models/
      comfyui_job_spec.rb
    commands/
      submit_job_spec.rb
      poll_job_status_spec.rb
      process_job_result_spec.rb
    services/
      comfyui_client_spec.rb
    workers/
      job_submitter_worker_spec.rb
      job_poller_worker_spec.rb
```

## Dependencies

- **job_orchestration pack**: SelectNextJob, BuildJobPayload commands
- **pipeline pack**: Pipeline, PipelineRun, ImageCandidate models
- **Faraday gem**: HTTP client for API calls
- **Sidekiq**: Background job processing

## Risks / Trade-offs

### Risk: ComfyUI API changes
**Mitigation**: 
- Version the API client
- Add integration tests that fail if API changes
- Document API version used

### Risk: Long-running jobs
**Mitigation**:
- Set reasonable timeout (5 minutes default)
- Mark jobs as failed after timeout
- Can manually retry from UI

### Risk: Image storage fills disk
**Mitigation**:
- Monitor disk usage
- Implement cleanup of old runs (future)
- Consider S3 storage (future)

### Risk: Worker crashes leave jobs in limbo
**Mitigation**:
- Periodic cleanup job to check for abandoned jobs
- Mark jobs as failed after X hours without update
- Restart workers automatically

## Migration Plan

1. Create pack structure (safe, no DB changes)
2. Add ComfyUI configuration
3. Create ComfyuiJob model and migration
4. Implement API client with mocked tests
5. Implement commands with unit tests
6. Implement workers
7. Deploy without starting workers
8. Manual testing with workers
9. Enable workers in production

## Open Questions

- Should we limit concurrent jobs to ComfyUI? **Decision**: Yes, start with 1 concurrent job, make configurable
- What happens if ComfyUI returns unexpected response? **Decision**: Log error, mark job as failed, alert
- Should we store the workflow JSON in the job record? **Decision**: Yes, useful for debugging and replay
- How to handle partial results (multiple images)? **Decision**: Create one ImageCandidate per image for now
