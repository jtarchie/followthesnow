# frozen_string_literal: true

require 'http'

class TestFetcher
  def json_response(url)
    response = HTTP.follow.get(url)
    raise HTTPCache::HTTPError unless response.status.success?

    JSON.parse(response.to_s)
  end
end
