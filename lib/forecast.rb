# frozen_string_literal: true

Forecast = Struct.new(
  :name,
  :short,
  :snow,
  :temp,
  :time_of_day,
  :wind_direction,
  :wind_gust,
  :wind_speed,
  keyword_init: true
) do
  def self.from(resort:, fetcher:, aggregates: [])
    first = Forecast::NOAA.new(
      resort: resort,
      fetcher: fetcher
    )

    aggregates.reduce(first) do |forecaster, aggregate|
      aggregate.new(
        forecasts: forecaster.forecasts
      )
    end
  end
end

require_relative './forecasts/aggregate'
require_relative './forecasts/noaa'
require_relative './forecasts/short'
require_relative './forecasts/text'
