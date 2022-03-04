#!/bin/bash
umask 0000

startserver="smartplug"   # set to choose method used to start backup server: "etherwake" (wake on lan) or "smartplug" tasmota smart switch
smartplugip="http://192.168.11.237" # set ip address of tasmota smart plug - ignored if start server set to etherwake
backupmacaddress="xx:xx:xx:xx:xx:xx" # set macaddress of backup servers' NIC (if using etherwake) - ignored if using smartplug
backupip="10.10.20.197"   # set ip address of the backup server
poweroff="backup"  # set to shutdown source server, backup server or neither server after sync --  "none" "both" "source" "backup"
containerstart="yes" # set to "yes or "no" to tell backup server to start selected containers on backup server after sync (if poweroff set to backup then this is ignored)
vm1="vm1"  # if this vm is running and poweroff is set to 'source' then poweroff will be set to none so source server doesnt shut down
vm2="vm2"  # if this vm is running and poweroff is set to 'source' then poweroff will be set to none so source server doesnt shut down
vm3="vm3"  # if this vm is running and poweroff is set to 'source' then poweroff will be set to none so source server doesnt shut down
continueifvmsrunning="no"  # If "yes" copy will continue but main server will not shutdown and backup server shutdown aftwards instead. If "no" backup server will not start and copy process not continue

############################# functions ########################################

checkbackupserver () {
ping $backupip -c3 > /dev/null 2>&1 ; yes=$? ; #ping backup server 3 times to check for reply
  if [ ! $yes == 0 ] ;then
  backupserverstatus="off"
  else
  backupserverstatus="on"
fi
}

shallicontinue () {
  checkbackupserver
  if [ "$backupserverstatus" == "on"  ] ; then
    echo "Backup server already running. So Sync must be manually run from backup server"
    echo "Exiting"
    exit
  else
    echo "Backup server is off....continuing"
  fi
 vmcheck
  if [ "$vmrunning" != "true" ] && [ "$poweroff" == "source"  ] ; then
    echo "No specified VMs are running so its safe for source server to be shutdown"

  elif [ "$vmrunning" = "true" ] && [ "$continueifvmsrunning" = "no" ] ;then
    echo "One or more specified VMs are running so process will not run"
    echo "Exiting"
    exit

  elif [ "$vmrunning" = "true" ] && [ "$continueifvmsrunning" = "yes" ] ;then
    echo "One or more specified VMs are running so source server will NOT shut down after process is finished"
    echo "Backup server will be set to shut down instead"
    poweroff="backup" 
fi 
}

setup () {
#set flag to shutdown backup or source server after sync
if [ "$poweroff" == "backup"  ] ; then
mkdir -p /mnt/user/appdata/backupserver/backupoff
echo "Backup server has been set to turn off after sync"
containerstart="no" #set continer start to no as backup server will shutdown
elif [ "$poweroff" == "source"  ] ; then
mkdir -p /mnt/user/appdata/backupserver/sourceoff
else
echo "Neither Source nor Backup server is set to be turned off"
fi
if [ "$containerstart" == "yes"  ] ; then
mkdir -p /mnt/user/appdata/backupserver/containerstart
echo "Containers are set to start on Backup server after sync completed"
else
echo "No containers on Backup server are set to start after sync had completed"
fi

# make directory to tell backup server when it starts to start backup process
mkdir -p /mnt/user/appdata/backupserver/start ; echo "Making directory in appdata for script flags"

}

wakeonlan () {
etherwake -b $backupmacaddress
}

vmcheck () {
echo "Checking if specified VMs are running"
for vmval in "$vm1" "$vm2" "$vm3"
do
vmstate=$(virsh list --all | grep " $vmval " | awk '{ print $NF}')
if [ "$vmstate" != "running" ]
then
    echo "$vmval"  "is not running."
else
    echo "$vmval"  "is running "
    vmrunning="true"
fi
done

}

backupserverstatus () {
#check if backup server has started up yet
checkbackup=1
while [ "$backupserverstatus" == "off" ]
do
  checkbackupserver
  echo ".............................Checking backup server attempt...""$checkbackup"
  echo "Backup server not started yet"
  echo "Waiting 30 seconds to check again"
  ((checkbackup=checkbackup+1))
  sleep 30  # wait 30 seconds before rechecking
done
echo "Okay server is now on, backup process should start from the backup server side"

if [ "$poweroff" == "backup"  ] ; then
checkbackup=1
#check if backup server has shutdown
while [ "$backupserverstatus" == "on" ]
do
  checkbackupserver
  echo ".............................Checking backup server attempt...""$checkbackup"
  echo "Backup server not shutdown"
  echo "Waiting 30 seconds to check again"
 ((checkbackup=checkbackup+1))
  sleep 30  # wait 30 seconds before rechecking
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

smartplugoff () {
if [ "$startserver" == "smartplug" ] ; then
curl "$smartplugip"/cm?cmnd=Power%20off  > /dev/null 2>&1 #turn off power by smart plug
fi
}

smartplugon () {
if [ "$startserver" == "smartplug" ] ; then
curl $smartplugip/cm?cmnd=Power%20On  > /dev/null 2>&1 #turn on power and start server
echo "Attempting to start the backup server"
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
