# frozen_string_literal: true

module Builder
  module Slug
    def slug(name)
      name.downcase.gsub(/\W+/, '-')
    end
  end
end
