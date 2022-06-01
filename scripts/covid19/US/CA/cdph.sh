#!/bin/bash

## Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_California_by_county.tab?action=raw' > commons.json

# Fetch the latest day's statistics by county from CKAN
# SELECT * FROM "046cdd2b-31e5-4d34-9ed3-b48cdbc4be7a" WHERE cumulative_total_tests <> '0' LIMIT 61
curl 'https://data.chhs.ca.gov/api/3/action/datastore_search_sql?sql=SELECT%20*%20FROM%20%22046cdd2b-31e5-4d34-9ed3-b48cdbc4be7a%22%20WHERE%20cumulative_total_tests%20<>%20%270%27%20LIMIT%2061' > dashboard.json

# Update Commons
jq -s --tab '.[0].data = (.[1].result.records | map([(.date | strptime("%m/%d/%Y") | strftime("%Y-%m-%d")), .area, (.population | values | tonumber) // null, (.cumulative_total_tests | values | tonumber) // null, (.cumulative_positive_tests | values | tonumber) // null, (.cumulative_cases | values | tonumber) // null, (.cumulative_deaths | values | tonumber) // null])) | .[0]' commons.json dashboard.json | expand -t4
