#!/bin/bash
#
#     Comments:
#
#       Created by:  Suresh Hariramani
#       Date:  April, 2020
#       Usage: backupUsingFTP.sh <IgateIP>
#       Example: backupUsingFTP.sh 192.168.10.150
#       This script uses wget to ftp a folder recursively. Sends trap if backup fails and generates a message in syslog on backup success.
#======================================================================
#Version:  1.0
#=====================================
#History:
#
#=====================================

#-----------------------------------
#       Define Variables
#-----------------------------------

Trap_Manager1=192.170.3.34:1164
Trap_Manager2=192.170.3.35:1164
Trap_Manager3=192.170.4.34:1164
Trap_Manager4=192.170.4.35:1164

server=$1

#-----------------------------------
#       Define functions.
#-----------------------------------
SendBackupFailTrap() {
#Usage: SendBackupFailTrap $Trap_Manager1

SourceIP=`ip route get 1.0.0.0 | awk '{print $NF;exit}'`
echo $SourceIP

echo "Sending trap now to $1"

snmptrap -v 2c -c public "$1" '' \
SNMPv2-SMI::enterprises.4629.3.1.3 \
SNMPv2-SMI::enterprises.4629.3.1.4.15 s "ELEM_TYPE=IGate;IP=$server" \
SNMPv2-SMI::enterprises.4629.3.1.4.14 s "EMS_APPL_ID=5;EMS_APPL_ERR_CODE=0;" \
SNMPv2-SMI::enterprises.4629.3.1.4.13 s "N" \
SNMPv2-SMI::enterprises.4629.3.1.4.12 s "$server" \
SNMPv2-SMI::enterprises.4629.3.1.4.11 s "NAME=IGate;APPL=Backup;" \
SNMPv2-SMI::enterprises.4629.3.1.4.10 s "BACKUP_TOOLS" \
SNMPv2-SMI::enterprises.4629.3.1.4.9 s $SourceIP \
SNMPv2-SMI::enterprises.4629.3.1.4.8 s "NAME=`hostname`;APPL=Igate Backup Script" \
SNMPv2-SMI::enterprises.4629.3.1.4.7 s "EMS" \
SNMPv2-SMI::enterprises.4629.3.1.4.6 s "Error in backup of Igate" \
SNMPv2-SMI::enterprises.4629.3.1.4.5 s "Major" \
SNMPv2-SMI::enterprises.4629.3.1.4.4 s "Igate BACKUP_FAILED" \
SNMPv2-SMI::enterprises.4629.3.1.4.3 s "`date "+%m-%d-%Y+%H:%M:%S"`" \
SNMPv2-SMI::enterprises.4629.3.1.4.2 i "1304"
#SNMPv2-SMI::enterprises.4629.3.1.4.1 s "654321"
}


## Backup and log paths ##
backupPath="/tmp/TMGbackup"
tmpFTPLOG=$backupPath/tmpftpLogFile.txt
FTPLOG=$backupPath/ftpLogFile.txt

## create backupPath directory if doesn't exist already ##
mkdir -p $backupPath;

## date format ##
NOW=$(date +"%y%m%d%H%M%S")

## Folder Name where backup will be saved ##
backupDir="$backupPath/TMG-$server-$NOW"

if [ -z $server ]; then
        echo "Usage: `basename $0` [IgateIP]"
        exit 1
fi

## Remove tmp log file if exists already ##
        rm -f  $tmpFTPLOG

## Check reachability##
ping -c1 -W1 -q $server &>/dev/null
status=`echo $?`

sleep 5

if [[ $status == 0 ]] ; then
        echo `date "+%Y-%m-%d %H:%M:%S"` "$server is reachable!" | tee -a $FTPLOG;

        ## Get backup now##
        wget -t 2 -r -nv -o $tmpFTPLOG  -P $backupDir --user="your_username" --password="your_password" ftp://$server/CFG/;type=i
else
        echo `date "+%Y-%m-%d %H:%M:%S"` "$server not reachable!" | tee -a $FTPLOG;
        echo `date "+%Y-%m-%d %H:%M:%S"` "$server Backup Failed" | tee -a $FTPLOG;
                SendBackupFailTrap $Trap_Manager1
                SendBackupFailTrap $Trap_Manager2
                SendBackupFailTrap $Trap_Manager3
                SendBackupFailTrap $Trap_Manager4
        exit 1
fi

if (grep "^FINISHED" $tmpFTPLOG ); then
                cat $tmpFTPLOG >> $FTPLOG;
        echo `date "+%Y-%m-%d %H:%M:%S"` "$server Backup Success" | tee -a $FTPLOG;
                logger -p user.err -t dbbkp_success "Backup of IGate TMG IP=$server completed successfully"
        exit 0
else
        echo `date "+%Y-%m-%d %H:%M:%S"` "$server Backup Failed" | tee -a $FTPLOG;
                SendBackupFailTrap $Trap_Manager1
                SendBackupFailTrap $Trap_Manager2
                SendBackupFailTrap $Trap_Manager3
                SendBackupFailTrap $Trap_Manager4
        exit 1
fi
