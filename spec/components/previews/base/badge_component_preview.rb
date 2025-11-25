# frozen_string_literal: true

# @label Base/Badge
class Base::BadgeComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render ::Base::BadgeComponent.new do
      "Badge"
    end
  end

  # @label All Variants
  def all_variants
    render_with_template
  end

  # @label All Sizes
  def all_sizes
    render_with_template
  end

  # @label Status Examples
  def status_examples
    render_with_template
  end
end
