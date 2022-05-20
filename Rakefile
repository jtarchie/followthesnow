# frozen_string_literal: true

require_relative './lib/builder'
require_relative './lib/resort'
require_relative './lib/http_cache'

def build!(resorts)
  aggregator = Forecast::Switcher.new(rules: [
                                        ->(r) { return Forecast::OpenWeatherMap if r.state == 'Colorado' }
                                      ])

  builder = Builder::Start.new(
    build_dir: File.join(__dir__, 'docs'),
    fetcher: HTTPCache.new,
    initial_aggregate: aggregator,
    resorts: resorts,
    source_dir: File.join(__dir__, 'pages')
  )

  builder.build!
  sh('minify docs/ --all --recursive -o .')
end

task :build do
  resorts = Resort.from_csv(File.join(__dir__, 'resorts', 'wikipedia.csv'))
  build!(resorts)
end

task :fast do
  resorts = Resort
            .from_csv(File.join(__dir__, 'resorts', 'wikipedia.csv'))
            .group_by(&:state)['Colorado']
            .take(5)
  build!(resorts)
end

task :fmt do
  sh('rubocop -A')
end

task :test do
  sh('bundle exec rspec')
end

task :wikipedia do
  sh('ruby lib/wikipedia.rb > resorts/wikipedia.csv')
end

task default: %i[fmt test build]
