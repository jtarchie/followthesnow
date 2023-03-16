# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Geo location' do
  context 'when given lat and lng' do
    it 'returns an address' do
      stub_geo_lookup(lat: 1.1, lng: 2.2)
      logger = Logger.new($stderr)

      client  = FollowTheSnow::Scrape::Geo.new(logger:)
      address = client.to_address(lat: '1.1', lng: '2.2')
      expect(address.city).to eq 'Denver'
      expect(address.state).to eq 'Colorado'
      expect(address.country).to eq 'US'
    end
  end
end
