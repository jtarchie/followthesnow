# frozen_string_literal: true

require 'json'
require 'open-uri'
require 'sqlite3'

HTTPCache = Struct.new(:filename, :rules, keyword_init: true) do
  def json_response(url, retries = 2)
    response_body = URI.open(url).read
    db.execute('INSERT INTO responses (url, response) VALUES (:url, :response);', url: url, response: response_body)
    response = JSON.parse(response_body)
  rescue OpenURI::HTTPError => e
    if retries.positive?
      retries -= 1
      sleep(5)
      retry
    end
    raise e
  end

  private

  def db
    db ||= begin
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
