# frozen_string_literal: true

require_relative './lib/builder'
require_relative './lib/resort'
require_relative './lib/http_cache'

def build!(resorts)
  builder = Builder::Start.new(
    build_dir: File.join(__dir__, 'docs'),
    fetcher: HTTPCache.new,
    initial_aggregate: Forecast::NOAA,
    resorts: resorts,
    source_dir: File.join(__dir__, 'pages')
  )

  builder.build!
  sh('minify docs/ --all --recursive -o .')
end

task :build do
  resorts = Resort.from_csv(File.join(__dir__, 'resorts.csv'))
  build!(resorts)
end

task :fast do
  resorts = Resort
            .from_csv(File.join(__dir__, 'resorts.csv'))
            .group_by(&:state).map do |_state, list|
    list.first
  end.take(5)
  build!(resorts)
end

task :fmt do
  sh('rubocop -A')
end

task :test do
  sh('bundle exec rspec')
end

task default: %i[fmt test build]
