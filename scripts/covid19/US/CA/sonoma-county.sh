#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Sonoma_County,_California.tab?action=raw' > commons.json

# Query the FeatureServer table for cases by day
curl 'https://services1.arcgis.com/P5Mv5GY5S66M8Z1Q/ArcGIS/rest/services/NCOV_Cases_Sonoma_County/FeatureServer/0/query?where=Date+<>+null&outFields=Date%2CNewCases%2CActive%2CDeaths%2CRecovered%2CCumulative&orderByFields=Date&f=json' > table.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Update Commons
jq -s --tab '.[1].data = ([.[0].features[].attributes | (.Date / 1000 | gmtime | .[3] -= 7 | mktime | strftime("%Y-%m-%d")) as $date | [if $date == "2019-11-28" then "2020-11-28" else $date end, .NewCases, .Active, .Deaths, .Recovered, .Cumulative]] | sort_by(.[0])) | .[1]' table.json commons.json | expand -t4
