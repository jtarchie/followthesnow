---
title: 'Weekly forecast of snow for [resort]'
description: 'Weekly forecast of snow for [state]'
---

## [<%= h resorts.first.country %>](/#<%= resorts.first.country.parameterize %>) &raquo; <%= h state %>


<%= table_for_resorts(resorts) %>


*Last Updated:* <%= h current_timestamp %>