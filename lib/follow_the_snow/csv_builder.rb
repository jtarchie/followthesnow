# frozen_string_literal: true

require_relative './scrape/wikipedia'
require_relative './scrape/website'
require_relative './scrape/geo'
require 'csv'
require 'ougai'

module FollowTheSnow
  CSVBuilder = Struct.new(:build_dir, :country, :url, keyword_init: true) do
    def build!
      @logger       = Ougai::Logger.new($stderr)
      @logger.level = Ougai::Logger::DEBUG

      wikipedia = Scrape::Wikipedia.new(url: url, logger: @logger)
      geo       = Scrape::Geo.new
      # website   = Scrape::Website.new(logger:)

      filename  = File.expand_path(File.join(build_dir, "#{country}.csv"))
      file      = File.open(filename, 'w')
      file.sync = true
      file.puts 'name,closed,lat,lng,city,state,country,url'

      Parallel.each(wikipedia.resorts, in_threads: 3) do |resort|
        logger   = @logger.child(resort: resort.name)
        address  = geo.to_address(lat: resort.lat, lng: resort.lng, logger: logger)
        metadata = OpenStruct.new(closed: false)

        sleep(rand(0.0..1.0))

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
end

if __FILE__ == $PROGRAM_NAME
  urls = {
    canada: 'https://en.wikipedia.org/wiki/List_of_ski_areas_and_resorts_in_Canada',
    japan: 'https://en.wikipedia.org/wiki/List_of_ski_areas_and_resorts_in_Japan',
    united_states: 'https://en.wikipedia.org/wiki/List_of_ski_areas_and_resorts_in_the_United_States',
  }

  build_dir = File.join(__dir__, '..', '..', 'resorts')

  urls.each do |country, url|
    puts "Loading for country: #{country}"
    FollowTheSnow::CSVBuilder.new(
      build_dir: build_dir,
      country: country,
      url: url
    ).build!
  end
end
