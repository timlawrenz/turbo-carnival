# Implementation Tasks

## 1. Pack Setup
- [ ] 1.1 Create pack directory structure `packs/scheduling/`
- [ ] 1.2 Create `packs/scheduling/package.yml` with dependencies
- [ ] 1.3 Create README.md explaining pack purpose

## 2. Database Schema
- [ ] 2.1 Create initial migration for scheduling_posts table
- [ ] 2.2 Create enhancement migration for cluster/strategy tracking
- [ ] 2.3 Create migration for caption_metadata field
- [ ] 2.4 Run migrations and verify schema

## 3. Models
- [ ] 3.1 Create `Scheduling::Post` model
- [ ] 3.2 Add state machine with transitions
- [ ] 3.3 Add scopes for filtering posts
- [ ] 3.4 Add associations to Photo and Persona
- [ ] 3.5 Write model specs

## 4. Instagram Client
- [ ] 4.1 Create `Instagram::Client` class
- [ ] 4.2 Implement `create_post` method
- [ ] 4.3 Add error handling
- [ ] 4.4 Configure credentials loading
- [ ] 4.5 Write client specs

## 5. Commands
- [ ] 5.1 Create `Scheduling::Commands::CreatePostRecord`
- [ ] 5.2 Create `Scheduling::Commands::GeneratePublicPhotoUrl`
- [ ] 5.3 Create `Scheduling::Commands::SendPostToInstagram`
- [ ] 5.4 Create `Scheduling::Commands::UpdatePostWithInstagramId`
- [ ] 5.5 Create main `Scheduling::SchedulePost` command chain
- [ ] 5.6 Write command specs with rollback tests

## 6. Rake Tasks
- [ ] 6.1 Create `scheduling:post_scheduled` task
- [ ] 6.2 Create `scheduling:create_scheduled_post` task
- [ ] 6.3 Test tasks manually

## 7. Credentials
- [ ] 7.1 Document required Instagram credentials
- [ ] 7.2 Copy credentials from fluffy-train production credentials
- [ ] 7.3 Verify credentials structure

## 8. Shell Script for Cron
- [ ] 8.1 Create `bin/scheduled_posting.sh` wrapper script
- [ ] 8.2 Add logging to `log/scheduled_posting.log`
- [ ] 8.3 Test script manually

## 9. Integration Testing
- [ ] 9.1 Write integration spec for full posting flow
- [ ] 9.2 Test state transitions
- [ ] 9.3 Test error handling and rollback

## 10. Documentation
- [ ] 10.1 Document scheduling workflow
- [ ] 10.2 Document Instagram API setup
- [ ] 10.3 Add usage examples to README
- [ ] 10.4 Document cron setup instructions

## 11. Deployment
- [ ] 11.1 Update cron job to point to turbo-carnival
- [ ] 11.2 Verify first hourly run succeeds
- [ ] 11.3 Monitor for 24 hours
