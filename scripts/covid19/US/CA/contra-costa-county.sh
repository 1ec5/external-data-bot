#!/bin/bash

# Fetch the current table as JSON
curl 'https://commons.wikimedia.org/wiki/Data:COVID-19_cases_in_Contra_Costa_County,_California.tab?action=raw' > commons.json

# Fetch the new cases by day from the dashboard over JSON-RPC
(
    sleep 2; echo '{"delta":true,"handle":-1,"method":"OpenDoc","params":["b7d7f869-fb91-4950-9262-0b89473ceed6","","","",false],"id":1,"jsonrpc":"2.0"}'
    sleep 2; echo '{"delta":true,"handle":1,"method":"GetObject","params":["cWjnGdK"],"id":3,"jsonrpc":"2.0"}'
    sleep 2; echo '{"delta":true,"handle":2,"method":"GetLayout","params":[],"id":5,"jsonrpc":"2.0"}'
    sleep 4
) | websocat 'wss://dashboard.cchealth.org/app/b7d7f869-fb91-4950-9262-0b89473ceed6' | tail -n 1 > dashboard.json
# Convert date from number of days since 1899-12-30 to YYYY-MM-DD
jq '.result.qLayout[].value.qHyperCube.qDataPages[].qMatrix | map({date: ((.[0].qNum - 2) * 24 * 60 * 60 | gmtime | .[0] -= 70 | strftime("%Y-%m-%d")), newCases: .[1].qNum})' dashboard.json > newcases.json

# Fetch the total cases by day from the dashboard over JSON-RPC
(
    sleep 1; echo '{"delta":true,"handle":-1,"method":"OpenDoc","params":["b7d7f869-fb91-4950-9262-0b89473ceed6","","","",false],"id":1,"jsonrpc":"2.0"}'
    sleep 1; echo '{"delta":true,"handle":1,"method":"GetObject","params":["jWjFxe"],"id":3,"jsonrpc":"2.0"}'
    sleep 1; echo '{"delta":true,"handle":2,"method":"GetLayout","params":[],"id":5,"jsonrpc":"2.0"}'
    sleep 3
) | websocat -B 131071 'wss://dashboard.cchealth.org/app/b7d7f869-fb91-4950-9262-0b89473ceed6' | tail -n 1 > dashboard.json
# Convert date from MM/DD/YYYY to YYYY-MM-DD
jq '.result.qLayout[].value.qHyperCube.qDataPages[].qMatrix | map({date: ((.[0].qNum - 2) * 24 * 60 * 60 | gmtime | .[0] -= 70 | strftime("%Y-%m-%d")), cases: .[1].qNum})' dashboard.json > totalcases.json

# Fetch the total recoveries from the dashboard over JSON-RPC
(
    sleep 2; echo '{"delta":true,"handle":-1,"method":"OpenDoc","params":["b7d7f869-fb91-4950-9262-0b89473ceed6","","","",false],"id":1,"jsonrpc":"2.0"}'
    sleep 2; echo '{"delta":true,"handle":1,"method":"GetObject","params":["LuVGBZ"],"id":3,"jsonrpc":"2.0"}'
    sleep 2; echo '{"delta":true,"handle":2,"method":"GetLayout","params":[],"id":5,"jsonrpc":"2.0"}'
    sleep 4
) | websocat 'wss://dashboard.cchealth.org/app/b7d7f869-fb91-4950-9262-0b89473ceed6' | tail -n 1 > dashboard.json
RECOV=$(jq '.result.qLayout[].value.qHyperCube.qDataPages[].qMatrix[][].qNum' dashboard.json)

# Fetch the new deaths by day from the dashboard over JSON-RPC
(
    sleep 2; echo '{"delta":true,"handle":-1,"method":"OpenDoc","params":["b7d7f869-fb91-4950-9262-0b89473ceed6","","","",false],"id":1,"jsonrpc":"2.0"}'
    sleep 2; echo '{"delta":true,"handle":1,"method":"GetObject","params":["zKvfuW"],"id":3,"jsonrpc":"2.0"}'
    sleep 2; echo '{"delta":true,"handle":2,"method":"GetLayout","params":[],"id":5,"jsonrpc":"2.0"}'
    sleep 4
) | websocat 'wss://dashboard.cchealth.org/app/b7d7f869-fb91-4950-9262-0b89473ceed6' | tail -n 1 > dashboard.json
# Calculate a running total
jq '[.result.qLayout[].value.qHyperCube.qDataPages[].qMatrix | map({date: ((.[0].qNum - 2) * 24 * 60 * 60 | gmtime | .[0] -= 70 | strftime("%Y-%m-%d")), newDeaths: (.[1].qNum + .[2].qNum)}) | foreach .[] as $row (0; . + $row.newDeaths; . as $x | $row | (.deaths = $x))]' dashboard.json > deaths.json

# Join the new and total cases and death tolls
# Insert an entry for recoveries on the latest date
# Backfill recoveries from Commons
# Update Commons
JQJOINRECOV=('.[3] as $commons | ($commons.data | INDEX(.[0])) as $oldData | .[:3] | transpose | map(reduce .[] as $item ({}; . + $item)) | .[-1].recoveries =' ${RECOV} '| map([.date, .newCases, .cases, .newDeaths, .deaths, .recoveries // $oldData[.date][5]]) as $newData | $commons | .data = $newData')
jq -s --tab "${JQJOINRECOV[*]}" newcases.json totalcases.json deaths.json commons.json | expand -t4
