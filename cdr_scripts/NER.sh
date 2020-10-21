echo "THIS SCRIPT  WILL PROCESS VERAZ CDR'S AND WILL CALCULATE ASR, ACD, TOTAL MINUTES USES PER TG."
echo "IT WILL CONSIDER ONLY S AND U STATUS IN CDR'S. OTHER STATUS LIKE E, K, I ETC WILL BE IGNORED."
# Author Suresh Hariramani - 09999500282, suresh.hariramani@wipro.com, shariramani@gmail.com
#=================================================================================================================

# change local directory
##cd /cygdrive/d/cdr
##echo `date +%d"-"%m"-"%Y" "%T` working directory is `pwd`
# Search and Set following parameters in the script as per your setup
#"icdr.5_7_0E.0.1." ----------- Veraz CDR file name format
#hostname="192.168.50.9"  -------- Veraz CDR server IP
#username="root" -----------------Veraz CDR Server FTP username
#password="veraz" ---------------- Veraz CDR Server FTP password
#cd /cdr/ICDR/secondary ---------- Veraz cdr server directory from which you want to pull CDR files

#echo this script started at `date`
#===================================================================================================================

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

# check if output files exists, and has a size greater than zero else create all output files with headers 
# make data folder

	mkdir ./Data 
	##mkdir ./OldData 
	##touch ./Data/LocalFTPlist.csv 

	if [ -s ./Data/ASR-e2e.csv ]; then
		echo `date +%d"-"%m"-"%Y" "%T` New ASR-e2e.csv header file not required
	else 
		nawk 'BEGIN { print "DATE,HOUR,IngressTG,EgressTG,Total-Calls,S-Count,U-Count,E-Count,S-MOU,E-MOU" }' OFS=',' > ./Data/ASR-e2e.csv
		echo `date +%d"-"%m"-"%Y" "%T` ASR-e2e.csv header file created
	fi

	if [ -s ./Data/e2eCauseText.csv ]; then
		echo `date +%d"-"%m"-"%Y" "%T` New e2eCauseText.csv header file not required
	else 
		nawk 'BEGIN { print "DATE,HOUR,IngressTG,EgressTG,Status,Rel_Cause,Ing_Count,Eg_Count" }' OFS=',' > ./Data/e2eCauseText.csv
		echo `date +%d"-"%m"-"%Y" "%T` e2eCauseText.csv header file created
	fi

	
	
	if [ -s ./Data/Daily-e2e.csv ]; then
		echo `date +%d"-"%m"-"%Y" "%T` New Daily-e2e.csv header file not required
	else 
		nawk 'BEGIN { print "DATE,IngressTG,EgressTG,Total-Calls,S-Count,U-Count,E-Count,S-MOU,E-MOU" }' OFS=',' > ./Data/Daily-e2e.csv
		echo `date +%d"-"%m"-"%Y" "%T` Daily-e2e.csv header file created
	fi

	
	if [ -s ./Data/NetPerf.csv ]; then
		echo `date +%d"-"%m"-"%Y" "%T` New NetPerf.csv header file not required
	else 
		nawk 'BEGIN { print "DATE,HOUR,IngressTG,EgressTG,Status,Ingress_Category,Egress_Category,Rel_Direction,Count,MOU" }' OFS=',' > ./Data/NetPerf.csv
		echo `date +%d"-"%m"-"%Y" "%T` NetPerf.csv header file created
	fi
	
	
	
	if [ -s ./Data/NER.csv ]; then
		echo `date +%d"-"%m"-"%Y" "%T` New NER.csv header file not required
	else 
		nawk 'BEGIN { print "DATE,HOUR,IngressTG,EgressTG,Status,Category,Rel_Direction,Count,MOU" }' OFS=',' > ./Data/NER.csv
		echo `date +%d"-"%m"-"%Y" "%T` NER.csv header file created
	fi
	
	
	if [ -s ./Data/NoRtDest.csv ]; then
		echo `date +%d"-"%m"-"%Y" "%T` New NoRtDest.csv header file not required
	else 
		nawk 'BEGIN { print "DATE,HOUR,IngressTG,EgressTG,Ingress_Rel_Cause,Egress_Rel_Cause,Rel_Direction,Called_Number,Count" }' OFS=',' > ./Data/NoRtDest.csv
		echo `date +%d"-"%m"-"%Y" "%T` NoRtDest.csv header file created
	fi
	
	
	
	if [ -s ./Data/Utilization.csv ]; then
		echo `date +%d"-"%m"-"%Y" "%T` New Utilization.csv header file not required
	else 
		nawk 'BEGIN { print "DATE,HOUR,CCP,TG,MGW-ID,Card,Span,Channel,CIC,Count" }' OFS=',' > ./Data/Utilization.csv
		echo `date +%d"-"%m"-"%Y" "%T` Utilization.csv header file created
	fi
	
	
	
	
	
	if [ -s ./OldData/e2eCauseText.csv ]; then
		echo `date +%d"-"%m"-"%Y" "%T` New Olde2eCauseText.csv header file not required
	else 
		nawk 'BEGIN { print "DATE,IngressTG,EgressTG,Status,Rel_Cause,Ing_Count,Eg_Count" }' OFS=',' > ./OldData/e2eCauseText.csv
		echo `date +%d"-"%m"-"%Y" "%T` Old e2eCauseText.csv header file created
	fi

#====================================================================================================================================

# Last Record date and time 
LAST_DATE=`(tail -1 ./Data/ASR-e2e.csv | cut -c1-8)`
LAST_HOUR=`(tail -1 ./Data/ASR-e2e.csv | cut -c10-11)`
echo `date +%d"-"%m"-"%Y" "%T` "last processing on" $LAST_DATE at $LAST_HOUR


# Date of CDR's to be proccesed
CDRDATE="20"`date +%y\%m\%d`
PreCDRDATE="20"`date -d "-1 day" +%y\%m\%d`

# Hour of CDR to be processed ( Current hour - 1 hour) Result should be in 02 digits.
if ((`date +%k` > 10))
then 
CDRHOUR=$((`date +%k` - 1))
else 
CDRHOUR="0"$((`date +%k` - 1))
fi

echo `date +%d"-"%m"-"%Y" "%T` "current Date $CDRDATE Hour $CDRHOUR for processing"

#==================================================================================================================================
# Exit this script if the current date is earlier than last record in e2e ASR file
 ExitDate=`(head -1 ./Data/LocalFTPlist.csv | cut -c17-24)`
 
 if [ -z $ExitDate ] ; then  
    echo `date +%d"-"%m"-"%Y" "%T` "LocalFTPlist not available or it is empty" 
elif (($CDRDATE >= $ExitDate)) ; then
     echo 
else
     echo `date +%d"-"%m"-"%Y" "%T` "Exiting as system date too old. Exitdate $ExitDate"
					# Delete lock file
					rm ${tmpfile}
					echo "======================================================================================================="
					exit
fi
 
 #=========================================================================================================================================
# Delete the data beyond specified days and optimize tables.

# You can change the time when data deletion will happen. In following command input (required time - 1) as deletion time.
if ((10#$CDRHOUR == 02))
	then 

		# You can change the days in following command.
		DEL_DATE="20"`date -d "-37 day" +%y\%m\%d`
		echo `date +%d"-"%m"-"%Y" "%T` Now deleting the data earlier than $DEL_DATE
				echo `date +%d"-"%m"-"%Y" "%T` clearing output tables
					nawk '$1 > "'"$DEL_DATE"'"' ./Data/ASR-e2e.csv > Tmp-ASR-e2e.csv
					#awk '$1 <= "'"$DEL_DATE"'"' ./Data/ASR-e2e.csv | sort >> ./OldData/ASR-e2e.csv
					mv Tmp-ASR-e2e.csv ./Data/ASR-e2e.csv

					nawk '$1 > "'"$DEL_DATE"'"' ./Data/e2eCauseText.csv > Tmp-e2eCauseText.csv
					nawk '$1 <= "'"$DEL_DATE"'"' ./Data/e2eCauseText.csv | sort >> ./OldData/e2eCauseText.csv
					mv Tmp-e2eCauseText.csv ./Data/e2eCauseText.csv
		
					nawk 'substr($1,17,8) > "'"$DEL_DATE"'"' ./Data/LocalFTPlist.csv > Tmp-LocalFTPlist.csv
					mv Tmp-LocalFTPlist.csv ./Data/LocalFTPlist.csv
					
# Set here the number of days for CDR file retention in local folder. Also uncomment related section in last.			
				echo `date +%d"-"%m"-"%Y" "%T` "clearing CDR files"
				DEL_DATE="20"`date -d "-3 day" +%y\%m\%d`
					DEL_DATE="icdr.5_7_0E.0.1."$DEL_DATE"*.*"
					rm $DEL_DATE
					
	# Optimize the Old data table by samurizing the data on daily basis instead of hourly 


	
	
	
sed '1d' ./OldData/e2eCauseText.csv | nawk 'BEGIN {FS=";"} BEGIN { print "DATE,IngressTG,EgressTG,Status,Rel_Cause,Ing_Count,Eg_Count" } {b[$1","$3","$4","$5","$6]=b[$1","$3","$4","$5","$6]+$7;c[$1","$3","$4","$5","$6]=c[$1","$3","$4","$5","$6]+$8}END{for (i in b) print i,b[i],c[i]}' OFS=',' > ./OldData/OptMe2eCauseText.csv
mv ./OldData/OptMe2eCauseText.csv ./OldData/e2eCauseText.csv
					
fi
#=========================================================================================================================================


#===========================================================================================================================


##CDRFILE="icdr.5_7_0E.0.1."`echo $CDRDATE`"*.*"
##PreCDRFILE="icdr.5_7_0E.0.1."`echo $PreCDRDATE`"*.*"
##echo `date +%d"-"%m"-"%Y" "%T` Get Dir listing for CDR files CDRFILE and PreCDRFILE


# FTP and get required Dir filelist
#cd /cdr/ICDR/secondary
##hostname="192.168.50.9"
##username="root"
##password="veraz"
##ftp -in $hostname <<EOF
##quote USER $username
##quote PASS $password
##cd /cdr/ICDR/secondary
##binary
##mls $PreCDRFILE $CDRFILE RemoteFTPlist.csv
##quit
##EOF


# Compare Dir listings and Get unique filenames in RemoteFTPlist.csv (These are files to be imported from CDR server)

# comm command works on sorted files. Remove blank lines and sort both the files 

##echo `date +%d"-"%m"-"%Y" "%T` removing blank lines and sorting the dir listings of CDR files
##sed '/^$/d' RemoteFTPlist.csv | sort > File1
##mv File1 RemoteFTPlist.csv
##sed '/^$/d' ./Data/LocalFTPlist.csv | sort > File2
##mv File2 ./Data/LocalFTPlist.csv

##comm -23 RemoteFTPlist.csv ./Data/LocalFTPlist.csv > DiffFTPlist.csv

##echo `date +%d"-"%m"-"%Y" "%T` made a list of required CDR files. Now starting FTP
# FTP and get New CDR files


# Make a FTP script file. change username password IP address in following command
##awk 'BEGIN { print "ftp -in $hostname <<EOF\n" "quote USER $username\n" "quote PASS $password\n" "binary\n" "cd /cdr/ICDR/secondary"} {print "get "$0 " UP"$0} END {print "quit\n" "EOF"}' DiffFTPlist.csv | sed '1i hostname="192.168.50.9"' | sed '2i username="root"' |  sed '3i password="veraz"' > FTPlist.csv

##./FTPlist.csv 

##sleep 3
##echo `date +%d"-"%m"-"%Y" "%T` "Files received from CDR server for processing "

# made a list of files received from FTP. Latter it will be updated in LocalFilelist.csv in data folder
##ls UPicdr* > DiffFTPlist.csv

##sed '/^$/d' DiffFTPlist.csv | sed -e 's/UP//'| sort > File3
##mv File3 DiffFTPlist.csv

find /data1/CRESTEL/MEDIATION_ROOT/COLLECTION_ROOT/Veraz/archived/2009/11/ -name icdr.5_7_0D.0.1.200911* > filelist
CDRFILE=`cat filelist`

#=============================================================================================================================================
# End to End ASR
echo `date +%d"-"%m"-"%Y" "%T` starting computation `date`
echo $CDRFILE

#Get all required fields End To End TG combinations e2eTG, Status (S,U,I, K etc) , Status count, and seconds with release causes and direction


nawk 'BEGIN {FS=";"} {a[$36","$53",""0"$138"0"$139","substr($35 $5,1,13)","$58","$59","$7]++;b[$36","$53",""0"$138"0"$139","substr($35 $5,1,13)","$58","$59","$7]=b[$36","$53",""0"$138"0"$139","substr($35 $5,1,13)","$58","$59","$7]+$137}END{for (i in a) print i,a[i],b[i]}' OFS=',' $CDRFILE > ReqFields.csv



#Get End To End TG combinations e2eTG, Status (S,U,I, K etc) , Status count, and seconds

#nawk 'BEGIN {FS=";"} {a[$4","$5","$6","$7]=a[$4","$5","$6","$7]+$8;b[$4","$5","$6","$7]=b[$4","$5","$6","$7]+$9}END{for (i in a) print i,a[i],b[i]}' OFS=',' ReqFields.csv > e2eDetails.csv

#echo `date +%d"-"%m"-"%Y" "%T` "End to End cdr's groupby TG and got TG, Status (S,U,I, K etc) , Status count, and minutes" && \


# Seperate the details for Succesfull (S) and Unsuccesfull (U) calls, calculate ACD. This is latter used for making a pivot table and making ASR table in next steps. Pattern #@# inserted to make both TG's appare as single and it is replaced by coma with sed command latter.
#nawk 'BEGIN {FS=";"} ($4 == "U") {print $1"#@#"$2"#@#"$3,$4,$5}' OFS=',' e2eDetails.csv > e2e-U-Details.csv && \
#nawk 'BEGIN {FS=";"} ($4 == "S") {print $1"#@#"$2"#@#"$3,$4,$5,$6}' OFS=',' e2eDetails.csv > e2e-S-Details.csv && \
#nawk 'BEGIN {FS=";"} ($4 == "E") {print $1"#@#"$2"#@#"$3,$4,$5,$6}' OFS=',' e2eDetails.csv > e2e-E-Details.csv && \
#echo `date +%d"-"%m"-"%Y" "%T` "e2e - Seperated the details for Succesfull (S,E) and Unsuccesfull (U) calls, calculate ACD" && \
#
# Now above two tables are merged and ASR is calculated. $0="E-TG I-TG U U-Count Blank S S-Count MOU ACD ". convert sec to min.
# For blank fields ",0" is inserted. (Note - "," is the field seperater.)
#nawk 'BEGIN {FS=";"} NR==1{for(i=1;i<NF;++i)n1=",0"n1} NR==FNR{a1[$1]=substr($0,length($1)+1);t[$1];next} FNR==1{for(i=1;i<NF;++i)n2=",0"n2} {a2[$1]=substr($0,length($1)+1);t[$1];next} END{for(i in t)print i (i in a1 ? a1[i] : n1) (i in a2 ? a2[i] : n2) | "sort"} ' OFS=',' e2e-U-Details.csv e2e-S-Details.csv > e2e-US-Details.csv


#nawk 'BEGIN {FS=";"} NR==1{for(i=1;i<NF;++i)n1=",0"n1} NR==FNR{a1[$1]=substr($0,length($1)+1);t[$1];next} FNR==1{for(i=1;i<NF;++i)n2=",0"n2} {a2[$1]=substr($0,length($1)+1);t[$1];next} END{for(i in t)print i (i in a1 ? a1[i] : n1) (i in a2 ? a2[i] : n2) | "sort"} ' OFS=',' e2e-US-Details.csv e2e-E-Details.csv | nawk 'BEGIN {FS=";"} {print $1,$3+$5,$5,$3,$8,$6/60,$9/60}' OFS=',' | sed -e 's/#@#/,/g' | nawk 'BEGIN {FS=";"} {print substr($1,1,4) substr($1,6,2) substr($1,9,2), substr($1,12,2),$2,$3,$4,$5,$6,$7,$8,$9,$10}' OFS=','> ASR-e2eH.csv && \

#echo `date +%d"-"%m"-"%Y" "%T` "ASR for End to End calculated" && \




#=========================================================================================================================================

# Cause code tables

echo `date +%d"-"%m"-"%Y" "%T` "Geting Cause codes for egress Tg's, status ,Cause Code and Count"   && \

#nawk 'BEGIN {FS=";"} {a[$53","substr($35 $5,1,13)","$58","$59","$7]++}END{for (i in a) print i,a[i]}' OFS=',' $CDRFILE | nawk 'BEGIN {FS=","} print $1, substr($2,1,4) substr($2,6,2) substr($2,9,2), substr($2,12,2),$3,$4,$6,$5 }' OFS=',' > e2eECauseCode.csv


#echo `date +%d"-"%m"-"%Y" "%T` "Geting Cause codes Text details for Egress Tg's. Release_Cause.csv required in same directory" && \
#nawk 'BEGIN {FS=","} NR==FNR {a[$1]=$2;next} a[$1] {$1=a[$1]} {print $2,$3,$4,$5,$7,$1,"0",$6}' OFS=',' ./Data/Release_Cause.csv e2eECauseCode.csv > e2eECauseText.csv && \




#echo `date +%d"-"%m"-"%Y" "%T` "Geting Cause codes for Ingress Tg's, status ,Cause Code and Count"  && \

#nawk 'BEGIN {FS=";"} {a[$36","substr($35 $5,1,13)","$58","$59","$7]++}END{for (i in a) print i,a[i]}' OFS=',' $CDRFILE | nawk 'BEGIN {FS=","} { print $1, substr($2,1,4) substr($2,6,2) substr($2,9,2), substr($2,12,2),$3,$4,$6,$5 }' OFS=',' > e2eICauseCode.csv


#echo `date +%d"-"%m"-"%Y" "%T` "Geting Cause codes Text details for Ingress Tg's. Release_Cause.csv required in same directory" && \







#nawk 'BEGIN {FS=","} NR==FNR {a[$1]=$2;next} a[$1] {$1=a[$1]} {print $2,$3,$4,$5,$7,$1,$6,"0"}' OFS=',' ./Data/Release_Cause.csv e2eICauseCode.csv > e2eICauseText.csv && \



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

nawk 'BEGIN {FS=","}  ($5 == "S") ||  ($5 == "E") {print $1,$2,$3,$4,$5,"Ans-"$6,"Ans-"$7,$8,$9,$10}' OFS=',' NetPerf3.csv > NetPerf4.csv
nawk 'BEGIN {FS=","}  ($5 != "S") && ($5 != "E") {print $0}' OFS=',' NetPerf3.csv  >> NetPerf4.csv

#===========================================================================================================================================

#echo `date +%d"-"%m"-"%Y" "%T` "Spice NER"
#nawk 'BEGIN {FS=";"}  ($5 != "I")  && ($7 == "Ingress-Rel-only") {print $1,$2,$3,$4,$5,$6,$8,$9,$10}' OFS=',' NetPerf3.csv  > NER1.csv
#nawk 'BEGIN {FS=";"}  ($5 != "I")  && ($7 != "Ingress-Rel-only") {print $1,$2,$3,$4,$5,$7,$8,$9,$10}' OFS=',' NetPerf3.csv  >> NER1.csv


#===========================================================================================================================================
# Get No Route / No Destination Numbers

nawk 'BEGIN {FS=";"} ($36 == "3") || ($36 == "2") || ($53 == "3") || ($53 == "2") {a["0"$138"0"$139","substr($35 $5,1,13)","$58","$59","$36","$53","substr($11,1,5)]++}END{for (i in a) print i,a[i]}' OFS=',' $CDRFILE > NoRtDest1.csv


#Replace 1st field Rel Direction by Text and move this field in last. Rearrange fields layout to get Count in last

nawk 'BEGIN {FS=","}  NR==FNR {a[$1]=$2;next} a[$1] {$1=a[$1]} {print substr($2,1,4) "-" substr($2,6,2) "-" substr($2,9,2), substr($2,12,2),$3,$4,$5,$6,$1,$7,$8}' OFS=',' ./Data/Rel_Dir.csv NoRtDest1.csv > NoRtDest2.csv
#===========================================================================================================================================
#echo `date +%d"-"%m"-"%Y" "%T` performing utilization calculation
# Date,Hour,CCP,TG,MGW-ID,Card,Span,Channel,CIC,Count

#nawk 'BEGIN {FS=";"} ($7 != "I") && ($7 != "E") {a[substr($35 $5,1,10)","substr($35 $5,12,2)","$17","$58","$22","$23","$24","$25","$115]++ }END{for (i in a) print i,a[i]}' OFS=',' $CDRFILE  > Utilization1.csv
#nawk 'BEGIN {FS=";"}  ($7 != "I")  && ($7 != "E") {a[substr($35 $5,1,10)","substr($35 $5,12,2)","$37","$59","$42","$43","$44","$45","$116]++ }END{for (i in a) print i,a[i]}' OFS=',' $CDRFILE >> Utilization1.csv


#=========================================================================================================================================
# Delete processed cdr files
rm UPi*

# Uncomment following to Rename Under Procesing Files (UP*) files to normal icdr filename pattern.
#echo " Renaming Processed Files"
#for file in `ls UP*` ; do 
#newname=`echo $file | cut -c3-39` 
#mv $file $newname ; done

#=========================================================================================================================================
# Write Data in output tables

# Write data to hourly table in Data Directory
echo `date +%d"-"%m"-"%Y" "%T` "writing data"
#cat ASR-e2eH.csv >> ./Data/ASR-e2e.csv
#nawk 'BEGIN {FS=";"} {print substr($1,1,4)"-" substr($1,5,2)"-" substr($1,7,8),$3,$4,$5,$6,$7,$8,$9,$10}' OFS=',' ASR-e2eH.csv >> ./Data/Daily-e2e.csv

# Merge Egress and Ingress Cause code tables by write in Data Directory 
cat e2eICauseText.csv >> ./Data/e2eCauseText.csv
cat e2eECauseText.csv >> ./Data/e2eCauseText.csv
# Update file names processed in local file
#cat DiffFTPlist.csv >> ./Data/LocalFTPlist.csv
cat NetPerf4.csv >> ./Data/NetPerf.csv
cat NoRtDest2.csv >> ./Data/NoRtDest.csv
#cat NER1.csv >> ./Data/NER.csv
#cat Utilization1.csv >> ./Data/Utilization.csv
#=========================================================================================================================================
# Optimize the table by groupby on Date+Hour+IngressTG+EgressTg and adding other fields
# If code becomes slow, optimizing can be scheduled in night time. Simply cut this section and paste in "Delete the data beyond specified days and optimize tables." section.


#sed '1d' ./Data/ASR-e2e.csv | nawk 'BEGIN {FS=";"} BEGIN { print "DATE,HOUR,IngressTG,EgressTG,Total-Calls,S-Count,U-Count,E-Count,S-MOU,E-MOU" } {b[$1","$2","$3","$4]=b[$1","$2","$3","$4]+$5;c[$1","$2","$3","$4]=c[$1","$2","$3","$4]+$6;d[$1","$2","$3","$4]=d[$1","$2","$3","$4]+$7;e[$1","$2","$3","$4]=e[$1","$2","$3","$4]+$8;f[$1","$2","$3","$4]=f[$1","$2","$3","$4]+$9;g[$1","$2","$3","$4]=g[$1","$2","$3","$4]+$10}END{for (i in b) print i,b[i],c[i],d[i],e[i],f[i],g[i]}' OFS=',' > OptMe2eDetails.csv
#mv OptMe2eDetails.csv ./Data/ASR-e2e.csv


#sed '1d' ./Data/Daily-e2e.csv | nawk 'BEGIN {FS=";"} BEGIN { print "DATE,IngressTG,EgressTG,Total-Calls,S-Count,U-Count,E-Count,S-MOU,E-MOU" } {b[$1","$2","$3]=b[$1","$2","$3]+$4;c[$1","$2","$3]=c[$1","$2","$3]+$5;d[$1","$2","$3]=d[$1","$2","$3]+$6;e[$1","$2","$3]=e[$1","$2","$3]+$7;f[$1","$2","$3]=f[$1","$2","$3]+$8;g[$1","$2","$3]=g[$1","$2","$3]+$9}END{for (i in b) print i,b[i],c[i],d[i],e[i],f[i],g[i]}' OFS=',' > ./Data/OptMDaily-e2e.csv
#mv ./Data/OptMDaily-e2e.csv ./Data/Daily-e2e.csv



# Optimize the table by groupby on Date+Hour+IngressTG+EgressTg+status+Rel_cause and adding other fields
sed '1d' ./Data/e2eCauseText.csv | nawk 'BEGIN {FS=","} BEGIN { print "DATE,HOUR,IngressTG,EgressTG,Status,Rel_Cause,Ing_Count,Eg_Count" } {a[$1","$2","$3","$4","$5","$6]=a[$1","$2","$3","$4","$5","$6]+$7;b[$1","$2","$3","$4","$5","$6]=b[$1","$2","$3","$4","$5","$6]+$8}END{for (i in a) print i,a[i],b[i]}' OFS=',' > OptMe2eCauseText.csv
mv OptMe2eCauseText.csv ./Data/e2eCauseText.csv

# Optimize NetPerf table by groupby on Date+Hour+IngressTG+EgressTg+status+Rel_cause and adding other fields

sed '1d' ./Data/NetPerf.csv | nawk 'BEGIN {FS=","} BEGIN { print "DATE,HOUR,IngressTG,EgressTG,Status,Ingress_Category,Egress_Category,Rel_Direction,Count,MOU" } {a[$1","$2","$3","$4","$5","$6","$7","$8]=a[$1","$2","$3","$4","$5","$6","$7","$8]+$9;b[$1","$2","$3","$4","$5","$6","$7","$8]=b[$1","$2","$3","$4","$5","$6","$7","$8]+$10}END{for (i in a) print i,a[i],b[i]}' OFS=',' > OptNetPerf.csv
mv OptNetPerf.csv ./Data/NetPerf.csv




#=========================================================================================================

# Write data to shared folder
#cp ./Data/Daily-e2e.csv ./SharedData/Daily-e2e.csv
#cp ./Data/e2eCauseText.csv ./SharedData/e2eCauseText.csv
#cp ./Data/ASR-e2e.csv ./SharedData/ASR-e2e.csv
#cp ./Data/NetPerf.csv ./SharedData/NetPerf.csv
#cp ./Data/NoRtDest.csv ./SharedData/NoRtDest.csv
#cp ./Data/NER.csv ./SharedData/NER.csv
#cp ./Data/Utilization.csv ./SharedData/Utilization.csv
#====================================================================================================================
# Write data for ASR<X% query
#rm ./SharedData/CombinedQuery.csv

#sed '1d' ./SharedData/ASR-e2e.csv |nawk 'BEGIN {FS=";"} BEGIN { print "DATE,HOUR,IngressTG,EgressTG,Status,Rel_Cause,Ing_Count,Eg_Count,Total-Calls,S-Count,U-Count,E-Count,S-MOU,E-MOU,MOU" }{print $1,$2,$3,$4,",T_MOU-ASR-ACD,0,0,"$5,$6,$7,$8,$9,$10}'  OFS="," > ./SharedData/CombinedQuery.csv

#sed '1d' ./SharedData/e2eCauseText.csv |nawk 'BEGIN {FS=";"} {print $0,"0,0,0,0,0,0,"}'  OFS=","  >> ./SharedData/CombinedQuery.csv
#=====================================================================================================================

# Remove temp tables made
echo `date +%d"-"%m"-"%Y" "%T` "Removing temporary tables"
#rm ASR-e2eH.csv DiffFTPlist.csv e2eDetails.csv e2eECauseCode.csv e2eECauseText.csv e2eICauseText.csv e2e-S-Details.csv e2e-U-Details.csv FTPlist.csv RemoteFTPlist.csv e2eICauseCode.csv e2e-US-Details.csv e2e-E-Details.csv NoRt*.csv NetPerf*.csv ReqF*.csv && \
echo `date +%d"-"%m"-"%Y" "%T` this script ended at `date`
echo "Thanks for using ASR script. Suresh Hariramani - 09999500282."
echo ======================================================================================================================
# end of script
rm ${tmpfile}
#=============================================================================================================================================
