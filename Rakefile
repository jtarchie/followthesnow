# frozen_string_literal: true

require_relative './lib/builder'
require_relative './lib/resort'
require_relative './lib/http_cache'

task :build do
  resorts = Resort.from_csv(File.join(__dir__, 'resorts.csv'))

  builder = Builder.new(
    build_dir: File.join(__dir__, 'docs'),
    fetcher: HTTPCache.new(
      filename: 'http_responses.db',
      rules: []
    ),
    resorts: resorts,
    source_dir: __dir__
  )

  builder.build!
end

task :fmt do
  sh('rubocop -A')
end

task default: %i[build]
