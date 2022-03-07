# frozen_string_literal: true

require_relative 'resort'

Prediction = Struct.new(:resort, :fetcher, keyword_init: true) do
  def text_report
    @text_report ||= begin
      points_response = json_response("https://api.weather.gov/points/#{resort.coords.join(',')}")
      forecast_url = points_response.dig('properties', 'forecast')

      forecast_response = json_response(forecast_url)
      periods = forecast_response.dig('properties', 'periods')

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
    fetcher.json_response(url)
  end
end
