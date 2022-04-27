#!/bin/bash
# start source server script -- needs source server script and destination server script to work  
umask 0000
############# variables ##############################################
CONFI="/mnt/user/appdata/backupserver/config.cfg" # dont change
############# other variables set in source server script  ###########


############################# functions ##############################

readconfig () { 
source "$CONFI"
HOST="root@""$source_server_ip" 
mkdir -p "$loglocation"
logname="$loglocation""$(date +'%Y-%m-%d--%H:%M')""--destination_to_source.txt"
touch "$logname"
}

############################

shallicontinue () {
if [ -f /mnt/user/appdata/backupserver/i_shutdown_source_server ] ; then
rm /mnt/user/appdata/backupserver/i_shutdown_source_server
  checksourceserver

  if [ "$sourceserverstatus" == "on"  ] ; then
    echo "Source server already running."
    echo "Shutting down backup server"
    #poweroff
    exit
  else
    echo "Source server is off...continuing"
    echo "Attempting to start source server"
  fi

else
echo "I didnt shutdown the source server so i will not start it up ....exiting"
exit
fi
}

############################

shutdowncontainersbackup() {

for contval in "${container_start_stop[@]}"
do
  echo "Shutting down specified containers on backup server before sync ....." 
  docker stop "$contval"
  echo 
done
sleep 10
}

############################

shutdowncontainerssource() {

for contval in "${container_start_stop[@]}"
do
  echo "Shutting down specified containers on source server before sync ....." 
  ssh "$HOST" docker stop "$contval"
  echo 
done
sleep 10
}

############################

startupcontainerssource() {

for contval in "${container_start_stop[@]}"
do
   echo "Restarting specified containers on source server now appdata is synced ....." 
   ssh "$HOST" docker start "$contval"
   echo 
done

}

############################

syncappdata () {
if [ "$sync_appdata_both_ways" == "yes"  ] ; then
echo "Appdata will be synced back to source server"
shutdowncontainerssource
# the appdata locations below will be synced (these are defined in basic settings on source server)
if [ "$appsource1" != "" ] && [ "$appdestination1" != ""  ] ; then
rsync -avhsP --delete "$appdestination1" "$HOST":"$appsource1"     # first appdata location to sync
fi
if [ "$appsource2" != "" ] && [ "$appdestination2" != ""  ] ; then
rsync -avhsP --delete "$appdestination2" "$HOST":"$appsource2"     # second appdata location to sync
fi
if [ "$appsource3" != "" ] && [ "$appdestination3" != ""  ] ; then
rsync -avhsP --delete "$appdestination3" "$HOST":"$appsource3"   # third appdata location to sync
fi
if [ "$appsource4" != "" ] && [ "$appdestination4" != ""  ] ; then
rsync -avhsP --delete "$appdestination4"  "$HOST":"$appsource4"   # forth appdata location to sync
fi
if [ "$appsource5" != "" ] && [ "$appdestination5" != ""  ] ; then
rsync -avhsP --delete "$appdestination5" "$HOST":"$appsource5"     # fifth appdata location to sync
fi
if [ "$appsource6" != "" ] && [ "$appdestinatio62" != ""  ] ; then
rsync -avhsP --delete "$appdestination6" "$HOST":"$appsource6"     # sixth appdata location to sync
fi
if [ "$appsource7" != "" ] && [ "$appdestination7" != ""  ] ; then
rsync -avhsP --delete "$appdestination7" "$HOST":"$appsource7"   # seventh appdata location to sync
fi
if [ "$appsource8" != "" ] && [ "$appdestination8" != ""  ] ; then
rsync -avhsP --delete "$appdestination8" "$HOST":"$appsource8" # eighth appdata location to sync
fi
if [ "$appsource9" != "" ] && [ "$appdestination9" != ""  ] ; then
rsync -avhsP --delete "$appdestination9" "$HOST":"$appsource9"  # ninth appdata location to sync
fi
startupcontainerssource # Restart the shutdown containers on source now appdata has been synced
fi
}

############################

# sync data from destination server to source server
syncmaindata () {
if [ "$sync_maindata_both_ways" == "yes"  ] ; then
echo "Main data will be synced back to source server"

# the locations below will be synced (these are defined in basic settings on source server)
if [ "$source1" != "" ] && [ "$destination1" != ""  ] ; then
rsync -avhsP --delete  "$destination1" "$HOST":"$source1"    # first location to sync
fi
if [ "$source2" != "" ] && [ "$destination2" != ""  ] ; then
rsync -avhsP --delete   "$destination2" "$HOST":"$source2"  # second location to sync
fi
if [ "$source3" != "" ] && [ "$destination3" != ""  ] ; then
rsync -avhsP --delete "$destination3" "$HOST":"$source3"  # third location to sync
fi
if [ "$source4" != "" ] && [ "$destination4" != ""  ] ; then
rsync -avhsP --delete  "$destination4" "$HOST":"$source4" # forth location to sync
fi
if [ "$source5" != "" ] && [ "$destination5" != ""  ] ; then
rsync -avhsP --delete  "$destination5" "$HOST":"$source5"   # fifth location to sync
fi
if [ "$source6" != "" ] && [ "$destination6" != ""  ] ; then
rsync -avhsP --delete  "$destination6" "$HOST":"$source6"   # sixth location to sync
fi
if [ "$source7" != "" ] && [ "$destination7" != ""  ] ; then
rsync -avhsP --delete  "$destination7" "$HOST":"$source7"  # seventh location to sync
fi
if [ "$source8" != "" ] && [ "$destination8" != ""  ] ; then
rsync -avhsP --delete  "$destination8" "$HOST":"$source8" # eighth location to sync
fi
if [ "$source9" != "" ] && [ "$destination9" != ""  ] ; then
rsync -avhsP --delete  "$destination9" "$HOST":"$source9" # ninth location to sync
fi
fi
}

############################

checkarraystarted () {
arraycheck=1
while ssh "$HOST" [ ! -d "/mnt/user/appdata/backupserver/" ]
do
echo "Attempt" "$arraycheck" "waiting for source server array to become available"
echo "Waiting 10 seconds to retry...."
((arraycheck=arraycheck+1))
sleep 10
done
echo "Attempt" "$arraycheck" "Ok. Source server array now started...."
echo "I will wait 30 seconds to be sure docker service has started"
sleep 30
}

############################

checksourceserver () {
ping "$source_server_ip" -c3 > /dev/null 2>&1 ; yes=$? ; #ping source server 3 times to check for reply
  if [ ! $yes == 0 ] ;then
  sourceserverstatus="off"
  else
  sourceserverstatus="on"

fi
}

############################

sourceserverstatus () {
sourcecheck=1
#check if source server has started up yet
while [ "$sourceserverstatus" == "off" ]
do
  checksourceserver
  echo "..........Checking source server attempt..." "$sourcecheck"
  echo "Source server not started yet"
  echo "Waiting 30 seconds to retry ......"
  ((sourcecheck=sourcecheck+1))
  sleep 30  # wait 30 seconds before rechecking
done
echo "..........Checking source server attempt..." "$sourcecheck"
echo "Source server is now up"
}

############################

wakeonlan () {
  if [ "$startsource" == "etherwake" ] ; then
etherwake -b "$backupmacaddress"
fi
}

############################

smartplugoff () {
if [ "$startsource" == "smartplug" ] ; then
curl "$source_smartplug_ip"/cm?cmnd=Power%20off  > /dev/null 2>&1 #turn off power by smart plug
fi
}

############################

smartplugon () {
if [ "$startsource" == "smartplug" ] ; then
curl "$source_smartplug_ip"/cm?cmnd=Power%20On  > /dev/null 2>&1 #turn on power and start server
fi
}

#################

ipmi_on () {
if [ "$startsource" == "ipmi" ] ; then
ipmitool -I lan -H "$source_server_ip" -U "$source_ipmiadminuser" -P "$source_ipmiadminpassword" chassis power on
fi
}

################# 
sync2source () {
syncmaindata
syncappdata 
}

################# start process ################################################
readconfig
shallicontinue
wakeonlan
ipmi_on
smartplugoff
sleep 5
smartplugon
sourceserverstatus 
checkarraystarted 
sync2source 2>&1 | tee -a "$logname"
rsync -avhsP  "$logname" "$HOST":"$logname" >/dev/null
rm "$logname"
poweroff # shutdown server
exit
