# frozen_string_literal: true

require 'csv'
require 'geo/coord'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'ostruct'

WikipediaScraper = Struct.new(:url, keyword_init: true) do
  def resorts
    doc = Nokogiri::HTML(URI.open(url))
    doc.css('.mw-category-group ul li a').each do |link|
      href = link['href']
      next if href =~ /Template|Category|Comparison/i

      link_doc = Nokogiri::HTML(URI.open(%(https://en.wikipedia.org#{href})))

      location = link_doc.css('.geo').first
      next unless location

      title   = link_doc.css('h1').text
      geo     = Geo::Coord.parse(location.text)
      address = address(lat: geo.lat, lng: geo.lng)

      city = address.city || address.village || address.leisure || address.tourism || address.building

      puts [title, geo.lat.to_f, geo.lng.to_f, city, address.state].to_csv
      sleep(1) # rate limit
    end
  end

  private

  def address(lat:, lng:)
    response = JSON.parse(URI.open(%(https://nominatim.openstreetmap.org/reverse?lat=#{lat.to_f}&lon=#{lng.to_f}&format=jsonv2)).read)
    OpenStruct.new(response['address'])
  end
end

if __FILE__ == $PROGRAM_NAME
  urls = [
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_California',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Colorado',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Idaho',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Montana',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_New_Mexico',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Utah',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Wyoming'
  ]

  puts 'name,lat,lng,city,state'
  urls.each do |url|
    scraper = WikipediaScraper.new(url: url)
    scraper.resorts
  end
end
