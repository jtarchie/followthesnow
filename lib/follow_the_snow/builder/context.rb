# frozen_string_literal: true

require 'active_support'
require 'active_support/time'
require 'active_support/core_ext/string'

module FollowTheSnow
  module Builder
    class Context
      include ERB::Util

      attr_reader :resorts

      def initialize(resorts:)
        @resorts = resorts.sort_by do |r|
          [r.country, r.state, r.name].join
        end
      end

      def resorts_by_countries
        @resorts_by_countries ||= @resorts.group_by(&:country)
      end

      def countries
        resorts_by_countries.keys.sort
      end

      def states(country:)
        resorts_by_countries.fetch(country).group_by(&:state).keys
      end

      def table_for_resorts(resorts)
        max_days = resorts.map do |resort|
          resort.forecasts.map(&:time_of_day)
        end.max_by(&:length)

        headers  = ['Location'] + max_days

        rows = resorts.map do |resort|
          snow_days = resort.forecasts.map do |f|
            f.snow.to_s
          end

          row  = [%(<a href="/resorts/#{resort.name.parameterize}">#{resort.name}</a>).html_safe]
          row += if snow_days.length == max_days.length
                   snow_days
                 else
                   snow_days + ([''] * (max_days.length - snow_days.length))
                 end
          row
        end

        [headers, rows]
      end

      def table_for_longterm(resort)
        headers = ['Date', 'Snowfall', 'Icon', 'Short', 'Temp', 'Wind Speed', 'Wind Gusts']

        forecasts = resort.forecasts(
          aggregates: [FollowTheSnow::Forecast::Daily]
        )

        rows = forecasts.map do |f|
          [
            f.name,
            f.snow,
            f.short_icon,
            f.short,
            f.temp,
            f.wind_speed,
            f.wind_gust
          ]
        end

        [headers, rows]
      end

      def current_timestamp
        Time.zone = 'Eastern Time (US & Canada)'
        Time.zone.now.strftime('%Y-%m-%d %l:%M%p %Z')
      end
    end
  end
end
