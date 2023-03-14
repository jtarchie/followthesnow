# frozen_string_literal: true

require 'ostruct'
require 'http'
require 'json'

module Scrape
  class Geo
    def to_address(lat:, lng:)
      response = JSON.parse(http.follow.get(%(/reverse?lat=#{lat.to_f}&lon=#{lng.to_f}&format=jsonv2)).to_s)
      address  = OpenStruct.new(response['address'])

      OpenStruct.new({
                       city: address.city || address.village || address.leisure || address.tourism || address.building || address.road || address.county,
                       state: address.state,
                       country: address.country
                     })
    end

    private

    def http
      @http ||= HTTP.persistent('https://nominatim.openstreetmap.org')
    end
  end
end
