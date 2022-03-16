# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/array/conversions'

Forecast::Text = Struct.new(:forecasts, keyword_init: true) do
  def forecasts
    self['forecasts'].map.with_index do |forecast, index|
      time_of_day = forecast.time_of_day.strftime('%m/%d')
      time_of_day = 'Today' if Time.now.strftime('%m/%d') == time_of_day
      case forecast.snow.end
      when 0
        "no snow #{time_of_day}" if index < 2
      when 1
        "<1\" of snow #{time_of_day}"
      else
        "#{forecast.snow.begin}-#{forecast.snow.end}\" of snow #{time_of_day}"
      end
    end.compact.to_sentence
  end
end
