# frozen_string_literal: true

require 'spec_helper'
require 'csv'
require 'tmpdir'
require_relative '../lib/csv_builder'

RSpec.describe 'CSVBuilder' do
  let(:build_dir) { Dir.mktmpdir }

  before do
    ENV['OPENAI_ACCESS_TOKEN'] = 'fake_token'
  end

  it 'writes files for each country' do
    stub_country_page
    stub_resort_page
    stub_geo_lookup(lat: 3.533611111, lng: -113.4752778)
    stub_openai_prompt
    stub_browser(url: 'https://some-resort.com')

    builder = CSVBuilder.new(
      build_dir:,
      country: 'usa',
      url: 'https://wikipedia.com/page'
    )
    builder.build!

    csv_files = Dir.glob(File.join(build_dir, '*.csv'))
    expect(csv_files.length).to eq 1

    csv_file = File.join(build_dir, 'usa.csv')
    expect(csv_files).to eq [csv_file]

    rows = CSV.read(csv_file, headers: true)
    expect(rows.length).to eq 1
    expect(rows.first.to_h).to eq({
                                    'city' => 'Denver',
                                    'closed' => 'true',
                                    'country' => 'US',
                                    'lat' => '0.3533611111e1',
                                    'lng' => '-0.1134752778e3',
                                    'name' => 'Some Resort',
                                    'state' => 'Colorado',
                                    'url' => 'https://some-resort.com'
                                  })
  end
end
