# frozen_string_literal: true

require 'active_support'
require 'active_support/time'
require 'erb'
require 'fileutils'
require 'kramdown'
require 'terminal-table'
require_relative 'forecast'

Prediction = Struct.new(:resort, :forecast, keyword_init: true) do
  def days
    forecast.forecasts.map do |tod, _|
      tod
    end
  end

  def name
    resort.name
  end

  def url
    resort.url
  end

  def ranges
    forecast.forecasts.map do |_, range|
      range
    end
  end
end

Builder = Struct.new(:resorts, :build_dir, :source_dir, :fetcher, keyword_init: true) do
  include ERB::Util

  def build!
    FileUtils.mkdir_p(build_dir)

    layout = ERB.new(File.read(File.join(source_dir, '_layout.html.erb')), nil, '-')

    Dir[File.join(source_dir, '*.md.erb')].each do |source_filename|
      build_filename = File.basename(source_filename, '.md.erb')
      file = ERB.new(File.read(source_filename), nil, '-')

      markdown = file.result(erb_binding)
      File.write(File.join(build_dir, "#{build_filename}.md"), markdown)

      File.write(
        File.join(build_dir, "#{build_filename}.html"),
        layout.result(erb_binding { markdown_render(markdown) })
      )
    end
  end

  private

  def erb_binding
    binding
  end

  def by_state(forecasters = [Forecast::Text])
    predictions(forecasters).group_by do |prediction|
      prediction.resort.state
    end
  end

  def markdown_render(text)
    Kramdown::Document.new(
      text,
      input: 'GFM',
      gfm_emojis: true,
      hard_wrap: false
    ).to_html
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
