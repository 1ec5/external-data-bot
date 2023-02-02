#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_San_Mateo_County,_California.tab?action=raw' > commons.json

# Fetch the total by day from the dashboard
curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/querydata' --compressed --data '{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"c","Entity":"cases_by_day","Type":0}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"episode_date"},"Name":"cases_by_day.episode_date"},{"Measure":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"Sum of n running total in episode_date"},"Name":"cases_by_day.Sum of n running total in episode_date"}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1]}]},"DataReduction":{"DataVolume":4,"Primary":{"Sample":{}}},"Version":1},"ExecutionMetricsKind":1}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"c\",\"Entity\":\"cases_by_day\",\"Type\":0}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"episode_date\"},\"Name\":\"cases_by_day.episode_date\"},{\"Measure\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"Sum of n running total in episode_date\"},\"Name\":\"cases_by_day.Sum of n running total in episode_date\"}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"Sample\":{}}},\"Version\":1},\"ExecutionMetricsKind\":1}}]}","QueryId":"","ApplicationContext":{"DatasetId":"aa4631ab-2f78-40f6-b4c4-d2f5f8a89bcc","Sources":[{"ReportId":"baf74baa-bdc9-4c71-995a-b996f1d0b7e9","VisualId":"f3e56a2f76f805cf6c39"}]}},{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"d1","Entity":"death by sex","Type":0}],"Select":[{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"d1"}},"Property":"n"}},"Function":0},"Name":"Sum(death by sex.n)"},{"Column":{"Expression":{"SourceRef":{"Source":"d1"}},"Property":"sex"},"Name":"death by sex.sex"}],"OrderBy":[{"Direction":1,"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"d1"}},"Property":"sex"}}}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1]}]},"DataReduction":{"DataVolume":4,"Primary":{"Window":{"Count":1000}}},"Version":1},"ExecutionMetricsKind":1}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"d1\",\"Entity\":\"death by sex\",\"Type\":0}],\"Select\":[{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"d1\"}},\"Property\":\"n\"}},\"Function\":0},\"Name\":\"Sum(death by sex.n)\"},{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"d1\"}},\"Property\":\"sex\"},\"Name\":\"death by sex.sex\"}],\"OrderBy\":[{\"Direction\":1,\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"d1\"}},\"Property\":\"sex\"}}}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"Window\":{\"Count\":1000}}},\"Version\":1},\"ExecutionMetricsKind\":1}}]}","QueryId":"","ApplicationContext":{"DatasetId":"aa4631ab-2f78-40f6-b4c4-d2f5f8a89bcc","Sources":[{"ReportId":"baf74baa-bdc9-4c71-995a-b996f1d0b7e9","VisualId":"28a9693175461b9cd964"}]}}],"cancelQueries":[],"modelId":275725}' > dashboard.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Fill in counts repeated from previous days, which are indicated by C = null, R = 2
jq 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); def by_day(key): .results | map(.result.data) | map((.descriptor.Select[] | select(.Name | contains(key))) as $field | ($field | .Value[1:] | tonumber) as $index | .dsr.DS[0].PH[0].DM0 | map(select(has("Ø") | not) | {date: (.C[0] / 1000 | strftime("%Y-%m-%d")), ($field.Name): (if .R and .R / 2 == $index + 1 then null elif .R and .R / 2 < $index + 1 then .C[$index] else .C[$index + 1] end)}) | [eval_repeats($field.Name)] | INDEX(.date)); by_day("running total")[0]' dashboard.json > cases.json

# Fetch the new cases by day from the dashboard
curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/querydata' --compressed --data '{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"c","Entity":"cases_by_day","Type":0}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"episode_date"},"Name":"cases_by_day.episode_date"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"n"}},"Function":0},"Name":"Sum(cases_by_day.n)"}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1]}]},"DataReduction":{"DataVolume":4,"Primary":{"Sample":{}}},"Version":1},"ExecutionMetricsKind":1}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"c\",\"Entity\":\"cases_by_day\",\"Type\":0}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"episode_date\"},\"Name\":\"cases_by_day.episode_date\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"n\"}},\"Function\":0},\"Name\":\"Sum(cases_by_day.n)\"}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"Sample\":{}}},\"Version\":1},\"ExecutionMetricsKind\":1}}]}","QueryId":"","ApplicationContext":{"DatasetId":"aa4631ab-2f78-40f6-b4c4-d2f5f8a89bcc","Sources":[{"ReportId":"baf74baa-bdc9-4c71-995a-b996f1d0b7e9","VisualId":"b16f0b1f2d9b4fb37a62"}]}},{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"c","Entity":"cases_by_race","Type":0}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"race_cat"},"Name":"cases_by_race.race_cat"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"n"}},"Function":0},"Name":"Sum(cases_by_race.n)"}],"OrderBy":[{"Direction":1,"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"c"}},"Property":"race_cat"}}}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1]}]},"DataReduction":{"DataVolume":4,"Primary":{"Window":{"Count":1000}}},"Version":1},"ExecutionMetricsKind":1}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"c\",\"Entity\":\"cases_by_race\",\"Type\":0}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"race_cat\"},\"Name\":\"cases_by_race.race_cat\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"n\"}},\"Function\":0},\"Name\":\"Sum(cases_by_race.n)\"}],\"OrderBy\":[{\"Direction\":1,\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"c\"}},\"Property\":\"race_cat\"}}}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"Window\":{\"Count\":1000}}},\"Version\":1},\"ExecutionMetricsKind\":1}}]}","QueryId":"","ApplicationContext":{"DatasetId":"aa4631ab-2f78-40f6-b4c4-d2f5f8a89bcc","Sources":[{"ReportId":"baf74baa-bdc9-4c71-995a-b996f1d0b7e9","VisualId":"25be663c95d2dc449677"}]}}],"cancelQueries":[],"modelId":275725}' > dashboard.json

# Convert date from number of milliseconds to YYYY-MM-DD
# Fill in counts repeated from previous days, which are indicated by C = null, R = 2
jq 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); def by_day(key): .results | map(.result.data) | map((.descriptor.Select[] | select(.Name | contains(key))) as $field | ($field | .Value[1:] | tonumber) as $index | .dsr.DS[0].PH[0].DM0 | map(select(has("Ø") | not) | {date: (.C[0] / 1000 | strftime("%Y-%m-%d")), ($field.Name): (if .R and .R / 2 == $index + 1 then null elif .R and .R / 2 < $index + 1 then .C[$index] else .C[$index + 1] end)}) | [eval_repeats($field.Name)] | INDEX(.date)); by_day("cases_by_day.n")[0]' dashboard.json > newcases.json

# Fetch the confirmed hospitalizations by day from the dashboard
# Convert date from number of milliseconds to YYYY-MM-DD
# Fill in counts repeated from previous days:
#  - If R = 2, then 1 repeats
#  - If R = 4, then 2 repeats
#  - If R = 6, then 1 and 2 repeat
curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/querydata' --compressed --data '{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"r","Entity":"reddinet_daily_data","Type":0},{"Name":"subquery","Expression":{"Subquery":{"Query":{"Version":2,"From":[{"Name":"r1","Entity":"reddinet_daily_data","Type":0}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"r1"}},"Property":"date"},"Name":"field"}],"Where":[{"Condition":{"Comparison":{"ComparisonKind":0,"Left":{"Column":{"Expression":{"SourceRef":{"Source":"r1"}},"Property":"date"}},"Right":{"AnyValue":{"DefaultValueOverridesAncestors":true}}}}}],"OrderBy":[{"Direction":2,"Expression":{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r1"}},"Property":"date"}},"Function":4}}}],"Top":12}}},"Type":2}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"},"Name":"reddinet_daily_data.date"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"icu_covid_conf"}},"Function":0},"Name":"Sum(reddinet_daily_data.icu_covid_conf)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"ms_conf_covid"}},"Function":0},"Name":"Sum(reddinet_daily_data.ms_conf_covid)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"conf_covid_1_3d_avg"}},"Function":0},"Name":"Sum(reddinet_daily_data.conf_covid_1_3d_avg)"}],"Where":[{"Condition":{"In":{"Expressions":[{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"}}],"Table":{"SourceRef":{"Source":"subquery"}}}}}],"OrderBy":[{"Direction":1,"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"}}}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1,2,3]}]},"DataReduction":{"DataVolume":4,"Primary":{"Window":{"Count":1000}}},"Version":1},"ExecutionMetricsKind":1}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"r\",\"Entity\":\"reddinet_daily_data\",\"Type\":0},{\"Name\":\"subquery\",\"Expression\":{\"Subquery\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"r1\",\"Entity\":\"reddinet_daily_data\",\"Type\":0}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r1\"}},\"Property\":\"date\"},\"Name\":\"field\"}],\"Where\":[{\"Condition\":{\"Comparison\":{\"ComparisonKind\":0,\"Left\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r1\"}},\"Property\":\"date\"}},\"Right\":{\"AnyValue\":{\"DefaultValueOverridesAncestors\":true}}}}}],\"OrderBy\":[{\"Direction\":2,\"Expression\":{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r1\"}},\"Property\":\"date\"}},\"Function\":4}}}],\"Top\":12}}},\"Type\":2}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"},\"Name\":\"reddinet_daily_data.date\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"icu_covid_conf\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.icu_covid_conf)\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"ms_conf_covid\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.ms_conf_covid)\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"conf_covid_1_3d_avg\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.conf_covid_1_3d_avg)\"}],\"Where\":[{\"Condition\":{\"In\":{\"Expressions\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"}}],\"Table\":{\"SourceRef\":{\"Source\":\"subquery\"}}}}}],\"OrderBy\":[{\"Direction\":1,\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"}}}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1,2,3]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"Window\":{\"Count\":1000}}},\"Version\":1},\"ExecutionMetricsKind\":1}}]}","QueryId":"","ApplicationContext":{"DatasetId":"ac16a19d-af9b-47d0-9d10-61463679ba70","Sources":[{"ReportId":"6e1710bb-689f-4b23-b790-ac23dbcce4bd","VisualId":"028ebbca2ac47c3b9891"}]}}],"cancelQueries":[],"modelId":290640}' > dashboard.json
jq 'def propagate_repeats(dm1): if .R == 2 then .C = .C[:1] + [null] + .C[1:] elif .R == 4 then .C = .C[:2] + [null] + .C[2:] elif .R == 6 then .C = .C[:1] + [null, null] + .C[1:] else . end; def eval_repeats(series): series | map(.C) | foreach .[] as $row ([]; [., $row] | transpose | map(.[1] // .[0]); .); .results | map(.result.data | (.descriptor.Select | map(.Name) | .[0] = "date") as $desc | .dsr.DS[0].PH[0].DM1 | map(select(has("Ø") | not) | propagate_repeats(.)) | [eval_repeats(.)] | map(select(.[0] != null) | [$desc, (.[0] = (.[0] / 1000 | strftime("%Y-%m-%d")))] | transpose | map({(.[0]): .[1]}) | add)) | add | group_by(.date) | map(add | .hospitalized = (.["Sum(reddinet_daily_data.icu_covid_conf)"] + .["Sum(reddinet_daily_data.ms_conf_covid)"]))' dashboard.json > hosp.json

curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/querydata' --compressed --data '{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"r","Entity":"reddinet_daily_data","Type":0},{"Name":"subquery","Expression":{"Subquery":{"Query":{"Version":2,"From":[{"Name":"r1","Entity":"reddinet_daily_data","Type":0}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"r1"}},"Property":"date"},"Name":"field"}],"Where":[{"Condition":{"Comparison":{"ComparisonKind":0,"Left":{"Column":{"Expression":{"SourceRef":{"Source":"r1"}},"Property":"date"}},"Right":{"AnyValue":{"DefaultValueOverridesAncestors":true}}}}}],"OrderBy":[{"Direction":2,"Expression":{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r1"}},"Property":"date"}},"Function":4}}}],"Top":12}}},"Type":2}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"},"Name":"reddinet_daily_data.date"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"icu_available"}},"Function":0},"Name":"Sum(reddinet_daily_data.icu_available)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"icu_covid"}},"Function":0},"Name":"Sum(reddinet_daily_data.icu_covid)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"icu_other"}},"Function":0},"Name":"Sum(reddinet_daily_data.icu_other)"}],"Where":[{"Condition":{"In":{"Expressions":[{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"}}],"Table":{"SourceRef":{"Source":"subquery"}}}}}],"OrderBy":[{"Direction":1,"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"}}}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1,2,3]}]},"DataReduction":{"DataVolume":4,"Primary":{"Window":{"Count":1000}}},"Version":1},"ExecutionMetricsKind":1}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"r\",\"Entity\":\"reddinet_daily_data\",\"Type\":0},{\"Name\":\"subquery\",\"Expression\":{\"Subquery\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"r1\",\"Entity\":\"reddinet_daily_data\",\"Type\":0}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r1\"}},\"Property\":\"date\"},\"Name\":\"field\"}],\"Where\":[{\"Condition\":{\"Comparison\":{\"ComparisonKind\":0,\"Left\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r1\"}},\"Property\":\"date\"}},\"Right\":{\"AnyValue\":{\"DefaultValueOverridesAncestors\":true}}}}}],\"OrderBy\":[{\"Direction\":2,\"Expression\":{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r1\"}},\"Property\":\"date\"}},\"Function\":4}}}],\"Top\":12}}},\"Type\":2}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"},\"Name\":\"reddinet_daily_data.date\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"icu_available\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.icu_available)\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"icu_covid\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.icu_covid)\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"icu_other\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.icu_other)\"}],\"Where\":[{\"Condition\":{\"In\":{\"Expressions\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"}}],\"Table\":{\"SourceRef\":{\"Source\":\"subquery\"}}}}}],\"OrderBy\":[{\"Direction\":1,\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"}}}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1,2,3]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"Window\":{\"Count\":1000}}},\"Version\":1},\"ExecutionMetricsKind\":1}}]}","QueryId":"","ApplicationContext":{"DatasetId":"ac16a19d-af9b-47d0-9d10-61463679ba70","Sources":[{"ReportId":"6e1710bb-689f-4b23-b790-ac23dbcce4bd","VisualId":"0d5f037c329cb64481b1"}]}}],"cancelQueries":[],"modelId":290640}' > dashboard.json
jq 'def propagate_repeats(dm1): if .R == 2 then .C = .C[:1] + [null] + .C[1:] elif .R == 4 then .C = .C[:2] + [null] + .C[2:] elif .R == 6 then .C = .C[:1] + [null, null] + .C[1:] else . end; def eval_repeats(series): series | map(.C) | foreach .[] as $row ([]; [., $row] | transpose | map(.[1] // .[0]); .); .results | map(.result.data | (.descriptor.Select | map(.Name) | .[0] = "date") as $desc | .dsr.DS[0].PH[0].DM1 | map(select(has("Ø") | not) | propagate_repeats(.)) | [eval_repeats(.)] | map(select(.[0] != null) | [$desc, (.[0] = (.[0] / 1000 | strftime("%Y-%m-%d")))] | transpose | map({(.[0]): .[1]}) | add)) | add | group_by(.date) | map(add | .hospitalizedInclSuspectedICU = .["Sum(reddinet_daily_data.icu_covid)"])' dashboard.json > hosp2.json

curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/querydata' --compressed --data '{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"r","Entity":"reddinet_daily_data","Type":0},{"Name":"subquery","Expression":{"Subquery":{"Query":{"Version":2,"From":[{"Name":"r1","Entity":"reddinet_daily_data","Type":0}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"r1"}},"Property":"date"},"Name":"field"}],"Where":[{"Condition":{"Comparison":{"ComparisonKind":0,"Left":{"Column":{"Expression":{"SourceRef":{"Source":"r1"}},"Property":"date"}},"Right":{"AnyValue":{"DefaultValueOverridesAncestors":true}}}}}],"OrderBy":[{"Direction":2,"Expression":{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r1"}},"Property":"date"}},"Function":4}}}],"Top":12}}},"Type":2}],"Select":[{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"},"Name":"reddinet_daily_data.date"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"ms_available"}},"Function":0},"Name":"Sum(reddinet_daily_data.ms_available)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"ms_covid"}},"Function":0},"Name":"Sum(reddinet_daily_data.ms_covid)"},{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"ms_other"}},"Function":0},"Name":"Sum(reddinet_daily_data.ms_other)"}],"Where":[{"Condition":{"In":{"Expressions":[{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"}}],"Table":{"SourceRef":{"Source":"subquery"}}}}}],"OrderBy":[{"Direction":1,"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"r"}},"Property":"date"}}}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0,1,2,3]}]},"DataReduction":{"DataVolume":4,"Primary":{"Window":{"Count":1000}}},"Version":1},"ExecutionMetricsKind":1}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"r\",\"Entity\":\"reddinet_daily_data\",\"Type\":0},{\"Name\":\"subquery\",\"Expression\":{\"Subquery\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"r1\",\"Entity\":\"reddinet_daily_data\",\"Type\":0}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r1\"}},\"Property\":\"date\"},\"Name\":\"field\"}],\"Where\":[{\"Condition\":{\"Comparison\":{\"ComparisonKind\":0,\"Left\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r1\"}},\"Property\":\"date\"}},\"Right\":{\"AnyValue\":{\"DefaultValueOverridesAncestors\":true}}}}}],\"OrderBy\":[{\"Direction\":2,\"Expression\":{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r1\"}},\"Property\":\"date\"}},\"Function\":4}}}],\"Top\":12}}},\"Type\":2}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"},\"Name\":\"reddinet_daily_data.date\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"ms_available\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.ms_available)\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"ms_covid\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.ms_covid)\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"ms_other\"}},\"Function\":0},\"Name\":\"Sum(reddinet_daily_data.ms_other)\"}],\"Where\":[{\"Condition\":{\"In\":{\"Expressions\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"}}],\"Table\":{\"SourceRef\":{\"Source\":\"subquery\"}}}}}],\"OrderBy\":[{\"Direction\":1,\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"date\"}}}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0,1,2,3]}]},\"DataReduction\":{\"DataVolume\":4,\"Primary\":{\"Window\":{\"Count\":1000}}},\"Version\":1},\"ExecutionMetricsKind\":1}}]}","QueryId":"","ApplicationContext":{"DatasetId":"ac16a19d-af9b-47d0-9d10-61463679ba70","Sources":[{"ReportId":"6e1710bb-689f-4b23-b790-ac23dbcce4bd","VisualId":"bcfdddc000668004e0e0"}]}}],"cancelQueries":[],"modelId":290640}' > dashboard.json
jq 'def propagate_repeats(dm1): if .R == 2 then .C = .C[:1] + [null] + .C[1:] elif .R == 4 then .C = .C[:2] + [null] + .C[2:] elif .R == 6 then .C = .C[:1] + [null, null] + .C[1:] else . end; def eval_repeats(series): series | map(.C) | foreach .[] as $row ([]; [., $row] | transpose | map(.[1] // .[0]); .); .results | map(.result.data | (.descriptor.Select | map(.Name) | .[0] = "date") as $desc | .dsr.DS[0].PH[0].DM1 | map(select(has("Ø") | not) | propagate_repeats(.)) | [eval_repeats(.)] | map(select(.[0] != null) | [$desc, (.[0] = (.[0] / 1000 | strftime("%Y-%m-%d")))] | transpose | map({(.[0]): .[1]}) | add)) | add | group_by(.date) | map(add | .hospitalizedInclSuspectedAcute = .["Sum(reddinet_daily_data.ms_covid)"])' dashboard.json > hosp3.json

jq -s '[.[0][]] + [.[1][]] + [.[2][]] + [.[3][]] + [.[4][]] | group_by(.date) | map(reduce .[] as $item ({}; . + $item)) | map({date: .date, newCases: .["Sum(cases_by_day.n)"], cases: .["cases_by_day.Sum of n running total in episode_date"], hospitalized: .hospitalized, hospitalizedInclSuspected: (.hospitalizedInclSuspectedICU + .hospitalizedInclSuspectedAcute)})' cases.json newcases.json hosp.json hosp2.json hosp3.json > dates.json

# Fetch the dashboard's UI, which contains the death toll timestamp
curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/86dc380f-4914-4cff-b2a5-03af9f292bbd/modelsAndExploration?preferReadOnlySession=true' --compressed -H 'X-PowerBI-ResourceKey: 86dc380f-4914-4cff-b2a5-03af9f292bbd' > ui.json

# Isolate the death toll's timestamp
DEATH_DATE=$(jq '.exploration.sections[].visualContainers[].config | match("[Dd]eath data last updated (\\w+ \\d+, \\d+)").captures[0].string | strptime("%B %d, %Y") | strftime("%Y-%m-%d")' ui.json)

# Fetch the death toll from the dashboard
curl 'https://wabi-us-gov-iowa-api.analysis.usgovcloudapi.net/public/reports/querydata' --compressed --data '{"version":"1.0.0","queries":[{"Query":{"Commands":[{"SemanticQueryDataShapeCommand":{"Query":{"Version":2,"From":[{"Name":"d1","Entity":"deaths by race","Type":0}],"Select":[{"Aggregation":{"Expression":{"Column":{"Expression":{"SourceRef":{"Source":"d1"}},"Property":"n"}},"Function":0},"Name":"Sum(deaths by race.n)"}]},"Binding":{"Primary":{"Groupings":[{"Projections":[0]}]},"DataReduction":{"DataVolume":3,"Primary":{"Top":{}}},"Version":1},"ExecutionMetricsKind":1}}]},"CacheKey":"{\"Commands\":[{\"SemanticQueryDataShapeCommand\":{\"Query\":{\"Version\":2,\"From\":[{\"Name\":\"d1\",\"Entity\":\"deaths by race\",\"Type\":0}],\"Select\":[{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"d1\"}},\"Property\":\"n\"}},\"Function\":0},\"Name\":\"Sum(deaths by race.n)\"}]},\"Binding\":{\"Primary\":{\"Groupings\":[{\"Projections\":[0]}]},\"DataReduction\":{\"DataVolume\":3,\"Primary\":{\"Top\":{}}},\"Version\":1},\"ExecutionMetricsKind\":1}}]}","QueryId":"","ApplicationContext":{"DatasetId":"aa4631ab-2f78-40f6-b4c4-d2f5f8a89bcc","Sources":[{"ReportId":"baf74baa-bdc9-4c71-995a-b996f1d0b7e9","VisualId":"a4f624ba349213e53774"}]}}],"cancelQueries":[],"modelId":275725}' > dashboard.json
DEATHS=$(jq '.results[0].result.data.dsr.DS[].PH[].DM0[].M0' dashboard.json)

echo "{\"date\": ${DEATH_DATE}, \"deaths\": ${DEATHS}}" > today.json

# Join cases with hospitalizations and deaths
# Backfill deaths and hospitalizations from Commons
# Update Commons
jq -s --tab 'def eval_repeats(key): foreach .[] as $row (0; ($row[key] // .); . as $x | $row | (.[key] = (.[key] // $x))); .[0] as $commons | ($commons.data | map({date: .[0], deaths: .[3], hospitalized: .[4], hospitalizedInclSuspected: .[5]})) + .[1] + [.[2]] | group_by(.date) | map(map(with_entries(select(.value != null))) | add | [.date, .newCases, .cases, .deaths, .hospitalized, .hospitalizedInclSuspected]) | [eval_repeats(3)] as $data | $commons | .data = $data' commons.json dates.json today.json | expand -t4
