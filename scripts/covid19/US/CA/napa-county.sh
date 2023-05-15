#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Napa_County,_California.tab?action=raw' > commons.json

# Fetch statistics from the Tableau dashboard embedded in the LiveStories landing page
curl 'https://public.tableau.com/views/LandingPage_16292272663630/DailySummary?:showVizHome=no&:embed=true' > dashboard.html
SESSIONID=$(grep tsConfigContainer dashboard.html | sed -E $'s/ *<[^>]+>//g' | textutil -convert txt -format html -stdin -stdout | jq -r '.sessionid')
curl -X POST -d 'sheet_id=Daily%20Summary' https://public.tableau.com/vizql/w/LandingPage_16292272663630/v/DailySummary/bootstrapSession/sessions/${SESSIONID} | sed -E 's/^[0-9]+;//' > /dev/null
curl -X POST -d 'worksheet=Deaths&dashboard=Daily%20Summary&vizRegionRect={"r":"xheader","x":578,"y":11,"w":0,"h":0,"fieldVector":null}&allowHoverActions=true&allowPromptText=true&allowWork=false&useInlineImages=true' "https://public.tableau.com/vizql/w/LandingPage_16292272663630/v/DailySummary/sessions/${SESSIONID}/commands/tabsrv/render-tooltip-server" > dashboard.json
jq '.vqlCmdResponse.layoutStatus.applicationPresModel.dataDictionary.dataSegments["0"].dataColumns | {date: (now | localtime | strftime("%Y-%m-%d")), hospitalized: .[1].dataValues[0], deaths: .[1].dataValues[2], undatedCases: (.[2].dataValues[4] | sub(","; "") | tonumber)}' dashboard.json > today.json

# Update Commons
jq -s --tab 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); .[0] as $commons | (.[0].data | map([["date", "cases", "recovered", "hospitalized", "deaths"], .] | transpose | map({key: .[0], value: .[1]}) | from_entries)) + [.[4]] | group_by(.date) | map(add | select(.date != null)) | [eval_repeats("cases")] | [eval_repeats("undatedCases")] | [eval_repeats("deaths")] | map([.date, (.cases? + .undatedCases) // null, .recovered, .hospitalized, .deaths]) as $data | $commons | .data = $data' commons.json today.json | expand -t4
