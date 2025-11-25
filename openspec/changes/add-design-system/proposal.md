# Change: Add Design System for App-Like Interface

## Why
The application is growing beyond its initial scope and needs a professional, scalable design system. Current components are ad-hoc with inconsistent styling patterns. As the project expands to support more features and better navigation, we need a foundation that enables rapid, consistent UI development while maintaining accessibility and professional aesthetics.

## What Changes
- Upgrade to Tailwind CSS v4 with CSS-first configuration using `@theme` blocks
- Install Lookbook for component development and documentation
- Create a Base component library from Tailwind Plus Catalyst UI kit
- Establish `DESIGN_SYSTEM.md` documentation for AI-assisted development (generic, not tool-specific)
- Create application shell components (navigation, sidebar, header)
- Define design tokens (colors, typography, spacing, radii) as CSS variables
- Port existing components to follow new design system patterns
- Update `AGENTS.md` with design system conventions for AI assistants

## Impact
- **Affected specs:** Creates new `ui-design-system` capability
- **Affected code:** 
  - `app/assets/stylesheets/` - Tailwind v4 configuration
  - `app/components/` - New Base:: namespace, refactored existing components
  - `app/components/button_component.rb` - Deprecated, replaced by Base::ButtonComponent
  - `app/components/card_component.rb` - Deprecated, replaced by Base::CardComponent
  - `app/components/voting_card_component.rb` - Refactored to use Base components
  - `app/components/comparison_view_component.rb` - Refactored to use Base components
  - `app/components/image_display_component.rb` - Refactored to use Base components
  - `Gemfile` - Add lookbook gem
  - `AGENTS.md` - Add design system instructions
  - `DESIGN_SYSTEM.md` - New file for design documentation
- **Breaking:** Minor - existing components continue to work but will be gradually migrated
- **User impact:** Improved visual consistency, better navigation, more app-like feel
- **Note:** Existing ButtonComponent and CardComponent already follow good patterns (variants, slots) which will be preserved in Base implementations
