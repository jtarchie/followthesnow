# frozen_string_literal: true

require 'csv'

Resort = Struct.new(
  :city,
  :closed,
  :forecast_url,
  :lat,
  :lng,
  :name,
  :state,
  :country,
  :url,
  keyword_init: true
) do
  def coords
    [lat, lng]
  end

  def self.from_csv(filename)
    CSV.read(filename, headers: true).map do |resort|
      Resort.new(resort.to_h)
    end.uniq(&:name)
  end

  def closed?
    self['closed'] == 'true'
  end

  def forecasts(aggregates: [
    Forecast::Aggregate,
    Forecast::Short
  ])
    @forecast ||= Forecast::OpenWeatherMap.new(
      resort: self
    )

    aggregates.reduce(@forecast) do |forecaster, aggregate|
      aggregate.new(
        forecasts: forecaster.forecasts
      )
    end.forecasts
  end
end
