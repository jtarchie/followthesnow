# frozen_string_literal: true

require 'http'
require 'nokogiri'
require 'ostruct'
require 'geo/coord'

module Scrape
  Wikipedia = Struct.new(:url, keyword_init: true) do
    def resorts
      doc = Nokogiri::HTML(HTTP.follow.get(url).to_s)
      doc.css('#mw-content-text ul > li > a:first-child').map do |link|
        href = link['href']
        next if href =~ /Template|Category|Comparison|List|Former/i

        begin
          link_doc = Nokogiri::HTML(HTTP.follow.get("https://en.wikipedia.org#{href}").to_s)
        rescue HTTP::ConnectionError
          next
        end

        location = link_doc.css('.geo').first
        next unless location

        title = link_doc.css('h1')
                        .text
                        .gsub(/\s*\(.*\)\s*/, '')
                        .gsub(/\s*,.*$/, '')
                        .strip
        geo   = ::Geo::Coord.parse(location.text)
        url   = if (link = link_doc.css('.infobox-data .url a').first)
                  link['href']
                end
        puts "  resort: #{title}"

        OpenStruct.new({
                         name: title,
                         lat: geo.lat,
                         lng: geo.lng,
                         url:
                       })
      end.compact
    end
  end
end
