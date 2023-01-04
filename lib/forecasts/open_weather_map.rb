# frozen_string_literal: true

require 'http'
require 'json'

Forecast::OpenWeatherMap = Struct.new(:resort, keyword_init: true) do
  def forecasts
    @forecasts ||= begin
      forecast_response = JSON.parse(
        HTTP.get("https://api.openweathermap.org/data/3.0/onecall?units=imperial&exclude=alerts,current,minutely,hourly&lat=#{resort.lat}&lon=#{resort.lng}&appid=#{ENV.fetch('OPENWEATHER_API_KEY')}")
      )

      forecast_response.fetch('daily', []).map do |period|
        dt = Time.at(period['dt'])

        temp_range       = (period['temp']['min'].round)..(period['temp']['max'].round)
        snow_range       = 0..0
        snow_range       = 0..period['snow'].round if period.key?('snow')
        wind_gust_range  = 0..period['wind_gust'].round
        wind_speed_range = 0..period['wind_speed'].round

        Forecast.new(
          name: dt.strftime('%a'),
          short: period.dig('weather', 0, 'description'),
          snow: snow_range,
          temp: temp_range,
          time_of_day: dt,
          wind_direction: wind_direction(period['wind_deg']),
          wind_gust: wind_gust_range,
          wind_speed: wind_speed_range
        )
      end
    end
  rescue OpenSSL::SSL::SSLError, HTTP::Error
    sleep(1)
    retry
  end

  private

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
