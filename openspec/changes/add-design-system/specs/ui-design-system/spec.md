## ADDED Requirements

### Requirement: Design Token System
The application SHALL define all design tokens (colors, typography, spacing, radii) as CSS variables using Tailwind CSS v4 `@theme` blocks.

#### Scenario: CSS variables defined
- **WHEN** stylesheets are loaded
- **THEN** CSS variables are available for all colors (primary, surface, semantic)
- **AND** typography scale is defined (font families, sizes, weights)
- **AND** spacing scale is defined
- **AND** border radii are defined
- **AND** shadow/elevation scale is defined

#### Scenario: AI-readable token format
- **WHEN** AI assistant reads design tokens
- **THEN** tokens are in standard CSS variable format (--color-primary, --radius-md)
- **AND** tokens are documented with semantic meaning
- **AND** tokens use native CSS without compilation step

### Requirement: Base Component Library
The application SHALL provide a Base:: namespace containing atomic UI components ported from Tailwind Plus Catalyst UI kit.

#### Scenario: Base components available
- **WHEN** developer creates a new feature
- **THEN** Base::ButtonComponent is available with variants (primary, secondary, outline, ghost)
- **AND** Base::InputComponent is available for form inputs
- **AND** Base::CardComponent is available for content containers
- **AND** Base::BadgeComponent is available for labels
- **AND** Base::AlertComponent is available with severity levels (info, success, warning, error)
- **AND** all Base components follow accessibility standards (WCAG)

#### Scenario: Component composition via slots
- **WHEN** Base component is rendered
- **THEN** it accepts content via slots (renders_one, renders_many)
- **AND** it accepts variant props
- **AND** it accepts custom CSS classes for extension
- **AND** it uses tailwind_merge for class composition

#### Scenario: Professional design quality
- **WHEN** Base components are used
- **THEN** they match Tailwind Plus Catalyst visual design
- **AND** they include proper focus states
- **AND** they support keyboard navigation
- **AND** they include proper ARIA attributes

### Requirement: Lookbook Component Development
The application SHALL use Lookbook for component development, testing, and documentation.

#### Scenario: Lookbook mounted in development
- **WHEN** Rails server starts in development mode
- **THEN** Lookbook is accessible at /lookbook path
- **AND** Lookbook is NOT mounted in production

#### Scenario: Component previews exist
- **WHEN** Base component is created
- **THEN** a corresponding preview file exists in test/components/previews/
- **AND** preview demonstrates all component variants
- **AND** preview shows different states (default, hover, disabled, error)

#### Scenario: Living documentation
- **WHEN** developer views Lookbook
- **THEN** all Base components are listed
- **AND** each component shows usage examples
- **AND** each component shows available props
- **AND** components can be interacted with in browser

### Requirement: Application Shell Layout
The application SHALL provide Layout:: components for consistent application shell structure.

#### Scenario: Layout components available
- **WHEN** application renders
- **THEN** Layout::SidebarComponent provides navigation sidebar
- **AND** Layout::HeaderComponent provides top header with user menu
- **AND** Layout::NavigationComponent provides main nav links
- **AND** layout is responsive (mobile, tablet, desktop)

#### Scenario: Collapsible sidebar
- **WHEN** user interacts with sidebar
- **THEN** sidebar can collapse to icon-only mode
- **AND** sidebar state persists across page loads
- **AND** sidebar adapts to mobile (drawer/overlay)

#### Scenario: App-like interface
- **WHEN** user navigates application
- **THEN** interface feels like a native app
- **AND** navigation is fast (Turbo/Stimulus)
- **AND** interactions have smooth transitions
- **AND** layout is consistent across all pages

### Requirement: Design System Documentation
The application SHALL provide DESIGN_SYSTEM.md documentation for AI-assisted component development.

#### Scenario: Design system documented
- **WHEN** AI assistant reads DESIGN_SYSTEM.md
- **THEN** CSS variable usage is documented
- **AND** Base component inventory is listed
- **AND** composition patterns are explained with examples
- **AND** accessibility requirements are stated

#### Scenario: AI composition instructions
- **WHEN** AI generates a new feature component
- **THEN** AI uses Base components for all primitives (buttons, inputs, cards)
- **AND** AI composes Base components rather than writing raw HTML
- **AND** AI uses semantic CSS variables (--color-primary) not raw hex values
- **AND** AI follows accessibility guidelines

### Requirement: Generic AI Instructions
The application SHALL document design system conventions in AGENTS.md using tool-agnostic language.

#### Scenario: AGENTS.md updated
- **WHEN** AGENTS.md is read
- **THEN** "UI Component Generation" section exists
- **AND** Base:: component usage rules are documented
- **AND** semantic color usage guidelines are provided
- **AND** instructions work for any AI assistant (Gemini, Copilot, etc.)

#### Scenario: No vendor lock-in
- **WHEN** instructions reference AI tools
- **THEN** language is generic ("AI assistant" not "GitHub Copilot")
- **AND** examples work regardless of tool
- **AND** no tool-specific configuration files (.github/copilot-instructions.md)

### Requirement: Dark Mode Support
The application SHALL support dark mode across all components using Tailwind dark: prefix.

#### Scenario: Dark mode colors
- **WHEN** system prefers dark mode
- **THEN** all components use dark mode color palette
- **AND** contrast ratios meet WCAG standards
- **AND** CSS variables adapt to dark mode

#### Scenario: Consistent dark mode
- **WHEN** Base components are used
- **THEN** dark mode is built-in
- **AND** developers don't need to add dark: classes manually
- **AND** feature components inherit dark mode from Base

### Requirement: Accessibility Standards
All UI components SHALL meet WCAG 2.1 Level AA accessibility standards.

#### Scenario: Keyboard navigation
- **WHEN** user navigates with keyboard
- **THEN** all interactive elements are reachable
- **AND** focus indicators are visible
- **AND** tab order is logical

#### Scenario: Screen reader support
- **WHEN** screen reader is used
- **THEN** all components have proper ARIA labels
- **AND** semantic HTML is used
- **AND** form errors are announced
- **AND** dynamic content updates are announced

#### Scenario: Color contrast
- **WHEN** components are rendered
- **THEN** text has minimum 4.5:1 contrast ratio
- **AND** UI elements have minimum 3:1 contrast ratio
- **AND** contrast ratios are maintained in dark mode

### Requirement: Responsive Design
All layout and components SHALL be fully responsive across mobile, tablet, and desktop viewports.

#### Scenario: Mobile-first breakpoints
- **WHEN** viewport is mobile (< 640px)
- **THEN** sidebar becomes drawer overlay
- **AND** navigation adapts to hamburger menu
- **AND** tables become scrollable
- **AND** form layouts stack vertically

#### Scenario: Touch-friendly targets
- **WHEN** interface is used on touch device
- **THEN** all interactive elements are minimum 44x44px
- **AND** spacing prevents accidental taps
- **AND** gestures work as expected (swipe, pinch)
