#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_San_Francisco.tab?action=raw' > commons.json

# Fetch the new cases and deaths by day from the API
curl https://data.sfgov.org/resource/tvq9-ec9w.json > tvq9-ec9w.json

# Convert date from full timestamp to YYYY-MM-DD
# Pivot on dates as rows and counts by case disposition as columns
# Calculate running totals
jq -s '.[0] | group_by(.date)[] | {date: (.[0].date | strptime("%Y-%m-%dT%H:%M:%S.000") | strftime("%Y-%m-%d")), newConfirmedCases: (reduce (.[] | select(.case_disposition == "Confirmed").case_count | tonumber) as $count (0; . + $count)), newDeaths: (reduce (.[] | select(.case_disposition == "Death").case_count | tonumber) as $count (0; . + $count))}' tvq9-ec9w.json | jq -s 'foreach .[] as $row (0; . + $row.newConfirmedCases; . as $x | $row | (.totalConfirmedCases = $x))' | jq -s 'foreach .[] as $row (0; . + $row.newDeaths; . as $x | $row | (.totalDeaths = $x)) | [.date, .newConfirmedCases, .totalConfirmedCases, .newDeaths, .totalDeaths]' | jq -s > data.json

# Replace the data in the table
jq -s --tab '.[0].data = .[1] | .[0]' commons.json data.json | expand -t4
