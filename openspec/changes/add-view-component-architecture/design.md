# Design: ViewComponent Architecture

## Context

The application currently uses traditional Rails ERB partials for reusable UI elements. While functional, this approach has limitations for testing, encapsulation, and cross-project reusability. The application uses Tailwind CSS for styling and Hotwire (Turbo/Stimulus) for interactivity.

**Current patterns observed:**
- Duplicated image card markup in `_comparison.html.erb` (same structure repeated for left/right images)
- Nested partials with implicit dependencies (run_card → run_card_content)
- Limited ability to test UI logic in isolation
- No formal component API or documentation

**Goals of this change:**
- Improve UI code maintainability and testability
- Enable component reuse across this and future projects
- Maintain compatibility with existing Turbo Frames and Stimulus controllers
- Establish patterns for future component development

## Goals / Non-Goals

### Goals
- Introduce ViewComponent gem with minimal disruption
- Create 4-6 foundational components based on current UI patterns
- Establish testing patterns for components
- Enable component previews for development workflow
- Document component creation and usage patterns
- Design components for future extraction to shared library

### Non-Goals
- Convert all existing partials (incremental migration preferred)
- Change existing UI/UX design or styling
- Replace Turbo/Stimulus functionality
- Create a complex design system (start simple)
- Extract to external gem immediately (prepare for future extraction)

## Decisions

### Component Organization
**Decision**: Use `app/components/` directory with component class + template co-location

**Structure**:
```
app/components/
├── application_component.rb          # Base class
├── button_component.rb               # Generic button with variants
├── button_component.html.erb
├── card_component.rb                 # Generic card container
├── card_component.html.erb
├── image_display_component.rb        # Image with fallback
├── image_display_component.html.erb
├── voting_card_component.rb          # Domain-specific
└── voting_card_component.html.erb
```

**Rationale**: 
- ViewComponent convention, good IDE support
- Clear 1:1 mapping between class and template
- Easier to extract to gem later (self-contained units)

**Alternatives considered**:
- Nested directories by domain (`app/components/voting/`, `app/components/gallery/`) - Rejected: Premature organization, only a few components initially
- Include CSS in sidecar files - Rejected: Tailwind utility classes work well inline

### Component API Design
**Decision**: Use keyword arguments with explicit defaults and documentation

**Example**:
```ruby
class ButtonComponent < ApplicationComponent
  # @param text [String] button label
  # @param variant [Symbol] style variant (:primary, :secondary, :danger)
  # @param classes [String] additional CSS classes
  def initialize(text:, variant: :primary, classes: "")
    @text = text
    @variant = variant
    @classes = classes
  end
end
```

**Rationale**:
- Clear API surface for reusability
- Type hints improve documentation
- Enables validation and error messages
- Easy to extract to gem with stable API

### Testing Strategy
**Decision**: Use RSpec with ViewComponent test helpers

**Pattern**:
```ruby
RSpec.describe ButtonComponent, type: :component do
  it "renders primary variant" do
    render_inline(ButtonComponent.new(text: "Click", variant: :primary))
    expect(page).to have_css("button.bg-blue-600")
  end
end
```

**Rationale**:
- Matches existing test infrastructure (RSpec)
- ViewComponent provides excellent test helpers
- Fast unit tests without full integration overhead
- Can test edge cases (nil values, long text, etc.)

### Preview Configuration
**Decision**: Enable ViewComponent previews for development

**Location**: `test/components/previews/` (ViewComponent default)

**Rationale**:
- Visual testing during development
- Living documentation of component variants
- Accessible at `/rails/view_components` in development
- Supports design iteration without running full app

### Incremental Migration Strategy
**Decision**: Convert high-value duplicated patterns first, leave simple partials alone

**Priority order**:
1. Duplicated image voting cards (highest duplication)
2. Button patterns (used across forms)
3. Card containers (generic utility)
4. Other partials as needed

**Rationale**:
- Deliver value quickly (reduce duplication)
- Learn patterns before mass conversion
- Avoid disrupting working code
- Build confidence with team

### Compatibility with Turbo/Stimulus
**Decision**: Components render standard HTML, remain compatible with Turbo Frames and Stimulus

**Pattern**:
```erb
<!-- Component can include Turbo/Stimulus attributes -->
<%= turbo_frame_tag dom_id(@run) do %>
  <%= render CardComponent.new(...) %>
<% end %>
```

**Rationale**:
- ViewComponent is view-layer only, doesn't conflict
- Components can accept Turbo/Stimulus data attributes as parameters
- Maintains existing interactivity patterns

## Risks / Trade-offs

### Risk: Team Learning Curve
**Mitigation**: 
- Start with simple components
- Provide clear documentation and examples
- Use component previews for experimentation
- Pair on initial components

### Risk: Over-Engineering
**Mitigation**:
- Start with 4-6 components only
- Avoid premature abstraction (no "BaseCardComponent" until 3+ card types)
- Convert existing patterns, don't invent new ones
- Measure: component should be used 2+ times to justify creation

### Trade-off: More Files
**Impact**: Each component = 2+ files (class, template, test, preview)
**Justification**: Better organization and testability outweigh file count

### Trade-off: Initial Setup Time
**Impact**: ~4-8 hours for setup + initial components
**Justification**: Long-term maintenance savings and reusability benefits

## Migration Plan

### Phase 1: Setup (Week 1)
1. Add gem and configuration
2. Create ApplicationComponent base class
3. Set up testing and preview infrastructure
4. Document component creation process

### Phase 2: Foundation Components (Week 1-2)
1. ButtonComponent (simple, high usage)
2. CardComponent (containers)
3. ImageDisplayComponent (domain-specific but reusable)

### Phase 3: Domain Components (Week 2-3)
1. VotingCardComponent (encapsulate voting pattern)
2. Convert `_comparison.html.erb` to use components
3. Update tests and verify functionality

### Phase 4: Documentation & Future Planning (Week 3)
1. Complete documentation
2. Document extraction strategy for gem
3. Identify next candidates for conversion

### Rollback Plan
If major issues arise:
1. Components are additive, can be removed without breaking existing partials
2. Revert Gemfile and bundle
3. Remove `app/components/` directory
4. Restore original partial usage in views

No database migrations or data changes, so rollback is simple.

## Open Questions

1. **Component naming convention**: Should we suffix all with `Component` or use shorter names?
   - **Recommendation**: Use `Component` suffix for clarity (matches ViewComponent convention)

2. **Tailwind class organization**: Inline in ERB or use component methods?
   - **Recommendation**: Start inline, extract to methods if patterns emerge

3. **Future extraction**: Create as separate gem or use packwerk pack?
   - **Recommendation**: Design for gem extraction (more portable), decide later based on needs

4. **Stimulus integration**: Should components provide their own Stimulus controllers?
   - **Recommendation**: Not initially. Keep components as pure view layer, add interactivity separately if needed

5. **Icon system**: How should we handle icons in components?
   - **Recommendation**: Pass as content blocks or emoji for now, revisit if icon library needed
