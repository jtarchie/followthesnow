require 'spec_helper'
require 'tmpdir'
require_relative '../pages/build'
require_relative '../lib/resort'

RSpec.describe('Building') do
  let(:build_dir) { Dir.mktmpdir }
  let(:pages_dir) { File.expand_path(File.join(__dir__, '..', 'pages')) }
  let(:resorts_dir) { File.expand_path(File.join(__dir__, '..', 'resorts'))}

  it 'builds HTML files', :vcr do
    resorts = Dir[File.join(resorts_dir, '*.csv')].flat_map do |filename|
      Resort.from_csv(filename)
    end.take(5)

    builder   = Builder::Site.new(
      build_dir: build_dir,
      resorts: resorts,
      source_dir: pages_dir
    )
  
    builder.build!
    
    html_files = Dir[File.join(build_dir, "**", "*.html")].to_a
    expect(html_files.length).to eq(7)
  end
end