# frozen_string_literal: true

Forecast::Emoji = Struct.new(:forecasts, keyword_init: true) do
  class Snow < SimpleDelegator
    def to_s
      case self.begin
      when 0
        case self.end
        when 0
          '🚫'
        else
          "<#{self.end}\""
        end
      else
        "#{self.begin}-#{self.end}\""
      end
    end
  end

  class ForecastDelegate < SimpleDelegator
    def snow
      Snow.new(__getobj__.snow)
    end
  end

  def forecasts
    self['forecasts'].map do |forecast|
      ForecastDelegate.new(forecast)
    end
  end
end
