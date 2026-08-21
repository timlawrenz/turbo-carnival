# Change: Add Growth Harness (autonomous follower-growth loop)

**Status:** Live — running autonomously
**Created:** 2026-08-20

## Summary

Add a self-improving follower-growth harness for the turbo-carnival Instagram
pipeline: track a follower goal (default: 1,000 followers within 365 days) for
the `a1.sarah.a1` persona, maintain posting cadence automatically, collect
follower snapshots, and periodically review progress against the goal
trajectory — adjusting strategy (cadence, hashtag count, strategy rotation,
posting effort) when running behind or cutting back when ahead. Every strategy
change is logged as a decision record so the loop is auditable and reversible.

**Note:** Implemented alongside a B2-replacement: photo media is now served by
the app itself at `carnival.pi216.ai/media/photos/:id` (from the NAS backup
tree), because the shared Backblaze B2 key across all projects is invalid.

---

## Why

The existing pipeline (persona → content strategy → caption generation →
scheduling → Instagram publish → insights) posts on a schedule, but nothing
measures whether posting is *growing the audience* toward a concrete goal.
Posts go out, insights come back, and no component decides "we need to post
more / change strategy" based on measured follower growth. This change closes
that loop with a growth harness that:

- Defines a measurable goal (followers + deadline) per persona.
- Guarantees cadence by topping up the scheduled-post queue.
- Measures follower count over time (Graph API `followers_count`).
- Runs a periodic strategy review (trajectory vs. goal) that adjusts knobs
  and records a decision log.

**Key Insight:** All building blocks already exist (scheduling, auto post
creation, insights collection). The harness adds the goal/trajectory/review
layer that ties them together.

---

## What Changes

- New SQL tables: `growth_goals`, `growth_snapshots`, `growth_decisions`.
- New pack `packs/growth_harness` (models, services, rake tasks).
- `Instagram::Client#followers_count` — fetch current follower count.
- Rake tasks: `growth:sync_cadence`, `growth:snapshot_followers`,
  `growth:review_strategy`, `growth:status`, `growth:run_all`.
- Cron script `bin/growth_harness.sh` (hourly loop; review runs on interval).
- Dashboard at `/growth` showing goal trajectory, snapshots, decisions.

No breaking changes. All new code is additive; existing scheduling behavior is
unchanged.

---

## Impact

- Affected specs: `growth-harness` (new capability)
- Affected code:
  - `packs/scheduling/app/clients/instagram/client.rb` (new method)
  - `packs/growth_harness/` (new pack: models, services, rake)
  - `config/routes.rb` (dashboard route)
  - `app/controllers/growth_controller.rb` (new)
  - `db/migrate/*` (new tables)