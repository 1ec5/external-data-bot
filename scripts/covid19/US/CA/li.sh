#!/bin/bash

curl 'https://liproduction-reportsbucket-bhk8fnhv1s76.s3-us-west-1.amazonaws.com/v1/latest/timeseries-byLocation.json' > li.json

# https://w.wiki/ZBB
curl 'https://query.wikidata.org/sparql?query=SELECT%20%3Ffips%20%3Fqid%20%3Fcases%20%3Frecovered%20%3Fdeaths%20WHERE%20%7B%0A%20%20%3Fqid%20wdt%3AP361%2B%20wd%3AQ87455852%3B%0A%20%20%20%20%20%20%20wdt%3AP276%2Fwdt%3AP3403%3F%20%3Fcounty.%0A%20%20%3Fcounty%20wdt%3AP31%20wd%3AQ13212489%3B%0A%20%20%20%20%20%20%20%20%20%20wdt%3AP882%20%3Ffips.%0A%20%20OPTIONAL%20%7B%0A%20%20%20%20%3Fqid%20p%3AP1603%20%5B%0A%20%20%20%20%20%20ps%3AP1603%20%3Fcases%3B%0A%20%20%20%20%20%20prov%3AwasDerivedFrom%20%5Bpr%3AP248%20wd%3AQ96777164%5D%0A%20%20%20%20%5D.%0A%20%20%7D%0A%20%20OPTIONAL%20%7B%0A%20%20%20%20%3Fqid%20p%3AP8010%20%5B%0A%20%20%20%20%20%20ps%3AP8010%20%3Frecovered%3B%0A%20%20%20%20%20%20prov%3AwasDerivedFrom%20%5Bpr%3AP248%20wd%3AQ96777164%5D%0A%20%20%20%20%5D.%0A%20%20%7D%0A%20%20OPTIONAL%20%7B%0A%20%20%20%20%3Fqid%20p%3AP1120%20%5B%0A%20%20%20%20%20%20ps%3AP1120%20%3Fdeaths%3B%0A%20%20%20%20%20%20prov%3AwasDerivedFrom%20%5Bpr%3AP248%20wd%3AQ96777164%5D%0A%20%20%20%20%5D.%0A%20%20%7D%0A%20%20SERVICE%20wikibase%3Alabel%20%7B%0A%20%20%20%20bd%3AserviceParam%20wikibase%3Alanguage%20%22vi%2Cen%22.%0A%20%20%7D%0A%7D%0AORDER%20BY%20%3Ffips&format=json' | jq '.results.bindings | map(map_values(.value) | .qid = .qid[31:])' > wikidata.json

echo 'qid,-P1603,-P8010,-P1120'
jq -r 'map(select(.cases // .deaths // .recovered) | [.qid, ((.cases)? | tonumber) // null, ((.recovered)? | tonumber) // null, ((.deaths)? | tonumber) // null])[] | @csv' wikidata.json

echo

echo 'qid,P1603,qal585,S248,P8010,qal585,S248,P1120,qal585,S248'
jq -sr '(.[0] | map({qid: .qid, fips: .fips})) + (.[1] | map(select(.stateID == "iso2:US-CA" and .level == "county") | .countyID[5:] as $fips | (.dates | keys | max) as $date | .dates | add | .fips = $fips | .date = ($date | "+\(.)T00:00:00Z/11"))) | group_by(.fips) | map(add | select(.cases // .deaths // .recovered) | [.qid, .cases // null, .date, "Q96777164", .recovered // null, .date, "Q96777164", .deaths // null, .date, "Q96777164"])[] | @csv' wikidata.json li.json
