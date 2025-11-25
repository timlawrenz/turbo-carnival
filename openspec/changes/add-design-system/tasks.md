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

## 2. Base Component Library (75% complete - 9/12 components)
- [x] 2.1 Port Tailwind Plus Catalyst components to Base:: namespace
  - [x] 2.1.1 Base::ButtonComponent (primary, secondary, outline, ghost, warning variants)
  - [x] 2.1.2 Base::InputComponent (text, email, password, etc.)
  - [x] 2.1.3 Base::SelectComponent
  - [x] 2.1.4 Base::TextareaComponent
  - [x] 2.1.5 Base::CheckboxComponent
  - [ ] 2.1.6 Base::RadioComponent (deferred)
  - [x] 2.1.7 Base::CardComponent
  - [x] 2.1.8 Base::BadgeComponent
  - [x] 2.1.9 Base::AlertComponent (info, success, warning, error)
  - [x] 2.1.10 Base::LoadingComponent (spinners, skeletons)
  - [ ] 2.1.11 Base::ModalComponent
  - [ ] 2.1.12 Base::TabsComponent
  - [ ] 2.1.13 Base::TooltipComponent (deferred)
- [x] 2.2 Create Lookbook previews for each Base component (9/9 complete)
  - [x] 2.2.1 Button preview with all variants ✅ /lookbook
  - [x] 2.2.2 Input preview with states (default, error, disabled) ✅ /lookbook
  - [x] 2.2.3 Card preview with various content ✅ /lookbook
  - [x] 2.2.4 Alert preview with all severity levels ✅ /lookbook
  - [x] 2.2.5 Form components previews (Select, Textarea, Checkbox) ✅ /lookbook
  - [x] 2.2.6 Badge preview with all variants ✅ /lookbook
  - [x] 2.2.7 Loading preview with all states ✅ /lookbook
  - [ ] 2.2.8 Modal preview (pending component)
  - [ ] 2.2.9 Tabs preview (pending component)

## 3. Application Shell Components
- [ ] 3.1 Create layout components
  - [ ] 3.1.1 Layout::SidebarComponent (collapsible, responsive)
  - [ ] 3.1.2 Layout::HeaderComponent (with user menu, notifications)
  - [ ] 3.1.3 Layout::NavigationComponent (main nav links)
  - [ ] 3.1.4 Layout::FooterComponent
- [ ] 3.2 Create Lookbook previews for layout components
- [ ] 3.3 Update application.html.erb to use new layout components
- [ ] 3.4 Ensure responsive behavior (mobile, tablet, desktop)

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
