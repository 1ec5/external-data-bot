#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Napa_County,_California.tab?action=raw' > commons.json

# Query the demographics FeatureServer table for case collection dates
curl 'https://services1.arcgis.com/Ko5rxt00spOfjMqj/ArcGIS/rest/services/CaseDataDemographics/FeatureServer/0/query?where=DtLabCollect<>NULL&outFields=DtLabCollect%2CCOUNT%28*%29+AS+newCases&returnDistinctValues=true&orderByFields=DtLabCollect&groupByFieldsForStatistics=DtLabCollect&f=json' > table.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Accumulate cases
jq '.features | map(.attributes | .date = (.DtLabCollect / 1000 | localtime | strftime("%Y-%m-%d") | sub("^1992"; "2021"))) | group_by(.date) | map({date: .[0].date, newCases: (map(.newCases) | add)}) | [foreach .[] as $date (0; . + $date.newCases; . as $cases | $date | .cases = $cases)]' table.json > cases.json

# Query the demographics FeatureServer table for case result dates in cases where collection date is unknown
curl 'https://services1.arcgis.com/Ko5rxt00spOfjMqj/ArcGIS/rest/services/CaseDataDemographics/FeatureServer/0/query?where=DtLabCollect%3DNULL&outFields=DtLabResult%2CCOUNT%28*%29+AS+newCases&returnDistinctValues=true&orderByFields=DtLabResult&groupByFieldsForStatistics=DtLabResult&f=json' > table.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Accumulate cases
jq '.features | map(.attributes | .date = (.DtLabResult / 1000 | localtime | strftime("%Y-%m-%d"))) | [foreach .[] as $date (0; . + $date.newCases; . as $cases | $date | .undatedCases = $cases)]' table.json > undatedcases.json

# Query the demographics FeatureServer table for death dates
curl 'https://services1.arcgis.com/Ko5rxt00spOfjMqj/ArcGIS/rest/services/CaseDataDemographics/FeatureServer/0/query?where=DtDeath<>NULL&outFields=DtDeath&f=json' > table.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Accumulate deaths
jq '.features | map(.attributes) | group_by(.DtDeath) | map({date: (.[0].DtDeath / 1000 | localtime | strftime("%Y-%m-%d")), newDeaths: length}) | [foreach .[] as $date (0; . + $date.newDeaths; . as $deaths | $date | .deaths = $deaths)]' table.json > deaths.json

# Query the demographics FeatureServer table for recoveries
RECOV=$(curl 'https://services1.arcgis.com/Ko5rxt00spOfjMqj/ArcGIS/rest/services/CaseDataDemographics/FeatureServer/0/query?where=Recovered='"'"'Y'"'"'&returnCountOnly=true&f=pjson' | jq '.count')

# Fetch cumulative hospitalization counts from a LiveStories dashboard hooked up to a Google Sheets spreadsheet
HOSP=$(curl 'https://legacy.livestories.com/dataset.json?dashId=5ec97d92a789540013c3298d' | jq '.series[].data[.categories | index("Cumulative/Acumulado")].y')

# Fetch the HTML version of the daily update
# Parse out the latest update's timestamp
# Convert the date from MMMM DD, YYYY to YYYY-MM-DD
LATEST_DATE=$(curl 'https://www.countyofnapa.org/2770/Situation-Update-Archive' | grep -oE '<li.*?> *(</?strong> *)+(\w+ +\d+ *, +\d+)' | grep -oE '\w+ +\d+ *, +\d+' | head -n 1)
LATEST_DATE=$(date -jf '%b %d, %Y' "${LATEST_DATE}" '+%Y-%m-%d')

echo '{}' | jq "{date: \"${LATEST_DATE}\", hospitalized: ${HOSP}, recovered: ${RECOV}}" > today.json

# Update Commons
jq -s --tab 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); .[0] as $commons | (.[0].data | map([["date", "cases-overwrite", "recovered", "hospitalized", "deaths-overwrite"], .] | transpose | map({key: .[0], value: .[1]}) | from_entries)) + .[1] + .[2] + .[3] + [.[4]] | group_by(.date) | map(add) | [eval_repeats("cases")] | [eval_repeats("undatedCases")] | [eval_repeats("deaths")] | map([.date, .cases + .undatedCases, .recovered, .hospitalized, .deaths]) as $data | $commons | .data = $data' commons.json cases.json undatedcases.json deaths.json today.json | expand -t4
