# frozen_string_literal: true

require 'geo/coord'
require 'http'
require 'nokogiri'
require 'ostruct'
require 'parallel'

module FollowTheSnow
  module Scrape
    Wikipedia = Struct.new(:url, :logger, keyword_init: true) do
      def resorts
        doc   = Nokogiri::HTML(HTTP.follow.timeout(10).get(url).to_s)
        links = doc.css('#mw-content-text ul > li > a:not(.new):first-child, #mw-content-text ul > li > a.new + a')
        Parallel.map(links, in_threads: 5) do |link|
          href = link['href']
          next if href =~ /Template|Category|Comparison|List|Former/i

          child_logger = logger.child(wiki: href)

          begin
            child_logger.info('loading page')
            link_doc = Nokogiri::HTML(HTTP.follow.timeout(10).get("https://en.wikipedia.org#{href}").to_s)
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
          child_logger.info('found resort', { resort: title })

          resort = OpenStruct.new({
                                    name: title,
                                    lat: geo.lat,
                                    lng: geo.lng,
                                    url: url
                                  })
          # prevent rate limit and bot detection
          # from wikipedia
          sleep(rand(0.0..1.0))
          resort
        end.compact
      end
    end
  end
end
