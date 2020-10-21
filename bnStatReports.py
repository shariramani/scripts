#!/usr/bin/env python
#
#     Comments:
#
#       Created by:  Suresh Hariramani
#       Date:  Aug, 2020
#       Usage: ./bnStatReports.py
#
# Script will generate bordernet csv reports. Report will have last one hour data at five minute granularity.
# For example if you run script at 10:15AM, report will be generated for period 09:00:00 to 09:59:59
# PeerStatsSummary
# PeerStatsIncoming
# PeerStatsOutgoing
# SystemStatsSummary
#
#Script has option to scp reports to remote destination.
#Script will fail on fresh BN untill you config peers and make few calls.
#======================================================================
#Version:  1.0	
#Version:  1.1 csv file rename as /tmp/AutoReports/ARH_Dialogic_BN_Mumbai_vsbc45_PeerStatsSummary_082520-1856.csv
#=====================================
#History:
#
#=====================================
import sys
import sqlite3
import csv
import datetime
from datetime import datetime, timedelta
import time
import os
import logging, logging.handlers
import subprocess
from subprocess import Popen, PIPE, STDOUT

# Base path to store reports# Please don't give "/" in last
## [[[   WARNING   ]]] Pay Attention, if you set already existing directory, then existing files will be deleted after set number of days.
base_path = "/tmp/AutoReports"

daysToSave=5

LOG_FILENAME = base_path + '/PeerStats.log'

#Time String to suffix filename
timestr = time.strftime("%m%d%y-%H%M")

#String to prefix filename
myhost = os.uname()[1]
PeerStatsSummaryFile=base_path + "/ARH_Dialogic_BN_Mumbai_"  + myhost + "_PeerStatsSummary_" + timestr + ".csv"
PeerStatsIncomingFile=base_path + "/ARH_Dialogic_BN_Mumbai_"  + myhost + "_PeerStatsIncoming_" + timestr + ".csv"
PeerStatsOutgoingFile=base_path + "/ARH_Dialogic_BN_Mumbai_"  + myhost + "_PeerStatsOutgoing_" + timestr + ".csv"
SystemStatsSummaryFile=base_path + "/ARH_Dialogic_BN_Mumbai_" + myhost + "_SystemStatsSummary_" + timestr + ".csv"

#Do you want to copy reports to other server? I will use scp.
# you need to setup and passwordless SSH to destination beforehand.
# This script will not create destination folders/subfolders. All folders/subfolders must pre-exist.
useSCP = "Y"
remoteDestination = "root@10.108.60.112:/tmp/AutoReports/"


## Action Starts from here

# Create directory if doesn't exist already
if not os.path.exists(base_path):
    os.makedirs(base_path)



# Set up a specific logger with our desired output level
my_logger = logging.getLogger('PeerStats')
my_logger.setLevel(logging.DEBUG)

# Add the log message handler to the logger.Limit the size to 1000000Bytes ~ 1MB. Set number of log files
handler = logging.handlers.RotatingFileHandler(LOG_FILENAME, maxBytes=1000000, backupCount=5)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s','%d-%b-%y %H:%M:%S')

my_logger.addHandler(handler)
handler.setFormatter(formatter)

## Lets log and print messages on console as well ##
# define a Handler which writes INFO messages or higher to the sys.stderr
console = logging.StreamHandler()
console.setLevel(logging.INFO)
# set a format which is simpler for console use
formatter = logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')
# tell the handler to use this format
console.setFormatter(formatter)
# add the handler to the root logger
logging.getLogger().addHandler(console)

#Function to log output of subprocess
def log_subprocess_output(pipe):
    for line in iter(pipe.readline, b''): # b'\n'-separated lines
        my_logger.debug('got line from subprocess: %r', line)

## -----##

my_logger.info('Script started to generate bordernet traffic Stat reports')


# Query to be executed
query_PeerStatsSummary = """SELECT Start_time, End_time, Peer_Name, Peer_Id, (Sessions_Attempts_Incoming + Sessions_Attempts_Outgoing) as Sessions_Attempts, (Sessions_Answered_Incoming + Sessions_Answered_Outgoing) as Sessions_Answered, Sessions_With_Media, round(((Sessions_Answered_Incoming + Sessions_Answered_Outgoing)*1.00/( Sessions_Attempts_Incoming + Sessions_Attempts_Outgoing)*1.00) * 100.00, 2) as Sessions_ASR, (Sessions_Emergency_Incoming + Sessions_Emergency_Outgoing) as Total_SessionsEmergency, (Sessions_SipI_Incoming + Sessions_SipI_Outgoing) as Total_SipICalls, Sessions_Active_Transcoding as Total_SessionsActiveTranscoding,round((Total_Call_Duration*1.00 / Total_Completed_Calls*1.00), 2) as Sessions_ACD FROM peer_security_report WHERE datetime(Start_time) >= ? AND datetime(Start_time) < ? ORDER BY datetime(start_time) DESC, Peer_Name"""


query_PeerStatsIncoming = """SELECT Start_time, End_time, Peer_Name, Peer_Id, Sessions_Attempts_Incoming, Sessions_Answered_Incoming, Sessions_Incoming_Average_Rate, Sessions_Incoming_Peak_Rate, Sessions_Incoming_Highest_Active_Sessions, Sessions_Rejected_Incoming_RE, Sessions_Rejected_Incoming_MAS, Sessions_Rejected_Incoming_MAOS, Sessions_Rejected_Incoming_Overload, Sessions_Emergency_Incoming, Sessions_Rejected_Incoming_BWL, round(Allocated_BW/1000.00, 2) as allocated_BW, Relative_Allocated_BW FROM peer_security_report  WHERE datetime(Start_time) >= ? AND datetime(Start_time) < ? ORDER BY datetime(start_time) DESC, Peer_Name"""

query_PeerStatsOutgoing = """SELECT Start_time, End_time, Peer_Name, Peer_Id, Sessions_Attempts_Outgoing, Sessions_Answered_Outgoing, Sessions_Outgoing_Average_Rate, Sessions_Outgoing_Peak_Rate, Sessions_Outgoing_Highest_Active_Sessions, Sessions_Rejected_Outgoing_RE, Sessions_Rejected_Outgoing_MAS, Sessions_Rejected_Outgoing_MAOS, Sessions_Rejected_Outgoing_Overload, Sessions_Emergency_Outgoing, Sessions_Rejected_Outgoing_BWL, round(Allocated_BW/1000.00, 2) as allocated_BW, Relative_Allocated_BW FROM peer_security_report  WHERE datetime(Start_time) >= ? AND datetime(Start_time) < ? ORDER BY datetime(start_time) DESC, Peer_Name"""

query_SystemStatsSummary = """SELECT Start_time,End_time,Sessions_Attempts_Incoming,Sessions_Attempts_Outgoing,Sessions_Answered_Incoming,Sessions_Incoming_Peak_Rate,Sessions_Incoming_Highest_Active_Sessions,Sessions_With_Media, round(((Sessions_Answered_Incoming*1.00) / (Sessions_Attempts_Incoming*1.00)) * 100.00, 2) as Incoming_ASR, Total_EmergencyCalls as Total_SessionsEmergency, Total_SecureSessions as Total_SessionsSecure, Total_SipICalls, Sessions_ActiveTranscoding as Total_SessionsActiveTranscoding,round((Total_Call_Duration*1.00 / Total_Completed_Calls*1.00), 2) as Sessions_ACD  FROM system_security_report  WHERE datetime(Start_time) >= ? AND datetime(Start_time) < ? ORDER BY datetime(start_time) DESC"""

## ORDER BY datetime(start_time) DESC

   ##-- Remove files older than defined days.
def remove_files(dir_path, n):
    all_files = os.listdir(dir_path)
    now = time.time()
    n_days = n * 86400
    for f in all_files:
        file_path = os.path.join(dir_path, f)
        if not os.path.isfile(file_path):
            continue
        if os.stat(file_path).st_mtime < now - n_days:
            os.remove(file_path)
            my_logger.debug("Deleted:%s", f)

remove_files(base_path, daysToSave)




# get current time
now = datetime.now()
my_logger.info ("Todays date:%s", str(now))

to_date = now.replace(minute=0, second=0,microsecond=0)
my_logger.info ("to_date: %s", str(to_date))

from_date = (to_date - timedelta(hours=1))
my_logger.info ("from_Date:%s", str(from_date))

#####################################
##Peer Statistics Reports

try:
        conn=sqlite3.connect("/archive/database/das/bn.peer_security_report.db")
        c=conn.cursor()
        my_logger.info("Successfully Connected to SQLite Database")

        conn.row_factory=sqlite3.Row

###########First Query

        crsr=conn.execute(query_PeerStatsSummary, (from_date,to_date,))

        row=crsr.fetchone()
        titles=row.keys()

        data = c.execute(query_PeerStatsSummary, (from_date,to_date,))

        if sys.version_info < (3,):
                f = open(PeerStatsSummaryFile, 'wb')
        else:
                f = open(PeerStatsSummaryFile, 'w', newline="")

        writer = csv.writer(f,delimiter=',')
        writer.writerow(titles)  # keys=title you're looking for
        # write the rest
        writer.writerows(data)
        my_logger.info ("output file names is : %s", PeerStatsSummaryFile)
###########Second Query

        crsr=conn.execute(query_PeerStatsIncoming, (from_date,to_date,))
        row=crsr.fetchone()
        titles=row.keys()

        data = c.execute(query_PeerStatsIncoming, (from_date,to_date,))

        if sys.version_info < (3,):
                f = open(PeerStatsIncomingFile, 'wb')
        else:
                f = open(PeerStatsIncomingFile, 'w', newline="")

        writer = csv.writer(f,delimiter=',')
        writer.writerow(titles)  # keys=title you're looking for
        # write the rest
        writer.writerows(data)
        my_logger.info ("output file names is : %s", PeerStatsIncomingFile)

###########Third Query

        crsr=conn.execute(query_PeerStatsOutgoing, (from_date,to_date,))
        row=crsr.fetchone()
        titles=row.keys()

        data = c.execute(query_PeerStatsOutgoing, (from_date,to_date,))

        if sys.version_info < (3,):
                f = open(PeerStatsOutgoingFile, 'wb')
        else:
                f = open(PeerStatsOutgoingFile, 'w', newline="")

        writer = csv.writer(f,delimiter=',')
        writer.writerow(titles)  # keys=title you're looking for
        # write the rest
        writer.writerows(data)
        my_logger.info ("output file names is : %s", PeerStatsOutgoingFile)

###############################

        f.close()
        c.close()

except sqlite3.Error as error:
    my_logger.error("Error while connecting to sqlite:%s", error)
finally:
    if (conn):
        conn.close()
        my_logger.info("The SQLite connection is closed")
#####################################
##System Statistics Summary

try:
        conn=sqlite3.connect("/archive/database/das/bn.system_security_report.db")
        c=conn.cursor()
        my_logger.info("Successfully Connected to SQLite Database")

        conn.row_factory=sqlite3.Row

        crsr=conn.execute(query_SystemStatsSummary, (from_date,to_date,))

        row=crsr.fetchone()
        titles=row.keys()

        data = c.execute(query_SystemStatsSummary, (from_date,to_date,))

        if sys.version_info < (3,):
                f = open(SystemStatsSummaryFile, 'wb')
        else:
                f = open(SystemStatsSummaryFile, 'w', newline="")

        writer = csv.writer(f,delimiter=',')
        writer.writerow(titles)  # keys=title you're looking for
        # write the rest
        writer.writerows(data)
        my_logger.info ("output file names is : %s", SystemStatsSummaryFile)

        f.close()
        c.close()

except sqlite3.Error as error:
    my_logger.error("Error while connecting to sqlite:%s", error)
finally:
    if (conn):
        conn.close()
        my_logger.info("The SQLite connection is closed")



# copy (scp) reports to remote destination
if useSCP == "Y":
        my_logger.info("Starting report copy to %s", remoteDestination )

        process = Popen(["scp","-B", PeerStatsSummaryFile, remoteDestination], stdout=PIPE, stderr=STDOUT)
        with process.stdout:
                log_subprocess_output(process.stdout)
        exitcode = process.wait() # 0 means success
        if exitcode == 0:
                my_logger.info("%s copied succesfully", PeerStatsSummaryFile)
        else:
                my_logger.error("%s copy failed", PeerStatsSummaryFile)

        process = Popen(["scp","-B", PeerStatsIncomingFile, remoteDestination], stdout=PIPE, stderr=STDOUT)
        with process.stdout:
                log_subprocess_output(process.stdout)
        exitcode = process.wait() # 0 means success
        if exitcode == 0:
                my_logger.info("%s copied succesfully", PeerStatsIncomingFile)
        else:
                my_logger.error("%s copy failed", PeerStatsIncomingFile)
				
        process = Popen(["scp","-B", PeerStatsOutgoingFile, remoteDestination], stdout=PIPE, stderr=STDOUT)
        with process.stdout:
                log_subprocess_output(process.stdout)
        exitcode = process.wait() # 0 means success
        if exitcode == 0:
                my_logger.info("%s copied succesfully", PeerStatsOutgoingFile)
        else:
                my_logger.error("%s copy failed", PeerStatsOutgoingFile)


        process = Popen(["scp","-B", SystemStatsSummaryFile, remoteDestination], stdout=PIPE, stderr=STDOUT)
        with process.stdout:
                log_subprocess_output(process.stdout)
        exitcode = process.wait() # 0 means success
        if exitcode == 0:
                my_logger.info("%s copied succesfully", SystemStatsSummaryFile)
        else:
                my_logger.error("%s copy failed", SystemStatsSummaryFile)


my_logger.info("***** Script Ended *****")
