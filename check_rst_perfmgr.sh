#!/bin/bash
#*/10 * * * * /root/check_rst_perfmgr.sh >>/tmp/check_rst_perfmgr.log 2>&1
if  curl -s -H "Content-Type: application/json" -H "Accept: application/json" -X GET  http://localhost:10080/services/perfmanager | grep -q "STOPPED" ; then
echo "perfmanager is not running"
curl -s -H "Content-Type: application/json" -H "Accept: application/json" -X GET  http://localhost:10080/services/eventmanager | grep -q "RUNNING" && curl -s -H "Content-Type: application/json" -H "Accept: application/json" -X PUT -d '{"state":"RUNNING"}'  http://localhost:10080/services/perfmanager && echo "started perfmanager"
fi
