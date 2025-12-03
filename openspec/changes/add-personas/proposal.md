# Change: Add Personas Capability

## Why

Turbo-carnival currently generates images in isolation without any concept of identity or character consistency. To enable persona-based content creation (as outlined in INTEGRATION_REPORT.md), we need a foundational Personas capability that:

1. Provides a single source of truth for persona identity
2. Enables future integration with content pillars, LoRA models, and scheduling
3. Serves as the anchor point for the unified content creation workflow

This is the first step in the phased integration plan (Week 1, Day 1-2) to merge fluffy-train functionality into turbo-carnival.

## What Changes

- **NEW**: Personas pack with Persona model and public API
- **NEW**: Database table for personas with name, caption config, hashtag strategy
- **NEW**: PersonasController for CRUD operations
- **NEW**: Web UI for persona management (index, show, new, edit)
- **NEW**: CreatePersona command using GLCommand pattern
- **OPTIONAL**: Persona selection UI (for future pipeline association)

**No Breaking Changes** - This is purely additive. Existing pipelines and functionality remain unchanged.

## Impact

**Affected Specs:**
- NEW spec: `personas` (created by this change)

**Affected Code:**
- NEW pack: `packs/personas/`
- NEW migration: `db/migrate/YYYYMMDD_create_personas.rb`
- NEW controller: `app/controllers/personas_controller.rb`
- NEW views: `app/views/personas/`
- NEW routes: `/personas` resource routes

**Future Dependencies:**
This capability is required by:
- Content Pillars (personas have content pillars)
- Clusters (clusters belong to personas)
- Scheduling (posts belong to personas)
- LoRA Management (LoRAs link to personas)

## Migration Path

Since this is the first persona-related feature in turbo-carnival:
1. No data migration needed (fresh table)
2. No conflicts with existing functionality
3. Personas are optional - pipelines can exist without persona association
4. Future changes will add `persona_id` to pipelines table (Phase 2 of integration)

## Notes

- Based on fluffy-train's `packs/personas/` implementation
- Uses Packwerk for modular architecture (consistent with turbo-carnival)
- Follows GLCommand pattern for business logic (per project conventions)
- Caption config and hashtag strategy stored as JSONB (forward-compatible)
- Design follows turbo-carnival's existing patterns (ViewComponents, Tailwind CSS)
