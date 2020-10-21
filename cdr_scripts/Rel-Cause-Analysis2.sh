echo "THIS SCRIPT  WILL PROCESS VERAZ CDR'S AND WILL CALCULATE Release Causes statics."

# Author Suresh Hariramani - 09999500282, suresh.hariramani@wipro.com, shariramani@gmail.com
#=================================================================================================================

# Lock the cron job from overlapping

# our tmpfile
tmpfile="mytmpfile"

# check to see if it exists.
# if it does then exit script
if [[ -f ${tmpfile} ]]; then
echo `date +%d"-"%m"-"%Y" "%T` "Exiting as script already running. Manualy delete the tmpfile in local folder if you are sure that it is not running already."
echo "============================================================================================================="
exit
fi

# it doesn't exist at this point so lets make one 
touch ${tmpfile}
#====================================================================================================================



find /ata1/CRESTEL/MEDIATION_ROOT/COLLECTION_ROOT/Veraz/archived/ -name icdr.5_7_0E.0.1.2010011[6-9]* > filelist
find /data1/CRESTEL/MEDIATION_ROOT/COLLECTION_ROOT/Veraz/archived/ -name icdr.5_7_0E.0.1.2010012[0-9]* >> filelist
find /data1/CRESTEL/MEDIATION_ROOT/COLLECTION_ROOT/Veraz/archived/ -name icdr.5_7_0E.0.1.2010013[0-1]* >> filelist


#====================================================================================================================================

# check if output files exists, and has a size greater than zero else create all output files with headers 
# make data folder

	mkdir ./Data 
		
	if [ -s ./Data/NetPerf.csv ]; then
		echo `date +%d"-"%m"-"%Y" "%T` New NetPerf.csv header file not required
	else 
		nawk 'BEGIN { print "DATE,HOUR,IngressTG,EgressTG,Status,Ingress_Category,Egress_Category,Rel_Direction,Count,MOU" }' OFS=',' > ./Data/NetPerf.csv
		echo `date +%d"-"%m"-"%Y" "%T` NetPerf.csv header file created
	fi
	
	
	if [ -s ./Data/OptNetPerfDaily.csv ]; then
		echo `date +%d"-"%m"-"%Y" "%T` OptNetPerfDaily.csv header file not required
	else 
		nawk 'BEGIN { print "DATE,IngressTG,EgressTG,Status,Ingress_Category,Egress_Category,Rel_Direction,Count,MOU" }' OFS=',' > ./Data/OptNetPerfDaily.csv
		echo `date +%d"-"%m"-"%Y" "%T` OptNetPerfDaily.csv header file created
	fi
	
	
	
##	if [ -s ./Data/NoRtDest.csv ]; then
##		echo `date +%d"-"%m"-"%Y" "%T` New NoRtDest.csv header file not required
##	else 
##	nawk 'BEGIN { print "DATE,HOUR,IngressTG,EgressTG,Ingress_Rel_Cause,Egress_Rel_Cause,Rel_Direction,Called_Prefix,Count" }' OFS=',' > ./Data/NoRtDest.csv
##		echo `date +%d"-"%m"-"%Y" "%T` NoRtDest.csv header file created
##	fi
	
	
	
	



#=============================================================================================================================================
# End to End ASR
echo `date +%d"-"%m"-"%Y" "%T` starting computation `date`
rm ./Data/NetPerf.csv ./Data/NetPerfDaily.csv ./Data/NoRtDest.csv
#echo $CDRFILE

for k in `cat filelist` 

#Get all required fields End To End TG combinations e2eTG, Status (S,U,I, K etc) , Status count, and seconds with release causes and direction

do echo $k

nawk 'BEGIN {FS=";"} {a[$36","$53",""0"$138"0"$139","substr($35 $5,1,13)","$58","$59","$7]++;b[$36","$53",""0"$138"0"$139","substr($35 $5,1,13)","$58","$59","$7]=b[$36","$53",""0"$138"0"$139","substr($35 $5,1,13)","$58","$59","$7]+$137}END{for (i in a) print i,a[i],b[i]}' OFS=',' $k > ReqFields.csv



#=========================================================================================================================================

#Network performance
#To change CV names, Categaries etc check Data folder, (Filter I, E status records in Pivot table as these are duplicated records)

echo `date +%d"-"%m"-"%Y" "%T` "Calculating Network performance"   && \


#Replace 1st field IngressCV by CV_Categary and move this field in last
nawk 'BEGIN {FS=","} NR==FNR {a[$1]=$2;next} a[$1] {$1=a[$1]} {print $2,$3,$4,$5,$6,$7,$8,$9,$1}' OFS=',' ./Data/CV_Category.csv ReqFields.csv > NetPerf1.csv 


#Replace 1st field EgressCV by CV_Categary and move this field in last

nawk 'BEGIN {FS=","} NR==FNR {a[$1]=$2;next} a[$1] {$1=a[$1]} {print $2,$3,$4,$5,$6,$7,$8,$9,$1}' OFS=',' ./Data/CV_Category.csv NetPerf1.csv > NetPerf2.csv


#Replace 1st field Rel Direction by Text and move this field in last. Convert Sec to Min. Rearrange fields layout to get Count and MOU in last

nawk 'BEGIN {FS=","}  NR==FNR {a[$1]=$2;next} a[$1] {$1=a[$1]} {print substr($2,1,4) "-" substr($2,6,2) "-" substr($2,9,2), substr($2,12,2),$3,$4,$5,$8,$9,$1,$6,$7/60}' OFS=',' ./Data/Rel_Dir.csv NetPerf2.csv > NetPerf3.csv


#Above NetPerf table have CallComplete Field. We need to take out answered and completed calls seperately. "U" calls with CV-16,31 are also succesful calls. 

##nawk 'BEGIN {FS=","}  ($5 == "S") ||  ($5 == "E") {print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10}' OFS=',' NetPerf3.csv > NetPerf4.csv
nawk 'BEGIN {FS=","}  ($5 != "S") && ($5 != "E") {print $0}' OFS=',' NetPerf3.csv  > NetPerf4.csv

#===========================================================================================================================================

# Get No Route / No Destination Number Prefixes (5 Digits)

##nawk 'BEGIN {FS=";"} ($36 == "3") || ($36 == "2") || ($53 == "3") || ($53 == "2") {a["0"$138"0"$139","substr($35 $5,1,13)","$58","$59","$36","$53","substr($11,1,5)]++}END{for (i in a) print i,a[i]}' OFS=',' $k > NoRtDest1.csv


#Replace 1st field Rel Direction by Text and move this field in last. Rearrange fields layout to get Count in last

##nawk 'BEGIN {FS=","}  NR==FNR {a[$1]=$2;next} a[$1] {$1=a[$1]} {print substr($2,1,4) "-" substr($2,6,2) "-" substr($2,9,2), substr($2,12,2),$3,$4,$5,$6,$1,$7,$8}' OFS=',' ./Data/Rel_Dir.csv NoRtDest1.csv > NoRtDest2.csv
#===========================================================================================================================================
# Write Data in output tables

# Write data to hourly table in Data Directory
echo `date +%d"-"%m"-"%Y" "%T` "writing data"


cat NetPerf4.csv >> ./Data/NetPerf.csv
##cat NoRtDest2.csv >> ./Data/NoRtDest.csv
done
#=========================================================================================================================================

# Optimize NetPerf table by groupby on Date+Hour+IngressTG+EgressTg+status+Rel_cause and adding other fields

sed '1d' ./Data/NetPerf.csv | nawk 'BEGIN {FS=","} BEGIN { print "DATE,HOUR,IngressTG,EgressTG,Status,Ingress_Category,Egress_Category,Rel_Direction,Count,MOU" } {a[$1","$2","$3","$4","$5","$6","$7","$8]=a[$1","$2","$3","$4","$5","$6","$7","$8]+$9;b[$1","$2","$3","$4","$5","$6","$7","$8]=b[$1","$2","$3","$4","$5","$6","$7","$8]+$10}END{for (i in a) print i,a[i],b[i]}' OFS=',' > OptNetPerf.csv
mv OptNetPerf.csv ./Data/NetPerf.csv

# Optimize NetPerf table by groupby on Date+IngressTG+EgressTg+status+Rel_cause and adding other fields

sed '1d' ./Data/NetPerf.csv | nawk 'BEGIN {FS=","} BEGIN { print "DATE,IngressTG,EgressTG,Status,Ingress_Category,Egress_Category,Count" } {a[$1","$3","$4","$5","$6","$7]=a[$1","$3","$4","$5","$6","$7]+$9}END{for (i in a) print i,a[i]}' OFS=',' > OptNetPerfDaily.csv
mv OptNetPerfDaily.csv ./Data/NetPerfDaily.csv


#=========================================================================================================

# Remove temp tables made
echo `date +%d"-"%m"-"%Y" "%T` "Removing temporary tables"
rm NetPerf*.csv ReqFields.csv && \
echo `date +%d"-"%m"-"%Y" "%T` this script ended at `date`
echo "Thanks for using Release Cause script. Suresh Hariramani - 09999500282."
echo ======================================================================================================================
# end of script
rm ${tmpfile}
#=============================================================================================================================================
