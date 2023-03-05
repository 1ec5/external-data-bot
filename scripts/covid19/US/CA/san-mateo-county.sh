#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_San_Mateo_County,_California.tab?action=raw' > commons.json

# Fetch the deaths by day from the death dashboard
# Convert date from number of milliseconds to YYYY-MM-DD
# Fill in counts repeated from previous days:
#  - If R = 2, then 1 repeats
#  - If R = 4, then 2 repeats
#  - If R = 6, then 1 and 2 repeat
curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/querydata' --compressed --data '{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"t","Entity":"time_series","Type":0}],"Select":[{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"t"}},"Property":"Daily"}},"Function":0},"Name":"Sum(time_series.Daily)","NativeReferenceName":"Daily Count"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"t"}},"Property":"Rolling 7-day Average"}},"Function":0},"Name":"Sum(time_series.Rolling 7-day Average)","NativeReferenceName":"Rolling 7-day Average"},{"Column":{"Expression":{"SourceRef":{"Source":"t"}},"Property":"dod"},"Name":"time_series.dod","NativeReferenceName":"Date of Death"}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1,2]}]},"DataReduction":{"DataVolume":4,"Primary":{"Sample":{}}},"Version":1},"ExecutionMetricsKind":1}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"t\",\"Entity\":\"time_series\",\"Type\":0}],\"Select\":[{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"t\"}},\"Property\":\"Daily\"}},\"Function\":0},\"Name\":\"Sum(time_series.Daily)\",\"NativeReferenceName\":\"Daily Count\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"t\"}},\"Property\":\"Rolling 7-day Average\"}},\"Function\":0},\"Name\":\"Sum(time_series.Rolling 7-day Average)\",\"NativeReferenceName\":\"Rolling 7-day Average\"},{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"t\"}},\"Property\":\"dod\"},\"Name\":\"time_series.dod\",\"NativeReferenceName\":\"Date of Death\"}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1,2]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"Sample\":{}}},\"Version\":1},\"ExecutionMetricsKind\":1}}]}","QueryId":"ac775dba-8438-c4b8-a190-0ea4da7ddd7d","ApplicationContext":{"DatasetId":"0d7b41e0-0672-41fa-802d-65b2ab93b974","Sources":[{"ReportId":"e95cd128-edc0-4dde-b81a-0399ca652566","VisualId":"2a404062ca51b0e8b172"}]}}],"cancelQueries":[],"modelId":495458}' > dashboard.json
# The two series seem to have gotten mixed up
# Accumulate deaths
jq 'def propagate_repeats(dm1): if .R == 2 then .C = .C[:1] + [null] + .C[1:] elif .R == 4 then .C = .C[:2] + [null] + .C[2:] elif .R == 6 then .C = .C[:1] + [null, null] + .C[1:] else . end; def eval_repeats(series): series | map(.C) | foreach .[] as $row ([]; [., $row] | transpose | map(.[1] // .[0]); .); .results | map(.result.data | (.descriptor.Select | map(.Name) | .[0] = "date") as $desc | .dsr.DS[0].PH[0].DM0 | map(select(has("Ø") | not) | propagate_repeats(.)) | [eval_repeats(.)] | map(select(.[0] != null) | [$desc, (.[0] = (.[0] / 1000 | strftime("%Y-%m-%d")))] | transpose | map({(.[0]): .[1]}) | add)) | add | group_by(.date) | map(add | .newDeaths = .["Sum(time_series.Rolling 7-day Average)"]) | [foreach .[] as $date (0; . + $date.newDeaths; . as $deaths | $date | .deaths = $deaths)]' dashboard.json > deaths.json

# Fetch the confirmed hospitalizations by day from the hospitalization dashboard
curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/querydata' --compressed --data '{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"r","Entity":"reddinet_time_series","Type":0}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"},"Name":"reddinet_time_series.date"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"as_pos_icu_tot"}},"Function":0},"Name":"Sum(reddinet_time_series.as_pos_icu_tot)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"as_pos_ms_tot"}},"Function":0},"Name":"Sum(reddinet_time_series.as_pos_ms_tot)"}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1,2]}]},"DataReduction":{"DataVolume":4,"Primary":{"Sample":{}}},"Version":1},"ExecutionMetricsKind":1}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"r\",\"Entity\":\"reddinet_time_series\",\"Type\":0}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"},\"Name\":\"reddinet_time_series.date\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"as_pos_icu_tot\"}},\"Function\":0},\"Name\":\"Sum(reddinet_time_series.as_pos_icu_tot)\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"as_pos_ms_tot\"}},\"Function\":0},\"Name\":\"Sum(reddinet_time_series.as_pos_ms_tot)\"}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1,2]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"Sample\":{}}},\"Version\":1},\"ExecutionMetricsKind\":1}}]}","QueryId":"c2b629c2-c6f3-471c-6b6c-fe4e7488131c","ApplicationContext":{"DatasetId":"76b45a8b-cbcf-403c-85a4-00dd29e1d702","Sources":[{"ReportId":"d3070298-eafd-4861-aeaf-f317701aa017","VisualId":"efc0ea4419e95ab622de"}]}}],"cancelQueries":[],"modelId":495457}' > dashboard.json
jq 'def propagate_repeats(dm1): if .R == 2 then .C = .C[:1] + [null] + .C[1:] elif .R == 4 then .C = .C[:2] + [null] + .C[2:] elif .R == 6 then .C = .C[:1] + [null, null] + .C[1:] else . end; def eval_repeats(series): series | map(.C) | foreach .[] as $row ([]; [., $row] | transpose | map(.[1] // .[0]); .); .results | map(.result.data | (.descriptor.Select | map(.Name) | .[0] = "date") as $desc | .dsr.DS[0].PH[0].DM0 | map(select(has("Ø") | not) | propagate_repeats(.)) | [eval_repeats(.)] | map(select(.[0] != null) | [$desc, (.[0] = (.[0] / 1000 | strftime("%Y-%m-%d")))] | transpose | map({(.[0]): .[1]}) | add)) | add | group_by(.date) | map(add | .hospitalized = (.["Sum(reddinet_time_series.as_pos_icu_tot)"] + .["Sum(reddinet_time_series.as_pos_ms_tot)"]))' dashboard.json > hosp.json

jq -s '[.[0][]] + [.[1][]] | group_by(.date) | map(reduce .[] as $item ({}; . + $item)) | map({date: .date, deaths: .deaths, hospitalized: .hospitalized})' deaths.json hosp.json > dates.json

# Fetch the death dashboard's UI, which contains the death toll timestamp
curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/3ba15840-3c70-4c89-942b-5ad6fc0a9fe5/modelsAndExploration?preferReadOnlySession=true' --compressed -H 'X-PowerBI-ResourceKey: 3ba15840-3c70-4c89-942b-5ad6fc0a9fe5' > ui.json

# Isolate the death toll's timestamp
DEATH_DATE=$(jq '.exploration.sections[].visualContainers[].config | match("Data up to and including (\\w+ \\d+, \\d+)").captures[0].string | strptime("%B %d, %Y") | strftime("%Y-%m-%d")' ui.json)

# Fetch the death toll from the death dashboard
curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/querydata' --compressed --data '{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"t","Entity":"total","Type":0}],"Select":[{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"t"}},"Property":"n"}},"Function":0},"Name":"Sum(total.n)","NativeReferenceName":"n"}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0]}]},"DataReduction":{"DataVolume":3,"Primary":{"Top":{}}},"Version":1},"ExecutionMetricsKind":1}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"t\",\"Entity\":\"total\",\"Type\":0}],\"Select\":[{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"t\"}},\"Property\":\"n\"}},\"Function\":0},\"Name\":\"Sum(total.n)\",\"NativeReferenceName\":\"n\"}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0]}]},\"DataReduction\":{\"DataVolume\":3,\"Primary\":{\"Top\":{}}},\"Version\":1},\"ExecutionMetricsKind\":1}}]}","QueryId":"60a4cbf7-f8ce-f9e6-8473-e62457d80396","ApplicationContext":{"DatasetId":"0d7b41e0-0672-41fa-802d-65b2ab93b974","Sources":[{"ReportId":"e95cd128-edc0-4dde-b81a-0399ca652566","VisualId":"a4f624ba349213e53774"}]}}],"cancelQueries":[],"modelId":495458}' > dashboard.json
DEATHS=$(jq '.results[0].result.data.dsr.DS[].PH[].DM0[].M0' dashboard.json)

echo "{\"date\": ${DEATH_DATE}, \"deaths\": ${DEATHS}}" > today.json

# Join cases with hospitalizations and deaths
# Backfill deaths and hospitalizations from Commons
# Update Commons
jq -s --tab 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); .[0] as $commons | ($commons.data | map({date: .[0], newCases: .[1], cases: .[2], deaths: null, hospitalized: .[4], hospitalizedInclSuspected: .[5]})) + .[1] + [.[2]] | group_by(.date) | map(map(with_entries(select(.value != null))) | add | [.date, .newCases, .cases, .deaths, .hospitalized, .hospitalizedInclSuspected // .hospitalized]) | [eval_repeats(3)] as $data | $commons | .data = $data' commons.json dates.json today.json | expand -t4
