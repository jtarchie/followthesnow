# frozen_string_literal: true

Forecast::Aggregate = Struct.new(:forecasts, keyword_init: true) do
  def forecasts
    @forecasts ||= begin
      final_forecasts = self['forecasts'].dup
      self['forecasts'].group_by(&:time_of_day).each do |_time_of_day, grouped_forecasts|
        first, second = grouped_forecasts
        next unless first && second

        combined = Forecast.new(
          time_of_day: first.time_of_day,
          range: [first.range.begin, second.range.begin].max..(first.range.end + second.range.end)
        )
        final_forecasts.insert(final_forecasts.index(first), combined)
        final_forecasts.delete_at(final_forecasts.index(first))
        final_forecasts.delete_at(final_forecasts.index(second))
      end
      final_forecasts
    end
  end
end
