# frozen_string_literal: true

Prediction = Struct.new(:resort, :forecast, keyword_init: true) do
  def days
    forecast.forecasts.map(&:time_of_day)
  end

  def name
    resort.name
  end

  def closed?
    resort.closed?
  end

  def url
    resort.url
  end

  def snows
    forecast.forecasts.map do |f|
      f.snow.to_s
    end
  end
end
