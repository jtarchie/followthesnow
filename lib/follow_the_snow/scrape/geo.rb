# frozen_string_literal: true

require 'ostruct'
require 'http'
require 'json'

module FollowTheSnow
  module Scrape
    class Geo
      def to_address(lat:, lng:, logger:)
        response = JSON.parse(HTTP.follow.headers('Accept-Language' => 'en-US,en;q=0.5').timeout(10).get(%(https://nominatim.openstreetmap.org/reverse?lat=#{lat.to_f}&lon=#{lng.to_f}&format=jsonv2)).to_s)
        address  = OpenStruct.new(response['address'])

        logger.info('found address', { address: address })

        OpenStruct.new({
                         city: address.city || address.village || address.leisure || address.tourism || address.building || address.road || address.county,
                         state: address.state || address.province || address.region || address.municipality,
                         country: address.country
                       })
      end
    end
  end
end
