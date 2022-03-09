# frozen_string_literal: true

require_relative 'resort'
require 'active_support'
require 'active_support/core_ext/array/conversions'

Report = Struct.new(:time_of_day, :range, keyword_init: true)

Prediction = Struct.new(:resort, :fetcher, keyword_init: true) do
  def text_report
    @text_report ||= begin
      reports.map.with_index do |report, index|
        case report.range.end
        when 0
          "no snow #{report.time_of_day}" if index < 2
        when 1
          "<1\" of snow #{report.time_of_day}"
        else
          "#{report.range.begin}-#{report.range.end}\" of snow #{report.time_of_day}"
        end
      end.compact.to_sentence
    rescue OpenURI::HTTPError
      'no current weather reports can be found'
    end
  end

  def emoji_reports
    @emoji_reports ||= begin
      combine_reports = reports.each_slice(2).map.with_index do |(first, second), index|
        reports = [first, second]
        if index.positive?
          reports = [
            Report.new(
              time_of_day: first.time_of_day,
              range: [first.range.begin, second.range.begin].max..(first.range.end + second.range.end)
            )
          ]
        end
        reports
      end.flatten

      combine_reports.map do |report|
        emoji = case report.range.begin
                when 0
                  case report.range.end
                  when 0
                    '🚫'
                  else
                    "<#{report.range.end}\""
                  end
                else
                  "#{report.range.begin}-#{report.range.end}\""
                end
        [short_tod(report.time_of_day), emoji]
      end
    rescue OpenURI::HTTPError
      []
    end
  end

  private

  def short_tod(tod)
    new_tod = tod
              .gsub(/Tonight/i, '🌓')
              .gsub(/Night/i, '🌓')
              .gsub(/Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday/i) { |w| w[0..2] }
              .strip
    new_tod = 'Now' if new_tod.length > 3
    new_tod
  end

  def reports
    @reports ||= begin
      points_response = json_response("https://api.weather.gov/points/#{resort.coords.join(',')}")
      forecast_url = points_response.dig('properties', 'forecast')

      forecast_response = json_response(forecast_url)
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

        Report.new(
          time_of_day: period['name'],
          range: snow
        )
      end
    end
  end

  def json_response(url)
    fetcher.json_response(url)
  end
end
