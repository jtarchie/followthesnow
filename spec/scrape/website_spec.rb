# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe 'Website Metadata' do
  context 'when getting a resort frontpage' do
    let(:url) { 'https://some-resort.com' }

    before do
      ENV['OPENAI_ACCESS_TOKEN'] = 'fake_token'
    end

    it 'determines if it open or not' do
      stub_openai_prompt
      stub_browser(url:)
      logger = Ougai::Logger.new($stderr)

      client   = FollowTheSnow::Scrape::Website.new(logger:)
      metadata = client.metadata(url:)
      expect(metadata.closed).to eq(true)
    end
  end
end
