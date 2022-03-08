# frozen_string_literal: true

require_relative 'resort'
require 'active_support'
require 'active_support/core_ext/array/conversions'

Prediction = Struct.new(:resort, :fetcher, keyword_init: true) do
  def text_report
    @text_report ||= begin
      points_response = json_response("https://api.weather.gov/points/#{resort.coords.join(',')}")
      forecast_url = points_response.dig('properties', 'forecast')

      forecast_response = json_response(forecast_url)
      periods = forecast_response.dig('properties', 'periods')

      snow_predictions = periods.map do |period|
        time_period = period['name'].downcase
        snow_prediction = "no snow #{time_period}"

        short_forecast = period['shortForecast']
        if short_forecast.include?('Snow')
          detailed_forecast = period['detailedForecast']

          matches = /(\d+)\s+to\s+(\d+)\s+inches/.match(detailed_forecast)
          snow_prediction = %(#{matches[1]}-#{matches[2]}" of snow #{time_period}) if matches
        end

        snow_prediction
      end.compact.to_sentence
    rescue OpenURI::HTTPError
      'no current weather reports can be found'
    end
  end

  private

  def json_response(url)
    fetcher.json_response(url)
  end
end
