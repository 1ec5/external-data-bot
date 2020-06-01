#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Marin_County,_California.tab?action=raw' > commons.json

# Query the FeatureServer table
curl 'https://services6.arcgis.com/T8eS7sop5hLmgRRH/ArcGIS/rest/services/Covid19_Cumulative/FeatureServer/0/query?where=Date+<>+null+or+Date+%3D+null&outFields=Date%2CTotal_Cases%2CTotal_Recovered_%2CTotal_Hospitalized%2CTotal_Deaths&orderByFields=Date&f=json' > table.json

# Filter out totally empty days
# Convert date from number of milliseconds to YYYY-MM-DD
jq '.features | map(.attributes | .Date = (.Date / 1000 | strftime("%Y-%m-%d")) | [.Date, (.Total_Cases | (strings // numbers) | tonumber) // null, (.Total_Recovered_ | (strings // numbers) | tonumber) // null, (.Total_Hospitalized | (strings // numbers) | tonumber) // null, (.Total_Deaths | (strings // numbers) | tonumber) // null])' table.json > casesbyday.json

# Update Commons
jq -s --tab '.[1].data = .[0] | .[1]' casesbyday.json commons.json | expand -t4
