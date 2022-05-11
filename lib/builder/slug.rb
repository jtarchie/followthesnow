# frozen_string_literal: true

require 'active_support'
require 'active_support/inflector'

module Builder
  module Slug
    def slug(name)
      name.parameterize
    end
  end
end
