# frozen_string_literal: true

require 'csv'
require 'geo/coord'
require 'json'
require 'nokogiri'
require 'http'
require 'ostruct'

WikipediaScraper = Struct.new(:url, keyword_init: true) do
  def resorts
    $stdout.sync = true

    doc = Nokogiri::HTML(HTTP.follow.get(url).to_s)
    doc.css('.mw-category-group ul li a').each do |link|
      href = link['href']
      next if href =~ /Template|Category|Comparison/i

      link_doc = Nokogiri::HTML(HTTP.follow.get(%(https://en.wikipedia.org#{href})).to_s)

      location = link_doc.css('.geo').first
      next unless location

      title   = link_doc.css('h1')
                        .text
                        .gsub(/\s*\(.*\)\s*/, '')
                        .gsub(/\s*,.*$/, '')
                        .strip
      geo     = Geo::Coord.parse(location.text)
      address = address(lat: geo.lat, lng: geo.lng)
      url     = validate(url: link_doc.css('.infobox-data .url a').first)
      city    = address.city || address.village || address.leisure || address.tourism || address.building

      puts [
        title,
        geo.lat.to_f,
        geo.lng.to_f,
        city,
        address.state,
        url,
        forecast_url(lat: geo.lat.to_f, lng: geo.lng.to_f)
      ].to_csv
      sleep(1) # rate limit
    end
  end

  private

  def validate(url:)
    return unless url

    href = url['href']

    response = begin
      HTTP.follow.head(href)
    rescue StandardError
      return nil
    end
    return unless response.status.success?

    href
  end

  def forecast_url(lat:, lng:)
    JSON.parse(
      HTTP.follow.get(%(https://api.weather.gov/points/#{lat},#{lng})).to_s
    ).dig('properties', 'forecast')
  end

  def address(lat:, lng:)
    response = JSON.parse(HTTP.follow.get(%(https://nominatim.openstreetmap.org/reverse?lat=#{lat.to_f}&lon=#{lng.to_f}&format=jsonv2)).to_s)
    OpenStruct.new(response['address'])
  end
end

if __FILE__ == $PROGRAM_NAME
  urls = [
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_California',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Colorado',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Idaho',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Montana',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Nevada',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_New_Mexico',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Oregon',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Utah',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Vermont',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Washington_(state)',
    'https://en.wikipedia.org/wiki/Category:Ski_areas_and_resorts_in_Wyoming',
  ]

  puts 'name,lat,lng,city,state,url,forecast_url'
  urls.each do |url|
    scraper = WikipediaScraper.new(url: url)
    scraper.resorts
  end
end
