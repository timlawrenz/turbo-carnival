# Change: Adopt Catalyst Design System

## Why

The application currently has inconsistent UI styling with ad-hoc Tailwind classes and minimal ViewComponents. We have a Catalyst UI Kit license (from TailwindUI Plus) which provides a professional, production-ready design system.

**Current Problems:**
1. Inconsistent spacing, colors, and component patterns across views
2. Limited component reusability (only 5 ViewComponents)
3. No standardized design tokens (spacing scale, color palette, shadows)
4. Manual styling leads to visual inconsistencies
5. No dark mode support
6. Accessibility patterns not codified

**The Catalyst Opportunity:**
- Professional design system with 27+ component patterns
- Complete design token system (spacing, colors, typography, shadows)
- Built-in dark mode support
- Accessibility patterns baked in
- Can extract 100% of CSS/design without requiring React
- Uses only Tailwind classes (no custom CSS)

**Why ViewComponents vs React:**
We're extracting Catalyst's *design patterns* (Tailwind classes, spacing, colors) into Rails ViewComponents, NOT migrating to React. This gives us:
- Professional UI with 10% of the complexity
- Keep Rails productivity (Hotwire, Turbo, server rendering)
- Maintain existing architecture
- Get all visual benefits without frontend stack rewrite

## What Changes

### Phase 1: Foundation (Days 1-2)
- **ADD**: Inter font (Catalyst's default) to application layout
- **ADD**: Base Tailwind configuration with Catalyst design tokens
- **ADD**: `app/components/catalyst/` namespace for new components
- **ADD**: Design token constants module (`Catalyst::DesignTokens`)
- **UPDATE**: Application layout with dark mode support structure

### Phase 2: Core Components (Days 3-5)
Build Catalyst-styled ViewComponents:
- **NEW**: `Catalyst::ButtonComponent` - 3 variants (solid, outline, plain), 20+ colors
- **NEW**: `Catalyst::InputComponent` - Text inputs with focus states
- **NEW**: `Catalyst::TextareaComponent` - Multi-line text areas
- **NEW**: `Catalyst::FieldComponent` - Form field wrapper with label/description/error slots
- **NEW**: `Catalyst::CardComponent` - Card with header/body/footer slots
- **NEW**: `Catalyst::BadgeComponent` - Status indicators
- **NEW**: `Catalyst::AvatarComponent` - User profile images
- **NEW**: `Catalyst::DividerComponent` - Horizontal/vertical separators

### Phase 3: Data Display (Days 6-7)
- **NEW**: `Catalyst::TableComponent` - Tables with hover states
- **NEW**: `Catalyst::TableRowComponent` - Table row wrapper
- **NEW**: `Catalyst::DescriptionListComponent` - Key-value pairs
- **NEW**: `Catalyst::HeadingComponent` - H1-H6 with consistent sizing

### Phase 4: Navigation & Layout (Days 8-9)
- **NEW**: `Catalyst::LinkComponent` - Styled links
- **NEW**: `Catalyst::NavbarComponent` - Top navigation
- **NEW**: `Catalyst::SidebarLayoutComponent` - App shell with sidebar
- **NEW**: `Catalyst::StackedLayoutComponent` - Full-width layout

### Phase 5: Migration (Days 10-12)
- **REPLACE**: Existing `ButtonComponent` with `Catalyst::ButtonComponent`
- **REPLACE**: Existing `CardComponent` with `Catalyst::CardComponent`
- **UPDATE**: All views to use new Catalyst components
- **UPDATE**: Comparison view, voting cards, image display with Catalyst styling
- **ADD**: Storybook or component preview page (optional)

### Phase 6: Advanced (Future - Optional)
- **NEW**: `Catalyst::DialogComponent` - Modals/dialogs
- **NEW**: `Catalyst::DropdownComponent` - Dropdown menus
- **NEW**: `Catalyst::AlertComponent` - Notification messages
- **NEW**: `Catalyst::SelectComponent` - Custom select dropdowns
- **NEW**: `Catalyst::CheckboxComponent` - Custom checkboxes
- **NEW**: `Catalyst::RadioComponent` - Custom radio buttons
- **NEW**: `Catalyst::SwitchComponent` - Toggle switches

**No Breaking Changes** - Migration is gradual. Old components can coexist with new ones.

## Impact

### Design System Components
All components will follow Catalyst patterns:
- **Spacing**: Consistent padding/margin scale using Catalyst tokens
- **Colors**: Zinc-based neutrals for light/dark mode
- **Shadows**: Multi-layer shadow system (optical borders, inset highlights)
- **Focus States**: Blue outline with offset, keyboard-only focus
- **Dark Mode**: All components support dark mode via `dark:` classes
- **Typography**: Inter font with proper line heights and weights

### Affected Files
**New Files:**
- `app/components/catalyst/*.rb` (15-20 new components)
- `app/components/catalyst/*.html.erb` (matching templates)
- `app/components/catalyst/design_tokens.rb`
- `app/assets/stylesheets/catalyst.css` (optional overrides)

**Modified Files:**
- `app/views/layouts/application.html.erb` - Add Inter font, dark mode class
- `app/assets/stylesheets/application.tailwind.css` - Base configuration
- All view files (gradual migration to new components)

**Deprecated (Eventually):**
- `app/components/button_component.rb` → Replaced by `Catalyst::ButtonComponent`
- `app/components/card_component.rb` → Replaced by `Catalyst::CardComponent`

### Example Transformations

**Before:**
```erb
<%= render ButtonComponent.new(text: "Submit", variant: :primary, classes: "mt-4") %>
```

**After:**
```erb
<%= render Catalyst::ButtonComponent.new(color: :blue, class: "mt-4") do %>
  Submit
<% end %>
```

**Before:**
```erb
<div class="bg-white rounded-lg shadow p-4">
  <h2 class="text-lg font-bold mb-2">Card Title</h2>
  <p>Content here</p>
</div>
```

**After:**
```erb
<%= render Catalyst::CardComponent.new do |card| %>
  <% card.with_header do %>
    <h2>Card Title</h2>
  <% end %>
  <p>Content here</p>
<% end %>
```

## Migration Path

### Compatibility Strategy
1. **Namespace separation**: New components under `Catalyst::` namespace
2. **Gradual adoption**: Old and new components coexist
3. **No forced migration**: Update views incrementally
4. **Backward compatible**: Old components continue working

### Rollout Plan
1. ✅ Build all Catalyst components (Week 1-2)
2. ✅ Create component gallery/preview page
3. ✅ Migrate one page as proof of concept (Personas index)
4. ✅ Team review and feedback
5. ✅ Migrate remaining pages incrementally
6. ✅ Deprecate old components once all views migrated
7. ✅ Remove old components (optional, can keep for reference)

### Dark Mode Support
- Add dark mode toggle to layout (Stimulus controller)
- Toggle adds/removes `dark` class on `<html>`
- All Catalyst components support dark mode automatically
- Existing views remain light-only until migrated

### Testing Strategy
- ViewComponent tests for all new components
- Visual regression testing (optional, using Percy or similar)
- Accessibility testing (axe-core)
- Browser testing (Chrome, Firefox, Safari)

## Design Token Reference

### Colors
```ruby
# Neutrals (zinc)
zinc-50, zinc-100, ..., zinc-900, zinc-950

# Semantic
primary: blue-600
danger: red-600  
success: green-600
warning: amber-500
info: sky-500

# Text
Light mode: zinc-950 (main), zinc-500 (muted)
Dark mode: white (main), zinc-400 (muted)
```

### Spacing
```ruby
# Standard component padding
Default: px-3.5 py-2.5 (desktop), px-3 py-1.5 (mobile)
Compact: px-3 py-1.5
Relaxed: px-4 py-3

# Gaps
Tight: gap-2
Normal: gap-4  
Relaxed: gap-6
```

### Shadows
```ruby
Subtle: shadow-sm
Default: shadow
Elevated: shadow-lg
Optical border: shadow-[inset_0_1px_theme(colors.white/15%)]
```

### Typography
```ruby
Font: Inter (with cv11 feature)
Sizes: text-sm/6, text-base/6, text-lg/7 (size/line-height)
Weights: font-medium (500), font-semibold (600)
```

### Border Radius
```ruby
Standard: rounded-lg
Cards: rounded-xl
Inputs: rounded-lg
```

## Success Criteria

1. ✅ All 15+ core Catalyst components built and tested
2. ✅ Design token system documented and consistent
3. ✅ At least one complete page migrated (proof of concept)
4. ✅ Dark mode working on migrated pages
5. ✅ Component gallery/documentation page created
6. ✅ No visual regressions on existing pages
7. ✅ All components pass accessibility audit
8. ✅ ViewComponent tests for all new components

## Timeline

- **Days 1-2**: Foundation (fonts, tokens, namespace)
- **Days 3-5**: Core components (Button, Input, Field, Card, Badge)
- **Days 6-7**: Data display (Table, DescriptionList, Heading)
- **Days 8-9**: Navigation & layout (Link, Navbar, Sidebar)
- **Days 10-12**: Migration (replace old components, update views)

**Total: ~12 days** for complete design system adoption

## Risk Assessment

**Low Risk** ✅
- No architectural changes
- No dependency changes
- Gradual migration path
- Can roll back per-component
- Old components remain functional

**Medium Risk** ⚠️
- Visual changes may surprise users (mitigate: migrate incrementally)
- Developer learning curve (mitigate: component gallery + docs)

**No Risk** ❌
- No data migrations
- No API changes
- No breaking changes

## Future Enhancements

After core adoption:
1. Advanced components (Dialog, Dropdown, Alert)
2. Form components (Select, Checkbox, Radio, Switch)
3. Animation system (Stimulus + CSS transitions)
4. Component composition patterns
5. Responsive navigation (mobile menu)
6. Loading states and skeletons
7. Toast notifications
8. Breadcrumb navigation

## References

- Catalyst Documentation: https://catalyst.tailwindui.com/docs
- Catalyst Demo: https://catalyst-demo.tailwindui.com/
- Downloaded Kit: `./catalyst-ui-kit.zip`
- ViewComponent Docs: https://viewcomponent.org/
