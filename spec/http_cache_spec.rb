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

  it 'fails when block is not matched' do
    stub_request(:get, 'http://example.com/index.json')
      .to_return(status: 200, body: ['abc', 123].to_json)
      .to_return(status: 200, body: { 'abc' => 123 }.to_json)

    client = HTTPCache.new(filename: filename)
    response = client.json_response('http://example.com/index.json') do |res|
      !res.is_a?(Array)
    end
    expect(response).to eq({ 'abc' => 123 })
  end
end
