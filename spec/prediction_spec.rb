# frozen_string_literal: true

require 'json'
require 'spec_helper'
require 'webmock/rspec'
require_relative '../lib/prediction'

RSpec.describe 'Prediction' do
  before do
    WebMock.disable_net_connect!
  end

  context 'when the resort has snow' do
    it 'gives a helpful report' do
      resort = Resort.new(lat: 1.001, lng: 2.002)
      prediction = Prediction.new(resort: resort)

      stub_request(:get, 'https://api.weather.gov/points/1.001,2.002')
        .to_return(status: 200, body: {
          properties: {
            forecast: 'https://api.weather.gov/gridpoints/TEST/1,2/forecast'
          }
        }.to_json)

      stub_request(:get, 'https://api.weather.gov/gridpoints/TEST/1,2/forecast')
        .to_return(status: 200, body: {
          properties: {
            periods: [
              { shortForecast: 'Snow', detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
              { shortForecast: 'Snow', detailedForecast: 'We are expecting 4 to 9 inches of snow.' }
            ]
          }
        }.to_json)

      expect(prediction.text_report).to eq '2-4" of snow expected today and 4-9" of snow expected tonight'
    end
  end

  context 'when the resort will have light snow' do
    it 'gives a helpful report' do
      resort = Resort.new(lat: 1.001, lng: 2.002)
      prediction = Prediction.new(resort: resort)

      stub_request(:get, 'https://api.weather.gov/points/1.001,2.002')
        .to_return(status: 200, body: {
          properties: {
            forecast: 'https://api.weather.gov/gridpoints/TEST/1,2/forecast'
          }
        }.to_json)

      stub_request(:get, 'https://api.weather.gov/gridpoints/TEST/1,2/forecast')
        .to_return(status: 200, body: {
          properties: {
            periods: [
              { shortForecast: 'Snow', detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
              { shortForecast: 'Light Snow', detailedForecast: 'We are expecting 1 to 2 inches of snow.' }
            ]
          }
        }.to_json)

      expect(prediction.text_report).to eq '2-4" of snow expected today and 1-2" of snow expected tonight'
    end
  end

  context 'when the resort has snow today, but none tomorrow' do
    it 'gives a helpful report' do
      resort = Resort.new(lat: 1.001, lng: 2.002)
      prediction = Prediction.new(resort: resort)

      stub_request(:get, 'https://api.weather.gov/points/1.001,2.002')
        .to_return(status: 200, body: {
          properties: {
            forecast: 'https://api.weather.gov/gridpoints/TEST/1,2/forecast'
          }
        }.to_json)

      stub_request(:get, 'https://api.weather.gov/gridpoints/TEST/1,2/forecast')
        .to_return(status: 200, body: {
          properties: {
            periods: [
              { shortForecast: 'Snow', detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
              { shortForecast: 'Sunny', detailedForecast: 'It is way too sunny to ski.' }
            ]
          }
        }.to_json)

      expect(prediction.text_report).to eq '2-4" of snow expected today and no snow expected tonight'
    end
  end

  context 'when there is no snow today, but snow tomorrow' do
    it 'gives a helpful report' do
      resort = Resort.new(lat: 1.001, lng: 2.002)
      prediction = Prediction.new(resort: resort)

      stub_request(:get, 'https://api.weather.gov/points/1.001,2.002')
        .to_return(status: 200, body: {
          properties: {
            forecast: 'https://api.weather.gov/gridpoints/TEST/1,2/forecast'
          }
        }.to_json)

      stub_request(:get, 'https://api.weather.gov/gridpoints/TEST/1,2/forecast')
        .to_return(status: 200, body: {
          properties: {
            periods: [
              { shortForecast: 'Sunny', detailedForecast: 'It is way too sunny to ski.' },
              { shortForecast: 'Snow', detailedForecast: 'We are expecting 2 to 4 inches of snow.' }
            ]
          }
        }.to_json)

      expect(prediction.text_report).to eq 'no snow expected today and 2-4" of snow expected tonight'
    end
  end

  context 'when there no snow on either days' do
    it 'gives a helpful report' do
      resort = Resort.new(lat: 1.001, lng: 2.002)
      prediction = Prediction.new(resort: resort)

      stub_request(:get, 'https://api.weather.gov/points/1.001,2.002')
        .to_return(status: 200, body: {
          properties: {
            forecast: 'https://api.weather.gov/gridpoints/TEST/1,2/forecast'
          }
        }.to_json)

      stub_request(:get, 'https://api.weather.gov/gridpoints/TEST/1,2/forecast')
        .to_return(status: 200, body: {
          properties: {
            periods: [
              { shortForecast: 'Sunny', detailedForecast: 'It is way too sunny to ski.' },
              { shortForecast: 'Sunny', detailedForecast: 'It is way too sunny to ski.' }
            ]
          }
        }.to_json)

      expect(prediction.text_report).to eq 'no snow expected today and no snow expected tonight'
    end
  end
end
