# frozen_string_literal: true

require_relative 'resort'
require 'active_support'
require 'active_support/core_ext/array/conversions'

Period = Struct.new(:time_of_day, :range, keyword_init: true)

Prediction = Struct.new(:resort, :fetcher, keyword_init: true) do
  def text_report
    @text_report ||= begin
      reports.map.with_index do |report, index|
        case report.range
        when 0
          "no snow #{report.time_of_day}" if index < 2
        when 0..1
          "<#{report.range}\" of snow #{report.time_of_day}"
        else
          "#{report.range.begin}-#{report.range.end}\" of snow #{report.time_of_day}"
        end
      end.compact.to_sentence
    rescue OpenURI::HTTPError
      'no current weather reports can be found'
    end
  end

  def reports
    @reports ||= begin
      points_response = json_response("https://api.weather.gov/points/#{resort.coords.join(',')}")
      forecast_url = points_response.dig('properties', 'forecast')

      forecast_response = json_response(forecast_url)
      periods = forecast_response.dig('properties', 'periods')

      periods.map do |period|
        snow = 0

        short_forecast = period['shortForecast']
        if short_forecast =~ /snow/i
          detailed_forecast = period['detailedForecast']

          matches = /(\d+)\s+to\s+(\d+)\s+inches/.match(detailed_forecast)
          snow = if matches
                   matches[1]..matches[2]
                 elsif detailed_forecast =~ /less than|around/
                   1
                 else
                   warn 'detected snow, but no depth'
                   warn "  shortForecast=#{short_forecast.inspect}"
                   warn "  detailedForecast=#{detailed_forecast.inspect}"
                   0
                 end
        end

        Period.new(
          time_of_day: period['name'],
          range: snow
        )
      end
    end
  end

  private

  def json_response(url)
    fetcher.json_response(url)
  end
end
