## ADDED Requirements

### Requirement: Persona Creation and Management

System SHALL allow creation and management of personas with identity attributes.

**Acceptance Criteria:**
- Persona has name (unique, required)
- Persona stores caption_config in JSONB (tone, style, voice attributes)
- Persona stores hashtag_strategy in JSONB (strategy configuration)
- Persona belongs to no other entity (independent identity)
- Can create, read, update personas via public API
- Name validation ensures uniqueness and presence

#### Scenario: Create persona via public API

- **GIVEN** no persona with name "Sarah" exists
- **WHEN** I call `Personas.create(name: "Sarah")`
- **THEN** a persona is created
- **AND** result.success? is true
- **AND** result.persona.name == "Sarah"
- **AND** persona.caption_config is nil (default)
- **AND** persona.hashtag_strategy is nil (default)

#### Scenario: Prevent duplicate persona names

- **GIVEN** persona with name "Sarah" exists
- **WHEN** I call `Personas.create(name: "Sarah")`
- **THEN** creation fails
- **AND** result.success? is false
- **AND** result.full_error_message includes "Name has already been taken"

#### Scenario: Find persona by ID

- **GIVEN** persona "Sarah" exists with id 1
- **WHEN** I call `Personas.find(1)`
- **THEN** persona is returned
- **AND** persona.name == "Sarah"

#### Scenario: Find persona by name

- **GIVEN** persona "Sarah" exists
- **WHEN** I call `Personas.find_by_name(name: "Sarah")`
- **THEN** persona is returned
- **AND** persona.id is set

---

### Requirement: Caption Configuration

System SHALL support caption configuration as a structured value object stored in JSONB.

**Acceptance Criteria:**
- CaptionConfig value object with tone, style, voice attributes
- Persona.caption_config returns CaptionConfig instance or nil
- Can set caption_config via hash or CaptionConfig object
- Validates caption_config structure before saving
- Raises ArgumentError if invalid caption_config provided

#### Scenario: Set caption configuration

- **GIVEN** persona "Sarah" exists
- **WHEN** I set persona.caption_config = { tone: "warm", style: "conversational" }
- **AND** I save the persona
- **THEN** caption_config is persisted to database as JSONB
- **AND** persona.caption_config.tone == "warm"
- **AND** persona.caption_config.style == "conversational"

#### Scenario: Reject invalid caption configuration

- **GIVEN** persona "Sarah" exists
- **WHEN** I set persona.caption_config = { invalid_key: "value" }
- **THEN** ArgumentError is raised
- **AND** persona is not saved

---

### Requirement: Hashtag Strategy

System SHALL support hashtag strategy configuration as a structured value object stored in JSONB.

**Acceptance Criteria:**
- HashtagStrategy value object with strategy attributes
- Persona.hashtag_strategy returns HashtagStrategy instance or nil
- Can set hashtag_strategy via hash or HashtagStrategy object
- Validates hashtag_strategy structure before saving
- Raises ArgumentError if invalid hashtag_strategy provided

#### Scenario: Set hashtag strategy

- **GIVEN** persona "Sarah" exists
- **WHEN** I set persona.hashtag_strategy = { max_tags: 10, brand_tags: ["sarah", "fitness"] }
- **AND** I save the persona
- **THEN** hashtag_strategy is persisted to database as JSONB
- **AND** persona.hashtag_strategy.max_tags == 10

---

### Requirement: Public API

System SHALL provide a module-based public API for persona operations.

**Acceptance Criteria:**
- `Personas` module is the only public interface
- `Personas.create(name:)` creates persona via CreatePersona command
- `Personas.find(id)` finds persona by ID (returns nil if not found)
- `Personas.find_by_name(name:)` finds persona by name
- `Personas.list` returns all personas as array
- Public API documented in packs/personas/README.md

#### Scenario: Use public API from other packs

- **GIVEN** another pack wants to create a persona
- **WHEN** code calls `Personas.create(name: "Emma")`
- **THEN** persona is created without direct model access
- **AND** result context is returned with persona or errors

---

### Requirement: Web Interface

System SHALL provide web interface for persona management.

**Acceptance Criteria:**
- Personas index page shows all personas
- Persona show page displays persona details
- New persona form allows creation
- Edit persona form allows updates
- Routes: GET /personas, GET /personas/:id, GET /personas/new, POST /personas, GET /personas/:id/edit, PATCH /personas/:id
- All views styled with Tailwind CSS matching turbo-carnival dark theme

#### Scenario: View personas index

- **GIVEN** 3 personas exist ("Sarah", "Emma", "Alex")
- **WHEN** I visit GET /personas
- **THEN** I see all 3 personas listed
- **AND** each has a link to show page
- **AND** page has "New Persona" button

#### Scenario: Create persona via web form

- **GIVEN** I am on GET /personas/new
- **WHEN** I fill in name "Taylor"
- **AND** I submit the form
- **THEN** persona is created
- **AND** I am redirected to persona show page
- **AND** I see success message

---

### Requirement: Packwerk Compliance

System SHALL follow Packwerk modular architecture.

**Acceptance Criteria:**
- Pack located at `packs/personas/`
- `package.yml` has `enforce_dependencies: true`
- All inter-pack access goes through `app/public/personas.rb`
- Models and commands are private (in app/models, app/commands)
- No packwerk violations when running `bin/packwerk check`

#### Scenario: Access persona from another pack

- **GIVEN** job_orchestration pack wants to use personas
- **WHEN** code requires "personas" module
- **THEN** only Personas public API is accessible
- **AND** direct model access (Persona.create) causes packwerk violation

---

### Requirement: GLCommand Pattern

System SHALL use GLCommand for persona creation business logic.

**Acceptance Criteria:**
- CreatePersona command extends GLCommand::Command
- Command validates inputs
- Command implements rollback method
- Command returns GLCommand::Context with persona or errors
- PersonasController calls CreatePersona via Personas.create

#### Scenario: Create persona with validation

- **GIVEN** CreatePersona command exists
- **WHEN** command is called with valid name
- **THEN** persona is created
- **AND** context.success? is true
- **AND** context.persona contains created record

#### Scenario: Rollback on failure

- **GIVEN** CreatePersona creates persona then fails
- **WHEN** rollback is triggered
- **THEN** persona is destroyed
- **AND** database is returned to previous state

---

