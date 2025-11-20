# frozen_string_literal: true

# Preview for CardComponent variants and layouts.
# Access at /rails/view_components/card_component in development.
class CardComponentPreview < ViewComponent::Preview
  # Basic card with body content only
  def basic
    render CardComponent.new do |c|
      c.with_body do
        content_tag(:p, "This is a basic card with only body content.", class: "text-white")
      end
    end
  end

  # Card with header and body
  def with_header
    render CardComponent.new do |c|
      c.with_header do
        content_tag(:h3, "Card Title", class: "text-white font-bold")
      end
      c.with_body do
        content_tag(:p, "Card content goes here.", class: "text-gray-300")
      end
    end
  end

  # Card with all sections
  def complete
    render CardComponent.new(classes: "shadow-xl") do |c|
      c.with_header do
        content_tag(:h3, "Complete Card", class: "text-white font-bold")
      end
      c.with_body do
        content_tag(:p, "This card has header, body, and footer sections.", class: "text-gray-300")
      end
      c.with_footer do
        content_tag(:div, class: "flex gap-2") do
          content_tag(:button, "Cancel", class: "px-4 py-2 bg-gray-600 text-white rounded") +
          content_tag(:button, "Save", class: "px-4 py-2 bg-blue-600 text-white rounded")
        end
      end
    end
  end

  # Card with custom styling
  def custom_styled
    render CardComponent.new(classes: "shadow-2xl border-2 border-blue-500") do |c|
      c.with_body do
        content_tag(:p, "Custom styled card with additional classes", class: "text-white")
      end
    end
  end
end
