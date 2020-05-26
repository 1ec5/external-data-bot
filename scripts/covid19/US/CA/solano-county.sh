#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Solano_County,_California.tab?action=raw' > commons.json

# Query the FeatureServer table
curl 'https://services2.arcgis.com/SCn6czzcqKAFwdGU/ArcGIS/rest/services/COVID_19_Survey_part_1_v2_new_public_view/FeatureServer/0/query?where=date_reported+<>+null+or+date_reported+%3D+null&outFields=date_of_specimen_collection%2Cdate_reported%2Cnumber_of_specimens_collected_o%2Cnew_cases_confirmed_today%2Cactive_cases%2Chospitalized%2Ccurrently_hospitalized_cases%2Ctotal_hospitalizations%2Ctotal_deaths%2Ccumulative_number_of_cases_on_t%2Call_cases_hospitalized%2Call_cases_total&orderByFields=date_reported&f=json' > table.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Pivot collections by collection date and other numbers by reporting date, then join the two pivots together
# Calculate a running total of collections
# Calculate recoveries by subtracting deaths and active cases from confirmed cases
jq '.features | map(.attributes | select(.date_of_specimen_collection) | {date: (.date_of_specimen_collection / 1000 | strftime("%Y-%m-%d")), newCasesCollected: .number_of_specimens_collected_o}) + map(.attributes | select(.date_reported) | {date: (.date_reported / 1000 | strftime("%Y-%m-%d")), newCasesConfirmed: .new_cases_confirmed_today, active: .active_cases, recovered: (try (.all_cases_total - .total_deaths - .active_cases) catch null), currentlyHospitalized: .currently_hospitalized_cases, totalHospitalized: .all_cases_hospitalized, deaths: .total_deaths, totalConfirmedCases: .all_cases_total}) | group_by(.date) | map(add) | [foreach .[] as $row (0; . + $row.newCasesCollected; . as $x | $row | (.totalCollectedCases = $x))] | map([.date, .newCasesCollected // 0, .newCasesConfirmed, .active, .recovered, .currentlyHospitalized, .totalHospitalized, .deaths, .totalCollectedCases, .totalConfirmedCases])' table.json > casesbyday.json

# Update Commons
jq -s --tab '.[1].data = .[0] | .[1]' casesbyday.json commons.json | expand -t4
