# frozen_string_literal: true

require 'active_support'
require 'active_support/inflector'
require 'active_support/time'
require 'fileutils'
require 'kramdown'
require 'terminal-table'
require 'tilt/erb'
require 'front_matter_parser'
require_relative './builder/context'

module FollowTheSnow
  module Builder
    # builds the entire site
    class Site
      def initialize(build_dir:, resorts:, source_dir:)
        @build_dir    = build_dir
        @resorts      = resorts
        @context      = Context.new(resorts:)
        @source_dir   = source_dir
        @logger       = Logger.new($stderr)
        @logger.level = Logger::DEBUG
      end

      def build!
        FileUtils.mkdir_p(@build_dir)
        FileUtils.copy_entry(File.join(@source_dir, 'public'), @build_dir)

        layout_html = erb('_layout.erb.html')

        Dir[File.join(@source_dir, '**', '*.erb.md')].each do |filename|
          next if File.basename(filename) =~ /^_/

          parsed_file    = FrontMatterParser::Parser.parse_file(filename)
          metadata       = parsed_file.front_matter
          contents       = parsed_file.content
          template       = Tilt::ERBTemplate.new { contents }
          build_filename = filename.gsub(@source_dir, @build_dir).gsub('.erb.md', '.html')

          FileUtils.mkdir_p(File.dirname(build_filename))

          case filename
          when /\[state\]/
            states.each do |state|
              state_filename = build_filename.gsub('[state]', state.parameterize)
              write_file(layout_html, state_filename, template, {
                           title: metadata['title'].gsub('[state]', state),
                           description: metadata['description'].gsub('[state]', state),
                           resorts: resorts_by_state(state),
                           state:
                         })
            end
          when /\[resort\]/
            @resorts.each do |resort|
              resort_filename = build_filename.gsub('[resort]', resort.name.parameterize)
              write_file(layout_html, resort_filename, template, {
                           title: metadata['title'].gsub('[state]', resort.state).gsub('[name]', resort.name),
                           description: metadata['description'].gsub('[state]', resort.state).gsub('[name]', resort.name),
                           resort:
                         })
            end
          else
            write_file(layout_html, build_filename, template, metadata)
          end
        end
      end

      private

      def resorts_by_state(state)
        @resorts_by_state ||= @resorts.group_by(&:state)
        @resorts_by_state.fetch(state)
      end

      def states
        @states ||= @resorts.map(&:state).uniq.sort
      end

      def write_file(layout, filename, template, metadata)
        @logger.info "file: #{filename}, metadata: #{metadata}"
        FileUtils.mkdir_p(File.dirname(filename))
        File.write(
          filename,
          layout.render(@context, metadata.merge(
                                    content: from_markdown(template.render(@context, metadata))
                                  ))
        )
      end

      def erb(filename)
        Tilt::ERBTemplate.new(File.join(@source_dir, filename), trim: true)
      end

      def from_markdown(template)
        Kramdown::Document.new(
          template,
          input: 'GFM',
          gfm_emojis: true,
          hard_wrap: false
        ).to_html
      end
    end
  end
end
