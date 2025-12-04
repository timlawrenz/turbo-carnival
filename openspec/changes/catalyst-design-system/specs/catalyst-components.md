# Catalyst Design System Specification

## Overview

Catalyst is a professional UI kit built with Tailwind CSS, created by the Tailwind team. This spec defines how we adopt Catalyst's design patterns into Rails ViewComponents.

**Key Principle**: Extract design patterns (CSS classes, spacing, colors) from Catalyst's React components and implement them in Rails ViewComponents. No React required.

---

## Design Tokens

### Color Palette

#### Neutrals (Zinc)
```
zinc-50   #fafafa  (lightest - backgrounds)
zinc-100  #f4f4f5
zinc-200  #e4e4e7
zinc-300  #d4d4d8
zinc-400  #a1a1aa  (muted text dark mode)
zinc-500  #71717a  (muted text light mode)
zinc-600  #52525b
zinc-700  #3f3f46
zinc-800  #27272a
zinc-900  #18181b  (dark surfaces)
zinc-950  #09090b  (darkest - text)
```

#### Semantic Colors
```ruby
Primary:   blue-600   (#2563eb)
Danger:    red-600    (#dc2626)
Success:   green-600  (#16a34a)
Warning:   amber-500  (#f59e0b)
Info:      sky-500    (#0ea5e9)
```

#### Button Colors (20+ available)
- Dark/Zinc, Light, Dark/White, Dark, White
- Zinc, Indigo, Cyan, Red, Orange
- Amber, Yellow, Lime, Green, Emerald
- Teal, Sky, Blue, Violet, Purple
- Fuchsia, Pink, Rose

### Typography

#### Font Family
```css
font-family: Inter, system-ui, sans-serif;
font-feature-settings: 'cv11'; /* Inter stylistic variant */
```

#### Font Sizes (with line-height)
```
text-xs/4     0.75rem/1rem
text-sm/5     0.875rem/1.25rem
text-sm/6     0.875rem/1.5rem
text-base/6   1rem/1.5rem
text-base/7   1rem/1.75rem
text-lg/7     1.125rem/1.75rem
text-lg/8     1.125rem/2rem
text-xl/8     1.25rem/2rem
text-2xl/8    1.5rem/2rem
```

#### Font Weights
```
font-normal     400
font-medium     500
font-semibold   600
font-bold       700
```

### Spacing Scale

#### Component Padding
```ruby
# Buttons, inputs (default)
px-3.5 py-2.5          # Desktop
sm:px-3 sm:py-1.5      # Mobile

# Compact variant
px-3 py-1.5

# Relaxed variant  
px-4 py-3

# Card padding
p-6 sm:p-8
```

#### Gaps
```ruby
gap-2    0.5rem   # Tight (icons + text)
gap-4    1rem     # Normal (form fields)
gap-6    1.5rem   # Relaxed (sections)
gap-8    2rem     # Wide (page sections)
```

#### Layout Spacing
```ruby
space-y-3    # Form fields
space-y-6    # Card sections
space-y-8    # Page sections
```

### Shadows

#### Standard Shadows
```ruby
shadow-sm    # Subtle elevation (buttons, cards)
shadow       # Default elevation
shadow-lg    # High elevation (dropdowns, dialogs)
```

#### Optical Shadows (Catalyst technique)
```css
/* Inner highlight for depth */
shadow-[inset_0_1px_theme(colors.white/15%)]

/* Multi-layer button shadows */
before:shadow-sm  /* Optical border layer */
after:shadow-[inset_0_1px_--theme(--color-white/15%)]  /* Inner highlight */
```

### Border Radius

```ruby
rounded-lg     0.5rem   # Buttons, inputs, small cards
rounded-xl     0.75rem  # Large cards, dialogs
rounded-full   9999px   # Avatars, badges
```

### Borders

#### Light Mode
```ruby
border-zinc-950/10    # Standard borders (10% opacity)
border-zinc-950/5     # Subtle borders (5% opacity)
```

#### Dark Mode
```ruby
dark:border-white/10   # Standard borders
dark:border-white/5    # Subtle borders
dark:border-white/15   # Slightly stronger borders
```

---

## Component Patterns

### Button

#### Structure
```ruby
Base classes:
- relative isolate inline-flex items-baseline justify-center
- gap-x-2 rounded-lg border font-semibold
- focus:outline-2 focus:outline-offset-2 focus:outline-blue-500
- disabled:opacity-50 transition-colors

Sizing:
- Small:   px-3 py-1.5 text-sm/6
- Default: px-3.5 py-2.5 text-base/6 sm:px-3 sm:py-1.5 sm:text-sm/6
- Large:   px-4 py-3 text-base/6
```

#### Variants

**Solid (default)**
```ruby
border-transparent shadow-sm
bg-{color}-600 hover:bg-{color}-700 text-white
dark:border-white/5
```

**Outline**
```ruby
border-zinc-950/10 text-zinc-950
hover:bg-zinc-950/2.5
dark:border-white/15 dark:text-white
dark:hover:bg-white/5
```

**Plain**
```ruby
border-transparent text-zinc-950
hover:bg-zinc-950/5
dark:text-white dark:hover:bg-white/10
```

#### Colors
Each color has specific class combinations. Examples:

**Blue (primary)**
```ruby
text-white
bg-blue-600 hover:bg-blue-700
focus:ring-blue-500
```

**Red (danger)**
```ruby
text-white
bg-red-600 hover:bg-red-700
focus:ring-red-500
```

### Input

```ruby
Base:
- block w-full rounded-lg border-0
- bg-white dark:bg-white/5
- px-3 py-2 text-base/6 sm:text-sm/6
- text-zinc-950 dark:text-white

Ring (border):
- ring-1 ring-inset ring-zinc-950/10
- dark:ring-white/10
- focus:ring-2 focus:ring-inset focus:ring-blue-500

States:
- placeholder:text-zinc-500 dark:placeholder:text-zinc-400
- disabled:opacity-50 disabled:cursor-not-allowed
- invalid:ring-red-500
```

### Field (Form Wrapper)

```ruby
Container: space-y-3

Label:
- block text-sm/6 font-medium
- text-zinc-950 dark:text-white

Description:
- text-sm/6 text-zinc-500 dark:text-zinc-400

Error:
- text-sm/6 text-red-600 dark:text-red-400
```

### Card

```ruby
Container:
- bg-white dark:bg-zinc-900
- rounded-xl shadow-sm
- border border-zinc-950/10 dark:border-white/10
- overflow-hidden

Header:
- border-b border-zinc-950/10 dark:border-white/10
- px-6 py-4
- text-lg/7 font-semibold

Body:
- p-6 sm:p-8

Footer:
- border-t border-zinc-950/10 dark:border-white/10
- px-6 py-4
- bg-zinc-50 dark:bg-zinc-950/50
```

### Table

```ruby
Table:
- w-full text-left text-sm/6
- text-zinc-950 dark:text-white

Header:
- bg-zinc-950/[2.5%] dark:bg-white/[2.5%]
- text-zinc-500 dark:text-zinc-400
- font-medium

Header Cell:
- px-4 py-3
- border-b border-zinc-950/10 dark:border-white/10
- first:pl-4 sm:first:pl-6 lg:first:pl-8

Row:
- border-b border-zinc-950/5 dark:border-white/5
- hover:bg-zinc-950/[2.5%] dark:hover:bg-white/[2.5%]

Cell:
- px-4 py-4
- first:pl-4 sm:first:pl-6 lg:first:pl-8
- last:pr-4 sm:last:pr-6 lg:last:pr-8
```

### Badge

```ruby
Base:
- inline-flex items-center gap-x-1.5
- rounded-md px-2 py-1
- text-xs/5 font-medium

Colors (example: Blue):
- bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-600/20
- dark:bg-blue-400/10 dark:text-blue-400 dark:ring-blue-400/20

With dot:
- Add: <svg class="size-1.5 fill-current"><circle cx="3" cy="3" r="3"/></svg>
```

### Avatar

```ruby
Base:
- inline-grid shrink-0 align-middle
- rounded-full bg-zinc-950/5 dark:bg-white/5

Sizes:
- Small:  size-6
- Default: size-8
- Large:  size-10
- XL:     size-12

Image:
- size-full rounded-full object-cover

Initials:
- select-none text-xs/4 font-medium uppercase
- text-zinc-950 dark:text-white

Ring:
- ring-2 ring-white dark:ring-zinc-900
```

### Link

```ruby
Base:
- text-zinc-950 dark:text-white
- hover:underline

Variants:
- Primary: text-blue-600 hover:text-blue-700
- Muted: text-zinc-500 dark:text-zinc-400

With icon:
- inline-flex items-center gap-2
```

### Divider

```ruby
Horizontal:
- w-full border-t border-zinc-950/10 dark:border-white/10

Vertical:
- h-full border-l border-zinc-950/10 dark:border-white/10

With label:
- relative flex items-center
- before:flex-1 before:border-t
- after:flex-1 after:border-t
```

---

## Dark Mode Strategy

### Implementation
Dark mode uses Tailwind's class-based approach:

```html
<html class="dark">
  <!-- All dark: variants activate -->
</html>
```

### Toggle Pattern (Stimulus)
```javascript
// app/javascript/controllers/dark_mode_controller.js
toggle() {
  document.documentElement.classList.toggle('dark')
  localStorage.setItem('theme', 
    document.documentElement.classList.contains('dark') ? 'dark' : 'light'
  )
}
```

### Color Mappings

#### Backgrounds
```ruby
Light: bg-white, bg-zinc-50, bg-zinc-100
Dark:  dark:bg-zinc-900, dark:bg-zinc-950, dark:bg-zinc-800
```

#### Text
```ruby
Light: text-zinc-950 (main), text-zinc-500 (muted)
Dark:  dark:text-white (main), dark:text-zinc-400 (muted)
```

#### Borders
```ruby
Light: border-zinc-950/10
Dark:  dark:border-white/10
```

#### Surfaces (cards, inputs)
```ruby
Light: bg-white
Dark:  dark:bg-zinc-900 or dark:bg-white/5
```

---

## Focus States

### Standard Focus Ring
```ruby
focus:outline-2
focus:outline-offset-2  
focus:outline-blue-500
```

### Keyboard-Only Focus (using data-focus attribute)
```ruby
focus:not-data-focus:outline-hidden
data-focus:outline-2
data-focus:outline-offset-2
data-focus:outline-blue-500
```

Note: Requires Headless UI or custom JavaScript to set `data-focus` attribute.

---

## Accessibility Patterns

### Semantic HTML
- Use proper heading hierarchy (h1 → h2 → h3)
- Use `<button>` for actions, `<a>` for navigation
- Use `<label>` for form fields
- Use `<fieldset>` and `<legend>` for radio groups

### ARIA Attributes
```ruby
# Buttons
aria-label="Descriptive action"
aria-disabled="true" (when disabled)

# Form fields
aria-describedby="field-description"
aria-invalid="true" (when error)
aria-required="true" (when required)

# Dialogs
role="dialog"
aria-modal="true"
aria-labelledby="dialog-title"
```

### Keyboard Navigation
- All interactive elements focusable
- Logical tab order
- Escape closes dialogs/dropdowns
- Arrow keys for menus/selects
- Enter/Space activates buttons

### Color Contrast
All text meets WCAG 2.1 AA:
- Normal text: 4.5:1
- Large text: 3:1
- UI components: 3:1

---

## Responsive Design

### Breakpoints (Tailwind defaults)
```ruby
sm:   640px   # Small tablets
md:   768px   # Tablets
lg:   1024px  # Laptops
xl:   1280px  # Desktops
2xl:  1536px  # Large screens
```

### Mobile-First Patterns
```ruby
# Padding scales down on mobile
px-3.5 py-2.5 sm:px-3 sm:py-1.5

# Tables stack on mobile
block sm:table

# Sidebars collapse
hidden lg:block

# Grid responsive
grid-cols-1 md:grid-cols-2 lg:grid-cols-3
```

---

## ViewComponent Implementation Guidelines

### Component Structure
```ruby
# app/components/catalyst/button_component.rb
class Catalyst::ButtonComponent < ApplicationComponent
  def initialize(variant: :solid, color: :blue, size: :default, **attrs)
    @variant = variant
    @color = color
    @size = size
    @attrs = attrs
  end

  private

  def classes
    [base_classes, variant_classes, color_classes, size_classes, @attrs[:class]]
      .compact.join(' ')
  end
end
```

### Using Slots
```ruby
class Catalyst::CardComponent < ApplicationComponent
  renders_one :header
  renders_one :footer
  
  def initialize(**attrs)
    @attrs = attrs
  end
end
```

```erb
<%= render Catalyst::CardComponent.new do |card| %>
  <% card.with_header do %>
    <h2>Title</h2>
  <% end %>
  
  Content here
  
  <% card.with_footer do %>
    <button>Action</button>
  <% end %>
<% end %>
```

### Testing Pattern
```ruby
# spec/components/catalyst/button_component_spec.rb
RSpec.describe Catalyst::ButtonComponent, type: :component do
  it "renders solid blue button" do
    render_inline(described_class.new(color: :blue)) { "Click me" }
    
    expect(page).to have_button("Click me")
    expect(page).to have_css(".bg-blue-600")
  end
  
  it "renders outline variant" do
    render_inline(described_class.new(variant: :outline)) { "Click me" }
    
    expect(page).to have_css(".border-zinc-950\\/10")
  end
end
```

---

## Migration Checklist

### Per Component
- [ ] Extract Tailwind classes from Catalyst source
- [ ] Create ViewComponent with proper structure
- [ ] Implement variants and colors
- [ ] Add slots where needed
- [ ] Write ViewComponent tests
- [ ] Add to component gallery
- [ ] Document usage examples

### Per View
- [ ] Identify components used
- [ ] Replace with Catalyst equivalents
- [ ] Test interactions (Turbo, forms)
- [ ] Verify dark mode
- [ ] Check mobile responsive
- [ ] Accessibility audit

---

## References

- **Catalyst Docs**: https://catalyst.tailwindui.com/docs
- **Source Code**: `./catalyst-ui-kit.zip`
- **ViewComponent**: https://viewcomponent.org/
- **Tailwind CSS**: https://tailwindcss.com/docs
- **Dark Mode**: https://tailwindcss.com/docs/dark-mode
- **Inter Font**: https://rsms.me/inter/
