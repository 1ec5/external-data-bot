#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Santa_Clara_County,_California.tab?action=raw' > commons.json

# Fetch the cases by day
curl 'https://data.sccgov.org/resource/6cnm-gchg.json' | jq 'map({date: (.date | split("T")[0]), newCases: (.new_cases | tonumber), totalConfirmedCases: (.total_cases | tonumber)})' > casesbyday.json

# Fetch the current cases by gender
# Find the current total number of cases, including undated cases, by summing all the groups including Unknown
# Total case count for today is the total case count as of today minus the undated case count
curl 'https://data.sccgov.org/resource/ibdk-7rf5.json?$select=*,:updated_at' | jq '{date: (.[0][":updated_at"][:19] + "Z" | fromdate | gmtime | .[3] -= 7 | mktime | strftime("%Y-%m-%d")), totalConfirmedCasesInclUndated: (map(.count | tonumber) | add)}' > today.json

# Fetch the hospitalizations by day
#curl 'https://data.sccgov.org/resource/5xkz-6esm.json' | jq 'map(.date = (.date | split("T")[0]) | {date: (if .date >= "2021-12-27" then (.date | sub("^2021"; "2020")) else .date end), hospitalized: (.covid_total | tonumber), hospitalizedPUI: (.pui_total | tonumber)})' > hosp.json

# Fetch the hospitalizations by day from the Power BI dashboard
# https://www.sccgov.org/sites/covid19/Pages/dashboard-hospitals.aspx
curl 'https://wabi-us-gov-virginia-api.analysis.usgovcloudapi.net/public/reports/querydata' -H 'Host: wabi-us-gov-virginia-api.analysis.usgovcloudapi.net' --compressed --data $'{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"t","Entity":"trends","Type":0}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"t"}},"Property":"Data_Date"},"Name":"trends.Date"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"t"}},"Property":"covid_total"}},"Function":0},"Name":"Sum(trends.covid_total)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"t"}},"Property":"pui_total"}},"Function":0},"Name":"Sum(trends.pui_total)"}],"Where":[{"Condition":{"Comparison":{"ComparisonKind":2,"Left":{"Column":{"Expression":{"SourceRef":{"Source":"t"}},"Property":"Data_Date"}},"Right":{"DateSpan":{"Expression":{"Literal":{"Value":"datetime\'2020-05-13T00:00:00\'"}},"TimeUnit":5}}}}}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1,2]}]},"DataReduction":{"DataVolume":4,"Primary":{"Sample":{}}},"Version":1}}}]},"CacheKey":"{\\"Commands\\":[{\\"SemanticQueryDataShapeCommand\\":{\\"Query\\":{\\"Version\\":2,\\"From\\":[{\\"Name\\":\\"t\\",\\"Entity\\":\\"trends\\",\\"Type\\":0}],\\"Select\\":[{\\"Column\\":{\\"Expression\\":{\\"SourceRef\\":{\\"Source\\":\\"t\\"}},\\"Property\\":\\"Data_Date\\"},\\"Name\\":\\"trends.Date\\"},{\\"Aggregation\\":{\\"Expression\\":{\\"Column\\":{\\"Expression\\":{\\"SourceRef\\":{\\"Source\\":\\"t\\"}},\\"Property\\":\\"covid_total\\"}},\\"Function\\":0},\\"Name\\":\\"Sum(trends.covid_total)\\"},{\\"Aggregation\\":{\\"Expression\\":{\\"Column\\":{\\"Expression\\":{\\"SourceRef\\":{\\"Source\\":\\"t\\"}},\\"Property\\":\\"pui_total\\"}},\\"Function\\":0},\\"Name\\":\\"Sum(trends.pui_total)\\"}],\\"Where\\":[{\\"Condition\\":{\\"Comparison\\":{\\"ComparisonKind\\":2,\\"Left\\":{\\"Column\\":{\\"Expression\\":{\\"SourceRef\\":{\\"Source\\":\\"t\\"}},\\"Property\\":\\"Data_Date\\"}},\\"Right\\":{\\"DateSpan\\":{\\"Expression\\":{\\"Literal\\":{\\"Value\\":\\"datetime\'2020-05-13T00:00:00\'\\"}},\\"TimeUnit\\":5}}}}}]},\\"Binding\\":{\\"Primary\\":{\\"Groupings\\":[{\\"Projections\\":[0,1,2]}]},\\"DataReduction\\":{\\"DataVolume\\":4,\\"Primary\\":{\\"Sample\\":{}}},\\"Version\\":1}}}]}","QueryId":"","ApplicationContext":{"DatasetId":"98358f41-2327-449a-aa33-91c26301646a","Sources":[{"ReportId":"b751de7a-ad18-4a85-82d5-579bde5195a0"}]}}],"cancelQueries":[],"modelId":344051}' > dashboard.json
jq 'def propagate_repeats(dm1): if .R == 2 then .C = .C[:1] + [null] + .C[1:] elif .R == 4 then .C = .C[:2] + [null] + .C[2:] elif .R == 6 then .C = .C[:1] + [null, null] + .C[1:] else . end; def eval_repeats(series): series | map(.C) | foreach .[] as $row ([]; [., $row] | transpose | map(.[1] // .[0]); .); .results | map(.result.data | (.descriptor.Select | map(.Name) | .[0] = "date") as $desc | .dsr.DS[0].PH[0].DM0 | map(select(has("Ø") | not) | propagate_repeats(.)) | [eval_repeats(.)] | map([$desc, (.[0] = (.[0] / 1000 | strftime("%Y-%m-%d")))] | transpose | map({(.[0]): .[1]}) | add)) | add | group_by(.date) | map(add | .hospitalized = .["Sum(trends.covid_total)"] | .hospitalizedPUI = .["Sum(trends.pui_total)"])' dashboard.json > hosp.json

# Fetch the deaths by day
curl 'https://data.sccgov.org/resource/tg4j-23y2.json' | jq 'def extrapolate: foreach .[] as $row (0; ($row.date // .); . as $x | $row | .date = (.date // ($x | .[:-4] + "Z" | fromdate | gmtime | .[2] += 1 | mktime | todate))); [extrapolate] | map(.date = (.date | split("T")[0]) | {date: (.date | sub("^1921"; "2021")), deaths: (if .date = "2021-12-21" then null else (.cumulative | tonumber) end)})' > deaths.json

# Update the table's existing entries with new data from the dashboard, adding a row for today
# New case count for today is total case count for today minus total case count for yesterday
jq -s --tab 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); .[0] as $commons | (.[0].data | map({date: .[0], newCases: null, totalConfirmedCases: null, hospitalized: .[3], hospitalizedPUI: .[4], deaths: null, undatedCases: .[6]})) + .[1] + .[2] + .[3] + [.[4]] | group_by(.date) | map(map(with_entries(select(.value != null))) | add) | .[-1].totalConfirmedCases = (.[-1].totalConfirmedCases // .[-2].totalConfirmedCases // .[-3].totalConfirmedCases) | .[-1].undatedCases = (if .[-1].totalConfirmedCasesInclUndated then (.[-1].totalConfirmedCasesInclUndated - .[-1].totalConfirmedCases) else null end) | map([.date, .newCases, .totalConfirmedCases, .hospitalized, .hospitalizedPUI, .deaths, .undatedCases]) | [eval_repeats(5)] as $data | $commons | .data = $data' commons.json casesbyday.json hosp.json deaths.json today.json | expand -t4
