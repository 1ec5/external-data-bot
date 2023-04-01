#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Solano_County,_California.tab?action=raw' > commons.json

# Query the FeatureServer epidemiological curve table
curl 'https://services2.arcgis.com/SCn6czzcqKAFwdGU/ArcGIS/rest/services/Epi_Curve/FeatureServer/0/query?where=1%3D1&outFields=date_collected%2Cdaily_number%2Ccumulative_running_total_number&orderByFields=date_collected&f=json' > table.json
curl 'https://services2.arcgis.com/SCn6czzcqKAFwdGU/ArcGIS/rest/services/Epi_Curve/FeatureServer/0/query?where=1%3D1&outFields=date_collected%2Cdaily_number%2Ccumulative_running_total_number&orderByFields=date_collected&resultOffset=1000&f=json' > table2.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Accumulate cases
# Calculate recoveries by subtracting deaths and active cases from confirmed cases
jq -s '.[0].features + .[1].features | map(.attributes | {date: (.date_collected / 1000 | gmtime | .[3] -= 7 | mktime | strftime("%Y-%m-%d")), newCases: .daily_number, active: .cumulative_running_total_number}) | [foreach .[] as $date (0; . + $date.newCases; . as $cases | $date | .cases = $cases)]' table.json table2.json > casesbyday.json

# Query the FeatureServer hospitalization table
curl 'https://services2.arcgis.com/SCn6czzcqKAFwdGU/arcgis/rest/services/Hospital_Stats/FeatureServer/0/query?where=number_inpatient_by_day+IS+NOT+NULL&outFields=date_%2Cnumber_inpatient_by_day&orderByFields=date_&f=json' > table.json
curl 'https://services2.arcgis.com/SCn6czzcqKAFwdGU/arcgis/rest/services/Hospital_Stats/FeatureServer/0/query?where=number_inpatient_by_day+IS+NOT+NULL&outFields=date_%2Cnumber_inpatient_by_day&orderByFields=date_&resultOffset=1000&f=json' > table2.json

# Convert date from number of milliseconds to YYYY-MM-DD
jq -s '.[0].features + .[1].features | map(.attributes | {date: (.date_ / 1000 | gmtime | .[3] -= 7 | mktime | strftime("%Y-%m-%d")), hospitalized: .number_inpatient_by_day})' table.json table2.json > hosp.json

# Query the FeatureServer vaccination table and its metadata
curl 'https://services2.arcgis.com/SCn6czzcqKAFwdGU/ArcGIS/rest/services/Vaccine_Summary/FeatureServer/0/query?where=1%3D1&outFields=*&f=json' > table.json
VAX_DATE=$(curl 'https://services2.arcgis.com/SCn6czzcqKAFwdGU/ArcGIS/rest/services/Vaccine_Summary/FeatureServer/0?f=json' | jq '.editingInfo.lastEditDate | . / 1000 | gmtime | .[3] -= 7 | mktime | strftime("%Y-%m-%d")')
jq ".features[0].attributes | {date: ${VAX_DATE}, cases: .cumulative_cases, active: .active_cases, totalHospitalized: .total_hospitalizations, deaths: .total_deaths}" table.json > today.json

# Update Commons
jq -s --tab 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); .[0] as $commons | (.[0].data | map([["date", "newCases", "active", "recovered", "hospitalized", "totalHospitalized", "deaths", "cases"], .] | transpose | map({key: .[0], value: .[1]}) | from_entries)) + .[1] + .[2] + [.[3]] | group_by(.date) | map(add) | map(.deaths_copy = .deaths) | [eval_repeats("deaths_copy")] | map([.date, .newCases, .active, (.cases - (.active // 0) - (.deaths_copy // 0))? // null, .hospitalized, .totalHospitalized, .deaths, .cases]) as $data | $commons | .data = $data' commons.json casesbyday.json hosp.json today.json | expand -t4
