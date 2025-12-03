# Winner Selection

**Status:** Proposed  
**Created:** 2025-12-03  
**Updated:** 2025-12-03

## Problem

The current "winner" concept is passive and unclear:
- Users don't actively choose a winner
- The selection happens implicitly through the `winner` boolean flag
- There's no clear UI affordance for "this is the one I want to publish"
- The process doesn't feel like an intentional decision

## Solution

Implement an explicit "Pick Winner" action that:
1. Makes winner selection an active, intentional choice
2. Provides clear UI affordance (prominent button)
3. Ensures only one winner per run
4. Creates a clear path from generation → selection → publishing

## Design

### UI Flow

#### Run Show Page (`/personas/:id/content_pillars/:id/clusters/:id/runs/:id`)

**Current State:** Just displays candidates with a passive checkbox
**New State:** Active winner selection

```
┌─────────────────────────────────────────┐
│ Run #123                                │
│ Status: complete                        │
│ Created: 2 hours ago                    │
├─────────────────────────────────────────┤
│                                         │
│ ┌───────────────┐  ┌───────────────┐   │
│ │   Image 1     │  │   Image 2     │   │
│ │  [preview]    │  │  [preview]    │   │
│ │               │  │               │   │
│ │ "Casual day"  │  │ "Golden hour" │   │
│ │               │  │               │   │
│ │ [Pick Winner] │  │ ✓ WINNER      │   │
│ └───────────────┘  └───────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

### Data Model

#### Candidate Model Changes

```ruby
class Candidate < ApplicationRecord
  belongs_to :run
  
  # New column
  add_column :candidates, :selected_as_winner_at, :datetime
  
  # Scopes
  scope :winners, -> { where.not(selected_as_winner_at: nil) }
  scope :not_winners, -> { where(selected_as_winner_at: nil) }
  
  # Methods
  def winner?
    selected_as_winner_at.present?
  end
  
  def mark_as_winner!
    transaction do
      # Unmark other candidates in the same run
      run.candidates.where.not(id: id).update_all(selected_as_winner_at: nil)
      
      # Mark this one
      update!(selected_as_winner_at: Time.current)
    end
  end
  
  def unmark_as_winner!
    update!(selected_as_winner_at: nil)
  end
end
```

#### Photo Creation Trigger

When a candidate is marked as winner, automatically create a Photo record:

```ruby
class Candidate < ApplicationRecord
  after_update :create_photo_if_winner, if: :saved_change_to_selected_as_winner_at?
  
  private
  
  def create_photo_if_winner
    return unless winner?
    return if photo.present? # Don't create duplicate
    
    Photo.create!(
      cluster: run.cluster,
      candidate: self,
      caption: caption,
      status: :draft
    )
  end
end
```

### Routes

```ruby
resources :runs, only: [:show] do
  resources :candidates, only: [] do
    member do
      post :select_winner
      delete :unselect_winner
    end
  end
end
```

### Controller

```ruby
class CandidatesController < ApplicationController
  before_action :set_candidate
  
  def select_winner
    @candidate.mark_as_winner!
    redirect_to persona_content_pillar_cluster_run_path(
      @candidate.run.cluster.content_pillar.persona,
      @candidate.run.cluster.content_pillar,
      @candidate.run.cluster,
      @candidate.run
    ), notice: "Winner selected! Photo created in drafts."
  end
  
  def unselect_winner
    @candidate.unmark_as_winner!
    redirect_to persona_content_pillar_cluster_run_path(
      @candidate.run.cluster.content_pillar.persona,
      @candidate.run.cluster.content_pillar,
      @candidate.run.cluster,
      @candidate.run
    ), notice: "Winner unselected."
  end
  
  private
  
  def set_candidate
    @candidate = Candidate.find(params[:id])
  end
end
```

### View Updates

**app/views/runs/show.html.erb:**

```erb
<div class="candidates-grid">
  <% @run.candidates.each do |candidate| %>
    <div class="candidate-card <%= 'winner' if candidate.winner? %>">
      <%= image_tag candidate.image_path, class: "candidate-image" %>
      
      <div class="candidate-caption">
        <%= candidate.caption %>
      </div>
      
      <div class="candidate-actions">
        <% if candidate.winner? %>
          <div class="winner-badge">✓ WINNER</div>
          <%= button_to "Unselect", 
              unselect_winner_run_candidate_path(@run, candidate),
              method: :delete,
              class: "btn btn-secondary btn-sm" %>
        <% else %>
          <%= button_to "Pick Winner",
              select_winner_run_candidate_path(@run, candidate),
              method: :post,
              class: "btn btn-primary" %>
        <% end %>
      </div>
    </div>
  <% end %>
</div>
```

## Migration Strategy

### Phase 1: Add Column
```ruby
class AddSelectedAsWinnerAtToCandidates < ActiveRecord::Migration[7.1]
  def change
    add_column :candidates, :selected_as_winner_at, :datetime
    add_index :candidates, :selected_as_winner_at
  end
end
```

### Phase 2: Migrate Existing Data
```ruby
# For existing winners (if any), backfill the timestamp
Candidate.where(winner: true).update_all(selected_as_winner_at: Time.current)
```

### Phase 3: Remove Old Column (Future)
```ruby
# After confirming new system works
remove_column :candidates, :winner
```

## Benefits

1. **Clear Intent:** Users explicitly choose winners
2. **Better UX:** Prominent "Pick Winner" button makes the action obvious
3. **Automatic Photo Creation:** Winner selection triggers photo creation
4. **Audit Trail:** `selected_as_winner_at` timestamp tracks when decision was made
5. **Single Winner Guarantee:** Transaction ensures only one winner per run
6. **Reversible:** Can unselect and pick a different winner

## Future Enhancements

1. **Comparison View:** Side-by-side candidate comparison before selection
2. **Bulk Actions:** Select winners across multiple runs
3. **History:** Track winner changes (who changed it when)
4. **Auto-selection:** ML model suggests best candidate based on engagement metrics
