# frozen_string_literal: true

Forecast = Struct.new(:time_of_day, :snow, keyword_init: true) do
  def self.from(resort:, fetcher:, aggregates: [])
    first = Forecast::First.new(
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
require_relative './forecasts/first'
require_relative './forecasts/text'
