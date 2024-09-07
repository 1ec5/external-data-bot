#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Santa_Clara_County,_California.tab?action=raw' > commons.json

# Fetch the cases by day
curl 'https://wabi-us-gov-virginia-api.analysis.usgovcloudapi.net/public/reports/querydata?synchronous=true' --compressed -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-raw '{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"c","Entity":"case_date","Type":0}],"Select":[{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"New_cases_7davg"}},"Function":0},"Name":"Sum(case_date.New_cases_7davg)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"New_cases"}},"Function":0},"Name":"Sum(case_date.New_cases)"},{"Column":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"Date"},"Name":"case_date.Date"}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1,2]}]},"DataReduction":{"DataVolume":4,"Primary":{"Sample":{}}},"Version":1},"ExecutionMetricsKind":1}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"c\",\"Entity\":\"case_date\",\"Type\":0}],\"Select\":[{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"New_cases_7davg\"}},\"Function\":0},\"Name\":\"Sum(case_date.New_cases_7davg)\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"New_cases\"}},\"Function\":0},\"Name\":\"Sum(case_date.New_cases)\"},{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"Date\"},\"Name\":\"case_date.Date\"}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1,2]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"Sample\":{}}},\"Version\":1},\"ExecutionMetricsKind\":1}}]}","QueryId":"","ApplicationContext":{"DatasetId":"af9678ae-d901-4e62-8dc1-7f01ddda4f61","Sources":[{"ReportId":"0814c897-cde8-45f4-bb7d-4ec57edcb077","VisualId":"707c91ea47d20edeb096"}]}}],"cancelQueries":[],"modelId":344055}' > dashboard.json
jq 'def propagate_repeats(dm1): if .R == 2 then .C = .C[:1] + [null] + .C[1:] elif .R == 4 then .C = .C[:2] + [null] + .C[2:] elif .R == 6 then .C = .C[:1] + [null, null] + .C[1:] else . end; def eval_repeats(series): series | map(.C) | foreach .[] as $row ([]; [., $row] | transpose | map(.[1] // .[0]); .); .results | map(.result.data | (.descriptor.Select | map({key: .Value, value: .Name}) | from_entries | .G0 = "date") as $desc | .dsr.DS[0].PH[0].DM0 | (.[0].S | map(.N)) as $index | map(select(has("Ø") | not) | propagate_repeats(.)) | [eval_repeats(.)] | map([$index, (.[0] = (.[0] / 1000 | strftime("%Y-%m-%d")))] | transpose | map({($desc[.[0]]): .[1]}) | add)) | add | group_by(.date) | map(add | .newCases = .["Sum(case_date.New_cases)"]) | [foreach .[] as $date (0; . + $date.newCases; . as $cases | $date | .cases = $cases)]' dashboard.json > cases.json

# Fetch the current cases by gender
# Find the current total number of cases, including undated cases, by summing all the groups including Unknown
# Total case count for today is the total case count as of today minus the undated case count
curl 'https://data.sccgov.org/resource/ibdk-7rf5.json?$select=*,:updated_at' | jq '{date: (.[0][":updated_at"][:19] + "Z" | fromdate | gmtime | .[3] -= 7 | mktime | strftime("%Y-%m-%d")), cases: (map(.count | tonumber) | add)}' > cases_today.json

# Fetch the hospitalizations by day
curl 'https://data.sccgov.org/resource/5xkz-6esm.json' | jq 'map(.date = (.date | split("T")[0]) | {date: .date, hospitalized: (.covid_total | tonumber), hospitalizedPUI: (.pui_total | tonumber)})' > hosp.json

# Fetch the deaths by day
curl 'https://data.sccgov.org/resource/tg4j-23y2.json' | jq 'def extrapolate: foreach .[] as $row (0; ($row.date // .); . as $x | $row | .date = (.date // ($x | .[:-4] + "Z" | fromdate | gmtime | .[2] += 1 | mktime | todate))); [extrapolate] | map(.date = (.date | split("T")[0]) | {date: .date, deaths: (.cumulative | tonumber)})' > deaths.json

# Fetch the current deaths by age group
# Find the current total number of deaths, including undated deaths, by summing all the groups including Unknown
# Total death count for today is the total death count as of today minus the undated death count
curl 'https://data.sccgov.org/resource/pg8z-gbgv.json?$select=*,:updated_at' | jq '{date: (.[0][":updated_at"][:19] + "Z" | fromdate | gmtime | .[3] -= 7 | mktime | strftime("%Y-%m-%d")), deaths: (map(.count | tonumber) | add)}' > deaths_today.json

# Update the table's existing entries with new data from the dashboard
jq -s --tab 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); .[0] as $commons | (.[0].data | map({date: .[0], newCases: null, cases: null, hospitalized: .[3], hospitalizedPUI: .[4], deaths: null, undatedCases: .[6]})) + .[1] + .[2] + .[3] + [.[4]] + [.[5]] | group_by(.date) | map(map(with_entries(select(.value != null))) | add) | map([.date, .newCases, .cases, .hospitalized, .hospitalizedPUI, .deaths]) | [eval_repeats(5)] as $data | $commons | .data = $data' commons.json cases.json hosp.json deaths.json cases_today.json deaths_today.json | expand -t4
