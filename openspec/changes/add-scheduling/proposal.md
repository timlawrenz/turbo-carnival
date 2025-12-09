# Change: Add Instagram Scheduling and Posting

## Why
We have content flowing through the pipeline (photos, captions, personas), but no way to actually publish to Instagram. The fluffy-train application previously handled this with an hourly cron job (`0 * * * *`), but it's now out of posts. We need to migrate this scheduling functionality to turbo-carnival to automate posting selected content at optimal times while tracking post status and Instagram IDs.

## What Changes
- **ADDED**: Scheduling pack with Post model to track scheduled and posted content
- **ADDED**: Instagram Graph API client for creating posts
- **ADDED**: Command chain for creating, scheduling, and posting content
- **ADDED**: Database migrations for scheduling_posts table
- **ADDED**: Rake tasks for scheduled posting automation
- **ADDED**: State machine workflow (draft → scheduled → posting → posted/failed)

## Impact
- Affected specs: `scheduling` (new)
- Affected code:
  - New pack: `packs/scheduling/`
  - New migrations for `scheduling_posts` table
  - New Instagram API client
  - Dependencies on `packs/personas` and `packs/pipeline` (Photo model)
- External dependencies: 
  - Instagram Graph API credentials required (copy from fluffy-train)
  - Cron job needs to be updated to point to turbo-carnival
  - Migration path: fluffy-train → turbo-carnival posting automation
