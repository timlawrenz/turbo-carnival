## 1. Database Schema
- [ ] 1.1 Create migration for personas table (name, caption_config jsonb, hashtag_strategy jsonb, timestamps)
- [ ] 1.2 Add unique index on personas.name
- [ ] 1.3 Run migration and verify schema

## 2. Pack Structure
- [ ] 2.1 Create `packs/personas/` directory structure
- [ ] 2.2 Create `packs/personas/package.yml` with enforce_dependencies
- [ ] 2.3 Create `packs/personas/app/models/` directory
- [ ] 2.4 Create `packs/personas/app/commands/` directory
- [ ] 2.5 Create `packs/personas/app/public/` directory

## 3. Models
- [ ] 3.1 Create Persona model (`packs/personas/app/models/persona.rb`)
- [ ] 3.2 Add validations (name presence, uniqueness)
- [ ] 3.3 Create CaptionConfig value object (`packs/personas/app/models/personas/caption_config.rb`)
- [ ] 3.4 Create HashtagStrategy value object (`packs/personas/app/models/personas/hashtag_strategy.rb`)
- [ ] 3.5 Add accessor methods for caption_config and hashtag_strategy JSONB fields

## 4. Commands
- [ ] 4.1 Create CreatePersona command (`packs/personas/app/commands/create_persona.rb`)
- [ ] 4.2 Implement validation logic
- [ ] 4.3 Implement rollback support
- [ ] 4.4 Add command tests

## 5. Public API
- [ ] 5.1 Create public API module (`packs/personas/app/public/personas.rb`)
- [ ] 5.2 Implement `Personas.create(name:)`
- [ ] 5.3 Implement `Personas.find(id)`
- [ ] 5.4 Implement `Personas.find_by_name(name:)`
- [ ] 5.5 Implement `Personas.list`
- [ ] 5.6 Document public API in README

## 6. Controller & Routes
- [ ] 6.1 Create PersonasController (`app/controllers/personas_controller.rb`)
- [ ] 6.2 Implement index action
- [ ] 6.3 Implement show action
- [ ] 6.4 Implement new action
- [ ] 6.5 Implement create action (calls Personas.create)
- [ ] 6.6 Implement edit action
- [ ] 6.7 Implement update action
- [ ] 6.8 Implement destroy action (soft delete or restrict)
- [ ] 6.9 Add resource routes to `config/routes.rb`

## 7. Views
- [ ] 7.1 Create personas index view (`app/views/personas/index.html.erb`)
- [ ] 7.2 Create personas show view (`app/views/personas/show.html.erb`)
- [ ] 7.3 Create personas new view (`app/views/personas/new.html.erb`)
- [ ] 7.4 Create personas edit view (`app/views/personas/edit.html.erb`)
- [ ] 7.5 Create persona form partial (`app/views/personas/_form.html.erb`)
- [ ] 7.6 Style with Tailwind CSS (dark theme matching turbo-carnival)

## 8. Navigation
- [ ] 8.1 Add "Personas" link to main navigation
- [ ] 8.2 Update application layout if needed

## 9. Testing
- [ ] 9.1 Create persona factory (`spec/factories/personas.rb`)
- [ ] 9.2 Write model specs (`packs/personas/spec/models/persona_spec.rb`)
- [ ] 9.3 Write command specs (`packs/personas/spec/commands/create_persona_spec.rb`)
- [ ] 9.4 Write request specs (`spec/requests/personas_spec.rb`)
- [ ] 9.5 Test caption_config and hashtag_strategy JSONB handling
- [ ] 9.6 Test validations (name presence, uniqueness)

## 10. Packwerk Validation
- [ ] 10.1 Run `bin/packwerk check` and resolve violations
- [ ] 10.2 Run `bin/packwerk validate`
- [ ] 10.3 Ensure public API is the only entry point

## 11. Documentation
- [ ] 11.1 Create `packs/personas/README.md` with public API documentation
- [ ] 11.2 Update main README.md to mention personas
- [ ] 11.3 Add examples to README

## 12. OpenSpec
- [ ] 12.1 Validate change with `openspec validate add-personas --strict`
- [ ] 12.2 Fix any validation errors
- [ ] 12.3 Mark tasks as complete in tasks.md
