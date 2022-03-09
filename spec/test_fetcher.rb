# frozen_string_literal: true

require 'open-uri'

class TestFetcher
  def json_response(url)
    JSON.parse(URI.open(url).read)
  end
end
