#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Marin_County,_California.tab?action=raw' > commons.json

# Fetch the DataWrapper chart "Total Cases, Recovered, Hospitalizations and Deaths by Date Reported among Marin County Community Residents"
# Isolate the CSV data in the JSON in the page script
# Convert the CSV data to JSON
curl 'https://datawrapper.dwcdn.net/Eq6Es/127/' | grep 'JSON.parse' | sed -E 's/.*JSON\.parse\((".+")\);.*/\1/' | jq 'fromjson.data.chartData | split("\r\n") | map(split(","))[1:] | map([(.[0] | strptime("%m/%d/%Y") | strftime("%Y-%m-%d"))] + (.[1:] | map(tonumber)))' > casesbyday.json

# Update Commons
jq -s --tab '.[1].data = .[0] | .[1]' casesbyday.json commons.json | expand -t4
