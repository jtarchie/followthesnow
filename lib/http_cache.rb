# frozen_string_literal: true

require 'json'
require 'http'
require 'sqlite3'

# Handles the caching of assets for the HTTP Client
class HTTPCache
  MAX_RETRIES = 2
  NotMatchingBlock = RuntimeError
  HTTPError = RuntimeError
  Modifier = Struct.new(:matcher, :block) do
    def match?(url)
      Regexp.new(matcher).match?(url)
    end

    def call(url)
      block.call(url)
    end
  end

  def initialize(filename:, modifiers: [])
    @filename = filename
    @modifiers = modifiers
  end

  def json_response(url, retries = MAX_RETRIES)
    response = JSON.parse(get_response(url))

    raise NotMatchingBlock, "request to #{url} did not meet condition" if block_given? && !yield(response)

    response
  rescue HTTPError, NotMatchingBlock => e
    if retries.positive?
      retries -= 1
      delay = rand(5..15)
      warn "attempting retry on #{url}"
      warn "  delay=#{delay}"
      sleep(delay)
      retry
    end
    raise e
  end

  private

  def get_response(url)
    warn "attempting loading #{url} from HTTP GET"
    modifier = find_modifier(url)
    if modifier
      url = modifier.call(url)
      warn "  modified-url=#{url}"
    end

    response = HTTP
               .follow
               .headers({
                          'User-Agent' => "(followthesnow.today, jtachie+followthesnow#{Time.now.to_i}@gmail.com)"
                        })
               .get(url)

    warn "  status=#{response.status}"

    raise HTTPError, "request to #{url} was not successful: #{response.status}" unless response.status.success?

    response.to_s
  end

  def find_modifier(url)
    return if @modifiers.empty?

    @modifiers.find { |m| m.match?(url) }
  end
end
