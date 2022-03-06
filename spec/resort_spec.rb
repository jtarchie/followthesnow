# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/prediction'

RSpec.describe('Resort') do
  it 'returns coordinates' do
    resort = Resort.new(lat: 1.001, lng: 2.002)
    expect(resort.coords).to eq [1.001, 2.002]
  end
end
