# frozen_string_literal: true

require 'active_support'
require 'active_support/time'
require 'erb'
require 'fileutils'
require_relative 'forecast'

Prediction = Struct.new(:resort, :forecast, keyword_init: true)

Builder = Struct.new(:resorts, :build_dir, :source_dir, :fetcher, keyword_init: true) do
  include ERB::Util

  def build!
    FileUtils.mkdir_p(build_dir)

    Dir[File.join(source_dir, '*.html.erb')].each do |source_filename|
      build_filename = File.basename(source_filename, '.erb')
      file = ERB.new(File.read(source_filename))
      File.write(File.join(build_dir, build_filename), file.result(binding))
    end
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
    Time.zone.now.strftime(' %a %b %e, %Y %l:%M%p %Z')
  end
end
