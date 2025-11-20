# Change: Introduce ViewComponent Architecture for Reusable UI Components

## Why

The application currently uses ERB partials for UI components, which have limitations in terms of testing, encapsulation, and reusability. ViewComponent provides a better architecture for building reusable, testable, and maintainable UI components that can be shared across projects. This aligns with the goal of creating modular, reusable components for the existing image voting, gallery, and pipeline visualization features.

## What Changes

- Add `view_component` gem to the project
- Establish ViewComponent conventions and directory structure in `app/components/`
- Create initial ViewComponents for commonly reused UI patterns:
  - Card component (currently used in run cards)
  - Image display component with fallback (used in voting and gallery)
  - Button variants (primary, secondary, danger)
  - Header/title components
- Convert selected ERB partials to ViewComponents incrementally
- Add testing infrastructure for components using RSpec
- Document component usage and creation patterns in project documentation

## Impact

- **Affected specs**: New capability `ui-components` will be added
- **Affected code**: 
  - `Gemfile` - add view_component gem
  - `app/components/` - new directory for ViewComponents
  - `app/views/runs/_run_card.html.erb` - candidate for conversion
  - `app/views/image_votes/_comparison.html.erb` - candidate for conversion (has duplicated image card pattern)
  - `spec/components/` - new directory for component tests
  - `config/application.rb` - ViewComponent configuration
- **Migration strategy**: Incremental conversion, existing partials remain functional
- **Reusability goal**: Components will be designed for extraction to a shared gem or pack in the future
- **No breaking changes**: Existing views continue to work during migration

## Benefits

1. **Better testing**: Components are Ruby classes that can be unit tested in isolation
2. **Encapsulation**: Logic, templates, and styles are co-located in a component class
3. **Reusability**: Components can be easily shared across projects
4. **Type safety**: Strong contracts through initialize parameters
5. **Performance**: ViewComponent renders ~10x faster than partials
6. **Developer experience**: Better IDE support and refactoring capabilities
