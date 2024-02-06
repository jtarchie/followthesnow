# frozen_string_literal: true

require 'sqlite3'

module FollowTheSnow
  Resort = Struct.new(
    :id,
    :lat,
    :lon,
    :name,
    :region_code,
    :country_code,
    :country_name,
    :region_name,
    :url,
    :min_elevation,
    :max_elevation,
    keyword_init: true
  ) do
    def self.from_sqlite(filename)
      db      = SQLite3::Database.new filename
      rows    = db.prepare('SELECT * FROM resorts').execute
      results = []
      rows.each_hash do |payload|
        results.push Resort.new(payload)
      end
      results.uniq(&:name)
      rows.close

      results
    end

    def forecasts(aggregates: [
      Forecast::Daily
    ])
      @forecast ||= Forecast::OpenMeteo.new(
        resort: self
      )

      aggregates.reduce(@forecast) do |forecaster, aggregate|
        aggregate.new(
          forecasts: forecaster.forecasts
        )
      end.forecasts
    end
  end
end
