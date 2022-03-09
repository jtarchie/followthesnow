# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/array/conversions'

Forecast::Text = Struct.new(:forecasts, keyword_init: true) do
  def forecasts
    self['forecasts'].map.with_index do |forecast, index|
      case forecast.range.end
      when 0
        "no snow #{forecast.time_of_day}" if index < 2
      when 1
        "<1\" of snow #{forecast.time_of_day}"
      else
        "#{forecast.range.begin}-#{forecast.range.end}\" of snow #{forecast.time_of_day}"
      end
    end.compact.to_sentence
  end
end
