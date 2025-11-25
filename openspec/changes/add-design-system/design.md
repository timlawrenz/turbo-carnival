## Context
The application currently has a minimal UI with ad-hoc component styling. As we scale to support more features and build an app-like interface, we need a systematic approach to UI development. This design system will serve as the foundation for all future UI work.

**Background:**
- Existing components lack consistency in styling patterns
- No centralized design token system
- Component development is time-consuming and error-prone
- AI-assisted component generation produces inconsistent results

**Constraints:**
- Must maintain existing functionality during migration
- Need to support accessibility standards (WCAG)
- Should enable rapid AI-assisted development
- Must work with existing ViewComponent architecture

## Goals / Non-Goals

**Goals:**
- CSS-first design system using Tailwind v4 `@theme` blocks
- High-quality Base component library from Tailwind Plus Catalyst
- Component development environment with Lookbook
- Clear documentation for AI-assisted development (tool-agnostic)
- Responsive, accessible, app-like interface
- Dark mode support

**Non-Goals:**
- Not replacing ViewComponent architecture (building on top of it)
- Not creating custom CSS framework (using Tailwind utilities)
- Not implementing visual regression testing in this phase (future enhancement)
- Not migrating all existing components immediately (gradual migration)
- Not tool-specific AI instructions (keeping AGENTS.md generic)

## Decisions

### Decision 1: Tailwind CSS v4 with @theme blocks
**What:** Move from tailwind.config.js to CSS-first configuration using `@theme` blocks in stylesheets.

**Why:**
- CSS variables are native and well-understood by AI models
- No config file compilation step
- Better integration with standard CSS tooling
- Cleaner separation of design tokens from build config

**Alternatives considered:**
- Keep Tailwind v3 config file → Rejected: CSS-first is the future direction, better for AI
- Use vanilla CSS variables without Tailwind → Rejected: Lose utility-first benefits

**Implementation:**
```css
@import "tailwindcss";

@theme {
  --color-primary: #3b82f6;
  --color-primary-foreground: #ffffff;
  --radius-md: 0.375rem;
}
```

### Decision 2: Base:: Component Namespace
**What:** Create `app/components/base/` namespace for foundational atomic components.

**Why:**
- Clear separation between "source of truth" components and feature components
- Prevents accidental modification of foundational components
- Establishes convention: `Base::ButtonComponent` vs `Dashboard::ActionButtonComponent`
- AI can be instructed to always use Base components for primitives

**Alternatives considered:**
- Flat namespace → Rejected: Leads to naming confusion
- UI:: namespace → Rejected: Less semantic than Base::

**Implementation:**
```ruby
# app/components/base/button_component.rb
class Base::ButtonComponent < ViewComponent::Base
  # ...
end
```

### Decision 3: Lookbook for Component Development
**What:** Install Lookbook gem for component preview and documentation.

**Why:**
- Storybook-like experience for Rails
- Isolated component development
- Living documentation
- Better DX for designers and developers

**Alternatives considered:**
- Build custom preview system → Rejected: Reinventing the wheel
- Use Storybook with Rails → Rejected: Awkward integration, Lookbook is Rails-native

### Decision 4: Generic AGENTS.md Instead of Tool-Specific Instructions
**What:** Add design system instructions to AGENTS.md rather than creating `.github/copilot-instructions.md`.

**Why:**
- Project uses multiple AI tools (Gemini, Copilot, etc.)
- Instructions should be tool-agnostic
- AGENTS.md already exists as the central AI instruction file
- Avoids vendor lock-in

**Implementation:**
- Add "UI Component Generation" section to AGENTS.md
- Document Base:: component usage patterns
- Provide examples of composing features from Base components
- Keep language generic (not Copilot-specific)

### Decision 5: Port Tailwind Plus Catalyst, Not Custom Build
**What:** Use Tailwind Plus Catalyst UI kit as the foundation for Base components.

**Why:**
- Production-grade accessibility built-in
- Professional visual design
- Saves significant development time
- Maintained by Tailwind team

**Alternatives considered:**
- Build from scratch → Rejected: Time-consuming, likely to have accessibility gaps
- Use shadcn/ui → Rejected: React-focused, difficult to port to Rails
- Use other Rails UI kit → Rejected: None have the quality and ecosystem of Tailwind Plus

**Migration Path:**
1. Access Tailwind Plus (user has active subscription)
2. Review application-ui blocks for patterns and layouts
3. Document key patterns in docs/design-system/inspiration/
4. Extract component patterns (not exact HTML) as reference
5. Implement Base components using patterns as guidance
6. Adapt HTML structure to ViewComponent conventions (slots, etc.)
7. Add Lookbook previews
8. Test accessibility

**Usage Rights:**
- User has paid Tailwind Plus subscription with full rights to use content
- Will adapt patterns to Rails/ViewComponent architecture
- Focus on layout strategies and component patterns, not verbatim copying
- Store reference examples in docs/design-system/inspiration/ for context

### Decision 6: Gradual Component Migration Strategy
**What:** Don't force-migrate all existing components immediately. Allow gradual adoption.

**Why:**
- Reduces risk of breaking existing functionality
- Allows learning from early migrations
- Enables iterative improvement
- No big-bang deployment

**Implementation:**
1. Create Base components first
2. New features use Base components from day one
3. Refactor existing components as they need changes
4. Deprecation markers on old components (comments)
5. Eventually remove deprecated components

## Risks / Trade-offs

### Risk: Tailwind v4 Migration Complexity
**Risk:** Upgrading from v3 to v4 might break existing styles.
**Mitigation:** 
- Keep existing classes working during migration
- Test thoroughly with existing components
- Have rollback plan (keep v3 config in git history)

### Risk: Lookbook Performance
**Risk:** Lookbook might slow down development environment.
**Mitigation:**
- Mount only in development
- Lazy-load previews
- Monitor boot time and iteration speed

### Risk: Over-Abstraction
**Risk:** Base components might become too generic or complex.
**Mitigation:**
- Follow "Rule of Three" - only abstract after 3 uses
- Keep Base components simple with sensible defaults
- Use slots for composition, not complex prop APIs

### Risk: Design System Adoption
**Risk:** Developers might bypass Base components and write custom HTML.
**Mitigation:**
- Document in AGENTS.md for AI assistants
- Code review enforcement
- Make Base components easy and delightful to use

## Migration Plan

### Phase 1: Foundation (This proposal)
1. Install Tailwind v4 and Lookbook
2. Define design tokens in CSS
3. Create first 5 Base components (Button, Card, Input, Badge, Alert)
4. Update AGENTS.md and create DESIGN_SYSTEM.md
5. Verify existing functionality still works

### Phase 2: Expansion (Future)
1. Complete remaining Base components
2. Create Layout components
3. Refactor 2-3 existing components as proof-of-concept
4. Update application layout

### Phase 3: Migration (Future)
1. Systematically refactor remaining components
2. Update all views to use new layouts
3. Remove deprecated components
4. Add visual regression tests

### Rollback Plan
If major issues arise:
1. Revert Tailwind v4 → v3 (keep config in git)
2. Remove Lookbook gem
3. Keep Base components (they work with v3 too)
4. Continue using existing components

### Testing Strategy
- Unit tests for Base component rendering
- Accessibility tests using axe-core (future)
- Visual tests in Lookbook (manual)
- Integration tests for existing features (ensure no regression)

## Existing Component Audit

### Current Components (app/components/)
1. **ButtonComponent** - Has variant support (:primary, :secondary, :danger)
   - Status: Will be replaced by Base::ButtonComponent
   - Migration: Deprecate, update all usages to Base::Button
   
2. **CardComponent** - Good slots pattern (header, body, footer)
   - Status: Will be replaced by Base::CardComponent  
   - Migration: Port existing slot structure to Base, update usages
   - Note: Already follows best practices with renders_one

3. **VotingCardComponent** - Feature component for voting interface
   - Status: Keep as feature component
   - Migration: Refactor to use Base::Card and Base::Button internally
   
4. **ComparisonViewComponent** - Feature component for A vs B comparison
   - Status: Keep as feature component
   - Migration: Refactor to use Base components internally
   
5. **ImageDisplayComponent** - Feature component for image rendering
   - Status: Keep as feature component
   - Migration: Refactor to use Base::Card or similar

### Migration Strategy
- **Atomic components** (Button, Card) → Move to Base:: namespace
- **Feature components** (VotingCard, ComparisonView) → Refactor to compose Base components
- Preserve good patterns (slots, variants) in Base implementation
- Add deprecation comments to old components during migration

## Open Questions
1. ~~**Tailwind Plus Access**: Confirm credentials/access to Tailwind Plus Catalyst UI kit~~ ✓ RESOLVED: User has active paid subscription
2. **Reference Material Format**: Should we store screenshots, HTML snippets, or just pattern descriptions from Tailwind Plus?
3. **Icon Library**: Should we use Heroicons (Tailwind default) or continue with current approach?
4. **Dark Mode Strategy**: System preference, toggle, or both?
5. **Component Versioning**: How do we handle breaking changes to Base components?
6. **Existing Component Patterns**: Should Base::CardComponent preserve exact slot structure from current CardComponent?
