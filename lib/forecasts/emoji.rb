# frozen_string_literal: true

Forecast::Emoji = Struct.new(:forecasts, keyword_init: true) do
  def forecasts
    self['forecasts'].map do |forecast|
      emoji = case forecast.range.begin
              when 0
                case forecast.range.end
                when 0
                  '🚫'
                else
                  "<#{forecast.range.end}\""
                end
              else
                "#{forecast.range.begin}-#{forecast.range.end}\""
              end
      [forecast.time_of_day, emoji]
    end
  end
end
