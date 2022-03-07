# frozen_string_literal: true

require_relative './lib/builder'
require_relative './lib/resort'

task :build do
  resorts = Resort.from_csv(File.join(__dir__, 'resorts.csv'))

  builder = Builder.new(
    resorts: resorts,
    source_dir: __dir__,
    build_dir: File.join(__dir__, 'docs')
  )

  builder.build!
end

task :fmt do
  sh('rubocop -A')
end

task default: %i[build]
