# Implementation Tasks

## 1. Foundation Setup
- [x] 1.1 Upgrade to Tailwind CSS v4
  - [x] 1.1.1 Update tailwindcss gem/npm package
  - [x] 1.1.2 Migrate tailwind.config.js to CSS `@theme` blocks
  - [x] 1.1.3 Test existing styles still work
- [x] 1.2 Install and configure Lookbook
  - [x] 1.2.1 Add lookbook gem to Gemfile
  - [x] 1.2.2 Create lookbook configuration
  - [x] 1.2.3 Mount lookbook routes (development only)
- [x] 1.3 Define design tokens in CSS
  - [x] 1.3.1 Create `app/assets/stylesheets/design-tokens.css`
  - [x] 1.3.2 Define color palette (primary, surface, semantic colors)
  - [x] 1.3.3 Define typography scale (font families, sizes, weights)
  - [x] 1.3.4 Define spacing scale
  - [x] 1.3.5 Define border radii
  - [x] 1.3.6 Define shadows and elevations

## 2. Base Component Library ✅ COMPLETE (12/12 components - 100%)
- [x] 2.1 Port Tailwind Plus Catalyst components to Base:: namespace
  - [x] 2.1.1 Base::ButtonComponent (primary, secondary, outline, ghost, warning, danger variants)
  - [x] 2.1.2 Base::InputComponent (text, email, password, with validation states)
  - [x] 2.1.3 Base::SelectComponent (with validation states, multiple options support)
  - [x] 2.1.4 Base::TextareaComponent (with validation states, configurable rows)
  - [x] 2.1.5 Base::CheckboxComponent (with validation states, labels)
  - [x] 2.1.6 Base::CardComponent (with header, footer, interactive variants)
  - [x] 2.1.7 Base::BadgeComponent (info, success, warning, error, neutral variants + sizes)
  - [x] 2.1.8 Base::AlertComponent (info, success, warning, error with icons)
  - [x] 2.1.9 Base::LoadingComponent (spinner, skeleton, dots variants + sizes)
  - [x] 2.1.10 Base::ModalComponent (5 sizes, header/footer slots, backdrop)
  - [x] 2.1.11 Base::TabsComponent (active states, hover effects, icon support)
  - [x] 2.1.12 Base::TooltipComponent (4 positions, pure CSS, arrow pointer)
- [x] 2.2 Create Lookbook previews for each Base component (12/12 complete)
  - [x] 2.2.1 Button preview with all variants ✅ /lookbook
  - [x] 2.2.2 Input preview with states (default, error, disabled) ✅ /lookbook
  - [x] 2.2.3 Card preview with various content ✅ /lookbook
  - [x] 2.2.4 Alert preview with all severity levels ✅ /lookbook
  - [x] 2.2.5 Form components previews (Select, Textarea, Checkbox) ✅ /lookbook
  - [x] 2.2.6 Badge preview with all variants ✅ /lookbook
  - [x] 2.2.7 Loading preview with all states ✅ /lookbook
  - [x] 2.2.8 Modal preview (default, with footer, all sizes, form example) ✅ /lookbook
  - [x] 2.2.9 Tabs preview (default, with icons, many tabs) ✅ /lookbook
  - [x] 2.2.10 Tooltip preview (all positions, with buttons, with icons) ✅ /lookbook

## 3. Application Shell Components ✅ COMPLETE (100%)
- [x] 3.1 Create layout components
  - [x] 3.1.1 Base::NavbarComponent (top navigation, logo, items, actions, mobile menu)
  - [x] 3.1.2 Base::SidebarComponent (sections, items with icons, header, collapsible)
  - [x] 3.1.3 Base::LayoutComponent (wrapper combining navbar + sidebar + main + footer)
  - [x] 3.1.4 Base::FooterComponent (sections with links, bottom slot)
- [x] 3.2 Create Lookbook previews for layout components
  - [x] 3.2.1 Navbar preview (default, with actions, minimal) ✅ /lookbook
  - [x] 3.2.2 Sidebar preview (default, minimal) ✅ /lookbook
  - [x] 3.2.3 Layout preview (full layout, without sidebar, full width) ✅ /lookbook
  - [x] 3.2.4 Footer preview (default, minimal, two columns) ✅ /lookbook
- [x] 3.3 Create RSpec tests for layout components
  - [x] 3.3.1 Navbar component spec (6 tests)
  - [x] 3.3.2 Sidebar component spec (3 tests)
  - [x] 3.3.3 Footer component spec (2 tests)
  - [x] 3.3.4 Layout component spec (6 tests)
- [x] 3.4 Ensure responsive behavior (mobile, tablet, desktop)
  - [x] 3.4.1 Mobile menu toggle with Stimulus controller
  - [x] 3.4.2 Responsive navbar (hidden menu on mobile, visible on md+)
  - [x] 3.4.3 Collapsible sidebar (hidden on mobile, visible on lg+)
  - [x] 3.4.4 Responsive footer grid (1 col on mobile, 2 on md, 4 on lg)
- [ ] 3.5 Apply layout to application
  - [ ] 3.5.1 Update app/views/layouts/application.html.erb to use Base components
  - [ ] 3.5.2 Test all existing pages render correctly with new layout

## 4. Documentation
- [ ] 4.1 Create DESIGN_SYSTEM.md
  - [ ] 4.1.1 Document CSS variable usage
  - [ ] 4.1.2 Document Base component inventory
  - [ ] 4.1.3 Document composition patterns
  - [ ] 4.1.4 Document accessibility requirements
  - [ ] 4.1.5 Provide examples of building features with Base components
- [ ] 4.2 Create docs/design-system/inspiration/ with Tailwind Plus references
  - [ ] 4.2.1 Document sidebar layout patterns (screenshots/goals)
  - [ ] 4.2.2 Document navigation patterns
  - [ ] 4.2.3 Document form layout examples
  - [ ] 4.2.4 Document data display patterns (tables, cards, lists)
  - [ ] 4.2.5 Create component inventory checklist
- [ ] 4.3 Update AGENTS.md with design system instructions
  - [ ] 4.3.1 Add section on UI component generation
  - [ ] 4.3.2 Document Base:: component usage rules
  - [ ] 4.3.3 Add semantic color usage guidelines
  - [ ] 4.3.4 Add reference to Tailwind Plus inspiration docs
  - [ ] 4.3.5 Keep instructions generic (not tool-specific)

## 5. Component Migration (50% complete)
- [x] 5.1 Audit existing components (COMPLETED - see design.md)
  - [x] 5.1.1 List all components in app/components/
  - [x] 5.1.2 Categorize: keep as-is, refactor to use Base, replace
  - [x] 5.1.3 Document migration path for each component
- [x] 5.2 Refactor existing components to use Base components
  - [x] 5.2.1 VotingCardComponent (uses Base::Button) ✅
  - [x] 5.2.2 Migrate all buttons in views to Base::ButtonComponent ✅
  - [x] 5.2.3 Migrate all badges to Base::BadgeComponent ✅
  - [x] 5.2.4 Migrate all cards to Base::CardComponent ✅
  - [ ] 5.2.5 Migrate forms to use Base::Input/Select/Textarea
  - [ ] 5.2.6 Deprecate old ButtonComponent/CardComponent
- [ ] 5.3 Update component specs to use RSpec (currently test/components/)

## 6. Testing
- [ ] 6.1 Add component specs for Base components
  - [ ] 6.1.1 Test rendering with various props
  - [ ] 6.1.2 Test variant classes applied correctly
  - [ ] 6.1.3 Test accessibility attributes
- [ ] 6.2 Add visual regression tests (optional, future enhancement)
- [ ] 6.3 Verify no N+1 queries in components that fetch data

## 7. Integration & Polish
- [ ] 7.1 Update all views to use new layout components
- [ ] 7.2 Ensure dark mode support across all components
- [ ] 7.3 Test responsive behavior on mobile/tablet/desktop
- [ ] 7.4 Run linters and fix any issues
- [ ] 7.5 Update README with Lookbook usage instructions
