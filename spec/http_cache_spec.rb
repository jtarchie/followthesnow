# frozen_string_literal: true

require 'json'
require 'spec_helper'
require 'tmpdir'
require 'webmock/rspec'
require_relative '../lib/http_cache'

RSpec.describe 'HTTPCache' do
  let(:filename) { File.join(Dir.mktmpdir, 'test.db') }

  before do
    WebMock.disable_net_connect!
    allow_any_instance_of(Object).to receive(:sleep)
    allow_any_instance_of(Object).to receive(:warn)
  end

  it 'returns an HTTP response' do
    stub_request(:get, 'http://example.com/index.json')
      .to_return(status: 200, body: ['abc', 123].to_json)

    client = HTTPCache.new(filename: filename)
    response = client.json_response('http://example.com/index.json')
    expect(response).to eq ['abc', 123]
  end

  it 'retries 3 times' do
    stub_request(:get, 'http://example.com/index.json')
      .to_return(status: 500).times(2).then
      .to_return(status: 200, body: ['abc', 123].to_json)

    client = HTTPCache.new(filename: filename)
    response = client.json_response('http://example.com/index.json')
    expect(response).to eq ['abc', 123]
  end

  it 'will retry if the condition is not meant' do
    client = HTTPCache.new(
      filename: filename
    )

    stub_request(:get, 'http://example.com/index.json')
      .to_return(status: 200, body: ['abc', 123].to_json).then
      .to_return(status: 200, body: { 123 => 'abc' }.to_json).then

    response = client.json_response('http://example.com/index.json') do |resp|
      resp.is_a?(Hash)
    end
    expect(response).to eq({ '123' => 'abc' })
  end

  context 'with modifiers' do
    it 'allows the request to be altered' do
      client = HTTPCache.new(
        filename: filename,
        modifiers: [
          HTTPCache::Modifier.new('example.com', lambda { |url|
            url.gsub('example.com', 'foobar.com')
          })
        ]
      )

      stub_request(:get, 'http://foobar.com/index.json')
        .to_return(status: 200, body: ['abc', 123].to_json).then

      response = client.json_response('http://example.com/index.json')
      expect(response).to eq(['abc', 123])
    end
  end
end
