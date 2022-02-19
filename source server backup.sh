#!/bin/bash
umask 0000

startserver="smartplug"   #set to method to start backup server: etherwake (wake on lan) or smartplug
backupip="10.10.20.197"   #set ip of the backup server
backupmacaddress="52:54:00:33:6c:bb" # set macaddress of backup servers nic (if using etherwake) - ignored if using etherwake
smartplugip="http://192.168.11.237" #address of tasmota smart plug - ignored if start server set to etherwake
poweroff="backup"  #set to shutdown source server, backup server or none after sync  "none" "both" "source" "backup"
containerstart="no" # set to "yes or "no" to tell backup server to start selected (on backup server) containers to start


############################# functions ########################################

setup () {
# make directory to tell backup server when it starts to start backup process
mkdir -vp /mnt/user/appdata/backupserver/start
#set flag to shutdown backup or source server after sync
if [ "$poweroff" == "backup"  ] ; then
mkdir -vp /mnt/user/appdata/backupserver/backupoff
echo "Backup server has been set to turn off after sync"
elif [ "$poweroff" == "source"  ] ; then
mkdir -vp /mnt/user/appdata/backupserver/sourceoff
echo "Source server has been set to turn off after sync"
else
echo "Neither Source nor Backup server is set to be turned off"
fi
if [ "$containerstart" == "yes"  ] ; then
mkdir -vp /mnt/user/appdata/backupserver/containerstart
echo "Containers set to start on Backup server after sync completed"
else
echo "No containers on Backup server set to start after sync had completed"
}

wakeonlan () {
etherwake -b $backupmacaddress
}

shallicontinue () {
  checkbackupserver
  if [ "$backupserverstatus" == "on"  ] ; then
    echo "Backup server already running. Sync must be run from backup server"
    echo "Exiting"
    exit
  else
    echo "Backup server is off....continuing"
    echo "Attempting to start Backup server"
  fi
}

backupserverstatus () {
#check if backup server has started up yet
while [ "$backupserverstatus" == "off" ]
do
  checkbackupserver
  echo "Backup server not started yet"
  sleep 30  # wait 30 seconds before rechecking
done
echo "Okay server is now on, backup process should start from the backup server side"

if [ "$poweroff" == "backup"  ] ; then
#check if backup server has shutdown
while [ "$backupserverstatus" == "on" ]
do
  checkbackupserver
  echo "Backup server is still on"
  sleep 60  # wait 60 seconds before rechecking
done
smartplugoff
echo "backup server is down and smartplug powered off"

elif [ "$poweroff" == "source"  ] ; then
while [ ! -d /mnt/user/appdata/backupserver/sourceoffnow ]
do
  echo "Backup server not finished sync yet"
  sleep 30  # wait 30 seconds before rechecking
done
rm -r /mnt/user/appdata/backupserver/sourceoffnow  #delete flag
echo "Source and backup server are synced shutting down Source server"
poweroff # shutdown server
else
echo "No servers are set to power off after sync"
fi
}

checkbackupserver () {
ping $backupip -c3 > /dev/null 2>&1 ; yes=$? ; #ping backup server 3 times to check for reply
  if [ ! $yes == 0 ] ;then
  backupserverstatus="off"
  else
  backupserverstatus="on"
fi
}

smartplugoff () {
if [ "$startserver" == "smartplug" ] ; then
curl "$smartplugip"/cm?cmnd=Power%20off  > /dev/null 2>&1 #turn off power by smart plug
fi
}

smartplugon () {
if [ "$startserver" == "smartplug" ] ; then
curl $smartplugip/cm?cmnd=Power%20On  > /dev/null 2>&1 #turn on power and start server
fi
}

############################## start process ###################################
if [ "$startserver" == "smartplug" ] ; then
shallicontinue
setup
smartplugoff
sleep 5
smartplugon
backupserverstatus
else
shallicontinue
setup
wakeonlan
backupserverstatus
fi
exit
