# frozen_string_literal: true

require 'json'
require 'spec_helper'
require 'tmpdir'
require 'webmock/rspec'
require_relative '../lib/http_cache'

RSpec.describe 'HTTPCache' do
  before do
    WebMock.disable_net_connect!
    allow_any_instance_of(Object).to receive(:sleep)
  end

  it 'returns an HTTP response' do
    filename = File.join(Dir.mktmpdir, 'test.db')

    stub_request(:get, 'http://example.com/index.json')
      .to_return(status: 200, body: ['abc', 123].to_json)

    client = HTTPCache.new(filename: filename)
    response = client.json_response('http://example.com/index.json')
    expect(response).to eq ['abc', 123]
  end

  it 'retries 3 times' do
    filename = File.join(Dir.mktmpdir, 'test.db')

    stub_request(:get, 'http://example.com/index.json')
      .to_return(status: 500).times(2).then
      .to_return(status: 200, body: ['abc', 123].to_json)

    client = HTTPCache.new(filename: filename)
    response = client.json_response('http://example.com/index.json')
    expect(response).to eq ['abc', 123]
  end

  it 'saves the requests into the db' do
    filename = File.join(Dir.mktmpdir, 'test.db')

    stub_request(:get, 'http://example.com/index.json')
      .to_return(status: 200, body: ['abc', 123].to_json)

    client = HTTPCache.new(filename: filename)
    response = client.json_response('http://example.com/index.json')

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
end
