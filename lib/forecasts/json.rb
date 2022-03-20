# frozen_string_literal: true

require 'time'

Forecast::JSON = Struct.new(:resort, :fetcher, keyword_init: true) do
  def forecasts
    @forecasts ||= begin
      forecast_response = fetcher.json_response(
        resort.forecast_url,
        {
          'Feature-Flags' => 'forecast_temperature_qv, forecast_wind_speed_qv'
        }
      ) do |response|
        updated_at = response.dig('properties', 'updated')

        !updated_at.nil? && (Time.now - Time.parse(updated_at)) / 3600 <= 24
      end

      periods = forecast_response.dig('properties', 'periods') || []

      periods.map do |period|
        snow_range = 0..0

        short_forecast = period['shortForecast']
        if short_forecast =~ /snow/i
          detailed_forecast = period['detailedForecast']

          matches = /(\d+)\s+to\s+(\d+)\s+inches/.match(detailed_forecast)
          snow_range = if matches
                         matches[1].to_i..matches[2].to_i
                       elsif detailed_forecast =~ /less than|around/
                         0..1
                       else
                         0..0
                       end
        end

        wind_gust = period['windGust'] || {}
        wind_gust_range = if wind_gust['value']
                            0..(kph_to_mph(wind_gust['value']))
                          elsif wind_gust['minValue']
                            (kph_to_mph(wind_gust['minValue'])..kph_to_mph(wind_gust['maxValue']))
                          else
                            0..0
                          end

        wind_speed = period['windSpeed'] || {}
        wind_speed_range = if wind_speed['value']
                             0..(kph_to_mph(wind_speed['value']))
                           elsif wind_speed['minValue']
                             (kph_to_mph(wind_speed['minValue'])..kph_to_mph(wind_speed['maxValue']))
                           else
                             0..0
                           end

        temp = period['temperature'] || {}
        temp_range = if temp['value']
                       0..(c_to_f(temp['value']))
                     elsif temp['minValue']
                       (c_to_f(temp['minValue'])..c_to_f(temp['maxValue']))
                     else
                       0..0
                     end

        Forecast.new(
          short: period['shortForecast'],
          snow: snow_range,
          temp: temp_range,
          time_of_day: Time.parse(period['startTime']),
          wind_direction: period['windDirection'],
          wind_gust: wind_gust_range,
          wind_speed: wind_speed_range
        )
      end
    rescue Faraday::ServerError, HTTPCache::NotMatchingBlock
      [
        Forecast.new(
          short: 'Unknown',
          snow: 0..0,
          temp: 0..0,
          time_of_day: Time.now,
          wind_direction: '',
          wind_gust: 0..0,
          wind_speed: 0..0
        )
      ]
    end
  end

  private

  def kph_to_mph(value)
    (value / 1.609344).round
  end

  def c_to_f(value)
    (value * 9 / 5).round(3) + 32
  end
end
