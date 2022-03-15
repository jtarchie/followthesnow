# frozen_string_literal: true

require 'json'
require 'spec_helper'
require 'tempfile'
require 'webmock/rspec'
require_relative '../lib/forecast'
require_relative '../lib/http_cache'
require_relative '../lib/resort'

RSpec.describe 'Forecast' do
  let(:fetcher) do
    HTTPCache.new
  end
  let(:resort) { Resort.new(lat: 1.001, lng: 2.002) }
  let(:text_forecast) do
    Forecast.from(
      resort: resort,
      aggregates: [Forecast::Aggregate, Forecast::Text],
      fetcher: fetcher
    )
  end

  before do
    WebMock.disable_net_connect!
    allow_any_instance_of(Object).to receive(:warn)
    allow_any_instance_of(Object).to receive(:sleep)
  end

  def json_forecast(periods)
    stub_request(:get, 'https://api.weather.gov/points/1.001,2.002')
      .to_return(status: 200, body: {
        properties: {
          forecast: 'https://api.weather.gov/gridpoints/TEST/1,2/forecast'
        }
      }.to_json)

    stub_request(:get, 'https://api.weather.gov/gridpoints/TEST/1,2/forecast')
      .to_return(status: 200, body: {
        properties: {
          updated: Time.now.to_s,
          periods: periods
        }
      }.to_json)
  end

  context 'when the resort has snow' do
    it 'gives a helpful report' do
      json_forecast([
                      { shortForecast: 'Snow', name: 'Today', startTime: '2022-03-01T18:00:00-08:00',
                        detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
                      { shortForecast: 'Snow', name: 'Tonight', startTime: '2022-03-01T18:00:00-08:00',
                        detailedForecast: 'We are expecting 4 to 9 inches of snow.' }
                    ])

      expect(text_forecast.forecasts).to eq '4-13" of snow 03/01'
    end
  end

  context 'when the resort will have light snow' do
    it 'gives a helpful report' do
      json_forecast([
                      { shortForecast: 'Snow', name: 'Today', startTime: '2022-03-01T18:00:00-08:00',
                        detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
                      { shortForecast: 'Light Snow', name: 'Tonight', startTime: '2022-03-01T18:00:00-08:00',
                        detailedForecast: 'We are expecting 1 to 2 inches of snow.' }
                    ])

      expect(text_forecast.forecasts).to eq '2-6" of snow 03/01'
    end
  end

  context 'when the resort has snow Today, but none tomorrow' do
    it 'gives a helpful report' do
      json_forecast([
                      { shortForecast: 'Snow', name: 'Today', startTime: '2022-03-01T18:00:00-08:00',
                        detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
                      { shortForecast: 'Sunny', name: 'Tonight', startTime: '2022-03-01T18:00:00-08:00',
                        detailedForecast: 'It is way too sunny to ski.' }
                    ])

      expect(text_forecast.forecasts).to eq '2-4" of snow 03/01'
    end
  end

  context 'when there is no snow Today, but snow tomorrow' do
    it 'gives a helpful report' do
      json_forecast([
                      { shortForecast: 'Sunny', name: 'Today', startTime: '2022-03-01T18:00:00-08:00',
                        detailedForecast: 'It is way too sunny to ski.' },
                      { shortForecast: 'Snow', name: 'Tonight', startTime: '2022-03-01T18:00:00-08:00',
                        detailedForecast: 'We are expecting 2 to 4 inches of snow.' }
                    ])

      expect(text_forecast.forecasts).to eq '2-4" of snow 03/01'
    end
  end

  context 'when there no snow on either days' do
    it 'gives a helpful report' do
      json_forecast([
                      { shortForecast: 'Sunny', name: 'Today', startTime: '2022-03-01T18:00:00-08:00',
                        detailedForecast: 'It is way too sunny to ski.' },
                      { shortForecast: 'Sunny', name: 'Tonight', startTime: '2022-03-01T18:00:00-08:00',
                        detailedForecast: 'It is way too sunny to ski.' }
                    ])

      expect(text_forecast.forecasts).to eq 'no snow 03/01'
    end
  end

  context 'when there is snow a later in the week' do
    it 'gives a helpful report' do
      json_forecast([
                      { shortForecast: 'Sunny', name: 'Today', startTime: '2022-03-01T18:00:00-08:00',
                        detailedForecast: 'It is way too sunny to ski.' },
                      { shortForecast: 'Sunny', name: 'Tonight', startTime: '2022-03-01T18:00:00-08:00',
                        detailedForecast: 'It is way too sunny to ski.' },
                      { shortForecast: 'Snow', name: 'Thursday Night', startTime: '2022-03-02T18:00:00-08:00',
                        detailedForecast: 'We are expecting 2 to 4 inches of snow.' }
                    ])

      expect(text_forecast.forecasts).to eq 'no snow 03/01 and 2-4" of snow 03/02'
    end
  end

  context 'when the snow report is less than an inch' do
    it 'gives a helpful report' do
      json_forecast([
                      { shortForecast: 'Snow', name: 'Today', startTime: '2022-03-01T18:00:00-08:00',
                        detailedForecast: 'New snow accumulation of around one inch possible' },
                      { shortForecast: 'Snow', name: 'Tonight', startTime: '2022-03-01T18:00:00-08:00',
                        detailedForecast: 'New snow accumulation of less than half an inch possible' },
                      { shortForecast: 'Snow', name: 'Wednesday', startTime: '2022-03-02T18:00:00-08:00',
                        detailedForecast: 'New snow accumulation of less than one inch possible.' },
                      { shortForecast: 'Snow', name: 'Thursday', startTime: '2022-03-03T18:00:00-08:00',
                        detailedForecast: 'Little or no snow accumulation expected.' },
                      { shortForecast: 'Sunny', name: 'Friday Night', startTime: '2022-03-04T18:00:00-08:00',
                        detailedForecast: 'It is way too sunny to ski.' }
                    ])

      expect(text_forecast.forecasts).to eq('0-2" of snow 03/01 and <1" of snow 03/02')
    end
  end

  context 'when the points returns a 500' do
    it 'returns a prediction of cannot figure it out' do
      stub_request(:get, 'https://api.weather.gov/points/1.001,2.002')
        .to_return(status: 500)

      expect(text_forecast.forecasts).to eq 'no snow Today'
    end
  end

  context 'when the points does not have updated at' do
    it 'returns a prediction of cannot figure it out' do
      stub_request(:get, 'https://api.weather.gov/points/1.001,2.002')
        .to_return(status: 200, body: {
          properties: {
            forecast: 'https://api.weather.gov/gridpoints/TEST/1,2/forecast'
          }
        }.to_json)

      stub_request(:get, 'https://api.weather.gov/gridpoints/TEST/1,2/forecast')
        .to_return(status: 200, body: {}.to_json)

      expect(text_forecast.forecasts).to eq 'no snow Today'
    end
  end

  context 'when the forecast returns a 500' do
    it 'returns a prediction of cannot figure it out' do
      stub_request(:get, 'https://api.weather.gov/points/1.001,2.002')
        .to_return(status: 200, body: {
          properties: {
            forecast: 'https://api.weather.gov/gridpoints/TEST/1,2/forecast'
          }
        }.to_json)

      stub_request(:get, 'https://api.weather.gov/gridpoints/TEST/1,2/forecast')
        .to_return(status: 500)

      expect(text_forecast.forecasts).to eq 'no snow Today'
    end
  end

  context 'with emoji predictions' do
    it 'converts days to short names' do
      json_forecast([
                      { shortForecast: 'Snow', startTime: '2022-03-01T18:00:00-08:00', name: 'Today',
                        detailedForecast: 'It is way too sunny to ski.' },
                      { shortForecast: 'Snow', startTime: '2022-03-01T18:00:00-08:00', name: 'This Afternoon',
                        detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
                      { shortForecast: 'Snow', startTime: '2022-03-01T18:00:00-08:00', name: 'Tonight',
                        detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
                      { shortForecast: 'Snow', startTime: '2022-03-01T18:00:00-08:00', name: 'Overnight',
                        detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
                      { shortForecast: 'Snow', startTime: '2022-03-01T18:00:00-08:00', name: 'This Morning',
                        detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
                      { shortForecast: 'Snow', startTime: '2022-03-02T18:00:00-08:00', name: 'Wednesday',
                        detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
                      { shortForecast: 'Snow', startTime: '2022-03-02T18:00:00-08:00', name: 'Wednesday Night',
                        detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
                      { shortForecast: 'Snow', startTime: '2022-03-05T18:00:00-08:00', name: 'Saturday',
                        detailedForecast: 'We are expecting 2 to 4 inches of snow.' },
                      { shortForecast: 'Snow', startTime: '2022-03-05T18:00:00-08:00', name: 'Saturday Night',
                        detailedForecast: 'We are expecting 2 to 4 inches of snow.' }
                    ])

      emoji_forecast = Forecast.from(
        resort: resort,
        aggregates: [Forecast::Aggregate, Forecast::Emoji],
        fetcher: fetcher
      )

      emojis = emoji_forecast.forecasts.map do |forecast|
        [forecast.time_of_day, forecast.snow.to_s]
      end

      expect(emojis).to eq [
        ['03/01', '2-4"'],
        ['03/01', '2-4"'],
        ['03/01', '2-4"'],
        ['03/01', '2-4"'],
        ['03/02', '2-8"'],
        ['03/05', '2-8"']
      ]
    end
  end
end
