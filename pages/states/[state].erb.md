---
title: 'Weekly forecast of snow for <%= h state %>'
description: 'Weekly forecast of snow for <%= h state %>'
---

## [<%= h resorts.first.country %>](/#<%= resorts.first.country.parameterize %>) &raquo; <%= h state %>


<%= table_for_resorts(resorts) %>


*Last Updated:* <%= h current_timestamp %>