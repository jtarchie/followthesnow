# frozen_string_literal: true

Forecast::First = Struct.new(:resort, :fetcher, keyword_init: true) do
  def forecasts
    @forecasts ||= begin
      points_response = fetcher.json_response("https://api.weather.gov/points/#{resort.coords.join(',')}")
      forecast_url = points_response.dig('properties', 'forecast')

      forecast_response = fetcher.json_response(forecast_url)
      periods = forecast_response.dig('properties', 'periods')

      forecasts = periods.map do |period|
        snow = 0..0

        short_forecast = period['shortForecast']
        if short_forecast =~ /snow/i
          detailed_forecast = period['detailedForecast']

          matches = /(\d+)\s+to\s+(\d+)\s+inches/.match(detailed_forecast)
          snow = if matches
                   matches[1].to_i..matches[2].to_i
                 elsif detailed_forecast =~ /less than|around/
                   0..1
                 else
                   warn 'detected snow, but no depth'
                   warn "  shortForecast=#{short_forecast.inspect}"
                   warn "  detailedForecast=#{detailed_forecast.inspect}"
                   0..0
                 end
        end

        Forecast.new(
          time_of_day: Time.parse(period['startTime']).strftime('%m/%d'),
          range: snow
        )
      end
    rescue OpenURI::HTTPError
      [
        Forecast.new(
          time_of_day: 'Today',
          range: 0..0
        )
      ]
    end
  end
end
