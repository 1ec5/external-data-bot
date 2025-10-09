#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Sonoma_County,_California.tab?action=raw' > commons.json
grep -q 'COVID-19 cases in Sonoma County, California' commons.json
if [ ! "$?" -eq 0 ]; then
	echo 'Wrong script'
	exit 1
fi

# Query the FeatureServer table for cases by day
curl 'https://services1.arcgis.com/P5Mv5GY5S66M8Z1Q/ArcGIS/rest/services/NCOV_Cases_Sonoma_County/FeatureServer/0/query?where=Date+<>+null&outFields=Date%2CNewCases%2CActive%2CDeaths%2CRecovered%2CCumulative&orderByFields=Date&f=json' > table.json
jq 'def diff(key): [[{(key): 0}] + .[:-1], .] | transpose | map(.[1]["diff:" + key] = (if .[1][key] and .[0][key] then (.[1][key] - .[0][key]) else null end) | .[1]); [.features[].attributes | .date = (.Date / 1000 | gmtime | .[3] -= 7 | mktime | strftime("%Y-%m-%d"))] | sort_by(.date)' table.json > cases.json

# Query the FeatureServer for deaths by day
# Calculate running total of deaths
curl 'https://services1.arcgis.com/P5Mv5GY5S66M8Z1Q/arcgis/rest/services/NCOV_CaseData_DeathsTimeline/FeatureServer/0/query?f=json&resultRecordCount=32000&where=DateofDeath%20IS%20NOT%20NULL&orderByFields=DateofDeath%20asc&outFields=DateofDeath,Deaths&resultType=standard&returnGeometry=false' > table.json
curl 'https://services1.arcgis.com/P5Mv5GY5S66M8Z1Q/arcgis/rest/services/NCOV_CaseData_DeathsTimeline/FeatureServer/0/query?f=json&resultOffset=32000&resultRecordCount=32000&where=DateofDeath%20IS%20NOT%20NULL&orderByFields=DateofDeath%20asc&outFields=DateofDeath,Deaths&resultType=standard&returnGeometry=false' > table2.json
curl 'https://services1.arcgis.com/P5Mv5GY5S66M8Z1Q/arcgis/rest/services/NCOV_CaseData_DeathsTimeline/FeatureServer/0/query?f=json&resultOffset=64000&resultRecordCount=32000&where=DateofDeath%20IS%20NOT%20NULL&orderByFields=DateofDeath%20asc&outFields=DateofDeath,Deaths&resultType=standard&returnGeometry=false' > table3.json
curl 'https://services1.arcgis.com/P5Mv5GY5S66M8Z1Q/arcgis/rest/services/NCOV_CaseData_DeathsTimeline/FeatureServer/0/query?f=json&resultOffset=96000&resultRecordCount=32000&where=DateofDeath%20IS%20NOT%20NULL&orderByFields=DateofDeath%20asc&outFields=DateofDeath,Deaths&resultType=standard&returnGeometry=false' > table4.json
curl 'https://services1.arcgis.com/P5Mv5GY5S66M8Z1Q/arcgis/rest/services/NCOV_CaseData_DeathsTimeline/FeatureServer/0/query?f=json&resultOffset=128000&resultRecordCount=32000&where=DateofDeath%20IS%20NOT%20NULL&orderByFields=DateofDeath%20asc&outFields=DateofDeath,Deaths&resultType=standard&returnGeometry=false' > table5.json
curl 'https://services1.arcgis.com/P5Mv5GY5S66M8Z1Q/arcgis/rest/services/NCOV_CaseData_DeathsTimeline/FeatureServer/0/query?f=json&resultOffset=160000&resultRecordCount=32000&where=DateofDeath%20IS%20NOT%20NULL&orderByFields=DateofDeath%20asc&outFields=DateofDeath,Deaths&resultType=standard&returnGeometry=false' > table6.json
curl 'https://services1.arcgis.com/P5Mv5GY5S66M8Z1Q/arcgis/rest/services/NCOV_CaseData_DeathsTimeline/FeatureServer/0/query?f=json&resultOffset=192000&resultRecordCount=32000&where=DateofDeath%20IS%20NOT%20NULL&orderByFields=DateofDeath%20asc&outFields=DateofDeath,Deaths&resultType=standard&returnGeometry=false' > table7.json
curl 'https://services1.arcgis.com/P5Mv5GY5S66M8Z1Q/arcgis/rest/services/NCOV_CaseData_DeathsTimeline/FeatureServer/0/query?f=json&resultOffset=224000&resultRecordCount=32000&where=DateofDeath%20IS%20NOT%20NULL&orderByFields=DateofDeath%20asc&outFields=DateofDeath,Deaths&resultType=standard&returnGeometry=false' > table8.json
curl 'https://services1.arcgis.com/P5Mv5GY5S66M8Z1Q/arcgis/rest/services/NCOV_CaseData_DeathsTimeline/FeatureServer/0/query?f=json&resultOffset=256000&resultRecordCount=32000&where=DateofDeath%20IS%20NOT%20NULL&orderByFields=DateofDeath%20asc&outFields=DateofDeath,Deaths&resultType=standard&returnGeometry=false' > table9.json
curl 'https://services1.arcgis.com/P5Mv5GY5S66M8Z1Q/arcgis/rest/services/NCOV_CaseData_DeathsTimeline/FeatureServer/0/query?f=json&resultOffset=288000&resultRecordCount=32000&where=DateofDeath%20IS%20NOT%20NULL&orderByFields=DateofDeath%20asc&outFields=DateofDeath,Deaths&resultType=standard&returnGeometry=false' > table10.json
jq -s 'def total(key): foreach .[] as $row (0; . + $row[key]; . as $x | $row | (.["total:" + key] = $x)); (.[0].features + .[1].features + .[2].features + .[3].features + .[4].features + .[5].features + .[6].features + .[7].features + .[8].features + .[9].features) | map(.attributes) | group_by(.DateofDeath) | map(add) | [total("Deaths")] | map(.date = (.DateofDeath / 1000 | gmtime | .[3] -= 7 | mktime | strftime("%Y-%m-%d")) | {date: .date, deaths: .["total:Deaths"]})' table.json table2.json table3.json table4.json table5.json table6.json table7.json table8.json table9.json table10.json > deaths.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Update Commons
jq -s --tab 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); def diff(key): [[{(key): 0}] + .[:-1], .] | transpose | map(.[1]["diff:" + key] = (if .[1][key] and .[0][key] then (.[1][key] - .[0][key]) else null end) | .[1]); .[0].data = ((.[1] + .[2] | group_by(.date) | map(add)) | [eval_repeats("deaths")] | map([.date, .NewCases, .Active, .deaths, .Recovered, .Cumulative]) | map({cumulative: .[5], row: .}) | diff("cumulative") | map(.row[1] = (.row[1] // .["diff:cumulative"]) | .row)) | .[0]' commons.json cases.json deaths.json | expand -t4
