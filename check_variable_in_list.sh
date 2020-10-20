#!/bin/bash
echo "This script checks if a variable exists in a list"
datesOfCSbkp="1,7,14,9,20,21,2028,30"
datePart=`date +%d`
IFS=","

contains() {
if [[ ${datesOfCSbkp[*]} =~ (^|[[:space:]])$datePart($|[[:space:]]) ]] ; then
# yes, list include item
    result=0
else
    result=1
fi
  return $result
}

echo "Check: Does $datePart is in $datesOfCSbkp ?"

contains $datesOfCSbkp $datePart && echo "yes" || echo "no"