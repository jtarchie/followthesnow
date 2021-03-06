# frozen_string_literal: true

require 'erb'

module Builder
  # builds each single resort page
  class Resorts < Page
    include Builder::Renderer
    include Builder::Slug
    include ERB::Util

    def build!
      resort_path = File.join(build_dir, 'resorts')
      FileUtils.mkdir_p(resort_path)

      layout_path = File.join(source_dir, '_layout.html.erb')
      resort_file = File.join(source_dir, 'resort.md.erb')

      resorts.each do |resort|
        @resort = resort
        File.write(
          File.join(resort_path, "#{slug(resort.name)}.html"),
          render(
            layout: layout_path,
            page: resort_file,
            title: "#{resort.state} &raquo; #{resort.name}",
            description: "Weekly forecast of snow for #{resort.name}"
          )
        )
      end
    end

    private

    attr_reader :resort

    def current_timestamp
      Time.zone = 'Eastern Time (US & Canada)'
      Time.zone.now.strftime('%Y-%m-%d %l:%M%p %Z')
    end

    def long_term_table(resort)
      headers = ['Date', 'Snowfall', 'Icon', 'Short', 'Temp', 'Wind Speed', 'Wind Gusts']

      forecast = Forecast.from(
        fetcher: fetcher,
        resort: resort,
        aggregates: [
          initial_aggregate,
          Forecast::Short
        ]
      )

      rows = forecast.forecasts.map do |f|
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
        rows: rows
      )
      table.style = { border: :markdown }
      table.to_s
    end
  end
end
