# frozen_string_literal: true

require 'active_support'
require 'active_support/cache'
require 'active_support/cache/file_store'
require 'faraday-http-cache'
require 'faraday'
require 'faraday/detailed_logger'
require 'faraday/follow_redirects'
require 'faraday/net_http_persistent'
require 'faraday/retry'
require 'json'

# Handles the caching of assets for the HTTP Client
class HTTPCache
  NotMatchingBlock = Class.new(RuntimeError) {}

  def initialize
    @client = Faraday.new do |builder|
      builder.request :retry, {
        max: 4,
        interval: 5,
        interval_randomness: 10,
        exceptions: [
          Errno::ETIMEDOUT,
          'Timeout::Error',
          Faraday::TimeoutError,
          Faraday::RetriableResponse,
          Faraday::ServerError
        ]
      }
      builder.response :raise_error
      builder.use :http_cache,
                  store: ActiveSupport::Cache::FileStore.new(File.join(__dir__, '..', '.cache')),
                  shared_cache: true,
                  logger: Logger.new($stdout)
      builder.response :detailed_logger
      builder.response :json, content_type: //
      builder.use Faraday::FollowRedirects::Middleware
      builder.adapter :net_http_persistent, pool_size: 5
    end
  end

  def json_response(url, headers = {}, retries = 3, &block)
    block = ->(_response) { true } unless block_given?
    response = @client.get(
      url,
      nil,
      { 'User-Agent' => '(followthesnow.com, hello@followthesnow.com)' }.merge(headers)
    ).body
    raise NotMatchingBlock unless block.call(response)

    response
  rescue NotMatchingBlock => e
    retry if (retries -= 1).positive?
    raise e
  end
end
