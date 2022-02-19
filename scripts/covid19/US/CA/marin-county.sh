#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Marin_County,_California.tab?action=raw' > commons.json

# Fetch the DataWrapper chart "Total Cases, Recovered, Hospitalizations and Deaths by Date Reported among Marin County Community Residents"
# Follow the HTML meta redirect to the chart for today
# Isolate the CSV data in the JSON in the page script
# Convert the CSV data to JSON
curl $(curl 'https://datawrapper.dwcdn.net/Eq6Es/' | grep -oE 'https://[^"]+') | grep 'JSON.parse' | sed -E 's/.*JSON\.parse\((".+")\);.*/\1/' | jq 'fromjson.data.chartData | split("\r\n") | map(split(","))[1:] | map([(.[0] | strptime("%m/%d/%Y") | strftime("%Y-%m-%d"))] + (.[1:] | map(tonumber)))' > casesbyday.json

# Fetch the cases, hospitalizations, and deaths by date from Socrata
curl 'https://data.marincounty.org/resource/wg8s-i3c7.json?$limit=3000' | jq 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); group_by(.test_date) | map((INDEX(.status) | map_values(.cumulative_case_count | tonumber)) + {date: .[0].test_date | split("T")[0]}) | map({date: .date, cases: .["PCR Confirmed"], selfReportedCases: .["Antigen Detected Only (No PCR Test)"], hospitalized: .Hospitalized, deaths: .Death}) | [eval_repeats("cases")] | [eval_repeats("hospitalized")] | [eval_repeats("deaths")]' > disposition.json

## Fetch the current demographics from Socrata
## Pivot on disposition
#curl 'https://data.marincounty.org/resource/uu8g-ckxh.json' | jq 'map(select(.grouping | startswith("Gender")) | to_entries) | transpose | map({key: .[0].key, value: ((map(.value | tonumber?) | add) // .[0].value)}) | from_entries | {date: (.last_updated | split("T")[0]), cases: .cumulative, hospitalized: .hospitalized, deaths: .deaths}' > demographics.json

# Update Commons
# Overwrite DataWrapper values with Socrata values (retaining recoveries and any dates not covered by Socrata)
jq -s --tab '.[0].data = ((.[0].data + .[1] | map({date: .[0], cases: .[1], selfReportedCases: .[2], recovered: .[3], hospitalized: .[4], deaths: .[5]})) + .[2] | group_by(.date) | map(add | [.date, .cases, .selfReportedCases, .recovered, .hospitalized, .deaths])) | .[0]' commons.json casesbyday.json disposition.json | expand -t4
