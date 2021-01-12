#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Santa_Clara_County,_California.tab?action=raw' > commons.json

# Fetch the cases by day
curl 'https://data.sccgov.org/resource/6cnm-gchg.json' | jq 'map({date: (.date | split("T")[0]), newCases: (.new_cases | tonumber), totalConfirmedCases: (.total_cases | tonumber)})' > casesbyday.json

# Fetch the current cases by gender
# Find the current total number of cases, including undated cases, by summing all the groups including Unknown
# Total case count for today is the total case count as of today minus the undated case count
curl 'https://data.sccgov.org/resource/ibdk-7rf5.json?$select=*,:updated_at' | jq '{date: (.[0][":updated_at"][:19] + "Z" | fromdate | gmtime | .[3] -= 7 | mktime | strftime("%Y-%m-%d")), totalConfirmedCasesInclUndated: (map(.count | tonumber) | add)}' > today.json

# Fetch the hospitalizations by day
curl 'https://data.sccgov.org/resource/5xkz-6esm.json' | jq 'map(.date = (.date | split("T")[0]) | {date: (if .date >= "2021-12-27" then (.date | sub("^2021"; "2020")) else .date end), hospitalized: (.covid_total | tonumber), hospitalizedPUI: (.pui_total | tonumber)})' > hosp.json

# Fetch the deaths by day
curl 'https://data.sccgov.org/resource/tg4j-23y2.json' | jq 'map(.date = (.date | split("T")[0]) | {date: (.date | sub("^2012"; "2021") | sub("^2021-12-23"; "2021-01-10")), deaths: (.cumulative | tonumber)})' > deaths.json

# Update the table's existing entries with new data from the dashboard, adding a row for today
# New case count for today is total case count for today minus total case count for yesterday
jq -s --tab 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); .[0] as $commons | (.[0].data | map({date: .[0], newCases: null, totalConfirmedCases: null, hospitalized: .[3], hospitalizedPUI: .[4], deaths: null, undatedCases: .[6]})) + .[1] + .[2] + .[3] + [.[4]] | group_by(.date) | map(map(with_entries(select(.value != null))) | add) | .[-1].totalConfirmedCases = (.[-1].totalConfirmedCases // .[-2].totalConfirmedCases // .[-3].totalConfirmedCases) | .[-1].undatedCases = (if .[-1].totalConfirmedCasesInclUndated then (.[-1].totalConfirmedCasesInclUndated - .[-1].totalConfirmedCases) else null end) | map([.date, .newCases, .totalConfirmedCases, .hospitalized, .hospitalizedPUI, .deaths, .undatedCases]) | [eval_repeats(5)] as $data | $commons | .data = $data' commons.json casesbyday.json hosp.json deaths.json today.json | expand -t4
