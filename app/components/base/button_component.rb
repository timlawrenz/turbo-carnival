# frozen_string_literal: true

# Base button component following Tailwind Plus Catalyst design patterns.
# This is the foundational button component - DO NOT write raw button HTML, use this instead.
#
# @example Primary button
#   <%= render Base::ButtonComponent.new(variant: :primary) do %>
#     Save Changes
#   <% end %>
#
# @example Secondary button with custom classes
#   <%= render Base::ButtonComponent.new(variant: :secondary, class: "mt-4") do %>
#     Cancel
#   <% end %>
#
# @example Button as link
#   <%= render Base::ButtonComponent.new(variant: :outline, href: root_path) do %>
#     Go Home
#   <% end %>
module Base
  class ButtonComponent < ApplicationComponent
    # @param variant [Symbol] the button style variant
    # @param href [String, nil] if provided, renders as <a> tag instead of <button>
    # @param type [String] the button type attribute (button, submit, reset)
    # @param disabled [Boolean] whether the button is disabled
    # @param data [Hash] data attributes for Turbo/Stimulus
    # @param class [String] additional CSS classes to merge
    def initialize(variant: :primary, href: nil, type: "button", disabled: false, data: {}, class: "")
      @variant = variant
      @href = href
      @type = type
      @disabled = disabled
      @data = data
      @custom_classes = binding.local_variable_get(:class)
    end

    private

    def tag_name
      @href ? :a : :button
    end

    def tag_options
      options = {
        class: button_classes,
        disabled: (@disabled if tag_name == :button),
        data: @data
      }.compact

      if @href
        options[:href] = @href
      else
        options[:type] = @type
      end

      options
    end

    def button_classes
      base = "inline-flex items-center justify-center gap-2 rounded-[--radius-md] px-4 py-2 text-sm font-semibold transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
      
      variant_classes = case @variant
      when :primary
        "bg-[--color-primary] text-[--color-primary-foreground] hover:bg-[--color-primary-700] focus-visible:outline-[--color-primary]"
      when :secondary
        "bg-[--color-surface-700] text-white hover:bg-[--color-surface-600] focus-visible:outline-[--color-surface-700]"
      when :outline
        "border border-[--color-surface-300] dark:border-[--color-surface-700] bg-transparent hover:bg-[--color-surface-100] dark:hover:bg-[--color-surface-800] focus-visible:outline-[--color-surface-700]"
      when :ghost
        "bg-transparent hover:bg-[--color-surface-100] dark:hover:bg-[--color-surface-800] focus-visible:outline-[--color-surface-700]"
      when :danger
        "bg-[--color-danger] text-[--color-danger-foreground] hover:bg-[--color-danger-700] focus-visible:outline-[--color-danger]"
      else
        # Default to primary
        "bg-[--color-primary] text-[--color-primary-foreground] hover:bg-[--color-primary-700] focus-visible:outline-[--color-primary]"
      end

      [base, variant_classes, @custom_classes].join(" ").strip
    end
  end
end
