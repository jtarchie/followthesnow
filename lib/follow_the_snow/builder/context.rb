# frozen_string_literal: true

require 'active_support/time'
require 'active_support/core_ext/string'

module FollowTheSnow
  module Builder
    class Context
      include ERB::Util

      attr_reader :resorts

      def initialize(resorts:)
        @resorts = resorts.sort_by do |r|
          [r.country_code, r.region_code, r.name].join
        end
      end

      def resorts_by_countries
        @resorts_by_countries ||= @resorts.group_by(&:country_name)
      end

      def countries
        resorts_by_countries.keys.sort
      end

      def states(country:)
        resorts_by_countries.fetch(country).group_by(&:region_name).keys
      end

      # Check if a country has any snow in the forecast
      def country_has_snow?(country)
        resorts_by_countries.fetch(country).any? do |resort|
          resort.forecasts.any? { |f| f.snow.to_f.positive? }
        end
      end

      # Check if a state/region has any snow in the forecast
      def state_has_snow?(state)
        resorts = @resorts.select { |r| r.region_name == state }
        resorts.any? do |resort|
          resort.forecasts.any? { |f| f.snow.to_f.positive? }
        end
      end

      # Get total snow amount for a country
      def total_snow_for_country(country)
        resorts_by_countries.fetch(country).sum do |resort|
          resort.forecasts.sum { |f| f.snow.to_f }
        end
      end

      # Get total snow amount for a state/region
      def total_snow_for_state(state)
        resorts = @resorts.select { |r| r.region_name == state }
        resorts.sum do |resort|
          resort.forecasts.sum { |f| f.snow.to_f }
        end
      end

      # Get snow icon/indicator for display
      def snow_indicator
        %(<span class="snow-indicator" aria-label="Snow in forecast">❄️</span>).html_safe
      end

      # Check if a snow value should be highlighted
      def snow?(value)
        value.to_f.positive?
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
