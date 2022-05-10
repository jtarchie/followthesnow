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
  def self.from(
    resort:,
    fetcher:,
    aggregates: [Forecast::NOAA]
  )
    first_klass = aggregates.shift
    first       = first_klass.new(
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
require_relative './forecasts/open_weather_map'
require_relative './forecasts/short'
require_relative './forecasts/text'
