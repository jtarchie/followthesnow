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

      snow_predictions = periods.map.with_index do |period, index|
        time_period = period['name'].downcase
        snow_prediction = ("no snow #{time_period}" if index < 2)

        short_forecast = period['shortForecast']
        if short_forecast =~ /snow/i
          detailed_forecast = period['detailedForecast']

          snow_prediction = if matches = /(\d+)\s+to\s+(\d+)\s+inches/.match(detailed_forecast)
                              %(#{matches[1]}-#{matches[2]}" of snow #{time_period})
                            elsif detailed_forecast =~ /less than half an inch/
                              %(<0.5" of snow #{time_period})
                            elsif detailed_forecast =~ /around one inch/
                              %(<1" of snow #{time_period})
                            end
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
