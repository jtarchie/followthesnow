# frozen_string_literal: true

require 'csv'
require 'ferrum'
require 'geo/coord'
require 'http'
require 'json'
require 'nokogiri'
require 'ostruct'

WikipediaScraper = Struct.new(:url, keyword_init: true) do
  def resorts_to_csv(file:)
    doc        = Nokogiri::HTML(HTTP.follow.get(url).to_s)
    doc.css('#mw-content-text ul > li > a:first-child').map do |link|
      href = link['href']
      next if href =~ /Template|Category|Comparison|List/i

      begin
        link_doc = Nokogiri::HTML(HTTP.follow.get(%(https://en.wikipedia.org#{href})).to_s)
      rescue HTTP::ConnectionError
        next
      end

      location = link_doc.css('.geo').first
      next unless location

      title       = link_doc.css('h1')
                            .text
                            .gsub(/\s*\(.*\)\s*/, '')
                            .gsub(/\s*,.*$/, '')
                            .strip
      geo         = Geo::Coord.parse(location.text)
      address     = address(lat: geo.lat, lng: geo.lng)
      city        = address.city || address.village || address.leisure || address.tourism || address.building || address.road || address.county
      url, closed = validate(url: link_doc.css('.infobox-data .url a').first, matcher: /closed/i)

      file.puts [
        title,
        closed,
        geo.lat.to_f,
        geo.lng.to_f,
        city,
        address.state,
        address.country,
        url
      ].to_csv
    end
  end

  private

  def browser
    @browser ||= Ferrum::Browser.new
  end

  def validate(url:, matcher:)
    href     = url['href']
    browser.go_to(href)
    return nil, false unless browser.network.status == 200

    body = Nokogiri::HTML(browser.body)
    [href, matcher.match?(body.text)]
  rescue StandardError
    [nil, false]
  end

  def address(lat:, lng:)
    response = JSON.parse(HTTP.follow.get(%(https://nominatim.openstreetmap.org/reverse?lat=#{lat.to_f}&lon=#{lng.to_f}&format=jsonv2)).to_s)
    OpenStruct.new(response['address'])
  end
end

if __FILE__ == $PROGRAM_NAME
  urls = {
    canada: 'https://en.wikipedia.org/wiki/List_of_ski_areas_and_resorts_in_Canada',
    united_states: 'https://en.wikipedia.org/wiki/List_of_ski_areas_and_resorts_in_the_United_States'
  }

  urls.each do |country, url|
    puts "Loading for country: #{country}"
    filename  = File.expand_path(File.join(__dir__, '..', 'resorts', "#{country}.csv"))
    file      = File.open(filename, 'w')
    file.sync = true
    file.puts 'name,closed,lat,lng,city,state,country,url'
    scraper   = WikipediaScraper.new(url:)
    scraper.resorts_to_csv(file:)
    file.close
  end
end
