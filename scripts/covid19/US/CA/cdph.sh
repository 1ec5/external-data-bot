#!/bin/bash

## Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_California_by_county.tab?action=raw' > commons.json

# Fetch the latest day's statistics by county from CKAN
# SELECT * FROM (SELECT date,area,population,cumulative_total_tests,cumulative_positive_tests,cumulative_cases,cumulative_deaths,RANK() OVER (PARTITION BY area ORDER BY date DESC) area_rank FROM "046cdd2b-31e5-4d34-9ed3-b48cdbc4be7a" WHERE date IS NOT NULL) p WHERE p.area_rank = 1
curl 'https://data.chhs.ca.gov/api/3/action/datastore_search_sql?sql=SELECT%20*%20FROM%20(SELECT%20date,area,population,cumulative_total_tests,cumulative_positive_tests,cumulative_cases,cumulative_deaths,RANK()%20OVER%20(PARTITION%20BY%20area%20ORDER%20BY%20date%20DESC)%20area_rank%20FROM%20%22046cdd2b-31e5-4d34-9ed3-b48cdbc4be7a%22%20WHERE%20date%20%3E%20%272020-01-01%27)%20p%20WHERE%20p.area_rank%20=%201' > dashboard.json

# Update Commons
jq -s --tab '.[0].data = (.[1].result.records | map([.date, .area, (.population | values | tonumber) // null, (.cumulative_total_tests | values | tonumber) // null, (.cumulative_positive_tests | values | tonumber) // null, (.cumulative_cases | values | tonumber) // null, (.cumulative_deaths | values | tonumber) // null])) | .[0]' commons.json dashboard.json | expand -t4
