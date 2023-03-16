# frozen_string_literal: true

module FollowTheSnow
  Forecast::Aggregate = Struct.new(:forecasts, keyword_init: true) do
    def forecasts
      @forecasts ||= self['forecasts']
                     .sort_by(&:time_of_day)
                     .group_by { |f| f.time_of_day.strftime('%m/%d') }
                     .map do |_, grouped_forecasts|
        Forecast.new(
          time_of_day: grouped_forecasts.first.time_of_day,
          snow: grouped_forecasts.map { |f| f.snow.min }.max..(grouped_forecasts.sum { |f| f.snow.max })
        )
      end
    end
  end
end
