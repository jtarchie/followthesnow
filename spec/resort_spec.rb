# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/resort'

RSpec.describe('Resort') do
  it 'returns coordinates' do
    resort = Resort.new(lat: 1.001, lng: 2.002)
    expect(resort.coords).to eq [1.001, 2.002]
  end

  it 'can load a CSV file' do
    csv_files = Dir[File.join(__dir__, '..', 'resorts', '*.csv')]
    expect(csv_files.length).to be > 0

    csv_files.each do |csv_file|
      resorts = Resort.from_csv(csv_file)
      expect(resorts.length).to be > 0
    end
  end
end
