# frozen_string_literal: true

require_relative './lib/builder'
require_relative './lib/resort'
require 'csv'

task :build do
  resorts = CSV.read('resorts.csv', headers: true).map do |resort|
    Resort.new(resort.to_h)
  end

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
