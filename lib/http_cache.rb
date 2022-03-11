# frozen_string_literal: true

require 'json'
require 'http'
require 'sqlite3'

# Handles the caching of assets for the HTTP Client
class HTTPCache
  MAX_RETRIES = 2
  NotMatchingBlock = RuntimeError
  HTTPError = RuntimeError

  def initialize(filename:, rules: [])
    @filename = filename
    @rules = rules

    db
  end

  def json_response(url, retries = MAX_RETRIES)
    response = JSON.parse(get_response(url, retries != MAX_RETRIES))

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

  def get_response(url, force)
    expires = find_rule_expiry(url)
    if expires && !force
      warn "attempting loading #{url} from cache"
      results = db.execute(%(
        SELECT response FROM responses
        WHERE
          url = :url AND
          datetime('now', '-#{expires} minutes') <= created_at
        ORDER BY
          created_at
        LIMIT 1), url: url)
      if results.length.positive?
        warn '  loaded from cache'
        return results[0][0]
      end
    end

    warn "attempting loading #{url} from HTTP GET"

    response = HTTP
               .follow
               .headers({
                          'User-Agent' => "(followthesnow.today, jtachie+followthesnow#{Time.now.to_i}@gmail.com)",
                          'Cache-Control' => 'max-age=0',
                        })
               .get(url)

    warn "  status=#{response.status}"

    raise HTTPError, "request to #{url} was not successful: #{response.status}" unless response.status.success?

    db.execute('INSERT INTO responses (url, response) VALUES (:url, :response);', url: url, response: response.to_s)
    response.to_s
  end

  def find_rule_expiry(url)
    return if @rules.empty?

    rule = @rules.find { |match, _| url.include?(match) }
    rule[1] if rule
  end

  def db
    @db ||= begin
      db = SQLite3::Database.new(@filename)
      db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS responses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          url text,
          response text,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
      SQL
      db
    end
  end
end
