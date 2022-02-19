#!/bin/bash
umask 0000

startserver="smartplug"   #set to method to start backup server: etherwake (wake on lan) or smartplug
sourceip="10.10.20.199"   #set ip of the backup server
backupmacaddress="52:54:00:33:6c:bb" # set macaddress of backup servers nic (if using etherwake) - ignored if using etherwake
smartplugip="http://192.168.11.245" #address of tasmota smart plug - ignored if start server set to etherwake
copyappdata="yes"         # set to copy appdata for specific containers to backup server


dockersource1="/mnt/remotes/prime/appdata/EmbyServer/data/"    # set first appdata source directory to sync
dockerbackup1="/mnt/user/appdata/EmbyServer/data/"             # destination location for above

# remove '#' and fill in to add locations below for more directories to sync
# also remove '#' for each new location under function 'syncdata' in basic functions
# dockersource2="xxxxxxxxxxxxxxxx"              # set second appdata source directory to sync
# dockerbackup2="xxxxxxxxxxxxxxxx"              # destination location for above
# dockersource3="xxxxxxxxxxxxxxxx"              # set third appdata source directory to sync
# dockerbackup3="xxxxxxxxxxxxxxxx"              # destination location for above
# dockersource4="xxxxxxxxxxxxxxxx"              # set fourth appdata source directory to sync
# dockerbackup4="xxxxxxxxxxxxxxxx"              # destination location for above


############################# functions ########################################
shallicontinue () {
  checksourceserver
  if [ "$sourceserverstatus" == "on"  ] ; then
    echo "Source server already running."
    echo "Shutting down backup server"
    #powerdown
    exit
  else
    echo "Source server is off....continuing"
    echo "Attempting to start Backup server"
  fi
}


copyappdata () {
if [ "$copyappdata" == "yes"  ] ; then
# the locations below will be synced (these are defined in advanced settings)
rsync -avhP --delete "$dockerbackup1" "$dockersource1"    # first appdata to sync

# rsync -avhP --delete "$dockersource2" "$dockerbackup2"    # second appdata to sync
# rsync -avhP --delete "$dockersource3" "$dockerbackup3"   # third appdata to sync
# rsync -avhP --delete "$dockersource4" "$dockerbackup4"  # forth appdata to sync
# add additional locations if needed
fi
}

checksourceserver () {
ping $sourceip -c3 > /dev/null 2>&1 ; yes=$? ; #ping backup server 3 times to check for reply
  if [ ! $yes == 0 ] ;then
  sourceserverstatus="off"
  else
  sourceserverstatus="on"
fi
}

sourceserverstatus () {
#check if source server has started up yet
while [ "$sourceserverstatus" == "off" ]
do
  checksourceserver
  echo "Source server not started yet"
  sleep 30  # wait 30 seconds before rechecking
done
echo "Okay server is now on, Appdata will be synced back to source server"
sleep 60 # wait to make sure source server and backup servers mounted share is up
copyappdata
poweroff # shutdown server

}

wakeonlan () {
  if [ "$startserver" == "etherwake" ] ; then
etherwake -b $backupmacaddress
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

################# start process ################################################
shallicontinue
wakeonlan
smartplugoff
sleep 5
smartplugon
sourceserverstatus
exit
