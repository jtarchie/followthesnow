# frozen_string_literal: true

require_relative 'resort'
require 'open-uri'
require 'json'

Prediction = Struct.new(:resort, keyword_init: true) do
  def text_report
    @text_report ||= begin
      points_response = json_response("https://api.weather.gov/points/#{resort.coords.join(',')}")
      forecast_url = points_response.dig('properties', 'forecast')
      warn "  forecast_url = #{forecast_url}"

      forecast_response = json_response(forecast_url)
      periods = forecast_response.dig('properties', 'periods')
      warn "  periods = #{periods[0..1]}"

      snow_predictions = periods[0..1].map do |period|
        snow_prediction = 'no snow'

        short_forecast = period['shortForecast']
        if short_forecast.include?('Snow')
          detailed_forecast = period['detailedForecast']

          matches = /(\d+)\s+to\s+(\d+)\s+inches/.match(detailed_forecast)
          snow_prediction = %(#{matches[1]}-#{matches[2]}" of snow) if matches
        end

        snow_prediction
      end
      %(#{snow_predictions[0]} expected today and #{snow_predictions[1]} expected tonight)
    rescue OpenURI::HTTPError
      'no current weather reports can be found'
    end
  end

  private

  def json_response(url)
    JSON.parse(
      URI.open(url).read
    )
  end
end
