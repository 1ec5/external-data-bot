#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Alameda_County,_California.tab?action=raw' > commons.json

# Fetch cases and deaths by day from the API
curl 'https://services3.arcgis.com/1iDJcsklY3l3KIjE/arcgis/rest/services/AC_dates/FeatureServer/0/query?where=1%3D1&outFields=Date,BkLHJ_Cases,BkLHJ_CumulCases,BkLHJ_Deaths,BkLHJ_CumulDeaths,ACLHJ_Cases,ACLHJ_CumulCases,ACLHJ_Deaths,ACLHJ_CumulDeaths,AC_Cases,AC_CumulCases,AC_Deaths,AC_CumulDeaths&outSR=4326&f=json' > dates.json

# Fetch hospitalizations by day from the API
curl 'https://services3.arcgis.com/1iDJcsklY3l3KIjE/arcgis/rest/services/AC_hospitalized2/FeatureServer/0/query?where=1%3D1&outFields=Date,Hospitalized_COVID_19_Positive_&outSR=4326&f=json' > hosp.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Left join hospitalizations to cases and deaths
jq -s '[[.[].features[].attributes | .Date = (.Date / 1000 | strftime("%Y-%m-%d"))] | reduce .[] as $item ({}; .[$item.Date] += $item) | to_entries[].value | .Hospitalized_COVID_19_Positive_ //= null | to_entries | map(.value)]' dates.json hosp.json > data.json

# Update the table's existing entries with new data from the API
jq -s --tab '.[0].data = .[1] | .[0]' commons.json data.json | expand -t4
