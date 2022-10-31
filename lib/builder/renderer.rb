# frozen_string_literal: true

require 'tilt/erb'
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

    def render(layout:, page:, title:, description:)
      @layouts         ||= {}
      @layouts[layout] ||= Tilt::ERBTemplate.new(layout, trim: true)

      @pages       ||= {}
      @pages[page] ||= Tilt::ERBTemplate.new(page, trim: true)

      @layouts[layout].render(
        self,
        title: title,
        description: description,
        content: markdown_render(
          @pages[page].render(self)
        )
      )
    end
  end
end
