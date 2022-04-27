#!/bin/bash
# source server script -- needs destination server backup scrip on backupup server to work
umask 0000
############# Basic settings (these settings cover source and destination scripts    ########################
############# Set auto server startup method for source and backup server         ###########################
startbackup="etherwake"   	 # set to choose method used to start backup server: "etherwake" (wake on lan), "ipmi" (for IPMI capable servers) or "smartplug" tasmota smart switch 
startsource="etherwake"   	 # set to choose method used to start backup server: "etherwake" (wake on lan), "ipmi" (for IPMI capable servers) or "smartplug" tasmota smart switch
source_ipmiadminuser="admin"     	 # used for IPMI capable servers - admin user for source server
source_ipmiadminpassword="password" # used for IPMI capable servers - admin user  for source server
dest_ipmiadminuser="admin"     	 # used for IPMI capable servers - admin user for destination/backup server
dest_ipmiadminpassword="password" # used for IPMI capable servers - admin user for destination/backup server
backup_smartplug_ip="http://xxx.xxx.xxx.xxx" # set ip address of tasmota smart plug - ignored if start server set to etherwake
source_smartplug_ip="http://xxx.xxx.xxx.xxx" # set ip address of tasmota smart plug - ignored if start server set to etherwake

############# Set Ip and/or macaddresses for source and backup server      #################################
sourcemacaddress="xx:xx:xx:xx:xx:xx"  # set macaddress of backup servers' NIC (if using etherwake) - ignored if using smartplug
backupmacaddress="xx:xx:xx:xx:xx:xx"  # set macaddress of backup servers' NIC (if using etherwake) - ignored if using smartplug
source_server_ip="192.168.1.100"       # set ip address of the sourceserver
destination_server_ip="192.168.1.101"  # set ip address of the backup server

############# Sync process setiings     ####################################################################
poweroff="source"         # set to shutdown source server, backup server or neither server after sync --  "none" "both" "source" "backup"
copymaindata="yes"        # set to copy main array data for selected shares/locations from the source server to the backup server
copyappdata="yes"         # set to copy appdata for specific containers from the source server to the backup server

switchserver="yes"        # set to "yes" or "no"  for backup server to take over running specified containers or not - (if poweroff set to backup then this is ignored)
sync_appdata_both_ways="yes"  # default "yes" - set to "yes" to sync appback data from destination to source server when using switchserver
sync_maindata_both_ways="no"  # default "no" - set to "yes" to sync back data, as well as appdata from destination to source server when using switchserver

# Containers to shutdown before copy (used if wanting to backup appdata of a container or if server is switching servers from source to backup  ie emby/plex )
declare -a container_start_stop=("null" "null") # put each container name in quotes ie container_start_stop=("EmbyServerBeta" "swag")

# Vms listed below will be checked for and if found running source server will not shutdown if set to
declare -a vms=("null" "null") # put each vm name for script to check if tunning in quotes ie vms=("PopOS" "Wondows 10")
continueifvmsrunning="no"  # Default "no" backup server will not start and copy process not continue - If "yes" copy will continue but main server will not shutdown and backup server shutdown afterwards instead. 


#source directories to backup on source server
source1=""    # set first source directory to sync - example   source1="/mnt/user/Movies/"
source2=""  
source3=""
source4=""
source5=""
source6=""
source7=""
source8=""
source9=""
#source appdata directories to backup on source server
appsource1=""    # set first source directory to sync - example  appsource1="/mnt/user/appdata/EmbyServer/data/" 
appsource2=""  
appsource3=""
appsource4=""
appsource5=""
appsource6=""
appsource7=""
appsource8=""
appsource9=""

# target directories to sync to on destination server
destination1=""    # set first destination directory target - example destination1="/mnt/user/Movies/" 
destination2=""  
destination3=""
destination4=""
destination5=""
destination6=""
destination7=""
destination8=""
destination9=""
#target appdata directories to sync to on destination server
appdestination1=""    # set first source directory to sync - example appdestination1="/mnt/user/appdata/EmbyServer/data/"
appdestination2=""  
appdestination3=""
appdestination4=""
appdestination5=""
appdestination6=""
appdestination7=""
appdestination8=""
appdestination9=""


############# advanced variables/settings ##############################################
CONFI="/mnt/user/appdata/backupserver/config.cfg"  #dont change
loglocation="/mnt/user/appdata/backupserver/logs/" #dont change

logname="$loglocation""$(date +'%Y-%m-%d--%H:%M')"--source_to_destination.txt #dont change

############################# functions ########################################
 
shallicontinue () {
  checkbackupserver
  if [ "$destserverstatus" == "on"  ] ; then
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

######################################

setup () {
#set flag to shutdown backup or source server after sync
if [ "$poweroff" == "backup"  ] ; then
echo "Backup server has been set to turn off after sync"
switchserver="no" #set switchserver to no as backup server will shutdown

elif [ "$poweroff" == "source"  ] ; then
echo "Source server has been set to turn off after sync"
switchserver="yes" #set switchserver to yes as source server will shutdown
else
echo "Neither Source nor Backup server is set to be turned off"

fi
if [ "$switchserver" == "yes"  ] ; then
copyappdata="yes" # copyappdata set to yes as server duties set to switch
poweroff="source" # make sure source server is set to shutdown
echo "Containers are set to start on Backup server after sync completed"
else
echo "No containers on Backup server are set to start after sync had completed"
fi

# make flag file to tell backup server when it starts to start backup process
touch /mnt/user/appdata/backupserver/start ; echo "Making flag in appdata to tell backupserver job has been requested"
}

######################################

vmcheck () {
echo "Checking if specified VMs are running"
for vmval in "${vms[@]}"
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

######################################

checkbackupserver () {
ping $destination_server_ip -c3 > /dev/null 2>&1 ; yes=$? ; #ping backup server 3 times to check for reply
  if [ ! $yes == 0 ] ;then
  destserverstatus="off"
  else
  destserverstatus="on"
fi
}

######################################

backupserverstatus () {
#check if backup server has started up yet
checkbackup=1
while [ "$destserverstatus" == "off" ]
do
  checkbackupserver
  echo ".............................Checking backup server attempt...""$checkbackup"
  echo "Backup server not started yet"
  echo "Waiting 30 seconds to check again"
  ((checkbackup=checkbackup+1))
  sleep 30  # wait 30 seconds before rechecking
done
echo "Okay server is now on, taking" "$((checkbackup * 30))" "seconds to boot. Backup process should start from the backup server side"

if [ "$poweroff" == "backup"  ] && [ "$startbackup" = "smartplug" ] ;then
checkbackup=1
#check if backup server has shutdown
while [ "$destserverstatus" == "on" ]
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
fi
}

######################################

smartplugoff () {
if [ "$startbackup" == "smartplug" ] ; then
curl "$backup_smartplug_ip"/cm?cmnd=Power%20off  > /dev/null 2>&1 #turn off power by smart plug
fi
}

######################################

smartplugon () {
if [ "$startbackup" == "smartplug" ] ; then
curl $backup_smartplug_ip/cm?cmnd=Power%20On  > /dev/null 2>&1 #turn on power and start server
echo "Attempting to start the backup server"
fi
}

######################################

wakeonlan () {
etherwake -b $backupmacaddress
}

######################################

ipmi_on () {
ipmitool -I lan -H "$destination_server_ip" -U "$dest_ipmiadminuser" -P "$dest_ipmiadminpassword" chassis power on
}


######################################

writeconfig () {
echo
echo "Writing config file" 
echo
echo "# Data source directories to be copied/synced from source server" | sudo tee  $CONFI
echo "source1=\"$source1\"" | sudo tee  --append $CONFI
echo "source2=\"$source2\"" | sudo tee  --append $CONFI
echo "source3=\"$source3\"" | sudo tee  --append $CONFI
echo "source4=\"$source4\"" | sudo tee  --append $CONFI
echo "source5=\"$source5\"" | sudo tee  --append $CONFI
echo "source6=\"$source6\"" | sudo tee  --append $CONFI
echo "source7=\"$source7\"" | sudo tee  --append $CONFI
echo "source8=\"$source8\"" | sudo tee  --append $CONFI
echo "source9=\"$source9\"" | sudo tee  --append $CONFI
echo "# Appdata source directories to be copied/synced from source server" | sudo tee --append $CONFI
echo "appsource1=\"$appsource1\"" | sudo tee  --append $CONFI
echo "appsource2=\"$appsource2\"" | sudo tee  --append $CONFI
echo "appsource3=\"$appsource3\"" | sudo tee  --append $CONFI
echo "appsource4=\"$appsource4\"" | sudo tee  --append $CONFI
echo "appsource5=\"$appsource5\"" | sudo tee  --append $CONFI
echo "appsource6=\"$appsource6\"" | sudo tee  --append $CONFI
echo "appsource7=\"$appsource7\"" | sudo tee  --append $CONFI
echo "appsource8=\"$appsource8\"" | sudo tee  --append $CONFI
echo "appsource9=\"$appsource9\"" | sudo tee  --append $CONFI

echo "# Destination directories to be copied/synced to on destination server" | sudo tee --append $CONFI
echo "destination1=\"$destination1\"" | sudo tee  --append $CONFI
echo "destination2=\"$destination2\"" | sudo tee  --append $CONFI
echo "destination3=\"$destination3\"" | sudo tee  --append $CONFI
echo "destination4=\"$destination4\"" | sudo tee  --append $CONFI
echo "destination5=\"$destination5\"" | sudo tee  --append $CONFI
echo "destination6=\"$destination6\"" | sudo tee  --append $CONFI
echo "destination7=\"$destination7\"" | sudo tee  --append $CONFI
echo "destination8=\"$destination8\"" | sudo tee  --append $CONFI
echo "destination9=\"$destination9\"" | sudo tee  --append $CONFI
echo "# Destination appdata directories to be copied/synced to on destination server" | sudo tee --append $CONFI
echo "appdestination1=\"$appdestination1\"" | sudo tee  --append $CONFI
echo "appdestination2=\"$appdestination2\"" | sudo tee  --append $CONFI
echo "appdestination3=\"$appdestination3\"" | sudo tee  --append $CONFI
echo "appdestination4=\"$appdestination4\"" | sudo tee  --append $CONFI
echo "appdestination5=\"$appdestination5\"" | sudo tee  --append $CONFI
echo "appdestination6=\"$appdestination6\"" | sudo tee  --append $CONFI
echo "appdestination7=\"$appdestination7\"" | sudo tee  --append $CONFI
echo "appdestination8=\"$appdestination8\"" | sudo tee  --append $CONFI
echo "appdestination9=\"$appdestination9\"" | sudo tee  --append $CONFI

echo "# other variables" | sudo tee --append $CONFI
echo "source_server_ip=\"$source_server_ip\"" | sudo tee  --append $CONFI
echo "destination_server_ip=\"$destination_server_ip\"" | sudo tee  --append $CONFI
echo "poweroff=\"$poweroff\"" | sudo tee  --append $CONFI
echo "startbackup=\"$startbackup\"" | sudo tee  --append $CONFI
echo "startsource=\"$startsource\"" | sudo tee  --append $CONFI

echo "backup_smartplug_ip=\"$backup_smartplug_ip\"" | sudo tee  --append $CONFI
echo "source_smartplug_ip=\"$source_smartplug_ip\"" | sudo tee  --append $CONFI
echo "source_ipmiadminuser=\"$source_ipmiadminuser\"" | sudo tee  --append $CONFI
echo "source_ipmiadminpassword=\"$source_ipmiadminpassword\"" | sudo tee  --append $CONFI
echo "dest_ipmiadminuser=\"$dest_ipmiadminuser\"" | sudo tee  --append $CONFI
echo "dest_ipmiadminpassword=\"$dest_ipmiadminpassword\"" | sudo tee  --append $CONFI

echo "sourcemacaddress=\"$sourcemacaddress\"" | sudo tee  --append $CONFI
echo "backupmacaddress=\"$backupmacaddress\"" | sudo tee  --append $CONFI
echo "copyappdata=\"$copyappdata\"" | sudo tee  --append $CONFI
echo "copymaindata=\"$copymaindata\"" | sudo tee  --append $CONFI
echo "switchserver=\"$switchserver\"" | sudo tee  --append $CONFI
echo "sync_appdata_both_ways=\"$sync_appdata_both_ways\"" | sudo tee  --append $CONFI
echo "sync_maindata_both_ways=\"$sync_maindata_both_ways\"" | sudo tee  --append $CONFI
echo "container_start_stop=(${container_start_stop[@]})"  | sudo tee  --append $CONFI
echo "loglocation=\"$loglocation\"" | sudo tee  --append $CONFI
echo "logname=\"$logname\"" | sudo tee  --append $CONFI

}

######################################

mainfunction (){
if [ "$startbackup" == "smartplug" ] ; then
shallicontinue  
setup 
smartplugoff
sleep 5
smartplugon 
echo "Writing config file" 
writeconfig  >/dev/null
backupserverstatus 
elif [ "$startbackup" == "ipmi" ] ; then
shallicontinue 
setup
ipmi_on
echo "Writing config file"
writeconfig 
backupserverstatus
else
shallicontinue 
setup
wakeonlan
echo "Writing config file"
writeconfig 
backupserverstatus
fi
}

############################## start process ###################################
mkdir -p "$loglocation" && touch "$logname"
mainfunction 2>&1 | tee -a "$logname"
exit

