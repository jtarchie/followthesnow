# frozen_string_literal: true

require_relative './lib/follow_the_snow'
require 'fileutils'

sqlite_file = File.join(__dir__, 'data', 'features.sqlite')

def build!(resorts)
  build_dir = File.join(__dir__, 'docs')
  FileUtils.rm_rf(build_dir)
  builder   = FollowTheSnow::Builder::Site.new(
    build_dir: build_dir,
    resorts: resorts,
    source_dir: File.join(__dir__, 'pages')
  )

  builder.build!
  sh('minify docs/ --all --recursive -o docs/')
end

task :build do
  resorts = FollowTheSnow::Resort.from_sqlite(sqlite_file)
  build!(resorts)
end

task fast: [:css] do
  require 'webmock'
  include WebMock::API
  WebMock.enable!
  WebMock.disable_net_connect!

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

  resorts = FollowTheSnow::Resort.from_sqlite(sqlite_file)

  build!(resorts)
end

task :css do
  sh('npm run build')
  filepath = File.join(__dir__, 'pages/public/assets/main.css')
  contents = File.read(filepath)
  contents.gsub!(/^\s*--[\w-]+:\s*;$/, '')

  File.write(filepath, contents)
end

task fmt: [:css] do
  sh('deno fmt .')
  sh('rubocop -A')
  sh('bundle exec erblint --lint-all --enable-linters space_around_erb_tag,extra_newline -a pages/')
end

task :test do
  sh('bundle exec rspec')
end

task :scrape do
  builder = FollowTheSnow::OpenSkiMapBuilder.new(data_dir: File.join(__dir__, 'data'))
  builder.build!
end

task default: %i[fmt test build]
