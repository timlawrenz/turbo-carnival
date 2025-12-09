# Scheduling Pack

This pack handles Instagram post scheduling and publishing.

## Responsibilities

- Track scheduled posts with `Scheduling::Post` model
- Manage post lifecycle through state machine (draft → scheduled → posting → posted/failed)
- Publish posts to Instagram via Instagram Graph API
- Automate posting through rake tasks

## Components

### Models
- `Scheduling::Post` - Post records with status tracking

### Commands
- `Scheduling::SchedulePost` - Main command chain for scheduling posts
- `Scheduling::Commands::CreatePostRecord` - Create post record
- `Scheduling::Commands::GeneratePublicPhotoUrl` - Generate public URL for photo
- `Scheduling::Commands::SendPostToInstagram` - Post to Instagram API
- `Scheduling::Commands::UpdatePostWithInstagramId` - Update with Instagram ID

### Clients
- `Instagram::Client` - Instagram Graph API client

### Rake Tasks
- `scheduling:post_scheduled` - Post any scheduled posts that are due
- `scheduling:create_scheduled_post` - Create a scheduled post using content strategy

## Dependencies

- `packs/personas` - Persona model
- `packs/pipeline` - Photo model

## Usage

### Schedule a post manually
```ruby
result = Scheduling::SchedulePost.call!(
  photo: photo,
  persona: persona,
  caption: "My caption #hashtags"
)
```

### Run scheduled posting
```bash
bundle exec rails scheduling:post_scheduled
```

### Create scheduled post from strategy
```bash
bundle exec rails scheduling:create_scheduled_post[persona_name]
```
