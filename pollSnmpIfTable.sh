#!/bin/bash

#This scripts gets iftable data and writes to a csv file.

## date format ##
NOW=$(date +"%F")
 
## Backup path ##
myPath="/tmp/AutoReports"

FILETMG1="$myPath/TMG1-$NOW.csv"
FILETMG2="$myPath/TMG2-$NOW.csv"

if [ -s $FILETMG1 ]; then
		
		snmptable -mALL -v1 -c public -CH -Cf , 192.168.4.124 ifTable > /tmp/tmpfileSnmp
		awk -v date="$(date '+%Y-%m-%d %H:%M:%S')" 'BEGIN {FS=","} (NF>3) { print date","$0 }' /tmp/tmpfileSnmp >> $FILETMG1
	else 
		snmptable -mALL -v1 -c public -Cf , 192.168.4.124 ifTable > /tmp/tmpfileSnmp
		awk '(NR==3){print "TimeStamp," $0}' /tmp/tmpfileSnmp > $FILETMG1
		awk -v date="$(date '+%Y-%m-%d %H:%M:%S')" 'BEGIN {FS=","} (NR>3)&&(NF>3) { print date","$0 }' /tmp/tmpfileSnmp >> $FILETMG1
fi

rm -f  /tmp/tmpfileSnmp



if [ -s $FILETMG2 ]; then
		
		snmptable -mALL -v1 -c public -CH -Cf , 192.168.29.124 ifTable > /tmp/tmpfileSnmp
		awk -v date="$(date '+%Y-%m-%d %H:%M:%S')" 'BEGIN {FS=","} (NF>3) { print date","$0 }' /tmp/tmpfileSnmp >> $FILETMG2
	else 
		snmptable -mALL -v1 -c public -Cf , 192.168.29.124 ifTable > /tmp/tmpfileSnmp
		awk '(NR==3){print "TimeStamp," $0}' /tmp/tmpfileSnmp > $FILETMG2
		awk -v date="$(date '+%Y-%m-%d %H:%M:%S')" 'BEGIN {FS=","} (NR>3)&&(NF>3) { print date","$0 }' /tmp/tmpfileSnmp >> $FILETMG2
fi

rm -f  /tmp/tmpfileSnmp
