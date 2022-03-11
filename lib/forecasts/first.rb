# frozen_string_literal: true

Forecast::First = Struct.new(:resort, :fetcher, keyword_init: true) do
  def forecasts
    @forecasts ||= begin
      warn "loading forecasts for #{resort.name}"
      points_response = fetcher.json_response("https://api.weather.gov/points/#{resort.coords.join(',')}")
      forecast_url = points_response.dig('properties', 'forecast')

      forecast_response = fetcher.json_response(forecast_url) do |response|
        updated_at = Time.parse(response.dig('properties', 'updated'))
        current_time = Time.now
        if (Time.now - updated_at) / 3600 <= 24
          true
        else
          warn 'forecast payload:'
          warn "  current_time: #{current_time}"
          warn "  updated_at:   #{updated_at}"
          false
        end
      end

      periods = forecast_response.dig('properties', 'periods')

      periods.map do |period|
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
    rescue HTTPCache::HTTPError, HTTPCache::NotMatchingBlock
      [
        Forecast.new(
          time_of_day: 'Today',
          range: 0..0
        )
      ]
    end
  end
end
