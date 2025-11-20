# frozen_string_literal: true

# Preview for ButtonComponent variants and states.
# Access at /rails/view_components/button_component in development.
class ButtonComponentPreview < ViewComponent::Preview
  # Primary button variant
  def primary
    render ButtonComponent.new(text: "Primary Button", variant: :primary)
  end

  # Secondary button variant
  def secondary
    render ButtonComponent.new(text: "Secondary Button", variant: :secondary)
  end

  # Danger button variant
  def danger
    render ButtonComponent.new(text: "Delete", variant: :danger)
  end

  # Button with custom classes
  def with_custom_classes
    render ButtonComponent.new(
      text: "Custom Styled",
      variant: :primary,
      classes: "w-full text-lg"
    )
  end

  # Submit type button
  def submit_type
    render ButtonComponent.new(text: "Submit Form", type: "submit", variant: :primary)
  end
end
