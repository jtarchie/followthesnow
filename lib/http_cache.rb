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
    logger       = Logger.new($stderr)
    logger.level = Logger::INFO

    @client = Faraday.new do |builder|
      builder.request :retry, {
        max: 2,
        interval: 5,
        interval_randomness: 10,
        exceptions: [
          'Timeout::Error',
          Errno::ETIMEDOUT,
          Faraday::ConnectionFailed,
          Faraday::ParsingError,
          Faraday::RetriableResponse,
          Faraday::ServerError,
          Faraday::TimeoutError
        ]
      }
      builder.response :raise_error
      builder.use :http_cache,
                  store: ActiveSupport::Cache::FileStore.new(File.join(__dir__, '..', '.cache')),
                  shared_cache: true,
                  logger: logger
      builder.response :detailed_logger, logger
      builder.response :json, content_type: //
      builder.use Faraday::FollowRedirects::Middleware
      builder.adapter :net_http_persistent, pool_size: 5
    end
  end

  def json_response(url, headers = {}, retries = 2, &block)
    block    = ->(_response) { true } unless block_given?
    response = @client.get(
      url,
      nil,
      { 'User-Agent' => '(followthesnow.today, hello@followthesnow.today)' }.merge(headers)
    ).body
    raise NotMatchingBlock unless block.call(response)

    response
  rescue NotMatchingBlock => e
    retry if (retries -= 1).positive?
    raise e
  end
end
