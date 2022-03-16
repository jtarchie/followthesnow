# frozen_string_literal: true

Forecast::First = Struct.new(:resort, :fetcher, keyword_init: true) do
  def forecasts
    @forecasts ||= begin
      points_response = fetcher.json_response("https://api.weather.gov/points/#{resort.coords.join(',')}")
      forecast_url = points_response.dig('properties', 'forecast')

      forecast_response = fetcher.json_response(forecast_url) do |response|
        updated_at = response.dig('properties', 'updated')

        !updated_at.nil? && (Time.now - Time.parse(updated_at)) / 3600 <= 24
      end

      periods = forecast_response.dig('properties', 'periods')

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

        Forecast.new(
          time_of_day: Time.parse(period['startTime']).strftime('%m/%d'),
          snow: snow_range,
          short: period['shortForecast'],
          wind_gust: wind_gust_range,
          wind_speed: wind_speed_range
        )
      end
    rescue Faraday::ServerError, HTTPCache::NotMatchingBlock
      [
        Forecast.new(
          time_of_day: 'Today',
          snow: 0..0
        )
      ]
    end
  end

  private

  def kph_to_mph(value)
    (value / 1.609344).round(3)
  end
end
