# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Getting resorts from wikipedia' do
  it 'returns a list of resorts' do
    stub_country_page
    stub_resort_page
    logger = Ougai::Logger.new($stderr)

    client  = FollowTheSnow::Scrape::Wikipedia.new(
      url: 'https://wikipedia.com/page',
      logger: logger
    )
    resorts = client.resorts
    expect(resorts).to eq [OpenStruct.new(
      name: 'Some Resort',
      lat: 0.3533611111e1, lng: -0.1134752778e3, url: 'https://some-resort.com'
    )]
  end
end
