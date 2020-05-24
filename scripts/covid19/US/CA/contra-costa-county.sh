#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Contra_Costa_County,_California.tab?action=raw' > commons.json

# Fetch the new cases by day from the dashboard over JSON-RPC
(
    sleep 1; echo '{"delta":true,"handle":-1,"method":"OpenDoc","params":["93b7808b-5a6d-4e9a-9161-ed2eafeb4afc","","","",false],"id":1,"jsonrpc":"2.0"}'
    sleep 1; echo '{"delta":true,"handle":1,"method":"GetObject","params":["qmBLz"],"id":3,"jsonrpc":"2.0"}'
    sleep 1; echo '{"delta":true,"handle":2,"method":"GetLayout","params":[],"id":5,"jsonrpc":"2.0"}'
    sleep 1
) | websocat 'wss://dashboard.cchealth.org/app/93b7808b-5a6d-4e9a-9161-ed2eafeb4afc' | tail -n 1 > dashboard.json
# Convert date from MM/DD to YYYY-MM-DD
jq '.result.qLayout[].value.qHyperCube.qDataPages[].qMatrix | map({date: (.[0].qText | strptime("%m/%d") | strftime("2020-%m-%d")), newCases: .[1].qNum})' dashboard.json > newcases.json

# Fetch the total cases by day from the dashboard over JSON-RPC
(
    sleep 1; echo '{"delta":true,"handle":-1,"method":"OpenDoc","params":["93b7808b-5a6d-4e9a-9161-ed2eafeb4afc","","","",false],"id":1,"jsonrpc":"2.0"}'
    sleep 1; echo '{"delta":true,"handle":1,"method":"GetObject","params":["mSrtwKU"],"id":3,"jsonrpc":"2.0"}'
    sleep 1; echo '{"delta":true,"handle":2,"method":"GetLayout","params":[],"id":5,"jsonrpc":"2.0"}'
    sleep 1
) | websocat 'wss://dashboard.cchealth.org/app/93b7808b-5a6d-4e9a-9161-ed2eafeb4afc' | tail -n 1 > dashboard.json
# Convert date from MM/DD/YYYY to YYYY-MM-DD
jq '.result.qLayout[].value.qHyperCube.qDataPages[].qMatrix | map({date: (.[0].qText | strptime("%m/%d/%Y") | strftime("%Y-%m-%d")), cases: .[1].qNum})' dashboard.json > totalcases.json

# Fetch the total recoveries from the dashboard over JSON-RPC
(
    sleep 1; echo '{"delta":true,"handle":-1,"method":"OpenDoc","params":["93b7808b-5a6d-4e9a-9161-ed2eafeb4afc","","","",false],"id":1,"jsonrpc":"2.0"}'
    sleep 1; echo '{"delta":true,"handle":1,"method":"GetObject","params":["LuVGBZ"],"id":3,"jsonrpc":"2.0"}'
    sleep 1; echo '{"delta":true,"handle":2,"method":"GetLayout","params":[],"id":5,"jsonrpc":"2.0"}'
    sleep 1
) | websocat 'wss://dashboard.cchealth.org/app/93b7808b-5a6d-4e9a-9161-ed2eafeb4afc' | tail -n 1 > dashboard.json
RECOV=$(jq '.result.qLayout[].value.qHyperCube.qDataPages[].qMatrix[][].qNum' dashboard.json)

# Fetch the new deaths by day from the dashboard over JSON-RPC
(
    sleep 1; echo '{"delta":true,"handle":-1,"method":"OpenDoc","params":["93b7808b-5a6d-4e9a-9161-ed2eafeb4afc","","","",false],"id":1,"jsonrpc":"2.0"}'
    sleep 1; echo '{"delta":true,"handle":1,"method":"GetObject","params":["ERYPQRz"],"id":3,"jsonrpc":"2.0"}'
    sleep 1; echo '{"delta":true,"handle":2,"method":"GetLayout","params":[],"id":5,"jsonrpc":"2.0"}'
    sleep 1
) | websocat 'wss://dashboard.cchealth.org/app/93b7808b-5a6d-4e9a-9161-ed2eafeb4afc' | tail -n 1 > dashboard.json
# Calculate a running total
jq '[.result.qLayout[].value.qHyperCube.qDataPages[].qMatrix | map({date: (.[0].qText | strptime("%m/%d") | strftime("2020-%m-%d")), newDeaths: .[1].qNum}) | foreach .[] as $row (0; . + $row.newDeaths; . as $x | $row | (.deaths = $x))]' dashboard.json > deaths.json

# Join the new and total cases and death tolls
# Insert an entry for recoveries on the latest date
# Backfill recoveries from Commons
# Update Commons
JQJOINRECOV=('.[3] as $commons | ($commons.data | INDEX(.[0])) as $oldData | .[:3] | transpose | map(reduce .[] as $item ({}; . + $item)) | .[-1].recoveries =' ${RECOV} '| map([.date, .newCases, .cases, .newDeaths, .deaths, .recoveries // $oldData[.date][5]]) as $newData | $commons | .data = $newData')
jq -s --tab "${JQJOINRECOV[*]}" newcases.json totalcases.json deaths.json commons.json | expand -t4
