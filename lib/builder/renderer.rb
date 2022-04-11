# frozen_string_literal: true

require 'erb'
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

    def render(layout:, page:, title: nil)
      @layouts         ||= {}
      @layouts[layout] ||= ERB.new(File.read(layout), trim_mode: '-')

      @pages       ||= {}
      @pages[page] ||= ERB.new(File.read(page), trim_mode: '-')

      @layouts[layout]
        .result(
          erb_binding do |type|
            case type
            when :title
              title
            else
              markdown_render(
                @pages[page]
                  .result(erb_binding)
              )
            end
          end
        )
    end

    def erb_binding
      binding
    end
  end
end
