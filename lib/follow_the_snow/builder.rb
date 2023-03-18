# frozen_string_literal: true

require 'active_support'
require 'active_support/inflector'
require 'fileutils'
require 'kramdown'
require 'tilt/erb'
require 'front_matter_parser'
require_relative './builder/context'
require 'ougai'

module FollowTheSnow
  module Builder
    # builds the entire site
    class Site
      def initialize(build_dir:, resorts:, source_dir:)
        @build_dir    = build_dir
        @context      = Context.new(resorts:)
        @logger       = Ougai::Logger.new($stderr)
        @logger.level = Ougai::Logger::DEBUG
        @resorts      = resorts
        @source_dir   = source_dir
      end

      def build!
        FileUtils.mkdir_p(@build_dir)
        FileUtils.copy_entry(File.join(@source_dir, 'public'), @build_dir)

        layout_html = erb('_layout.erb.html')

        Dir[File.join(@source_dir, '**', '*.erb.md')].each do |filename|
          next if File.basename(filename) =~ /^_/

          build_filename = filename.gsub(@source_dir, @build_dir).gsub('.erb.md', '.html')
          FileUtils.mkdir_p(File.dirname(build_filename))

          case filename
          when /\[state\]/
            states.each do |state|
              state_filename = build_filename.gsub('[state]', state.parameterize)
              write_file(
                layout_html,
                filename,
                state_filename,
                {
                  resorts: resorts_by_state(state),
                  state:
                }
              )
            end
          when /\[resort\]/
            @resorts.each do |resort|
              resort_filename = build_filename.gsub('[resort]', resort.name.parameterize)
              write_file(
                layout_html,
                filename,
                resort_filename,
                {
                  resort:
                }
              )
            end
          else
            write_file(layout_html, filename, build_filename)
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

      def write_file(layout, source_filename, build_filename, metadata = {})
        template     = Tilt::ERBTemplate.new { File.read(source_filename) }
        parsed_file  = FrontMatterParser::Parser.new(:md).call(template.render(@context, metadata))
        front_matter = parsed_file.front_matter
        contents     = parsed_file.content
        variables    = front_matter
                       .merge(metadata)
                       .merge({
                                content: from_markdown(contents)
                              })

        @logger.info('writing file', { source: source_filename, build_filename:, metadata: })
        FileUtils.mkdir_p(File.dirname(build_filename))
        File.write(
          build_filename,
          layout.render(@context, variables)
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
