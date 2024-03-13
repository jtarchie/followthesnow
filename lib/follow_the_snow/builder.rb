# frozen_string_literal: true

require 'active_support'
require 'active_support/inflector'
require 'fileutils'
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
        @context      = Context.new(resorts: resorts)
        @logger       = Ougai::Logger.new($stderr)
        @logger.level = Ougai::Logger::DEBUG
        @source_dir   = source_dir
      end

      def resorts
        @context.resorts
      end

      def build!
        FileUtils.mkdir_p(@build_dir)
        FileUtils.copy_entry(File.join(@source_dir, 'public'), @build_dir)

        layout_html = erb(File.join(@source_dir, '_layout.html.erb'))

        Dir[File.join(@source_dir, '**', '*.html.erb')].each do |filename|
          next if File.basename(filename) =~ /^_/

          build_filename = filename.gsub(@source_dir, @build_dir).gsub('.html.erb', '.html')
          FileUtils.mkdir_p(File.dirname(build_filename))

          case filename
          when /\[country\]/
            countries.each do |country|
              country_filename = build_filename.gsub('[country]', country.parameterize)
              write_file(
                layout_html,
                filename,
                country_filename,
                {
                  country: country,
                  states: resorts_by_country(country)
                }
              )
            end
          when /\[state\]/
            states.each do |state|
              state_filename = build_filename.gsub('[state]', state.parameterize)
              write_file(
                layout_html,
                filename,
                state_filename,
                {
                  resorts: resorts_by_state(state),
                  state: state
                }
              )
            end
          when /\[resort\]/
            resorts.each do |resort|
              resort_filename = build_filename.gsub('[resort]', resort.name.parameterize)
              write_file(
                layout_html,
                filename,
                resort_filename,
                {
                  resort: resort
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
        @resorts_by_state ||= resorts.group_by(&:region_name)
        @resorts_by_state.fetch(state)
      end

      def states
        @states ||= resorts.map(&:region_name).uniq.sort
      end

      def resorts_by_country(country)
        @resorts_by_country ||= resorts.group_by(&:country_name)
        @resorts_by_country.fetch(country)
      end

      def countries
        @countries ||= resorts.map(&:country_name).uniq.sort
      end

      def write_file(layout, source_filename, build_filename, metadata = {})
        template     = erb(source_filename)
        parsed_file  = FrontMatterParser::Parser.new(:html).call(template.render(@context, metadata))
        front_matter = parsed_file.front_matter
        contents     = parsed_file.content
        variables    = front_matter
                       .merge(metadata)
                       .merge({
                                content: contents
                              })

        @logger.info('writing file', { source: source_filename, build_filename: build_filename })
        FileUtils.mkdir_p(File.dirname(build_filename))
        File.write(
          build_filename,
          layout.render(@context, variables)
        )
      end

      def erb(filename)
        Tilt::ERBTemplate.new(filename, trim: true)
      end
    end
  end
end
