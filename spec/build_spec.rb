# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require_relative '../pages/build'
require_relative '../lib/resort'

RSpec.describe('Building') do
  let(:build_dir) { Dir.mktmpdir }
  let(:pages_dir) { File.expand_path(File.join(__dir__, '..', 'pages')) }
  let(:resorts_dir) { File.expand_path(File.join(__dir__, '..', 'resorts')) }

  before do
    ENV['OPENWEATHER_API_KEY'] = 'fake-key-for-tests'
    stub_request(:get, /api.openweathermap.org/)
      .to_return(
        status: 200,
        body: {
          "lat": 51.0925,
          "lon": -115.39,
          "timezone": 'America/Edmonton',
          "timezone_offset": -25_200,
          "daily": [{ "dt": 1_672_945_200,
                      "sunrise": 1_672_933_461,
                      "sunset": 1_672_962_546,
                      "moonrise": 1_672_957_200,
                      "moonset": 1_672_932_060,
                      "moon_phase": 0.46,
                      "temp": { "day": 22.46, "min": -1.28, "max": 31.93, "night": 25, "eve": 26.01, "morn": 2.21 },
                      "feels_like": { "day": 15.44, "night": 16.52, "eve": 18.23, "morn": -7.47 },
                      "pressure": 1012,
                      "humidity": 75,
                      "dew_point": 16.48,
                      "wind_speed": 7.72,
                      "wind_deg": 246,
                      "wind_gust": 8.46,
                      "weather": [{ "id": 804,
                                    "main": 'Clouds',
                                    "description": "overcast
          clouds",
                                    "icon": '04d' }],
                      "clouds": 100,
                      "pop": 0,
                      "uvi": 0.59 }]
        }.to_json
      )
  end

  it 'builds HTML files', :vcr do
    resorts = Dir[File.join(resorts_dir, '*.csv')].flat_map do |filename|
      Resort.from_csv(filename)
    end.take(5)

    builder   = Builder::Site.new(
      build_dir:,
      resorts:,
      source_dir: pages_dir
    )

    builder.build!

    html_files = Dir[File.join(build_dir, '**', '*.html')].to_a
    expect(html_files.length).to eq(8)
  end
end
