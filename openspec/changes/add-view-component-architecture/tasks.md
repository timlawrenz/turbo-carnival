# Implementation Tasks

## 1. Setup and Configuration
- [x] 1.1 Add `view_component` gem to Gemfile
- [x] 1.2 Run `bundle install`
- [x] 1.3 Configure ViewComponent in `config/environments/development.rb`
- [x] 1.4 Set up component preview configuration for development
- [x] 1.5 Create `spec/components` directory for component tests
- [x] 1.6 Configure RSpec for ViewComponent testing

## 2. Foundation Components
- [x] 2.1 Create base `ApplicationComponent` class in `app/components/application_component.rb`
- [x] 2.2 Create `ButtonComponent` with variants (primary, secondary, danger)
  - [x] 2.2.1 Implement component class
  - [x] 2.2.2 Create template
  - [x] 2.2.3 Write RSpec tests
  - [x] 2.2.4 Create preview
- [x] 2.3 Create `CardComponent` for container UI pattern
  - [x] 2.3.1 Implement component class with slots for header, body, footer
  - [x] 2.3.2 Create template
  - [x] 2.3.3 Write RSpec tests
  - [x] 2.3.4 Create preview

## 3. Domain-Specific Components
- [x] 3.1 Create `ImageDisplayComponent` with fallback support
  - [x] 3.1.1 Implement component class (accepts image_path, fallback_text, css classes)
  - [x] 3.1.2 Create template with conditional rendering
  - [x] 3.1.3 Write RSpec tests
  - [ ] 3.1.4 Create preview
- [ ] 3.2 Create `VotingCardComponent` (encapsulates voting UI pattern)
  - [ ] 3.2.1 Implement component class with candidate and form parameters
  - [ ] 3.2.2 Create template using ImageDisplayComponent
  - [ ] 3.2.3 Write RSpec tests
  - [ ] 3.2.4 Create preview

## 4. Migration of Existing Partials
- [ ] 4.1 Refactor `app/views/image_votes/_comparison.html.erb` to use VotingCardComponent
- [ ] 4.2 Update run card partials to use CardComponent where applicable
- [ ] 4.3 Verify UI consistency after conversion
- [ ] 4.4 Run integration tests to ensure no regressions

## 5. Documentation
- [x] 5.1 Create `docs/view_components.md` with:
  - [x] 5.1.1 Component creation guidelines
  - [x] 5.1.2 Testing patterns
  - [x] 5.1.3 Preview usage
  - [x] 5.1.4 Reusability best practices
- [x] 5.2 Add inline documentation to ApplicationComponent
- [x] 5.3 Document extraction strategy for future gem/pack creation

## 6. Testing and Validation
- [x] 6.1 Run full test suite
- [ ] 6.2 Manually test voting interface
- [ ] 6.3 Manually test gallery views
- [ ] 6.4 Verify component previews work in development
- [ ] 6.5 Run linters (rubocop)
