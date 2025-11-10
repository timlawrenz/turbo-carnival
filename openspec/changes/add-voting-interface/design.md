## Context

This capability provides the frontend voting and curation interface for the image generation workflow. The UI serves as the primary "control panel" for users to guide the job algorithm through ELO-based ranking and branch pruning.

The interface must be:
- **Fast**: Rapid voting with keyboard shortcuts and optimistic UI
- **Intelligent**: Prioritize showing right-most (most complete) images first
- **Investigative**: Allow users to trace bad images to their root cause via parent navigation

## Goals

- Enable rapid A vs B voting with ELO score updates
- Implement "triage-right" strategy (show final images first)
- Provide "kill-left" navigation to find root causes of bad images
- Update ImageCandidate status to prune branches from future generation
- Minimize cognitive load with simple, clear UI

## Non-Goals

- Implementing the job algorithm itself (handled by separate capability)
- Building the ComfyUI integration (separate capability)
- Creating the PipelineStep or ImageCandidate models (assumed to exist)
- Advanced filtering or search (future enhancement)

## Decisions

### Decision: ELO Calculation Algorithm
Use standard ELO with K-factor of 32 for responsiveness to new votes.

**Formula:**
- Expected Score: `E_a = 1 / (1 + 10^((R_b - R_a) / 400))`
- New Rating: `R_a' = R_a + K * (S_a - E_a)` where S_a = 1 (win) or 0 (loss)

**Rationale:** 
- K=32 is standard for active rating systems
- Higher K allows faster convergence on new images
- Simple, proven algorithm

**Alternatives considered:**
- Glicko-2: Too complex for initial implementation
- Trueskill: Overkill for pairwise comparisons

### Decision: ViewComponent Architecture
Use three separate components (`VotingCard`, `ComparisonView`, `KillLeftNavigator`) rather than one monolithic component.

**Rationale:**
- Single responsibility - each component has one job
- Reusability - VotingCard can be used in different contexts
- Testability - easier to preview and test in isolation

**Alternatives considered:**
- Single monolithic component: Harder to maintain and test

### Decision: Optimistic UI with Turbo Streams
Update UI immediately on vote, then persist to backend.

**Rationale:**
- Perceived performance - feels instant
- Matches Rails 8 patterns (Turbo Streams)
- Graceful degradation if backend fails

**Alternatives considered:**
- Wait for backend: Slower UX
- Full SPA: Over-engineering for this use case

### Decision: Keyboard Shortcuts
- Left/Right arrows: Vote for left/right image
- K key: Kill current image (start kill-left workflow)
- N key: Next pair (skip without voting)

**Rationale:**
- Power users can vote rapidly without mouse
- Vim-style "K for kill" is memorable
- Standard left/right arrows are intuitive

## Risks / Trade-offs

### Risk: ELO Score Inflation/Deflation
As new images enter the system at baseline (1000), older images may accumulate artificially high scores.

**Mitigation:**
- Monitor score distribution over time
- Consider periodic normalization (future enhancement)
- Document in openspec for future review

### Risk: Concurrent Votes
Two users voting on same pair simultaneously could cause race conditions.

**Mitigation:**
- Use database transactions in `RecordVote` command
- Accept "last write wins" behavior initially
- Add optimistic locking if it becomes a problem

### Trade-off: Triage-Right vs Random
Showing right-most images first means left-most (base) images may never get voted on.

**Acceptance:**
- This is intentional - we care most about finished work
- Base images get indirect feedback via their children's performance
- If needed, can add "round robin" mode later

## Migration Plan

N/A - This is a new capability with no existing functionality to migrate.

## Open Questions

- Should we show ELO scores in the UI, or keep them hidden?
  - **Recommendation**: Hide initially to reduce cognitive load, add as optional setting
  
- How many pairs should be pre-fetched for smooth voting?
  - **Recommendation**: Fetch 3 pairs ahead, lazy load on scroll
  
- Should "kill" be destructive or reversible?
  - **Recommendation**: Make it reversible - add `status='archived'` vs `status='rejected'`, allow un-reject
