# frozen_string_literal: true

require 'http'
require 'json'

module FollowTheSnow
  Forecast::OpenMeteo = Struct.new(:resort, keyword_init: true) do
    def forecasts
      @forecasts ||= begin
        forecast_response = JSON.parse(
          HTTP.timeout(10).get("https://api.open-meteo.com/v1/forecast?latitude=#{resort.lat}&longitude=#{resort.lon}&models=best_match&daily=weathercode,temperature_2m_max,temperature_2m_min,sunrise,sunset,snowfall_sum,precipitation_hours,windspeed_10m_max,windgusts_10m_max,winddirection_10m_dominant&current_weather=true&temperature_unit=fahrenheit&windspeed_unit=mph&precipitation_unit=inch&timezone=America%2FNew_York")
        )

        daily = forecast_response.fetch('daily')

        daily.fetch('time').each_with_index.map do |timestamp, index|
          dt = Date.parse(timestamp)

          temp_range       = (daily.fetch('temperature_2m_min')[index].round(2))..(daily['temperature_2m_max'][index].round(2))
          snow_range       = 0..daily.fetch('snowfall_sum')[index].round(2)
          wind_gust_range  = 0..daily.fetch('windgusts_10m_max')[index].round(2)
          wind_speed_range = 0..daily.fetch('windspeed_10m_max')[index].round(2)

          Forecast.new(
            name: dt.strftime('%a'),
            short: weather_codes(daily.fetch('weathercode')[index]),
            snow: snow_range,
            temp: temp_range,
            time_of_day: dt,
            wind_direction: wind_direction(daily.fetch('winddirection_10m_dominant')[index]),
            wind_gust: wind_gust_range,
            wind_speed: wind_speed_range
          )
        end
      rescue JSON::ParserError, OpenSSL::SSL::SSLError, HTTP::Error, KeyError
        sleep(rand(5))
        retry
      end
    end

    private

    def weather_codes(code)
      {
        0 => 'Clear sky',
        1 => 'Mainly clear',
        2 => 'Partly cloudy',
        3 => 'Overcast',
        45 => 'Fog',
        48 => 'Depositing rime fog',
        51 => 'Drizzle: Light intensity',
        53 => 'Drizzle: Moderate intensity',
        55 => 'Drizzle: Dense intensity',
        56 => 'Freezing Drizzle: Light intensity',
        57 => 'Freezing Drizzle: Dense intensity',
        61 => 'Rain: Slight intensity',
        63 => 'Rain: Moderate intensity',
        65 => 'Rain: Heavy intensity',
        66 => 'Freezing Rain: Light intensity',
        67 => 'Freezing Rain: Heavy intensity',
        71 => 'Snow fall: Slight intensity',
        73 => 'Snow fall: Moderate intensity',
        75 => 'Snow fall: Heavy intensity',
        77 => 'Snow grains',
        80 => 'Rain showers: Slight intensity',
        81 => 'Rain showers: Moderate intensity',
        82 => 'Rain showers: Violent intensity',
        85 => 'Snow showers: Slight intensity',
        86 => 'Snow showers: Heavy intensity',
        95 => 'Thunderstorm: Slight or moderate',
        96 => 'Thunderstorm with slight hail',
        99 => 'Thunderstorm with heavy hail'
      }[code] || ''
    end

    def wind_direction(degree)
      directions = {
        N: [348.75..360, 0..11.25],
        NNE: [11.25..33.75],
        NE: [33.75..56.25],
        ENE: [56.25..78.75],
        E: [78.75..101.25],
        ESE: [101.25..123.75],
        SE: [123.75..146.25],
        SSE: [146.25..168.75],
        S: [168.75..191.25],
        SSW: [191.25..213.75],
        SW: [213.75..236.25],
        WSW: [236.25..258.75],
        W: [258.75..281.25],
        WNW: [281.25..303.75],
        NW: [303.75..326.25],
        NNW: [326.25..348.75]
      }

      directions.find do |_direction, degrees|
        degrees.any? do |range|
          range.include?(degree)
        end
      end.first
    end
  end
end
