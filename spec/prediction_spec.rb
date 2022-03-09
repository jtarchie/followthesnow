# frozen_string_literal: true

require 'json'
require 'spec_helper'
require 'tempfile'
require 'webmock/rspec'
require_relative '../lib/prediction'

RSpec.describe 'Prediction' do
  let(:fetcher) { TestFetcher.new }

  before do
    WebMock.disable_net_connect!
  end

  def forecast(periods)
    stub_request(:get, 'https://api.weather.gov/points/1.001,2.002')
      .to_return(status: 200, body: {
        properties: {
          forecast: 'https://api.weather.gov/gridpoints/TEST/1,2/forecast'
        }
      }.to_json)

    stub_request(:get, 'https://api.weather.gov/gridpoints/TEST/1,2/forecast')
      .to_return(status: 200, body: {
        properties: {
          periods: periods
        }
      }.to_json)
  end

  context 'when the resort has snow' do
    it 'gives a helpful report' do
      resort = Resort.new(lat: 1.001, lng: 2.002)
      prediction = Prediction.new(resort: resort, fetcher: fetcher)

      forecast([
                 { shortForecast: 'Snow', name: 'Today', detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
                 { shortForecast: 'Snow', name: 'Tonight', detailedForecast: 'We are expecting 4 to 9 inches of snow.' }
               ])

      expect(prediction.text_report).to eq '2-4" of snow Today and 4-9" of snow Tonight'
    end
  end

  context 'when the resort will have light snow' do
    it 'gives a helpful report' do
      resort = Resort.new(lat: 1.001, lng: 2.002)
      prediction = Prediction.new(resort: resort, fetcher: fetcher)

      forecast([
                 { shortForecast: 'Snow', name: 'Today', detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
                 { shortForecast: 'Light Snow', name: 'Tonight',
                   detailedForecast: 'We are expecting 1 to 2 inches of snow.' }
               ])

      expect(prediction.text_report).to eq '2-4" of snow Today and 1-2" of snow Tonight'
    end
  end

  context 'when the resort has snow Today, but none tomorrow' do
    it 'gives a helpful report' do
      resort = Resort.new(lat: 1.001, lng: 2.002)
      prediction = Prediction.new(resort: resort, fetcher: fetcher)

      forecast([
                 { shortForecast: 'Snow', name: 'Today', detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
                 { shortForecast: 'Sunny', name: 'Tonight', detailedForecast: 'It is way too sunny to ski.' }
               ])

      expect(prediction.text_report).to eq '2-4" of snow Today and no snow Tonight'
    end
  end

  context 'when there is no snow Today, but snow tomorrow' do
    it 'gives a helpful report' do
      resort = Resort.new(lat: 1.001, lng: 2.002)
      prediction = Prediction.new(resort: resort, fetcher: fetcher)

      forecast([
                 { shortForecast: 'Sunny', name: 'Today', detailedForecast: 'It is way too sunny to ski.' },
                 { shortForecast: 'Snow', name: 'Tonight', detailedForecast: 'We are expecting 2 to 4 inches of snow.' }
               ])

      expect(prediction.text_report).to eq 'no snow Today and 2-4" of snow Tonight'
    end
  end

  context 'when there no snow on either days' do
    it 'gives a helpful report' do
      resort = Resort.new(lat: 1.001, lng: 2.002)
      prediction = Prediction.new(resort: resort, fetcher: fetcher)

      forecast([
                 { shortForecast: 'Sunny', name: 'Today', detailedForecast: 'It is way too sunny to ski.' },
                 { shortForecast: 'Sunny', name: 'Tonight', detailedForecast: 'It is way too sunny to ski.' }
               ])

      expect(prediction.text_report).to eq 'no snow Today and no snow Tonight'
    end
  end

  context 'when there is snow a later in the week' do
    it 'gives a helpful report' do
      resort = Resort.new(lat: 1.001, lng: 2.002)
      prediction = Prediction.new(resort: resort, fetcher: fetcher)

      forecast([
                 { shortForecast: 'Sunny', name: 'Today', detailedForecast: 'It is way too sunny to ski.' },
                 { shortForecast: 'Sunny', name: 'Tonight', detailedForecast: 'It is way too sunny to ski.' },
                 { shortForecast: 'Snow', name: 'Thursday Night',
                   detailedForecast: 'We are expecting 2 to 4 inches of snow.' }
               ])

      expect(prediction.text_report).to eq 'no snow Today, no snow Tonight, and 2-4" of snow Thursday Night'
    end
  end

  context 'when the snow report is less than an inch' do
    it 'gives a helpful report' do
      resort = Resort.new(lat: 1.001, lng: 2.002)
      prediction = Prediction.new(resort: resort, fetcher: fetcher)

      forecast([
                 { shortForecast: 'Snow', name: 'Today',
                   detailedForecast: 'New snow accumulation of around one inch possible' },
                 { shortForecast: 'Snow', name: 'Tonight',
                   detailedForecast: 'New snow accumulation of less than half an inch possible' },
                 { shortForecast: 'Snow', name: 'Wednesday',
                   detailedForecast: 'New snow accumulation of less than one inch possible.' },
                { shortForecast: 'Snow', name: 'Thursday',
                    detailedForecast: 'Little or no snow accumulation expected.' },
                 { shortForecast: 'Sunny', name: 'Friday Night', detailedForecast: 'It is way too sunny to ski.' }
               ])

      expect(prediction.text_report).to eq(
        '<1" of snow Today, <1" of snow Tonight, ' \
        '<1" of snow Wednesday, no snow Thursday, and no snow Friday Night'
      )
    end
  end

  context 'when the points returns a 500' do
    it 'returns a prediction of cannot fiqure it out' do
      resort = Resort.new(lat: 1.001, lng: 2.002)
      prediction = Prediction.new(resort: resort, fetcher: fetcher)

      stub_request(:get, 'https://api.weather.gov/points/1.001,2.002')
        .to_return(status: 500)

      expect(prediction.text_report).to eq 'no current weather reports can be found'
    end
  end

  context 'when the forecast returns a 500' do
    it 'returns a prediction of cannot fiqure it out' do
      resort = Resort.new(lat: 1.001, lng: 2.002)
      prediction = Prediction.new(resort: resort, fetcher: fetcher)

      stub_request(:get, 'https://api.weather.gov/points/1.001,2.002')
        .to_return(status: 200, body: {
          properties: {
            forecast: 'https://api.weather.gov/gridpoints/TEST/1,2/forecast'
          }
        }.to_json)

      stub_request(:get, 'https://api.weather.gov/gridpoints/TEST/1,2/forecast')
        .to_return(status: 500)

      expect(prediction.text_report).to eq 'no current weather reports can be found'
    end
  end
end
