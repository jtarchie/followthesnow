# frozen_string_literal: true

Resort = Struct.new(:name, :lat, :lng, :city, :state, keyword_init: true) do
  def coords
    [lat, lng]
  end
end
