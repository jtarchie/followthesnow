# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Resort') do
  it 'can load a sqlite file' do
    files = Dir[File.join(__dir__, '..', 'data', '*.sqlite')]
    expect(files.length).to be > 0

    files.each do |file|
      resorts = FollowTheSnow::Resort.from_sqlite(file)
      expect(resorts.length).to be > 0
    end
  end
end
