# frozen_string_literal: true

class TestFetcher
  def json_response(url)
    JSON.parse(URI.open(url).read)
  end
end
