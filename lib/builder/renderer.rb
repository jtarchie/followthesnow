# frozen_string_literal: true

require 'kramdown'

module Builder
  # render functions
  module Renderer
    private

    def markdown_render(text)
      Kramdown::Document.new(
        text,
        input: 'GFM',
        gfm_emojis: true,
        hard_wrap: false
      ).to_html
    end

    def render(layout:, page:)
      @layouts ||= {}
      @layouts[layout] ||= ERB.new(File.read(layout), nil, '-')

      @pages ||= {}
      @pages[page] ||= ERB.new(File.read(page), nil, '-')

      @layouts[layout]
        .result(
          erb_binding do
            markdown_render(
              @pages[page]
                .result(erb_binding)
            )
          end
        )
    end

    def erb_binding
      binding
    end
  end
end
