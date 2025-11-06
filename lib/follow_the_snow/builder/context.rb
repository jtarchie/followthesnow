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

      # Get count of resorts with snow in a country
      def country_snow_count(country)
        resorts_by_countries.fetch(country).count do |resort|
          resort.forecasts.any? { |f| f.snow.to_f.positive? }
        end
      end

      # Get count of resorts with snow in a state
      def state_snow_count(state)
        resorts = @resorts.select { |r| r.region_name == state }
        resorts.count do |resort|
          resort.forecasts.any? { |f| f.snow.to_f.positive? }
        end
      end

      # Get top N resorts by total snow in forecast period
      def top_snowy_resorts(limit: 10)
        resort_snow = @resorts.map do |resort|
          total = resort.forecasts.sum { |f| f.snow.to_f }
          { resort: resort, total: total }
        end

        resort_snow.select { |rs| rs[:total].positive? }
                   .sort_by { |rs| -rs[:total] }
                   .take(limit)
      end

      # Get resorts with snow today (next 24 hours)
      def resorts_with_snow_today
        @resorts.select do |resort|
          # Get first forecast (usually today)
          first_forecast = resort.forecasts.first
          first_forecast && first_forecast.snow.to_f.positive?
        end.sort_by { |r| -r.forecasts.first.snow.to_f }
      end

      # Get regional summaries (country -> total snow, resort count)
      def regional_summaries
        resorts_by_countries.map do |country, resorts|
          total_snow = resorts.sum do |resort|
            resort.forecasts.sum { |f| f.snow.to_f }
          end

          resort_count = resorts.count do |resort|
            resort.forecasts.any? { |f| f.snow.to_f.positive? }
          end

          {
            country: country,
            total_snow: total_snow,
            resort_count: resort_count,
            total_resorts: resorts.count
          }
        end.select { |s| s[:resort_count].positive? }
                            .sort_by { |s| -s[:total_snow] }
      end

      # Format snow total for display
      def format_snow_total(inches)
        return '0"' if inches.zero?

        if inches >= 1
          "#{inches.round(1)}\""
        else
          "#{(inches * 10).round(0) / 10.0}\""
        end
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
