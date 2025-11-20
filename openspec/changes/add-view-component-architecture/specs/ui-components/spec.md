# Specification: UI Components

## ADDED Requirements

### Requirement: ViewComponent Integration
The system SHALL integrate the ViewComponent gem to enable component-based UI development.

#### Scenario: ViewComponent gem is available
- **WHEN** the application boots
- **THEN** ViewComponent classes can be defined and rendered

#### Scenario: Component previews are enabled in development
- **WHEN** running in development environment
- **THEN** component previews are accessible at `/rails/view_components`

### Requirement: Application Component Base Class
The system SHALL provide an ApplicationComponent base class that all components inherit from.

#### Scenario: Component inherits from base class
- **WHEN** a new component is created
- **THEN** it MUST inherit from ApplicationComponent
- **AND** inherit common component functionality

### Requirement: Button Component
The system SHALL provide a ButtonComponent for rendering styled buttons with variants.

#### Scenario: Render primary button
- **WHEN** ButtonComponent is initialized with variant: :primary
- **THEN** the button is rendered with primary styling (blue background)

#### Scenario: Render secondary button
- **WHEN** ButtonComponent is initialized with variant: :secondary
- **THEN** the button is rendered with secondary styling (gray background)

#### Scenario: Render danger button
- **WHEN** ButtonComponent is initialized with variant: :danger
- **THEN** the button is rendered with danger styling (red background)

#### Scenario: Custom CSS classes
- **WHEN** ButtonComponent receives additional CSS classes
- **THEN** the classes are appended to the button element
- **AND** default variant classes are preserved

### Requirement: Card Component
The system SHALL provide a CardComponent for rendering container elements with optional header, body, and footer slots.

#### Scenario: Render basic card
- **WHEN** CardComponent is rendered with body content
- **THEN** a styled card container is displayed
- **AND** the body content is rendered inside

#### Scenario: Card with header and footer
- **WHEN** CardComponent is rendered with header, body, and footer slots
- **THEN** all three sections are rendered
- **AND** sections are visually separated

#### Scenario: Card with custom styling
- **WHEN** CardComponent receives custom CSS classes
- **THEN** the classes are applied to the card container
- **AND** default card styling is preserved

### Requirement: Image Display Component
The system SHALL provide an ImageDisplayComponent for displaying images with fallback support.

#### Scenario: Display image when path exists
- **WHEN** ImageDisplayComponent receives a valid image_path
- **THEN** the image is rendered using image_tag
- **AND** configured CSS classes are applied

#### Scenario: Display fallback when image missing
- **WHEN** ImageDisplayComponent receives nil or blank image_path
- **THEN** fallback text is displayed instead
- **AND** fallback styling is applied

#### Scenario: Custom container classes
- **WHEN** ImageDisplayComponent receives container CSS classes
- **THEN** the classes are applied to the containing element

### Requirement: Voting Card Component
The system SHALL provide a VotingCardComponent for rendering candidate voting UI.

#### Scenario: Render voting card with candidate
- **WHEN** VotingCardComponent receives a candidate and vote URL
- **THEN** a form with voting button is rendered
- **AND** candidate image is displayed using ImageDisplayComponent
- **AND** candidate metadata (step name, order) is shown

#### Scenario: Handle candidate without image
- **WHEN** VotingCardComponent receives a candidate without image_path
- **THEN** fallback display is shown via ImageDisplayComponent
- **AND** voting functionality remains intact

### Requirement: Component Testing
The system SHALL support unit testing of components using RSpec.

#### Scenario: Test component rendering
- **WHEN** a component is tested with render_inline
- **THEN** the rendered output can be queried using Capybara matchers
- **AND** component behavior can be verified in isolation

#### Scenario: Test component with different parameters
- **WHEN** component tests provide various parameter combinations
- **THEN** each configuration renders correctly
- **AND** edge cases are covered (nil values, long strings, etc.)

### Requirement: Component Previews
The system SHALL provide component previews for visual development and documentation.

#### Scenario: View component variants in preview
- **WHEN** a developer accesses component previews
- **THEN** all component variants are displayed
- **AND** different parameter combinations are shown
- **AND** components are rendered in isolation

#### Scenario: Preview updates during development
- **WHEN** a component or preview is modified
- **THEN** the preview reflects changes on page refresh
- **AND** no application restart is required

### Requirement: Component Documentation
The system SHALL document component usage, creation patterns, and reusability guidelines.

#### Scenario: Component creation guidelines available
- **WHEN** a developer wants to create a new component
- **THEN** documentation explains the creation process
- **AND** examples are provided

#### Scenario: Testing patterns documented
- **WHEN** a developer needs to test a component
- **THEN** documentation shows RSpec testing patterns
- **AND** examples cover common scenarios

#### Scenario: Reusability guidelines documented
- **WHEN** designing components for cross-project use
- **THEN** documentation provides reusability best practices
- **AND** extraction strategies are explained

### Requirement: Incremental Migration
The system SHALL support incremental migration from ERB partials to ViewComponents.

#### Scenario: Components coexist with partials
- **WHEN** components are introduced
- **THEN** existing ERB partials continue to function
- **AND** views can use both partials and components

#### Scenario: Partial converted to component
- **WHEN** an ERB partial is refactored to a ViewComponent
- **THEN** the UI appearance remains unchanged
- **AND** functionality is preserved
- **AND** tests confirm no regression

### Requirement: Turbo and Stimulus Compatibility
The system SHALL ensure ViewComponents work seamlessly with Turbo Frames and Stimulus controllers.

#### Scenario: Component within Turbo Frame
- **WHEN** a component is rendered inside a turbo_frame_tag
- **THEN** Turbo Frame functionality works correctly
- **AND** frame updates render the component properly

#### Scenario: Component with Stimulus controller
- **WHEN** a component includes data-controller attributes
- **THEN** Stimulus controllers initialize correctly
- **AND** component interactivity functions as expected
