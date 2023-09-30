# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

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
          'lat' => 51.0925,
          'lon' => -115.39,
          'timezone' => 'America/Edmonton',
          'timezone_offset' => -25_200,
          'daily' => [{ 'dt' => 1_672_945_200,
                        'sunrise' => 1_672_933_461,
                        'sunset' => 1_672_962_546,
                        'moonrise' => 1_672_957_200,
                        'moonset' => 1_672_932_060,
                        'moon_phase' => 0.46,
                        'temp' => { 'day' => 22.46, 'min' => -1.28, 'max' => 31.93, 'night' => 25, 'eve' => 26.01, 'morn' => 2.21 },
                        'feels_like' => { 'day' => 15.44, 'night' => 16.52, 'eve' => 18.23, 'morn' => -7.47 },
                        'pressure' => 1012,
                        'humidity' => 75,
                        'dew_point' => 16.48,
                        'wind_speed' => 7.72,
                        'wind_deg' => 246,
                        'wind_gust' => 8.46,
                        'weather' => [{ 'id' => 804,
                                        'main' => 'Clouds',
                                        'description' => "overcast
          clouds",
                                        'icon' => '04d' }],
                        'clouds' => 100,
                        'pop' => 0,
                        'uvi' => 0.59 }]
        }.to_json
      )

    stub_request(:get, /api.open-meteo.com/)
      .to_return(
        status: 200,
        body: {
          'daily' => {
            'time' => %w[
              2023-03-14 2023-03-15 2023-03-16 2023-03-17 2023-03-18 2023-03-19 2023-03-20 2023-03-21
            ],
            'weathercode' => [3, 3, 75, 71, 73, 51, 3, 51],
            'temperature_2m_max' => [62.2, 67.6, 50.7, 38.4, 41.1, 46.7, 54.9, 58.7],
            'temperature_2m_min' => [36.8, 42.5, 23.7, 19.8, 28.5, 29.4, 35.5, 41.3],
            'snowfall_sum' => [0.000, 0.000, 2.950, 0.138, 0.139, 0.000, 0.000, 0.000],
            'precipitation_hours' => [0.0, 0.0, 12.0, 3.0, 6.0, 1.0, 0.0, 3.0],
            'windspeed_10m_max' => [12.8, 16.6, 15.1, 6.3, 10.6, 7.1, 4.2, 14.2],
            'windgusts_10m_max' => [21.7, 26.2, 26.8, 9.6, 8.7, 8.9, 8.9, 27.3],
            'winddirection_10m_dominant' => [278, 251, 35, 89, 99, 123, 220, 358]
          }
        }.to_json
      )
  end

  it 'builds HTML files', :focus do
    resorts = Dir[File.join(resorts_dir, '*.csv')].flat_map do |filename|
      FollowTheSnow::Resort.from_csv(filename)
    end.take(5)

    builder   = FollowTheSnow::Builder::Site.new(
      build_dir: build_dir,
      resorts: resorts,
      source_dir: pages_dir
    )

    builder.build!

    html_files = Dir[File.join(build_dir, '**', '*.html')].to_a
    expect(html_files.length).to eq(9)
  end
end
