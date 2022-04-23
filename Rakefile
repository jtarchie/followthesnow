# frozen_string_literal: true

require_relative './lib/builder'
require_relative './lib/resort'
require_relative './lib/http_cache'

task :build do
  resorts = Resort.from_csv(File.join(__dir__, 'resorts.csv'))

  builder = Builder::Start.new(
    build_dir: File.join(__dir__, 'docs'),
    fetcher: HTTPCache.new,
    resorts: resorts,
    source_dir: File.join(__dir__, 'pages')
  )

  builder.build!
  sh('minify docs/ --all --recursive -o .')
end

task :fmt do
  sh('rubocop -A')
end

task :test do
  sh('bundle exec rspec')
end

task default: %i[fmt test build]
