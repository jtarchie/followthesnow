# frozen_string_literal: true

require 'active_support'
require 'active_support/time'

module Builder
  # builds the front page
  class Index < Page
    include Builder::Renderer
    include ERB::Util

    def build!(output_filename: 'index.html')
      FileUtils.mkdir_p(build_dir)

      layout_path = File.join(source_dir, '_layout.html.erb')
      source_filename = File.join(source_dir, 'index.md.erb')

      File.write(
        File.join(build_dir, output_filename),
        render(
          layout: layout_path,
          page: source_filename
        )
      )
    end

    private

    def by_state(forecasters = [Forecast::Text])
      predictions(forecasters).group_by do |prediction|
        prediction.resort.state
      end
    end

    def predictions(forecasters)
      resorts
        .sort_by { |r| [r.state, r.name] }
        .map do |resort|
        Prediction.new(
          resort: resort,
          forecast: Forecast.from(
            fetcher: fetcher,
            resort: resort,
            aggregates: forecasters
          )
        )
      end
    end

    def current_timestamp
      Time.zone = 'Eastern Time (US & Canada)'
      Time.zone.now.strftime('%Y-%m-%d %l:%M%p %Z')
    end

    def table(predictions:)
      max_days = predictions.map(&:days).max_by(&:length)
      headers = ['Location'] + max_days

      rows = predictions.map do |p|
        row = if p.url
                ["[#{p.name}](#{p.url})"]
              else
                [p.name]
              end
        row += if p.ranges.length == max_days.length
                 p.ranges
               else
                 p.ranges + ([''] * (max_days.length - p.ranges.length))
               end
        row
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