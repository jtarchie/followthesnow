# frozen_string_literal: true

require 'csv'

Resort = Struct.new(:name, :lat, :lng, :city, :state, keyword_init: true) do
  def coords
    [lat, lng]
  end

  def self.from_csv(filename)
    CSV.read(filename, headers: true).map do |resort|
      Resort.new(resort.to_h)
    end
  end
end
