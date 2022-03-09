# frozen_string_literal: true

require 'json'
require 'open-uri'
require 'sqlite3'

HTTPCache = Struct.new(:filename, :rules, keyword_init: true) do
  NotMatchingBlock = RuntimeError
  MAX_RETRIES = 2

  def initialize(**)
    super
    db
  end

  def json_response(url, retries = MAX_RETRIES)
    response = JSON.parse(get_response(url, retries != MAX_RETRIES))
    return response if !block_given? || yield(response)

    raise NotMatchingBlock, "request to #{url} did not meet condition"
  rescue OpenURI::HTTPError, NotMatchingBlock => e
    if retries.positive?
      retries -= 1
      sleep(rand(5..15))
      retry
    end
    raise e
  end

  private

  def get_response(url, force)
    expires = find_rule_expiry(url)
    if expires && !force
      results = db.execute(%(
        SELECT response FROM responses
        WHERE
          url = :url AND
          datetime('now', '-#{expires} minutes') <= created_at
        ORDER BY
          created_at
        LIMIT 1), url: url)
      return results[0][0] if results.length.positive?
    end

    response = URI.open(url, {
                          'User-Agent' => '(followthesnow.today, jtachie+followthesnow@gmail.com)'
                        }).read
    db.execute('INSERT INTO responses (url, response) VALUES (:url, :response);', url: url, response: response)
    response
  end

  def find_rule_expiry(url)
    return unless rules

    rule = rules.find { |match, _| url.include?(match) }
    rule[1] if rule
  end

  def db
    @db ||= begin
      db = SQLite3::Database.new(filename)
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
