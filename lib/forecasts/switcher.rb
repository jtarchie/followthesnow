# frozen_string_literal: true

Forecast::Switcher = Struct.new(:rules, keyword_init: true) do
  def new(resort:, fetcher:)
    klass = Forecast::NOAA
    rule  = rules.find do |r|
      !r.call(resort).nil?
    end

    klass = rule.call(resort) if rule

    klass.new(resort: resort, fetcher: fetcher)
  end
end
