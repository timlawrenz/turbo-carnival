## 1. ViewComponents
- [ ] 1.1 Create `VotingCardComponent` with image display and vote buttons
- [ ] 1.2 Create `VotingCardComponent` preview in `spec/components/previews/`
- [ ] 1.3 Create `ComparisonViewComponent` to render A vs B layout
- [ ] 1.4 Create `ComparisonViewComponent` preview
- [ ] 1.5 Create `KillLeftNavigatorComponent` for parent traversal UI
- [ ] 1.6 Create `KillLeftNavigatorComponent` preview

## 2. Stimulus Controllers
- [ ] 2.1 Create `voting_controller.js` for vote button interactions
- [ ] 2.2 Create `kill_left_controller.js` for parent navigation
- [ ] 2.3 Add keyboard shortcuts (left/right arrow for voting, K for kill)
- [ ] 2.4 Implement optimistic UI updates with Turbo Streams

## 3. Backend - Controllers
- [x] 3.1 Create `ImageVotesController#show` - render comparison view
- [x] 3.2 Create `ImageVotesController#vote` - process A vs B vote
- [x] 3.3 Create `ImageVotesController#reject` - handle kill action
- [x] 3.4 Create `ImagesController#show` - serve image files through Rails
- [ ] 3.5 Create `ImageVotesController#navigate_parent` - load parent comparison

## 4. Backend - GLCommands
- [x] 4.1 Create `RecordVote` command to update ELO scores for both candidates
- [x] 4.2 Implement ELO calculation algorithm (K-factor, expected score)
- [x] 4.3 Create `RejectImageBranch` command to set status='rejected'
- [x] 4.4 Add rollback logic for both commands

## 5. Backend - Models
- [x] 5.1 Add `ImageCandidate#calculate_elo_change(opponent, won)` method
- [x] 5.2 Add `ImageCandidate#parent_with_sibling` query method
- [x] 5.3 Add `ImageCandidate.unvoted_pairs(pipeline_step)` scope
- [ ] 5.4 Add validation to prevent self-voting

## 6. Routing
- [x] 6.1 Add `/vote` route for main voting interface
- [x] 6.2 Add POST `/vote` for recording votes
- [x] 6.3 Add POST `/vote/reject/:id` for kill action
- [ ] 6.4 Add GET `/vote/parent/:id` for parent navigation

## 7. Tests
- [x] 7.1 Unit tests for `RecordVote` command with ELO math validation
- [x] 7.2 Unit tests for `RejectImageBranch` command with rollback
- [x] 7.3 Unit tests for `ImageCandidate` ELO and query methods
- [x] 7.4 Request specs for `ImageVotesController` actions
- [ ] 7.5 Component tests for ViewComponents
- [ ] 7.6 N+1 query test for vote pair fetching

## 8. Styling
- [x] 8.1 Tailwind classes for voting card layout (centered, large images)
- [x] 8.2 Button states (hover, active, disabled) for vote and kill actions
- [x] 8.3 Responsive design for mobile voting
- [ ] 8.4 Loading states and transitions
