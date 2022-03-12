# frozen_string_literal: true

require 'active_support'
require 'active_support/inflector'
require 'erb'
require 'fileutils'
require 'terminal-table'
require_relative 'forecast'
require_relative 'prediction'

Page = Struct.new(:build_dir, :fetcher, :source_dir, :resorts, keyword_init: true)

module Builder
  # starts building all the pages
  class Start < Page
    def build!
      warn 'building pages'

      FileUtils.mkdir_p(build_dir)
      Dir[File.join(source_dir, '*.rb')].each do |source_filename|
        warn "  loading #{source_filename}"
        require_relative source_filename

        klass_name = "builder/#{File.basename(source_filename, '.rb')}".camelize
        warn "  found #{klass_name}"

        klass = klass_name.constantize
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
