# frozen_string_literal: true

require 'csv'
require 'ferrum'
require 'geo/coord'
require 'http'
require 'json'
require 'nokogiri'
require 'ostruct'

WikipediaScraper = Struct.new(:url, keyword_init: true) do
  def resorts
    $stdout.sync = true

    doc = Nokogiri::HTML(HTTP.follow.get(url).to_s)
    doc.css('#mw-content-text ul > li > a:first-child').each do |link|
      href = link['href']
      next if href =~ /Template|Category|Comparison|List/i

      begin
        link_doc = Nokogiri::HTML(HTTP.follow.get(%(https://en.wikipedia.org#{href})).to_s)
      rescue HTTP::ConnectionError
        return
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
      city        = address.city || address.village || address.leisure || address.tourism || address.building
      url, closed = validate(url: link_doc.css('.infobox-data .url a').first, matcher: /closed/i)

      puts [
        title,
        closed,
        geo.lat.to_f,
        geo.lng.to_f,
        city,
        address.state,
        url,
        forecast_url(lat: geo.lat.to_f, lng: geo.lng.to_f)
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

  def forecast_url(lat:, lng:)
    # JSON.parse(
    #   HTTP.follow.get(%(https://api.weather.gov/points/#{lat},#{lng})).to_s
    # ).dig('properties', 'forecast')
    ""
  end

  def address(lat:, lng:)
    response = JSON.parse(HTTP.follow.get(%(https://nominatim.openstreetmap.org/reverse?lat=#{lat.to_f}&lon=#{lng.to_f}&format=jsonv2)).to_s)
    OpenStruct.new(response['address'])
  end
end

if __FILE__ == $PROGRAM_NAME
  urls = [
    'https://en.wikipedia.org/wiki/List_of_ski_areas_and_resorts_in_the_United_States'
  ]

  puts 'name,closed,lat,lng,city,state,url,forecast_url'
  urls.each do |url|
    scraper = WikipediaScraper.new(url: url)
    scraper.resorts
  end
end
