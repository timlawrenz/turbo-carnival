# frozen_string_literal: true

module Base
  class SidebarComponent < ViewComponent::Base
    renders_one :header
    renders_many :sections, "SectionComponent"

    def initialize(width: "w-64")
      @width = width
    end

    private

    def container_classes
      "#{@width} bg-gray-900 border-r border-gray-800 flex flex-col"
    end

    class SectionComponent < ViewComponent::Base
      renders_one :title
      renders_many :items, "ItemComponent"

      class ItemComponent < ViewComponent::Base
        def initialize(href:, active: false, icon: nil)
          @href = href
          @active = active
          @icon = icon
        end

        def call
          link_to @href, class: item_classes do
            concat content_tag(:span, @icon, class: "text-lg") if @icon
            concat content_tag(:span, content, class: "flex-1")
          end
        end

        private

        def item_classes
          base = "flex items-center gap-3 px-4 py-3 text-sm font-medium transition-colors"
          if @active
            "#{base} text-white bg-gray-800 border-l-2 border-blue-500"
          else
            "#{base} text-gray-400 hover:text-white hover:bg-gray-800"
          end
        end
      end
    end
  end
end
