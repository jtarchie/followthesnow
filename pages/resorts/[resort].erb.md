---
title: 'Weekly forecast of snow for [name]'
description: '[state] &raquo; [name]'
---

## [<%= h resort.country %>](/#<%= resort.country.parameterize %>) &raquo; [<%= h resort.state %>](/states/<%= resort.state.parameterize %>) &raquo; <%= h resort.name %>

<% unless resort.url.nil? %>
* [Homepage](<%= resort.url %>)
<% end %>
<% if resort.closed? %>
* Closed for season*
<% end %>

### Long term forecast

<%= table_for_longterm(resort) %>

<% if resort.closed? %>

(*) The resort may be closed for the season.

<% end %>

*Last Updated:* <%= h current_timestamp %>