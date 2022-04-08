# frozen_string_literal: true

require 'active_support'
require 'active_support/inflector'
require 'fileutils'
require_relative 'forecast'
require_relative 'prediction'

Page = Struct.new(:build_dir, :fetcher, :source_dir, :resorts, keyword_init: true)

module Builder
  # starts building all the pages
  class Start < Page
    def build!
      FileUtils.mkdir_p(build_dir)
      Dir[File.join(source_dir, '*.rb')].each do |source_filename|
        require_relative source_filename

        klass_name = "builder/#{File.basename(source_filename, '.rb')}".camelize
        klass      = klass_name.constantize
        klass.new(
          build_dir: build_dir,
          fetcher: fetcher,
          resorts: resorts,
          source_dir: source_dir
        ).build!
      end
    end
  end
end

require_relative 'builder/renderer'
require_relative 'builder/slug'
