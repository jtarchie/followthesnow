# frozen_string_literal: true

require_relative './lib/follow_the_snow'
require 'fileutils'

def build!(resorts)
  build_dir = File.join(__dir__, 'docs')
  FileUtils.rm_rf(build_dir)
  builder   = Builder::Site.new(
    build_dir:,
    resorts:,
    source_dir: File.join(__dir__, 'pages')
  )

  builder.build!
  sh('minify docs/ --all --recursive -o .')
end

task :build do
  resorts = Dir[File.join(__dir__, 'resorts', '*.csv')].flat_map do |filename|
    Resort.from_csv(filename)
  end
  build!(resorts)
end

task :fast do
  resorts = Dir[File.join(__dir__, 'resorts', '*.csv')].flat_map do |filename|
    Resort.from_csv(filename)
  end.shuffle.take(5)

  build!(resorts)
end

task :fmt do
  sh('rubocop -A')
end

task :test do
  sh('bundle exec rspec')
end

task :scrape do
  sh('ruby lib/csv_builder.rb')
end

task default: %i[fmt test build]
