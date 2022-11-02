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
)

require_relative './forecasts/aggregate'
require_relative './forecasts/open_weather_map'
require_relative './forecasts/short'
require_relative './forecasts/text'
