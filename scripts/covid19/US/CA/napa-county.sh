#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Napa_County,_California.tab?action=raw' > commons.json

# Query the demographics FeatureServer table for case collection dates
curl 'https://services1.arcgis.com/Ko5rxt00spOfjMqj/ArcGIS/rest/services/CaseDataDemographics/FeatureServer/0/query?where=DtLabCollect<>NULL&outFields=DtLabCollect%2CCOUNT%28*%29+AS+newCases&returnDistinctValues=true&orderByFields=DtLabCollect&groupByFieldsForStatistics=DtLabCollect&f=json' > table.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Accumulate cases
jq '.features | map(.attributes | .date = (.DtLabCollect / 1000 | localtime | strftime("%Y-%m-%d") | sub("^1992"; "2021") | sub("^1922"; "2022"))) | group_by(.date) | map(select(.[0].date | startswith("1899") | not)) | map({date: .[0].date, newCases: (map(.newCases) | add)}) | [foreach .[] as $date (0; . + $date.newCases; . as $cases | $date | .cases = $cases)]' table.json > cases.json

# Query the demographics FeatureServer table for case result dates in cases where collection date is unknown
curl 'https://services1.arcgis.com/Ko5rxt00spOfjMqj/ArcGIS/rest/services/CaseDataDemographics/FeatureServer/0/query?where=DtLabCollect%3DNULL&outFields=DtLabResult%2CCOUNT%28*%29+AS+newCases&returnDistinctValues=true&orderByFields=DtLabResult&groupByFieldsForStatistics=DtLabResult&f=json' > table.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Accumulate cases
jq '.features | map(.attributes | .date = (.DtLabResult | values / 1000 | localtime | strftime("%Y-%m-%d")) | select(.date | startswith("1899") | not)) | [foreach .[] as $date (0; . + $date.newCases; . as $cases | $date | .undatedCases = $cases)]' table.json > undatedcases.json

# Query the demographics FeatureServer table for death dates
curl 'https://services1.arcgis.com/Ko5rxt00spOfjMqj/ArcGIS/rest/services/CaseDataDemographics/FeatureServer/0/query?where=DtDeath<>NULL&outFields=DtDeath&f=json' > table.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Accumulate deaths
jq '.features | map(.attributes) | group_by(.DtDeath) | map({date: (.[0].DtDeath / 1000 | localtime | strftime("%Y-%m-%d")), newDeaths: length}) | [foreach .[] as $date (0; . + $date.newDeaths; . as $deaths | $date | .deaths = $deaths)]' table.json > deaths.json

# Query the demographics FeatureServer table for recoveries
RECOV=$(curl 'https://services1.arcgis.com/Ko5rxt00spOfjMqj/ArcGIS/rest/services/CaseDataDemographics/FeatureServer/0/query?where=Recovered='"'"'Y'"'"'&returnCountOnly=true&f=pjson' | jq '.count')

# Query the demographics FeatureServer table for the current date
# Convert date from number of milliseconds to YYYY-MM-DD
curl 'https://services1.arcgis.com/Ko5rxt00spOfjMqj/ArcGIS/rest/services/CaseDataDemographics/FeatureServer/0/query?where=1%3D1&outFields=EditDate_1&resultRecordCount=1&f=pjson' > dashboard.json
jq "{date: (.features[0].attributes.EditDate_1 / 1000 | localtime | strftime(\"%Y-%m-%d\")), recovered_IGNORE: ${RECOV}}" dashboard.json > recoveries.json

# Fetch statistics from a LiveStories dashboard hooked up to a Google Sheets spreadsheet
#curl 'https://insight.livestories.com/dataset.json?datasetId=5f59266a87d1d10013056e9e' > dashboard.json
#jq '.rows | map(select(.[1] != "") | {(.[1]): (.[2] | tonumber)}) | add | {date: (now | localtime | strftime("%Y-%m-%d")), cases: .["Cases - Cumulative/Casos Acumulados"], hospitalized: .["Hospitalized - Cumulative/Hospitalizado Acumulado"], deaths: ((.["Deaths - Total/Total de Muertes"] | tonumber) + (.["Deaths Among Non-Residents/\nMuertes Entre Personas Que No Residen En El Condado de Napa"] | tonumber))}' dashboard.json > today.json

# Fetch statistics from the Tableau dashboard embedded in the LiveStories landing page
curl 'https://public.tableau.com/views/LandingPage_16292272663630/DailySummary?:showVizHome=no&:embed=true' > dashboard.html
SESSIONID=$(grep tsConfigContainer dashboard.html | sed -E $'s/ *<[^>]+>//g' | textutil -convert txt -format html -stdin -stdout | jq -r '.sessionid')
curl -X POST -d 'sheet_id=Daily%20Summary' https://public.tableau.com/vizql/w/LandingPage_16292272663630/v/DailySummary/bootstrapSession/sessions/${SESSIONID} | sed -E 's/^[0-9]+;//' > /dev/null
curl -X POST -d 'worksheet=Deaths&dashboard=Daily%20Summary&vizRegionRect={"r":"xheader","x":578,"y":11,"w":0,"h":0,"fieldVector":null}&allowHoverActions=true&allowPromptText=true&allowWork=false&useInlineImages=true' "https://public.tableau.com/vizql/w/LandingPage_16292272663630/v/DailySummary/sessions/${SESSIONID}/commands/tabsrv/render-tooltip-server" > dashboard.json
jq '.vqlCmdResponse.layoutStatus.applicationPresModel.dataDictionary.dataSegments["0"].dataColumns | {date: (now | localtime | strftime("%Y-%m-%d")), hospitalized: .[1].dataValues[0], deaths: .[1].dataValues[2], undatedCases: (.[2].dataValues[4] | sub(","; "") | tonumber)}' dashboard.json > today.json

# Update Commons
jq -s --tab 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); .[0] as $commons | (.[0].data | map([["date", "cases-overwrite", "recovered", "hospitalized", "deaths"], .] | transpose | map({key: .[0], value: .[1]}) | from_entries)) + .[1] + .[2] + [.[3]] + .[4] + [.[5]] | group_by(.date) | map(add) | [eval_repeats("cases")] | [eval_repeats("undatedCases")] | [eval_repeats("deaths")] | map([.date, (.cases? + .undatedCases) // null, .recovered, .hospitalized, .deaths]) as $data | $commons | .data = $data' commons.json cases.json undatedcases.json recoveries.json deaths.json today.json | expand -t4
