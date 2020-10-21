echo "THIS SCRIPT  WILL PROCESS VERAZ CDR'S AND WILL GIVE EARLY EVENTS statics."

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



find /data1/CRESTEL/MEDIATION_ROOT/COLLECTION_ROOT/Veraz/archived/ -name icdr.5_7_0E.0.1.2010040[1-9]* > filelist
find /data1/CRESTEL/MEDIATION_ROOT/COLLECTION_ROOT/Veraz/archived/ -name icdr.5_7_0E.0.1.2010041[0-9]* >> filelist
find /data1/CRESTEL/MEDIATION_ROOT/COLLECTION_ROOT/Veraz/archived/ -name icdr.5_7_0E.0.1.2010042[0-9]* >> filelist
find /data1/CRESTEL/MEDIATION_ROOT/COLLECTION_ROOT/Veraz/archived/ -name icdr.5_7_0E.0.1.2010043[0-1]* >> filelist


#====================================================================================================================================

# check if output files exists, and has a size greater than zero else create all output files with headers 
# make data folder

	mkdir ./Data 
		
	if [ -s ./Data/ReqFields.csv ]; then
		echo `date +%d"-"%m"-"%Y" "%T` New header file not required
	else 
		nawk 'BEGIN { print "GCID,IngressReleaseCompleteTimeStamp,LastReceivedUpdateTimeStamp,Status,A-Party,B-Party,Ingress R-Cause,EgressR-Cause,IngressTG,EgressTG,EarlyEvent,Duration" }' OFS=',' > ./Data/ReqFields.csv
		echo `date +%d"-"%m"-"%Y" "%T` header file created
	fi
	
#=============================================================================================================================================
# End to End ASR
echo `date +%d"-"%m"-"%Y" "%T` starting computation `date`
#echo $CDRFILE

for k in `cat filelist` 

#Get all required fields End To End TG combinations e2eTG, Status (S,U,I, K etc) , Status count, and seconds with release causes and direction

do echo $k

nawk 'BEGIN {FS=";"} (($59 == "DLGIVS") || ($59 == "D2GIVS")) && (($7 == "S") || ($7 == "E")) && (($11 ~ /^7654/) || ($11 ~ /^8873/) || ($11 ~ /^9507/) || ($11 ~ /^9525/) || ($11 ~ /^9576/) || ($11 ~ /^9708/)) {print $4","$35","$5","$7","$9","$11","$36","$53","$58","$59","$132","$137}' OFS=',' $k > TempReqFields.csv


#===========================================================================================================================================
# Write Data in output tables

# Write data to hourly table in Data Directory
echo `date +%d"-"%m"-"%Y" "%T` "writing data"


cat TempReqFields.csv >> ./Data/ReqFields.csv
done
#================================================================================================================

# Remove temp tables made
echo `date +%d"-"%m"-"%Y" "%T` "Removing temporary tables"
rm TempReqFields.csv && \
echo `date +%d"-"%m"-"%Y" "%T` this script ended at `date`
echo "Thanks for using early events script. Suresh Hariramani - 09999500282."
echo ======================================================================================================================
# end of script
rm ${tmpfile}
#=============================================================================================================================================
