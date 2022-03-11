# frozen_string_literal: true

Prediction = Struct.new(:resort, :forecast, keyword_init: true) do
  def days
    forecast.forecasts.map do |tod, _|
      tod
    end
  end

  def name
    resort.name
  end

  def url
    resort.url
  end

  def ranges
    forecast.forecasts.map do |_, range|
      range
    end
  end
end
