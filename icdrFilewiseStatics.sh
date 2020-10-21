#!/bin/bash
#
#     Comments:
#
#       Created by:  Suresh Hariramani
#       Usage: icdrFilewiseStatics.sh
#       
# This script will reconcile the Elitecore Mediated Raw Table Data
# FileName,RowCount,Bytes,ITG_EndDate,ETG_EndDate,ITG,ETG,Status,Count,CeiledSeconds,ExactSeconds
# Get the required Veraz CDR files in a directory and run the script or Run it on Mediation server. Use Excel Pivot table further for analysis.
# Replace awk by nawk for solaris operating system.
# You can type whole script as a single command by adding ; at the end of each command.
#
#======================================================================

cdrPath=/cdr/ICDR/primary/
filename=icdr.5_10_2A.0.1.202010*


find $cdrPath -name $filename > filelist 

#ls icdr* > filelist

	awk 'BEGIN {print "FileName,RowCount,Bytes,ITG_EndDate,ETG_EndDate,ITG,ETG,Status,Count,CeiledDuration,ExactDuration"}' > Filewise_CDR_Statics

	for k in `cat filelist` 
	do echo "$k" "," `wc -l $k|awk '{print $1}'` "," `wc -c $k|awk '{print $1}'` "," >> Filewise_CDR_Statics
	
	awk 'BEGIN {FS=";"} {a[substr($34 $5,1,4) substr($34 $5,6,2) substr($34 $5,9,2)"," substr($51 $5,1,4) substr($51 $5,6,2) substr($51 $5,9,2)","$58","$59","$7]++;b[substr($34 $5,1,4) substr($34 $5,6,2) substr($34 $5,9,2)"," substr($51 $5,1,4) substr($51 $5,6,2) substr($51 $5,9,2)","$58","$59","$7]=b[substr($34 $5,1,4) substr($34 $5,6,2) substr($34 $5,9,2)","substr($51 $5,1,4) substr($51 $5,6,2) substr($51 $5,9,2)","$58","$59","$7]+ int($137+0.9999); c[substr($34 $5,1,4) substr($34 $5,6,2) substr($34 $5,9,2)","substr($51 $5,1,4) substr($51 $5,6,2) substr($51 $5,9,2)","$58","$59","$7]=c[substr($34 $5,1,4) substr($34$5,6,2) substr($34 $5,9,2)","substr($51 $5,1,4) substr($51 $5,6,2) substr($51 $5,9,2)","$58","$59","$7]+$137}END{for (i in a) print "'"$k"'", "," "," i,a[i],b[i],int(c[i])}' OFS=','  $k
	
	done >> Filewise_CDR_Statics
	