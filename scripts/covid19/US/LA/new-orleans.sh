#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_New_Orleans.tab?action=raw' > commons.json

# Query the FeatureServer table for case counts by day
curl "https://services5.arcgis.com/O5K6bb5dZVZcTo5M/ArcGIS/rest/services/Cases_Time_Enabled_2/FeatureServer/0/query?where=Parish+%3D+'Orleans'&outFields=DateTime%2CCases&returnGeometry=false&f=json&token=" > cases.json

# Fetch the dashboard's last edited date
# Convert date from number of milliseconds to YYYY-MM-DD
DATE=$(curl 'https://services5.arcgis.com/O5K6bb5dZVZcTo5M/ArcGIS/rest/services/Combined_COVID_Reporting/FeatureServer/0?f=json' | jq '.editingInfo.lastEditDate / 1000 | strftime("%Y-%m-%d")')

# Query the FeatureServer table for the current death toll
DEATHS=$(curl "https://services5.arcgis.com/O5K6bb5dZVZcTo5M/ArcGIS/rest/services/Combined_COVID_Reporting/FeatureServer/0/query?where=%22Group%22+%3D+'Orleans'+and+Measure+%3D+'Deaths'&outFields=Value&returnGeometry=false&f=json" | jq '.features[].attributes.Value')

# Convert date from number of milliseconds to YYYY-MM-DD
# Add the death toll to the current day's statistics
jq '.features | map(.attributes | .DateTime = (.DateTime / 1000 | strftime("%Y-%m-%d"))) | sort_by(.DateTime) | INDEX(.DateTime)' cases.json | jq ".[${DATE}] = .[${DATE}] // {} | .[${DATE}].DateTime = ${DATE} | .[${DATE}].Deaths = ${DEATHS}" > dates.json

# Update Commons
jq -s --tab '(.[0].data | map({DateTime: .[0], Cases: .[1], Deaths: .[2]}) | INDEX(.DateTime)) as $old | .[0].data = ($old + .[1] | map([.DateTime, .Cases, .Deaths // $old[.DateTime].Deaths]) | sort_by(.[0])) | .[0]' commons.json dates.json | expand -t4
