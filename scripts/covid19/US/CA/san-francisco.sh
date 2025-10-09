#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_San_Francisco.tab?action=raw' > commons.json

# Fetch the cases by specimen collection day from the API
curl 'https://data.sfgov.org/resource/d2ef-idww.json?$select=specimen_collection_date%20as%20date,new_confirmed_cases%20as%20newConfirmedCases,cumulative_confirmed_cases%20as%20totalConfirmedCases&area_type=Citywide&$limit=2000' | jq 'map(.date = (.date | split("T")[0]))' > cases.json

# Fetch the deaths by day from the API
curl 'https://data.sfgov.org/resource/g2di-xufg.json?$select=date_of_death%20as%20date,new_deaths%20as%20newDeaths,cumulative_deaths%20as%20totalDeaths&$limit=3000' | jq 'map(.date = (.date | split("T")[0]))' > deaths.json

# Fetch hospitalizations by day from the API
curl 'https://data.sfgov.org/resource/nxjg-bhem.json?$select=reportdate%20as%20date,sum%28patientcount%29%20as%20hospitalized&$group=reportdate&$order=reportdate&$limit=2000' | jq 'map(.date = (.date | split("T")[0]))' > hosp.json

# Join the counts and hospitalizations
jq -s 'add | group_by(.date) | map(add)' cases.json deaths.json hosp.json > data.json

# Replace the data in the table
# Backfill older hospitalization data that has been removed from the API using existing data from the table
jq -s --tab '.[0].data = (.[1] | map(select(.newConfirmedCases // .totalDeaths // .hospitalized) | [.date, (.newConfirmedCases | values | tonumber) // null, (.totalConfirmedCases | values | tonumber) // null, (.newDeaths | values | tonumber) // null, (.totalDeaths | values | tonumber) // null, (.hospitalized | values | tonumber) // null])) | .[0]' commons.json data.json | expand -t4
