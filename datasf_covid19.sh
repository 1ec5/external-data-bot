#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_San_Francisco.tab?action=raw' > commons.json

# Fetch the new cases and deaths by day from the API
curl https://data.sfgov.org/resource/tvq9-ec9w.json > tvq9-ec9w.json

# Convert date from full timestamp to YYYY-MM-DD
# Pivot on dates as rows and counts by case disposition as columns
# Calculate running totals
jq -s '.[0] | group_by(.date)[] | {date: (.[0].date | strptime("%Y-%m-%dT%H:%M:%S.000") | strftime("%Y-%m-%d")), newConfirmedCases: (reduce (.[] | select(.case_disposition == "Confirmed").case_count | tonumber) as $count (0; . + $count)), newDeaths: (reduce (.[] | select(.case_disposition == "Death").case_count | tonumber) as $count (0; . + $count))}' tvq9-ec9w.json | jq -s 'foreach .[] as $row (0; . + $row.newConfirmedCases; . as $x | $row | (.totalConfirmedCases = $x))' | jq -s 'foreach .[] as $row (0; . + $row.newDeaths; . as $x | $row | (.totalDeaths = $x))' | jq -s > cases.json

# Fetch hospitalizations by day from the API
curl https://data.sfgov.org/resource/nxjg-bhem.json > nxjg-bhem.json

# Convert date from full timestamp to YYYY-MM-DD
# Pivot on dates as rows and counts as columns
jq -s '.[0] | group_by(.reportdate)[] | {date: (.[0].reportdate | strptime("%Y-%m-%dT%H:%M:%S.000") | strftime("%Y-%m-%d")), hospitalizations: (reduce (.[].patientcount | tonumber) as $count (0; . + $count))}' nxjg-bhem.json | jq -s > hosp.json

# Join the counts and hospitalizations
jq -s 'map(INDEX(.date)) | JOIN(.[1]; .[0][]; .date; add)' cases.json hosp.json | jq -s > data.json

# Replace the data in the table
# Backfill older hospitalization data that has been removed from the API using existing data from the table
jq -s --tab '.[0].data as $orig | .[0].data = (.[1] | map([.date, .newConfirmedCases, .totalConfirmedCases, .newDeaths, .totalDeaths, .hospitalizations // (.date as $date | $orig[] | select(.[0] == $date) | .[5]) // null])) | .[0]' commons.json data.json | expand -t4
