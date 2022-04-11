# frozen_string_literal: true

require 'json'
require 'nokogiri'
require 'tmpdir'
require 'webmock/rspec'
require_relative '../lib/builder'
require_relative '../lib/http_cache'
require_relative '../lib/resort'

RSpec.describe 'Builder' do
  let(:fetcher) do
    HTTPCache.new
  end

  def doc(html)
    Nokogiri::HTML(html)
  end

  before do
    WebMock.disable_net_connect!
    allow_any_instance_of(Object).to receive(:sleep)
    allow_any_instance_of(Object).to receive(:warn)
  end

  it 'renders resorts in alphabetical order and by state' do
    resorts = [
      Resort.new(
        name: 'B Resort',
        state: 'New Mexico',
        forecast_url: 'https://api.weather.gov/gridpoints/TEST/1,2/forecast'
      ),
      Resort.new(
        name: 'A Resort',
        state: 'New Mexico',
        forecast_url: 'https://api.weather.gov/gridpoints/TEST/1,2/forecast'
      ),
      Resort.new(
        name: 'C Resort',
        state: 'Colorado',
        forecast_url: 'https://api.weather.gov/gridpoints/TEST/1,2/forecast'
      )
    ]

    build_dir = Dir.mktmpdir
    builder   = Builder::Start.new(
      build_dir: build_dir,
      fetcher: fetcher,
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
    expect(contents).to match(/Colorado.*New Mexico/m)
    expect(contents).to match(/A Resort.*B Resort/m)

    contents = File.read(File.join(build_dir, 'states', 'colorado.html'))
    expect(doc(contents).css('title').first.text).to match(/Colorado/)
    expect(contents).to match(/Colorado/m)
    expect(contents).to match(/C Resort/m)

    contents = File.read(File.join(build_dir, 'states', 'new-mexico.html'))
    expect(doc(contents).css('title').first.text).to match(/New Mexico/)
    expect(contents).to match(/New Mexico/m)
    expect(contents).to match(/A Resort.*B Resort/m)

    contents = File.read(File.join(build_dir, 'resorts', 'a-resort.html'))
    title    = doc(contents).css('title').first.text
    expect(title).to match(/New Mexico/)
    expect(title).to match(/A Resort/)
    expect(contents).to match(/A Resort/m)

    expect(File).to exist(File.join(build_dir, 'CNAME'))
    expect(File).to exist(File.join(build_dir, '404.html'))
    expect(File).to exist(File.join(build_dir, 'main.css'))
  end
end
