# frozen_string_literal: true

require_relative '../lib/builder'
require 'tmpdir'
require 'json'
require 'webmock/rspec'

RSpec.describe 'Builder' do
  before do
    WebMock.disable_net_connect!
    allow_any_instance_of(Object).to receive(:sleep)
    allow_any_instance_of(Object).to receive(:warn)
  end

  it 'renders resorts in alphabetical order and by state' do
    resorts = [
      Resort.new(name: 'B Resort', state: 'Wyoming'),
      Resort.new(name: 'A Resort', state: 'Wyoming'),
      Resort.new(name: 'C Resort', state: 'Colorado')
    ]

    build_dir = Dir.mktmpdir
    builder = Builder.new(
      build_dir: build_dir,
      fetcher: TestFetcher.new,
      source_dir: File.expand_path(File.join(__dir__, '..', 'pages')),
      resorts: resorts
    )

    stub_request(:get, /points/)
      .to_return(status: 200, body: {
        properties: {
          forecast: 'https://api.weather.gov/gridpoints/TEST/1,2/forecast'
        }
      }.to_json)

    stub_request(:get, /forecast/)
      .to_return(status: 200, body: {
        properties: {
          periods: []
        }
      }.to_json)

    builder.build!
    contents = File.read(File.join(build_dir, 'index.html'))
    expect(contents).to match(/Colorado.*Wyoming/m)
    expect(contents).to match(/A Resort.*B Resort/m)
  end
end
