# frozen_string_literal: true

require_relative './scrape/wikipedia'
require_relative './scrape/website'
require_relative './scrape/geo'
require 'csv'

CSVBuilder = Struct.new(:build_dir, :country, :url, keyword_init: true) do
  def build!
    resorts = Scrape::Wikipedia.new(url:).resorts
    geo     = Scrape::Geo.new
    website = Scrape::Website.new

    filename  = File.expand_path(File.join(build_dir, "#{country}.csv"))
    file      = File.open(filename, 'w')
    file.sync = true
    file.puts 'name,closed,lat,lng,city,state,country,url'

    resorts.map do |resort|
      address  = geo.to_address(lat: resort.lat, lng: resort.lng)
      metadata = if address.state == 'Colorado'
                   website.metadata(url: resort.url)
                 else
                   OpenStruct.new(closed: false)
                 end

      file.puts([
        resort.name,
        metadata.closed,
        resort.lat,
        resort.lng,
        address.city,
        address.state,
        address.country,
        resort.url
      ].to_csv)
    end

    file.close
  end
end

if __FILE__ == $PROGRAM_NAME
  urls = {
    canada: 'https://en.wikipedia.org/wiki/List_of_ski_areas_and_resorts_in_Canada',
    united_states: 'https://en.wikipedia.org/wiki/List_of_ski_areas_and_resorts_in_the_United_States'
  }

  build_dir = File.join(__dir__, '..', 'resorts')

  urls.each do |country, url|
    puts "Loading for country: #{country}"
    CSVBuilder.new(
      build_dir:,
      country:,
      url:
    ).build!
  end
end
