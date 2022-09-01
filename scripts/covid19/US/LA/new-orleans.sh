#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_New_Orleans.tab?action=raw' > commons.json

# Query the FeatureServer table for case counts by day
curl 'https://gis.nola.gov/arcgis/rest/services/apps/LDH_Data/MapServer/0/query?where=1%3D1&outFields=Date%2CNO_Cases%2CNO_Deaths&returnGeometry=false&orderByFields=Date&f=json' > table.json

# Convert date from number of milliseconds to YYYY-MM-DD
jq '.features | map(.attributes | .Date = (.Date / 1000 | strftime("%Y-%m-%d")))' table.json > cases.json

# Update Commons
jq -s --tab '.[0].data = (.[1] | map([.Date, .NO_Cases, .NO_Deaths])) | .[0]' commons.json cases.json | expand -t4
