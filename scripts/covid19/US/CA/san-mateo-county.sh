#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_San_Mateo_County,_California.tab?action=raw' > commons.json

# Fetch the total cases by day from the dashboard
curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/querydata' --compressed --data '{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"c","Entity":"cases_by_day","Type":0}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"date_result"},"Name":"cases_by_day.date_result"},{"Measure":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"Sum of n running total in date_result"},"Name":"cases_by_day.Sum of n running total in date_result"}],"Where":[{"Condition":{"In":{"Expressions":[{"Column":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"yesterday_or_before"}}],"Values":[[{"Literal":{"Value":"1L"}}],[{"Literal":{"Value":"0L"}}]]}}}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1]}]},"DataReduction":{"DataVolume":4,"Primary":{"Sample":{}}},"Version":1}}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"c\",\"Entity\":\"cases_by_day\",\"Type\":0}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"date_result\"},\"Name\":\"cases_by_day.date_result\"},{\"Measure\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"Sum of n running total in date_result\"},\"Name\":\"cases_by_day.Sum of n running total in date_result\"}],\"Where\":[{\"Condition\":{\"In\":{\"Expressions\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"yesterday_or_before\"}}],\"Values\":[[{\"Literal\":{\"Value\":\"1L\"}}],[{\"Literal\":{\"Value\":\"0L\"}}]]}}}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"Sample\":{}}},\"Version\":1}}}]}","QueryId":"","ApplicationContext":{"DatasetId":"aa4631ab-2f78-40f6-b4c4-d2f5f8a89bcc","Sources":[{"ReportId":"baf74baa-bdc9-4c71-995a-b996f1d0b7e9"}]}}],"cancelQueries":[],"modelId":275725}' > dashboard.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Fill in counts repeated from previous days, which are indicated by C = null, R = 2
jq 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); def by_day(key): .results | map(.result.data) | map((.descriptor.Select[] | select(.Name | contains(key))) as $field | ($field | .Value[1:] | tonumber) as $index | .dsr.DS[0].PH[0].DM0 | map(select(has("Ø") | not) | {date: (.C[0] / 1000 | strftime("%Y-%m-%d")), ($field.Name): (if .R and .R / 2 == $index + 1 then null elif .R and .R / 2 < $index + 1 then .C[$index] else .C[$index + 1] end)}) | [eval_repeats($field.Name)] | INDEX(.date)); by_day("running total")[0]' dashboard.json > cases.json

# Fetch the new cases by day from the dashboard
curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/querydata' --compressed --data '{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"c","Entity":"cases_by_day","Type":0}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"date_result"},"Name":"cases_by_day.date_result"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"n"}},"Function":0},"Name":"CountNonNull(cases_by_day.n)"}],"Where":[{"Condition":{"In":{"Expressions":[{"Column":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"yesterday_or_before"}}],"Values":[[{"Literal":{"Value":"1L"}}],[{"Literal":{"Value":"0L"}}]]}}}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1]}]},"DataReduction":{"DataVolume":4,"Primary":{"Sample":{}}},"Version":1}}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"c\",\"Entity\":\"cases_by_day\",\"Type\":0}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"date_result\"},\"Name\":\"cases_by_day.date_result\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"n\"}},\"Function\":0},\"Name\":\"CountNonNull(cases_by_day.n)\"}],\"Where\":[{\"Condition\":{\"In\":{\"Expressions\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"yesterday_or_before\"}}],\"Values\":[[{\"Literal\":{\"Value\":\"1L\"}}],[{\"Literal\":{\"Value\":\"0L\"}}]]}}}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"Sample\":{}}},\"Version\":1}}}]}","QueryId":"","ApplicationContext":{"DatasetId":"aa4631ab-2f78-40f6-b4c4-d2f5f8a89bcc","Sources":[{"ReportId":"baf74baa-bdc9-4c71-995a-b996f1d0b7e9"}]}}],"cancelQueries":[],"modelId":275725}' > dashboard.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Fill in counts repeated from previous days, which are indicated by C = null, R = 2
jq 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); def by_day(key): .results | map(.result.data) | map((.descriptor.Select[] | select(.Name | contains(key))) as $field | ($field | .Value[1:] | tonumber) as $index | .dsr.DS[0].PH[0].DM0 | map(select(has("Ø") | not) | {date: (.C[0] / 1000 | strftime("%Y-%m-%d")), ($field.Name): (if .R and .R / 2 == $index + 1 then null elif .R and .R / 2 < $index + 1 then .C[$index] else .C[$index + 1] end)}) | [eval_repeats($field.Name)] | INDEX(.date)); by_day("CountNonNull")[0]' dashboard.json > newcases.json

# Fetch the hospitalizations by day from the dashboard
# Convert date from number of milliseconds to YYYY-MM-DD
# Fill in counts repeated from previous days:
#  - If R = 2, then 1 repeats
#  - If R = 4, then 2 repeats
#  - If R = 6, then 1 and 2 repeat
curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/querydata' --compressed --data '{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"r","Entity":"reddinet_daily_data","Type":0}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"},"Name":"reddinet_daily_data.date"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"icu_covid_conf"}},"Function":0},"Name":"Sum(reddinet_daily_data.icu_covid_conf)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"ms_conf_covid"}},"Function":0},"Name":"Sum(reddinet_daily_data.ms_conf_covid)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"conf_covid_1_3d_avg"}},"Function":0},"Name":"Sum(reddinet_daily_data.conf_covid_1_3d_avg)"}],"Where":[{"Condition":{"Between":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"}},"LowerBound":{"DateSpan":{"Expression":{"DateAdd":{"Expression":{"DateAdd":{"Expression":{"Now":{}},"Amount":1,"TimeUnit":0}},"Amount":-15,"TimeUnit":0}},"TimeUnit":0}},"UpperBound":{"DateSpan":{"Expression":{"Now":{}},"TimeUnit":0}}}}}],"OrderBy":[{"Direction":1,"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"}}}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1,2,3]}]},"DataReduction":{"DataVolume":4,"Primary":{"Window":{"Count":1000}}},"Version":1}}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"r\",\"Entity\":\"reddinet_daily_data\",\"Type\":0}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"},\"Name\":\"reddinet_daily_data.date\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"icu_covid_conf\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.icu_covid_conf)\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"ms_conf_covid\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.ms_conf_covid)\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"conf_covid_1_3d_avg\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.conf_covid_1_3d_avg)\"}],\"Where\":[{\"Condition\":{\"Between\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"}},\"LowerBound\":{\"DateSpan\":{\"Expression\":{\"DateAdd\":{\"Expression\":{\"DateAdd\":{\"Expression\":{\"Now\":{}},\"Amount\":1,\"TimeUnit\":0}},\"Amount\":-15,\"TimeUnit\":0}},\"TimeUnit\":0}},\"UpperBound\":{\"DateSpan\":{\"Expression\":{\"Now\":{}},\"TimeUnit\":0}}}}}],\"OrderBy\":[{\"Direction\":1,\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"}}}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1,2,3]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"Window\":{\"Count\":1000}}},\"Version\":1}}}]}","QueryId":"","ApplicationContext":{"DatasetId":"ac16a19d-af9b-47d0-9d10-61463679ba70","Sources":[{"ReportId":"6e1710bb-689f-4b23-b790-ac23dbcce4bd"}]}},{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"r","Entity":"reddinet_daily_data","Type":0}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"},"Name":"reddinet_daily_data.date"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"icu_available"}},"Function":0},"Name":"Sum(reddinet_daily_data.icu_available)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"icu_covid"}},"Function":0},"Name":"Sum(reddinet_daily_data.icu_covid)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"icu_other"}},"Function":0},"Name":"Sum(reddinet_daily_data.icu_other)"}],"Where":[{"Condition":{"Between":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"}},"LowerBound":{"DateSpan":{"Expression":{"DateAdd":{"Expression":{"DateAdd":{"Expression":{"Now":{}},"Amount":1,"TimeUnit":0}},"Amount":-14,"TimeUnit":0}},"TimeUnit":0}},"UpperBound":{"DateSpan":{"Expression":{"Now":{}},"TimeUnit":0}}}}}],"OrderBy":[{"Direction":1,"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"}}}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1,2,3]}]},"DataReduction":{"DataVolume":4,"Primary":{"Window":{"Count":1000}}},"Version":1}}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"r\",\"Entity\":\"reddinet_daily_data\",\"Type\":0}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"},\"Name\":\"reddinet_daily_data.date\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"icu_available\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.icu_available)\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"icu_covid\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.icu_covid)\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"icu_other\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.icu_other)\"}],\"Where\":[{\"Condition\":{\"Between\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"}},\"LowerBound\":{\"DateSpan\":{\"Expression\":{\"DateAdd\":{\"Expression\":{\"DateAdd\":{\"Expression\":{\"Now\":{}},\"Amount\":1,\"TimeUnit\":0}},\"Amount\":-14,\"TimeUnit\":0}},\"TimeUnit\":0}},\"UpperBound\":{\"DateSpan\":{\"Expression\":{\"Now\":{}},\"TimeUnit\":0}}}}}],\"OrderBy\":[{\"Direction\":1,\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"}}}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1,2,3]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"Window\":{\"Count\":1000}}},\"Version\":1}}}]}","QueryId":"","ApplicationContext":{"DatasetId":"ac16a19d-af9b-47d0-9d10-61463679ba70","Sources":[{"ReportId":"6e1710bb-689f-4b23-b790-ac23dbcce4bd"}]}},{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"r","Entity":"reddinet_daily_data","Type":0}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"},"Name":"reddinet_daily_data.date"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"ms_available"}},"Function":0},"Name":"Sum(reddinet_daily_data.ms_available)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"ms_covid"}},"Function":0},"Name":"Sum(reddinet_daily_data.ms_covid)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"ms_other"}},"Function":0},"Name":"Sum(reddinet_daily_data.ms_other)"}],"Where":[{"Condition":{"Between":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"}},"LowerBound":{"DateSpan":{"Expression":{"DateAdd":{"Expression":{"DateAdd":{"Expression":{"Now":{}},"Amount":1,"TimeUnit":0}},"Amount":-14,"TimeUnit":0}},"TimeUnit":0}},"UpperBound":{"DateSpan":{"Expression":{"Now":{}},"TimeUnit":0}}}}}],"OrderBy":[{"Direction":1,"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"}}}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1,2,3]}]},"DataReduction":{"DataVolume":4,"Primary":{"Window":{"Count":1000}}},"Version":1}}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"r\",\"Entity\":\"reddinet_daily_data\",\"Type\":0}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"},\"Name\":\"reddinet_daily_data.date\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"ms_available\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.ms_available)\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"ms_covid\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.ms_covid)\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"ms_other\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.ms_other)\"}],\"Where\":[{\"Condition\":{\"Between\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"}},\"LowerBound\":{\"DateSpan\":{\"Expression\":{\"DateAdd\":{\"Expression\":{\"DateAdd\":{\"Expression\":{\"Now\":{}},\"Amount\":1,\"TimeUnit\":0}},\"Amount\":-14,\"TimeUnit\":0}},\"TimeUnit\":0}},\"UpperBound\":{\"DateSpan\":{\"Expression\":{\"Now\":{}},\"TimeUnit\":0}}}}}],\"OrderBy\":[{\"Direction\":1,\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"}}}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1,2,3]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"Window\":{\"Count\":1000}}},\"Version\":1}}}]}","QueryId":"","ApplicationContext":{"DatasetId":"ac16a19d-af9b-47d0-9d10-61463679ba70","Sources":[{"ReportId":"6e1710bb-689f-4b23-b790-ac23dbcce4bd"}]}}],"cancelQueries":[],"modelId":290640}' > dashboard.json
jq 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); def by_day(key): .results | map(.result.data) | map((.descriptor.Select[] | select(.Name | contains(key))) as $field | ($field | .Value[1:] | tonumber) as $index | .dsr.DS[0].PH[0].DM0 | map(select(has("Ø") | not) | {date: (.C[0] / 1000 | strftime("%Y-%m-%d")), ($field.Name): (if .R == 2 then .C = .C[:1] + [null] + .C[1:] elif .R == 4 then .C = .C[:2] + [null] + .C[2:] elif .R == 6 then .C = .C[:1] + [null, null] + .C[1:] else . end | .C[$index + 1])}) | [eval_repeats($field.Name)]); by_day("covid") | add | group_by(.date) | map(add | .hospitalized = (.["Sum(reddinet_daily_data.icu_covid_conf)"] + .["Sum(reddinet_daily_data.ms_conf_covid)"]) | .hospitalizedInclSuspected = (.["Sum(reddinet_daily_data.ms_covid)"] + .["Sum(reddinet_daily_data.icu_covid)"]))' dashboard.json > hosp.json

jq -s '[.[0][]] + [.[1][]] + [.[2][]] | group_by(.date) | map(reduce .[] as $item ({}; . + $item)) | map({date: .date, newCases: .["CountNonNull(cases_by_day.n)"], cases: .["cases_by_day.Sum of n running total in date_result"], hospitalized: .hospitalized, hospitalizedInclSuspected: .hospitalizedInclSuspected})' cases.json newcases.json hosp.json > dates.json

# Fetch the dashboard's UI, which contains the death toll timestamp
curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/86dc380f-4914-4cff-b2a5-03af9f292bbd/modelsAndExploration?preferReadOnlySession=true' --compressed -H 'X-PowerBI-ResourceKey: 86dc380f-4914-4cff-b2a5-03af9f292bbd' > ui.json

# Isolate the death toll's timestamp
DEATH_DATE=$(jq '.exploration.sections[].visualContainers[].config | match("Death data last updated (\\w+ \\d+, \\d+)").captures[0].string | strptime("%B %d, %Y") | strftime("%Y-%m-%d")' ui.json)

# Fetch the death toll from the dashboard
curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/querydata' --compressed --data '{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"d1","Entity":"deaths by race","Type":0}],"Select":[{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"d1"}},"Property":"n"}},"Function":0},"Name":"Sum(deaths by race.n)"}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0]}]},"DataReduction":{"DataVolume":3,"Primary":{"Top":{}}},"Version":1}}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"d1\",\"Entity\":\"deaths by race\",\"Type\":0}],\"Select\":[{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"d1\"}},\"Property\":\"n\"}},\"Function\":0},\"Name\":\"Sum(deaths by race.n)\"}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0]}]},\"DataReduction\":{\"DataVolume\":3,\"Primary\":{\"Top\":{}}},\"Version\":1}}}]}","QueryId":"","ApplicationContext":{"DatasetId":"aa4631ab-2f78-40f6-b4c4-d2f5f8a89bcc","Sources":[{"ReportId":"baf74baa-bdc9-4c71-995a-b996f1d0b7e9"}]}}],"cancelQueries":[],"modelId":275725}' > dashboard.json
DEATHS=$(jq '.results[].result.data.dsr.DS[].PH[].DM0[].M0' dashboard.json)

echo "{\"date\": ${DEATH_DATE}, \"deaths\": ${DEATHS}}" > today.json

# Join cases with hospitalizations and deaths
# Backfill deaths and hospitalizations from Commons
# Update Commons
jq -s --tab '.[0] as $commons | ($commons.data | map({date: .[0], deaths: .[3], hospitalized: .[4], hospitalizedInclSuspected: .[5]})) + .[1] + [.[2]] | group_by(.date) | map(map(with_entries(select(.value != null))) | add | [.date, .newCases, .cases, .deaths, .hospitalized, .hospitalizedInclSuspected]) as $data | $commons | .data = $data' commons.json dates.json today.json | expand -t4
