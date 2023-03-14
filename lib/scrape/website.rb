# frozen_string_literal: true

require 'ferrum'
require 'nokogiri'
require 'json'
require 'ostruct'
require 'openai'

module Scrape
  class Website
    def metadata(url:)
      return OpenStruct.new unless url

      browser.go_to(url)
      return OpenStruct.new unless browser.network.status == 200

      body          = browser.at_css('body').inner_text
      scrubbed_text = body
                      .split("\n")
                      .map do |line|
                        line
                          .chomp
                          .strip
                          .squeeze(' ')
                          .downcase
                      end
                      .reject { |line| line.split(' ').length <= 5 }
                      .uniq
                      .join(' ')
      prompt        = <<~PROMPT
        This is raw text from a ski resort website. Return JSON payload of the resort that includes if it is closed for the season. For example, `{"closed": true}`.

        #{scrubbed_text}
      PROMPT

      response      = client.chat(
        parameters: {
          model: 'gpt-3.5-turbo',
          messages: [{
            role: 'user',
            content: prompt
          }],
          temperature: 0.7
        }
      )

      payload = response.dig('choices', 0, 'message', 'content') || '{"closed": false}'
      OpenStruct.new(JSON.parse(payload))
    end

    private

    def browser
      @browser ||= Ferrum::Browser.new
    end

    def client
      @client ||= OpenAI::Client.new(access_token: ENV.fetch('OPENAI_ACCESS_TOKEN'))
    end
  end
end
