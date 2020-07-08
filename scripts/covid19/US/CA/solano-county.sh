#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Solano_County,_California.tab?action=raw' > commons.json

# Query the FeatureServer table
curl 'https://services2.arcgis.com/SCn6czzcqKAFwdGU/ArcGIS/rest/services/COVID19Surveypt1v3_view/FeatureServer/0/query?where=1%3D1&outFields=Date_reported%2Ccumulative_cases%2CActive_cases%2Ccurrently_hospitalized_cases%2Ctotal_hospitalizations%2Ctotal_deaths&returnGeometry=false&orderByFields=Date_reported&f=json' > table.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Calculate recoveries by subtracting deaths and active cases from confirmed cases
# Calculate new cases by day
jq 'def diff(key): [[{(key): 0}] + .[:-1], .] | transpose | map(.[1]["diff:" + key] = (if .[1][key] and .[0][key] then (.[1][key] - .[0][key]) else null end) | .[1]); .features | map(select(.attributes | .cumulative_cases or .currently_hospitalized_cases) | .attributes | {date: (.Date_reported / 1000 | gmtime | .[3] -= 7 | mktime | strftime("%Y-%m-%d")), active: .Active_cases, recovered: (try (.cumulative_cases - .total_deaths - .Active_cases) catch null), currentlyHospitalized: .currently_hospitalized_cases, totalHospitalized: .total_hospitalizations, deaths: .total_deaths, totalConfirmedCases: .cumulative_cases}) | diff("totalConfirmedCases") | map([.date, .["diff:totalConfirmedCases"], .active, .recovered, .currentlyHospitalized, .totalHospitalized, .deaths, .totalConfirmedCases])' table.json > casesbyday.json

# Update Commons
jq -s --tab '.[1].data = .[0] | .[1]' casesbyday.json commons.json | expand -t4
