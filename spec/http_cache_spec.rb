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

  it 'saves the requests into the db' do
    stub_request(:get, 'http://example.com/index.json')
      .to_return(status: 200, body: ['abc', 123].to_json)

    client = HTTPCache.new(filename: filename)
    client.json_response('http://example.com/index.json')

    db = SQLite3::Database.new(filename)
    db.results_as_hash = true
    results = db.execute <<-SQL
      SELECT * FROM responses
    SQL

    expect(results.length).to eq 1

    result = results.first
    expect(result['url']).to eq 'http://example.com/index.json'
    expect(result['response']).to eq '["abc",123]'
  end

  context 'when rules are given' do
    it 'will retry if the condition is not meant' do
      client = HTTPCache.new(
        filename: filename,
        rules: {
          'example.com' => 1
        }
      )

      stub_request(:get, 'http://example.com/index.json')
        .to_return(status: 200, body: ['abc', 123].to_json).then
        .to_return(status: 200, body: { 123 => 'abc' }.to_json).then

      response = client.json_response('http://example.com/index.json') do |resp|
        resp.is_a?(Hash)
      end
      expect(response).to eq({ '123' => 'abc' })
    end

    it 'will use the cached response' do
      client = HTTPCache.new(
        filename: filename,
        rules: {
          'example.com' => 1
        }
      )

      stub_request(:get, 'http://example.com/index.json')
        .to_return(status: 200, body: ['abc', 123].to_json).then
        .to_return(status: 200, body: [123, 'abc'].to_json).then

      10.times do
        response = client.json_response('http://example.com/index.json')
        expect(response).to eq ['abc', 123]
      end
    end

    it 'will reload an expired cached response' do
      client = HTTPCache.new(
        filename: filename,
        rules: {
          'example.com' => 1
        }
      )

      db = SQLite3::Database.new(filename)
      db.results_as_hash = true
      db.execute <<-SQL
        INSERT INTO responses (url, response, created_at) VALUES ('http://example.com/index.json', '[1,2,3]', datetime('now', '-10 minutes'))
      SQL

      stub_request(:get, 'http://example.com/index.json')
        .to_return(status: 200, body: ['abc', 123].to_json).then

      10.times do
        response = client.json_response('http://example.com/index.json')
        expect(response).to eq ['abc', 123]
      end
    end
  end
end
