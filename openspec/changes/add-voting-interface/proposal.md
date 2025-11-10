# Change: Add Image Voting and Curation Interface

## Why

The bottleneck in AI image generation is not generation itself, but curation and iteration. Users currently lack an efficient way to:
- Compare and rank generated images to guide the system's ELO scoring
- Identify and prune bad image branches at their root cause
- Efficiently triage thousands of candidates

This frontend interface provides the missing "control panel" that feeds the job algorithm with user preferences.

## What Changes

- **Primary Voting Interface**: Rapid "A vs. B" comparison view for ELO ranking
- **Triage-Right Strategy**: Prioritize showing images from right-most pipeline columns first
- **Kill-Left Navigation**: Interactive workflow to trace bad images back to their root parent
- **Real-time ELO Updates**: Backend integration to recalculate and persist ELO scores
- **Status Management**: UI actions to mark ImageCandidates as `rejected` to prune branches

## Impact

- Affected specs: `image-voting` (new capability)
- Affected code: 
  - New ViewComponents: `VotingCard`, `ComparisonView`, `KillLeftNavigator`
  - New controller: `ImageVotesController`
  - New GLCommand: `RecordVote`, `RejectImageBranch`
  - JavaScript/Stimulus controllers for interactive voting and navigation
  - ImageCandidate model updates for ELO calculation
- Note: No authorization - all users have full access
