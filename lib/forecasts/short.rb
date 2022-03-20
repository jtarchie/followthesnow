# frozen_string_literal: true

Forecast::Short = Struct.new(:forecasts, keyword_init: true) do
  class ForecastDelegate < SimpleDelegator
    def time_of_day
      current_date = __getobj__.time_of_day.strftime('%m/%d')

      if current_date == Time.now.strftime('%m/%d')
        'Today'
      elsif current_date == (Time.now + 86_400).strftime('%m/%d')
        'Tomorrow'
      else
        __getobj__.time_of_day.strftime('%a')
      end
    end

    def snow
      case __getobj__.snow.begin
      when 0
        case __getobj__.snow.end
        when 0
          '0"'
        else
          "<#{__getobj__.snow.end}\""
        end
      else
        "#{__getobj__.snow.begin}-#{__getobj__.snow.end}\""
      end
    end

    def short_icon
      case short
      when /Snow/i
        '❄️'
      when /Sunny/i
        '☀️'
      when /Cloud/i
        '☁️'
      else
        '⛅️'
      end
    end

    def temp
      "#{__getobj__.temp.end}°F"
    end

    def wind_gust
      "#{__getobj__.wind_gust.end} mph"
    end

    def wind_speed
      "#{__getobj__.wind_direction} #{__getobj__.wind_speed.end} mph"
    end
  end

  def forecasts
    self['forecasts'].map do |forecast|
      ForecastDelegate.new(forecast)
    end
  end
end
