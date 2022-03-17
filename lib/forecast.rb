# frozen_string_literal: true

Forecast = Struct.new(
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
    first = Forecast::JSON.new(
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
require_relative './forecasts/emoji'
require_relative './forecasts/json'
require_relative './forecasts/text'
