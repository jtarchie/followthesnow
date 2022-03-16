# frozen_string_literal: true

module Builder
  # builds each state page
  class Resorts < Page
    include Builder::Renderer

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
            page: resort_file
          )
        )
      end
    end

    private

    attr_reader :resort

    def slug(name)
      name.downcase.gsub(/\W+/, '-')
    end

    def long_term_table(resort)
      headers = ['Date', 'Snowfall', 'Icon', 'Short', 'Temp', 'Wind Speed', 'Wind Gusts']

      forecast = Forecast.from(
        fetcher: fetcher,
        resort: resort,
        aggregates: [Forecast::Emoji]
      )

      rows = forecast.forecasts.map do |f|
        [
          f.time_of_day,
          f.snow,
          f.short_icon,
          f.short,
          f.temp,
          f.wind_speed,
          f.wind_gust
        ]
      end

      table = Terminal::Table.new(
        headings: headers,
        rows: rows
      )
      table.style = { border: :markdown }
      table.to_s
    end
  end
end
