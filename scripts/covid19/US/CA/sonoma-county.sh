#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Sonoma_County,_California.tab?action=raw' > commons.json

# Query the FeatureServer table for cases by day
curl 'https://services1.arcgis.com/P5Mv5GY5S66M8Z1Q/ArcGIS/rest/services/NCOV_Cases_Sonoma_County/FeatureServer/0/query?where=Date+<>+null&outFields=Date%2CNewCases%2CActive%2CDeaths%2CRecovered%2CCumulative&orderByFields=Date&f=json' > table.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Update Commons
jq -s --tab 'def diff(key): [[{(key): 0}] + .[:-1], .] | transpose | map(.[1]["diff:" + key] = (if .[1][key] and .[0][key] then (.[1][key] - .[0][key]) else null end) | .[1]); .[1].data = ([.[0].features[].attributes | (.Date / 1000 | gmtime | .[3] -= 7 | mktime | strftime("%Y-%m-%d")) as $date | [$date, .NewCases, .Active, .Deaths, .Recovered, .Cumulative]] | sort_by(.[0]) | map({cumulative: .[5], row: .}) | diff("cumulative") | map(.row[1] = (.row[1] // .["diff:cumulative"]) | .row)) | .[1]' table.json commons.json | expand -t4
