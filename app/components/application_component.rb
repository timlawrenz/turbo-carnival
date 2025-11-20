# frozen_string_literal: true

# Base class for all ViewComponents in the application.
#
# All components should inherit from this class to gain common functionality
# and maintain consistent patterns across the component library.
#
# @example Creating a new component
#   class MyComponent < ApplicationComponent
#     def initialize(title:)
#       @title = title
#     end
#   end
#
# @see https://viewcomponent.org/guide/
class ApplicationComponent < ViewComponent::Base
end
