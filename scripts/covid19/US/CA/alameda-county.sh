#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Alameda_County,_California.tab?action=raw' > commons.json

# Fetch the current cases and deaths
curl 'https://services5.arcgis.com/ROBnTHSNjoZ2Wm1P/arcgis/rest/services/COVID_19_Statistics/FeatureServer/7/query?where=1%3D1&outFields=dtcreate%2CBerkeley_Berkeley_LHJ%2CBerkeley_Berkeley_LHJ_Cumulativ%2CBerkeley_Berkeley_LHJ_Deaths%2CBerkeley_Berkeley_LHJ_Deaths_Cu%2CAlameda_County_LHJ%2CAlameda_County_LHJ_Cumulative%2CAlameda_County_LHJ_Deaths%2CAlameda_County_LHJ_Deaths__Cumu%2CAlameda_County%2CAlameda_County__Cumulative%2CAlameda_County_Deaths%2CAlameda_County_Deaths__Cumulati&sqlFormat=none&f=json' | jq '.features | map(.attributes | map_values((strings | tonumber) // .) | .date = (.dtcreate / 1000 | todate | split("T")[0]))' > dates.json

# Fetch the hospitalizations by day from the dashboard
# Convert date from number of milliseconds to YYYY-MM-DD
# Fill in counts repeated from previous days, which are indicated by C = null, R = 2
curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/querydata?synchronous=true' --compressed --data '{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"t","Entity":"Tbl_Hospitalizations","Type":0}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"t"}},"Property":"Date"},"Name":"Tbl_Hospitalizations.Date"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"t"}},"Property":"3a# Confirmed positive hospitalizated"}},"Function":0},"Name":"Sum(Tbl_Hospitalizations.3a# Confirmed positive hospitalizated)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"t"}},"Property":"5b# Covid ICU confirmed positive"}},"Function":0},"Name":"Sum(Tbl_Hospitalizations.5b# Covid ICU confirmed positive)"}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1,2]}]},"DataReduction":{"DataVolume":4,"Primary":{"BinnedLineSample":{}}},"Version":1},"ExecutionMetricsKind":1}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"t\",\"Entity\":\"Tbl_Hospitalizations\",\"Type\":0}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"t\"}},\"Property\":\"Date\"},\"Name\":\"Tbl_Hospitalizations.Date\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"t\"}},\"Property\":\"3a# Confirmed positive hospitalizated\"}},\"Function\":0},\"Name\":\"Sum(Tbl_Hospitalizations.3a# Confirmed positive hospitalizated)\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"t\"}},\"Property\":\"5b# Covid ICU confirmed positive\"}},\"Function\":0},\"Name\":\"Sum(Tbl_Hospitalizations.5b# Covid ICU confirmed positive)\"}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1,2]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"BinnedLineSample\":{}}},\"Version\":1},\"ExecutionMetricsKind\":1}}]}","CacheOptions":7,"QueryId":"","ApplicationContext":{"DatasetId":"d4dfb3f4-9f51-4a0e-bb5b-d02063c27e02","Sources":[{"ReportId":"1bb49985-f852-4eaf-ae6b-ebc955422ac8","VisualId":"0ac9b427700c1bed5a9d"}]}}],"cancelQueries":[],"modelId":295461}' > dashboard.json
jq 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); def by_day(key): .results | map(.result.data) | map((.descriptor.Select[] | select(.Name | contains(key))) as $field | ($field | .Value[1:] | tonumber) as $index | .dsr.DS[0].PH[0].DM0 | map(select(has("Ø") | not) | {date: (.C[0] / 1000 | strftime("%Y-%m-%d")), ($field.Name): (if .R and .R / 2 == $index + 1 then null elif .R and .R / 2 < $index + 1 then .C[$index] else .C[$index + 1] end)}) | [eval_repeats($field.Name)]); by_day("Confirmed positive hospitalizated")[0] | map({date: .date, hospitalized: .["Sum(Tbl_Hospitalizations.3a# Confirmed positive hospitalizated)"]})' dashboard.json > hosp.json

# Update the table's existing entries with new data from the dashboard
jq -s --tab 'def eval_repeats(series): series | foreach .[] as $row ({}; . * $row; .); .[0].data = (((.[0].data | map({date: .[0], hospitalized: .[13]})) + (.[1] | map(map_values(values))) + .[2]) | group_by(.date) | map(add) | [eval_repeats(.)] | map([.date, .Berkeley_Berkeley_LHJ, .Berkeley_Berkeley_LHJ_Cumulativ, .Berkeley_Berkeley_LHJ_Deaths, .Berkeley_Berkeley_LHJ_Deaths_Cu, .Alameda_County_LHJ, .Alameda_County_LHJ_Cumulative, .Alameda_County_LHJ_Deaths, .Alameda_County_LHJ_Deaths__Cumu, .Alameda_County, .Alameda_County__Cumulative, .Alameda_County_Deaths, .Alameda_County_Deaths__Cumulati, .hospitalized])) | .[0]' commons.json dates.json hosp.json | expand -t4
