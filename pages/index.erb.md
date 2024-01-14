---
title: List by countries
description: List of countries that have ski resorts.
---

Our mission is to provide you with accurate and timely snowfall forecasts, so
you can make the most of your skiing adventures.

To use our site, simply browse through the provinces and states. Each
region to discover a comprehensive list of ski resorts, complete with snowfall
predictions for the next seven days.

<% countries.each do |country| %>

## <%= h country %> {#<%= country.parameterize %>}
<% states(country: country).each do |state| %>
* [<%= h state %>](/states/<%= state.parameterize %>)
<% end %>

<% end %>

*Last Updated:* <%= h current_timestamp %>