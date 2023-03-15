#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Contra_Costa_County,_California.tab?action=raw' > commons.json

# Fetch tables and keys from the dashboard over JSON-RPC
# https://qlik.dev/apis/json-rpc/qix/doc#%23%2Fentries%2FDoc%2Fentries%2FGetTablesAndKeys
#(
#    sleep 2; echo '{"delta":true,"handle":-1,"method":"OpenDoc","params":["b7d7f869-fb91-4950-9262-0b89473ceed6","","","",false],"id":1,"jsonrpc":"2.0"}'
#    sleep 2; echo '{"jsonrpc":"2.0","id":6,"handle":1,"method":"GetTablesAndKeys","params":{"qWindowSize":{"qcx":1,"qcy":1},"qNullSize":{"qcx":1,"qcy":1},"qCellHeight":1,"qSyntheticMode":true,"qIncludeSysVars":false,"qIncludeProfiling":false}}'
#    sleep 4
#) | websocat -B 1000000 'wss://dashboard.cchealth.org/app/b7d7f869-fb91-4950-9262-0b89473ceed6' | tail -n 1 > tables.json
#jq '.result.qtr | map({name: .qName, fields: .qFields | map(.qName)})' tables.json

# Fetch time series data from the dashboard over JSON-RPC
# https://qlik.dev/apis/json-rpc/qix/doc#%23%2Fentries%2FDoc%2Fentries%2FGetTableData
(
    sleep 2; echo '{"delta":true,"handle":-1,"method":"OpenDoc","params":["b7d7f869-fb91-4950-9262-0b89473ceed6","","","",false],"id":1,"jsonrpc":"2.0"}'
    sleep 2; echo '{"jsonrpc":"2.0","id":6,"handle":1,"method":"GetTableData","params":{"qOffset":0,"qRows":2000,"qSyntheticMode":true,"qTableName":"NUMBERS_BY_DATE"}}'
    sleep 4
) | websocat -B 4000000 'wss://dashboard.cchealth.org/app/b7d7f869-fb91-4950-9262-0b89473ceed6' | tail -n 1 > dashboard.json
# Convert date from number of days since 1899-12-30 to YYYY-MM-DD
# Calculate running total of deaths
jq 'def total(key): foreach .[] as $row (0; . + $row[key]; . as $x | $row | (.["total:" + key] = $x)); def eval_repeats(key): foreach .[] as $row (0; (if $row[key] == 0 then . else $row[key] end); . as $x | $row | (.[key] = (if .[key] == 0 then $x else .[key] end))); .result.qData | map(.qValue | {date: ((.[0].qNumber - 2) * 24 * 60 * 60 | gmtime | .[0] -= 70 | strftime("%Y-%m-%d")), newCases: .[20].qNumber, cases: .[23].qNumber, newDeaths: .[4].qNumber, deaths: .[5].qNumber, recoveries: .[13].qNumber, hospitalized: .[6].qNumber}) | sort_by(.date) | [eval_repeats("deaths")]' dashboard.json > casesbyday.json

# Update Commons
jq -s --tab '.[1].data = (.[0] | map([.date, .newCases, .cases, .newDeaths, .deaths, .recoveries, .hospitalized])) | .[1]' casesbyday.json commons.json | expand -t4
