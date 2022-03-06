# frozen_string_literal: true

require 'erb'
require 'fileutils'
require 'open-uri'
require 'json'

Builder = Struct.new(:predictions, keyword_init: true) do
  def build!
    build_dir = File.join(__dir__, 'docs')

    FileUtils.mkdir_p(build_dir)

    file = ERB.new(File.read(File.join(__dir__, 'index.html.erb')))
    File.write(File.join(build_dir, 'index.html'), file.result(binding))
  end

  def by_state
    @by_state ||= predictions.group_by do |prediction|
      prediction.location.state
    end
  end
end

Prediction = Struct.new(:location, keyword_init: true) do
  def text_report
    @text_report ||= begin
      points_response = JSON.parse(
        URI.open("https://api.weather.gov/points/#{location.coords.join(',')}").read
      )
      forecast_url = points_response.dig('properties', 'forecast')
      forecast_response = JSON.parse(
        URI.open(forecast_url).read
      )
      periods = forecast_response.dig('properties', 'periods')
      snow_predictions = periods[0..1].map do |period|
        snow_prediction = 'No snow'

        short_forecast = period['shortForecast']
        next unless short_forecast.include?('Snow')

        detailed_forecast = period['detailedForecast']

        matches = /(\d+)\s+to\s+(\d+) inches/.match(detailed_forecast)
        snow_prediction = %(#{matches[1]}-#{matches[2]}" of snow) if matches

        snow_prediction
      end
      %(#{snow_predictions[0]} expected today and #{snow_predictions[1]} expected tonight)
    end
  end
end

Resort = Struct.new(:name, :coords, :city, :state, keyword_init: true)

resorts = [
  Resort.new(
    name: 'Winter Park Ski Resort',
    coords: [39.8869, -105.7625],
    city: 'Winter Park',
    state: 'Colorado'
  )
].sort_by(&:city)

predictions = resorts.map do |location|
  Prediction.new(location: location)
end

builder = Builder.new(predictions: predictions)
builder.build!
