#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Napa_County,_California.tab?action=raw' > commons.json

# Query the FeatureServer table for case counts
curl 'https://services1.arcgis.com/Ko5rxt00spOfjMqj/ArcGIS/rest/services/Napa_Case_Regions/FeatureServer/0/query?where=1%3D1&returnGeometry=false&outStatistics=%5B%7B%22statisticType%22%3A%22max%22%2C%22onStatisticField%22%3A%22EditDate%22%2C%22outStatisticFieldName%22%3A%22date%22%7D%2C%7B%22statisticType%22%3A%22sum%22%2C%22onStatisticField%22%3A%22IncidentCount%22%2C%22outStatisticFieldName%22%3A%22cases%22%7D%2C%7B%22statisticType%22%3A%22sum%22%2C%22onStatisticField%22%3A%22Death%22%2C%22outStatisticFieldName%22%3A%22deaths%22%7D%2C%7B%22statisticType%22%3A%22sum%22%2C%22onStatisticField%22%3A%22RecoveredCount%22%2C%22outStatisticFieldName%22%3A%22recovered%22%7D%5D&f=json' > table.json

# Convert date from number of milliseconds to YYYY-MM-DD
jq '.features[].attributes | .date = (.date / 1000 | localtime | strftime("%Y-%m-%d"))' table.json > cases.json

# Fetch cumulative hospitalization counts from a LiveStories dashboard hooked up to a Google Sheets spreadsheet
HOSP=$(curl 'https://legacy.livestories.com/dataset.json?dashId=5ec97d92a789540013c3298d' | jq '.series[].data[.categories | index("Cumulative/Acumulado")].y')

# Fetch the HTML version of the daily update
# Parse out the latest update's timestamp
# Convert the date from MMMM DD, YYYY to YYYY-MM-DD
LATEST_DATE=$(curl 'https://www.countyofnapa.org/2770/Situation-Update-Archive' | grep -oE '<li> *(</?strong> *)+(\w+ +\d+ *, +\d+)' | grep -oE '\w+ +\d+ *, +\d+' | head -n 1)
LATEST_DATE=$(date -jf '%b %d, %Y' "${LATEST_DATE}" '+%Y-%m-%d')

jq ".date = \"${LATEST_DATE}\" | .hospitalized = ${HOSP}" cases.json > today.json

# Update Commons
jq -s --tab '.[0] as $today | .[1] | .data = (.data | map([["date", "cases", "recovered", "hospitalized", "deaths"], .] | transpose | map({key: .[0], value: .[1]}) | from_entries) + [$today] | group_by(.date) | map(add) | map([.date, .cases, .recovered, .hospitalized, .deaths]))' today.json commons.json | expand -t4
