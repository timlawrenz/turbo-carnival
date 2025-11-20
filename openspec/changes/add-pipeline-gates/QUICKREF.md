# Pipeline Gates - Quick Reference

## TL;DR

**Problem:** Exponential growth wastes compute on low-quality branches
**Solution:** Manual approval gates with ELO-based top-K filtering

## One-Sentence Summary

When you approve a step, only the top-K highest ELO candidates advance to become parents for the next step, controlling growth and improving quality.

## Key Changes

| Before | After |
|--------|-------|
| All candidates automatically advance | Manual approval required per step |
| Growth: 2 → 4 → 8 → 16 | Growth: 3 → 3 → 3 → 3 |
| No quality filter | Global top-K ELO filter |
| Set-and-forget | Checkpoint at each step |

## Database Schema

```ruby
create_table :pipeline_run_steps do |t|
  t.references :pipeline_run, null: false
  t.references :pipeline_step, null: false
  t.boolean :approved, default: false
  t.datetime :approved_at
  t.integer :top_k_count, default: 3
  t.timestamps
end
```

## Core Logic Changes

### SelectNextJob (Before)
```ruby
def find_eligible_parents(run)
  ImageCandidate
    .where(status: "active", pipeline_run: run)
    .where("child_count < ?", max_children)
    .where.not(pipeline_step_id: final_step_id)
end
```

### SelectNextJob (After)
```ruby
def find_eligible_parents(run)
  candidates = ImageCandidate
    .where(status: "active", pipeline_run: run)
    .where("child_count < ?", max_children)
    .where.not(pipeline_step_id: final_step_id)
  
  # Filter to approved steps + top-K only
  candidates.select do |candidate|
    step_approved?(candidate.pipeline_step, run) &&
    in_top_k?(candidate, run)
  end
end

def in_top_k?(candidate, run)
  prs = run.pipeline_run_steps.find_by(pipeline_step: candidate.pipeline_step)
  return false unless prs&.approved?
  
  k = prs.top_k_count
  top_k_ids = ImageCandidate
    .where(pipeline_step: candidate.pipeline_step, pipeline_run: run, status: 'active')
    .order(elo_score: :desc)
    .limit(k)
    .pluck(:id)
  
  top_k_ids.include?(candidate.id)
end
```

## API Examples

### Approve a Step
```ruby
# Controller action
def approve
  @run = PipelineRun.find(params[:run_id])
  @step = PipelineStep.find(params[:step_id])
  
  k = params[:top_k_count] || 3
  @run.approve_step!(@step, top_k: k)
  
  redirect_to run_path(@run), notice: "Step approved. Top #{k} candidates will advance."
end

# Model method
class PipelineRun
  def approve_step!(step, top_k: 3)
    prs = pipeline_run_steps.find_or_create_by(pipeline_step: step)
    raise "Already approved" if prs.approved?
    
    prs.update!(
      approved: true,
      approved_at: Time.current,
      top_k_count: top_k
    )
  end
end
```

### Check Approval Status
```ruby
run = PipelineRun.find(1)
step = run.pipeline.pipeline_steps.find_by(order: 2)

if run.step_approved?(step)
  puts "Step 2 is approved"
  prs = run.pipeline_run_steps.find_by(pipeline_step: step)
  puts "Top #{prs.top_k_count} candidates will advance"
else
  puts "Step 2 awaiting approval"
end
```

### Get Top-K Candidates
```ruby
prs = PipelineRunStep.find_by(pipeline_run: run, pipeline_step: step)
top_k = prs.top_k_candidates

# Returns candidates sorted by ELO descending, limited to K
top_k.each do |candidate|
  puts "#{candidate.id}: ELO #{candidate.elo_score}"
end
```

## UI Components Needed

### 1. Run Dashboard - Approval Badges
```erb
<% @run.pipeline.pipeline_steps.order(:order).each do |step| %>
  <div class="step-card">
    <h3><%= step.name %></h3>
    <%= render_approval_badge(@run, step) %>
  </div>
<% end %>

def render_approval_badge(run, step)
  prs = run.pipeline_run_steps.find_by(pipeline_step: step)
  
  if prs&.approved?
    count = step.image_candidates.where(pipeline_run: run, status: 'active').count
    "✅ Approved (#{prs.top_k_count}/#{count} advancing)"
  elsif step.order == 1
    "✅ Auto-approved"
  else
    candidate_count = step.image_candidates.where(pipeline_run: run, status: 'active').count
    if candidate_count > 0
      button_to "⏸️ Approve Step #{step.order}", 
        approve_run_step_path(run, step), 
        class: "btn-approve"
    else
      "🔒 Blocked"
    end
  end
end
```

### 2. Approval Preview Modal
```erb
<!-- Triggered by "Approve" button -->
<div class="modal">
  <h2>Approve Step <%= @step.order %>: <%= @step.name %></h2>
  
  <label>
    How many candidates should advance?
    <input type="range" min="1" max="<%= @candidates.count %>" 
           value="3" id="k-slider">
    <span id="k-value">3</span>
  </label>
  
  <div class="candidates-preview">
    <h3>✅ Will Advance (Top <span id="advancing-count">3</span>)</h3>
    <div id="advancing-list">
      <!-- Top K candidates, updated via JS -->
    </div>
    
    <h3>⏸️ Will Not Advance</h3>
    <div id="filtered-list">
      <!-- Remaining candidates -->
    </div>
  </div>
  
  <%= form_with url: approve_run_step_path(@run, @step) do |f| %>
    <%= f.hidden_field :top_k_count, value: 3, id: 'k-input' %>
    <%= f.submit "Approve with K=3", class: "btn-primary", id: "approve-btn" %>
  <% end %>
</div>

<script>
// Update preview when slider changes
document.getElementById('k-slider').addEventListener('input', (e) => {
  const k = parseInt(e.target.value);
  document.getElementById('k-value').textContent = k;
  document.getElementById('k-input').value = k;
  document.getElementById('approve-btn').textContent = `Approve with K=${k}`;
  updatePreview(k); // Re-render which candidates advance
});
</script>
```

### 3. Candidate Badges in Gallery
```erb
<div class="candidate-card">
  <%= image_tag candidate.image_path %>
  
  <div class="candidate-info">
    <span class="elo-badge">ELO: <%= candidate.elo_score %></span>
    <%= render_advancement_badge(candidate) %>
  </div>
</div>

def render_advancement_badge(candidate)
  prs = candidate.pipeline_run.pipeline_run_steps
    .find_by(pipeline_step: candidate.pipeline_step)
  
  return unless prs&.approved?
  
  top_k_ids = prs.top_k_candidates.pluck(:id)
  
  if top_k_ids.include?(candidate.id)
    content_tag :span, "✅ Advancing", class: "badge badge-success"
  else
    content_tag :span, "⏸️ Not advancing", class: "badge badge-muted"
  end
end
```

## Configuration

```ruby
# config/initializers/job_orchestration.rb
JobOrchestrationConfig.configure do |config|
  # N: How many to generate per parent
  config.max_children_per_node = 3
  
  # K default: How many advance by default
  config.default_top_k = 3
end
```

```bash
# .env
MAX_CHILDREN_PER_NODE=3  # N
# K is set per approval, no global env var
```

## Common Workflows

### Workflow 1: Standard Approval
1. Create run → Step 1 auto-approved
2. Wait for Step 1 generation (3 candidates)
3. Vote on Step 1 candidates
4. Approve Step 1 with K=3 → All 3 advance
5. Wait for Step 2 generation (9 candidates)
6. Vote on Step 2 candidates
7. Approve Step 2 with K=3 → Top 3 advance
8. Repeat until final step

### Workflow 2: Aggressive Pruning
1. Generate 5 per parent (N=5)
2. Approve with K=1 (only best advances)
3. Result: 3 → 5 → 5 → 5 growth

### Workflow 3: Skipping Approvals
Not allowed! Must approve each step sequentially.
Cannot approve Step 3 if Step 2 is unapproved.

## Migration Checklist

- [ ] Create migration for `pipeline_run_steps` table
- [ ] Run migration with backfill (auto-approve existing runs)
- [ ] Verify existing runs continue normally
- [ ] Deploy code changes
- [ ] Test new run requires approval at Step 2
- [ ] Test approval workflow end-to-end
- [ ] Monitor for stalled runs
- [ ] Update user documentation

## Troubleshooting

**Q: My run is stuck, no new images generating**
A: Check if previous step needs approval. Dashboard will show "⏸️ Awaiting Approval".

**Q: I approved but only some candidates advancing**
A: This is correct! You set K=3, so only top 3 by ELO advance.

**Q: Can I un-approve a step?**
A: No. Approvals are one-way. Create new run for different configuration.

**Q: What if I haven't voted enough?**
A: You'll see a warning but can still approve. ELO rankings may not be meaningful yet.

**Q: Can I approve Step 3 before Step 2?**
A: No. Must approve sequentially in order.
