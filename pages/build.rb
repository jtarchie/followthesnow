# frozen_string_literal: true

require 'active_support'
require 'active_support/inflector'
require 'active_support/time'
require_relative '../lib/follow_the_snow'
require 'fileutils'
require 'kramdown'
require 'terminal-table'
require 'tilt/erb'

module Builder
  # builds the entire site
  class Site
    include ERB::Util

    def initialize(build_dir:, resorts:, source_dir:, to_build: %i[index pages resorts])
      @build_dir  = build_dir
      @resorts    = resorts.sort_by { |r| [r.country, r.state, r.name] }
      @source_dir = source_dir
      @to_build   = to_build
    end

    def build!
      FileUtils.mkdir_p(@build_dir)
      FileUtils.copy_entry(File.join(@source_dir, 'public'), @build_dir)

      layout_html = erb('_layout.html.erb')

      if @to_build.include?(:index)
        main_md     = erb('index.md.erb')
        File.write(
          File.join(@build_dir, 'index.html'),
          layout_html.render(self, {
                               content: from_markdown(main_md.render(self)),
                               description: 'List of all states and provinces that have ski resorts.',
                               title: 'States and Provinces'
                             })
        )
      end

      if @to_build.include?(:pages)
        Dir[File.join(@source_dir, '*.md')].each do |markdown_file|
          render_filename = markdown_file.gsub(@source_dir, @build_dir).gsub('.md', '.html')
          puts "m: #{markdown_file}, r: #{render_filename}"
          title           = markdown_file.gsub(@source_dir, '').titleize
          File.write(
            render_filename,
            layout_html.render(
              self, {
                content: from_markdown(File.read(markdown_file)),
                description: title,
                title:
              }
            )
          )
        end
      end

      return unless @to_build.include?(:resorts)

      state_md  = erb('state.md.erb')
      state_dir = File.join(@build_dir, 'states')
      FileUtils.mkdir_p(state_dir)

      states.each do |state|
        state_filename = File.join(state_dir, "#{state.parameterize}.html")
        puts "Building state: #{state}"
        File.write(
          state_filename,
          layout_html.render(
            self,
            {
              content: from_markdown(
                state_md.render(
                  self,
                  {
                    state:,
                    resorts: resorts_by_state(state)
                  }
                )
              ),
              description: "Weekly forecast of snow for #{state}",
              title: "Weekly forecast of snow for #{state}"
            }
          )
        )
      end

      resort_md  = erb('resort.md.erb')
      resort_dir = File.join(@build_dir, 'resorts')
      FileUtils.mkdir_p(resort_dir)

      @resorts.each do |resort|
        resort_filename = File.join(resort_dir, "#{resort.name.parameterize}.html")
        puts "Building resort: #{resort.name}"
        File.write(
          resort_filename,
          layout_html.render(
            self,
            {
              content: from_markdown(resort_md.render(
                                       self,
                                       {
                                         resort:
                                       }
                                     )),
              description: "Weekly forecast of snow for #{resort.name}",
              title: "#{resort.state} &raquo; #{resort.name}"
            }
          )
        )
      end
    end

    private

    def resorts_by_state(state)
      @resorts_by_state ||= @resorts.group_by(&:state)
      @resorts_by_state.fetch(state)
    end

    def resorts_by_countries
      @resorts_by_countries ||= @resorts.group_by(&:country)
    end

    def countries
      resorts_by_countries.keys.sort
    end

    def states(country: nil)
      return resorts_by_countries.values.flatten.map(&:state).uniq if country.nil?

      resorts_by_countries.fetch(country).group_by(&:state).keys
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

    def table_for_resorts(resorts)
      max_days = resorts.map do |resort|
        resort.forecasts.map(&:time_of_day)
      end.max_by(&:length)

      headers  = ['Location'] + max_days

      rows = resorts.map do |resort|
        snow_days = resort.forecasts.map do |f|
          f.snow.to_s
        end

        row  = ["[#{resort.name}](/resorts/#{resort.name.parameterize})#{resort.closed? ? '*' : ''}"]
        row += if snow_days.length == max_days.length
                 snow_days
               else
                 snow_days + ([''] * (max_days.length - snow_days.length))
               end
        row
      end

      table       = Terminal::Table.new(
        headings: headers,
        rows:
      )
      table.style = { border: :markdown }
      table.to_s
    end

    def table_for_longterm(resort)
      headers = ['Date', 'Snowfall', 'Icon', 'Short', 'Temp', 'Wind Speed', 'Wind Gusts']

      forecasts = resort.forecasts(
        aggregates: [FollowTheSnow::Forecast::Short]
      )

      rows = forecasts.map do |f|
        [
          f.name,
          f.snow,
          f.short_icon,
          f.short,
          f.temp,
          f.wind_speed,
          f.wind_gust
        ]
      end

      table       = Terminal::Table.new(
        headings: headers,
        rows:
      )
      table.style = { border: :markdown }
      table.to_s
    end

    def current_timestamp
      Time.zone = 'Eastern Time (US & Canada)'
      Time.zone.now.strftime('%Y-%m-%d %l:%M%p %Z')
    end
  end
end
