#!/bin/bash
# backup server script -- needs source server script setup on source server to work
umask 0000
############# Basic settings ##########################################################
source_server_ip="192.168.1.10" # set to the ip of the source server
forcestart="no"  # default is "no" - set to yes to force process to run even if source server didn't request

############# advanced/optional settings ##############################################
checkandstart="no" # default is "no" - set to yes for script to start below containers if main server is NOT running
declare -a container_start=("EmbyServerBeta" "swag") # put each container name in quotes ie container_start_stop=("EmbyServerBeta" "swag")
##
HOST="root@""$source_server_ip" # dont change
CONFI="/mnt/user/appdata/backupserver/" # dont change

#############  Functions ##############################################################

Check_Source_Server () {
ping $source_server_ip -c3 > /dev/null 2>&1 ; yes=$? ; #ping source server 3 times to check for reply
  if [ ! $yes == 0 ] ;then
  sourceserverstatus="off"
  else
  sourceserverstatus="on"
fi

# check if containers should be started if source server is not running
if [ "$sourceserverstatus" == "off" ] && [ "$checkandstart" == "yes" ]; then
echo "Source server is off. I will start selected containers"
startcontainers_if_main_off
exit
fi
if [ "$sourceserverstatus" == "off" ]; then
echo "Source server is off. Exiting"
exit
else
# read config file written by source server to set variables
mkdir -p "$CONFI"
rsync -avhsP  "$HOST":"$CONFI" "$CONFI" ||  start="no";
source "$CONFI"config.cfg
ssh "$HOST" [[ -f /mnt/user/appdata/backupserver/start ]] && start="yes" ||  start="no";
fi
}

#######################################################################################

# sync data from source server to backup server
syncmaindata () {
if [ "$copymaindata" == "yes"  ] ; then
# the locations below will be synced (these are defined in basic settings)
if [ "$source1" != "" ] && [ "$destination1" != ""  ] ; then
rsync -avhsP --delete  "$HOST":"$source1" "$destination1"    # first location to sync
fi
if [ "$source2" != "" ] && [ "$destination2" != ""  ] ; then
rsync -avhsP --delete  "$HOST":"$source2" "$destination2"    # second location to sync
fi
if [ "$source3" != "" ] && [ "$destination3" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$source3" "$destination3"  # third location to sync
fi
if [ "$source4" != "" ] && [ "$destination4" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$source4" "$destination4"  # forth location to sync
fi
if [ "$source5" != "" ] && [ "$destination5" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$source5" "$destination5"    # fifth location to sync
fi
if [ "$source6" != "" ] && [ "$destination6" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$source6" "$destination6"    # sixth location to sync
fi
if [ "$source7" != "" ] && [ "$destination7" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$source7" "$destination7"  # seventh location to sync
fi
if [ "$source8" != "" ] && [ "$destination8" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$source8" "$destination8"  # eighth location to sync
fi
if [ "$source9" != "" ] && [ "$destination9" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$source9" "$destination9"  # ninth location to sync
fi

fi
}

#######################################################################################

syncappdata () {
if [ "$copyappdata" == "yes"  ] ; then
shutdowncontainersbackup
shutdowncontainerssource 

if [ "$appsource1" != "" ] && [ "$appdestination1" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$appsource1" "$appdestination1"    # first appdata location to sync
fi
if [ "$appsource2" != "" ] && [ "$appdestination2" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$appsource2" "$appdestination2"    # second appdata location to sync
fi
if [ "$appsource3" != "" ] && [ "$appdestination3" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$appsource3" "$appdestination3"  # third appdata location to sync
fi
if [ "$appsource4" != "" ] && [ "$appdestination4" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$appsource4" "$appdestination4"  # forth appdata location to sync
fi
if [ "$appsource5" != "" ] && [ "$appdestination5" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$appsource5" "$appdestination5"    # fifth appdata location to sync
fi
if [ "$appsource6" != "" ] && [ "$appdestinatio62" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$appsource6" "$appdestination6"    # sixth appdata location to sync
fi
if [ "$appsource7" != "" ] && [ "$appdestination7" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$appsource7" "$appdestination7"  # seventh appdata location to sync
fi
if [ "$appsource8" != "" ] && [ "$appdestination8" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$appsource8" "$appdestination8"  # eighth appdata location to sync
fi
if [ "$appsource9" != "" ] && [ "$appdestination9" != ""  ] ; then
rsync -avhsP --delete "$HOST":"$appsource9" "$appdestination9"  # ninth appdata location to sync
fi

startupcontainers
fi
}

#######################################################################################

# this function cleans up and exits script shutting down server if that has been set
endandshutdown () {

if [ "$poweroff" == "backup"  ] ; then
echo "Shutting down backup server"
poweroff # shutdown backup server

elif [ "$poweroff" == "source"  ] ; then
ssh "$HOST" 'poweroff'  # shutdown source server to shutdown
echo "source server will shut off shortly"
touch /mnt/user/appdata/backupserver/i_shutdown_source_server

else
echo "Neither Source nor backup server set to turn off"
fi

ssh "$HOST" 'rm /mnt/user/appdata/backupserver/start' 

}

#######################################################################################

# this function plays completion tune when sync finished (will not work without beep speaker)
completiontune () {
beep -l 600 -f 329.627556913 -n -l 400 -f 493.883301256 -n -l 200 -f 329.627556913 -n -l 200 -f 493.883301256 -n -l 200 -f 659.255113826 -n -l 600 -f 329.627556913 -n -l 400 -f 493.883301256 -n -l 200 -f 329.627556913 -n -l 200 -f 493.883301256 -n -l 200 -f 659.255113826 -n -l 600 -f 329.627556913 -n -l 360 -f 493.883301256 -n -l 200 -f 329.627556913 -n -l 200 -f 493.883301256 -n -l 640 -f 659.255113826 -n -l 160 -f 622.253967444 -n -l 200 -f 329.627556913 -n -l 200 -f 554.365261954 -n -l 200 -f 329.627556913 -n -l 200 -f 622.253967444 -n -l 200 -f 493.883301256 -n -l 200 -f 830.60939516 -n -l 200 -f 415.30469758 -n -l 80 -f 739.988845423 -n -l 40 -f 783.990871963 -n -l 80 -f 739.988845423 -n -l 200 -f 415.30469758 -n -l 200 -f 659.255113826 -n -l 200 -f 622.253967444 -n -l 400 -f 554.365261954 -n -l 1320 -f 415.30469758 -n -l 40 -f 7458.62018429 -n -l 40 -f 7040.0 -n -l 40 -f 4186.00904481 -n -l 40 -f 3729.31009214 -n -l 40 -f 6644.87516128 -n -l 40 -f 7902.1328201 -n -l 40 -f 16.3515978313 -n -l 200 -f 830.60939516 -n -l 200 -f 415.30469758 -n -l 40 -f 739.988845423 -n -l 80 -f 783.990871963 -n -l 80 -f 739.988845423 -n -l 200 -f 415.30469758 -n -l 200 -f 659.255113826 -n -l 200 -f 622.253967444 -n -l 400 -f 554.365261954 -n -l 1320 -f 415.30469758 -n -l 40 -f 4698.63628668
}

#######################################################################################

startupcontainers() {

if [ "$switchserver" == "yes"  ] ; then

for contval in "${container_start_stop[@]}"
do
   echo "Starting specified containers on backup server ....." 
   docker start "$contval"
   echo 
done
fi

if [ "$switchserver" == "no"  ] ; then

for contval in "${container_start_stop[@]}"
do
   echo "Starting specified containers on source server  ....." 
  ssh "$HOST" docker start "$contval"
   echo 
done
fi
}

#######################################################################################

shutdowncontainerssource() {

for contval in "${container_start_stop[@]}"
do
  echo "Shutting down specified containers on host ....." 
  ssh "$HOST" docker stop "$contval"
  echo 
done
sleep 10
}

#######################################################################################

shutdowncontainersbackup() {

for contval in "${container_start_stop[@]}"
do
  echo "Shutting down specified containers on backup server before sync ....." 
  docker stop "$contval"
  echo 
done
sleep 10
}

#######################################################################################

startcontainers_if_main_off() { 
for contval in "${container_start[@]}"
do
   docker start "$contval"
done
}

#######################################################################################

Main_Sync_Function () {

# check if main server started process by making start flag file, then start sync
if [ "$start" == "yes" ] ; then
syncmaindata 
syncappdata 
completiontune
endandshutdown 

# check if set to forcesync and if so, then start sync
elif  [ "$forcestart" == "yes"  ] ; then
syncmaindata 
syncappdata 
completiontune
endandshutdown 


# If source server didnt request sync then exit
else
echo "Source server didn't start the backup server so sync job has not been requested"
echo "Source server is " "$sourceserverstatus"
exit
fi
}

############# Start process #############################################################
Check_Source_Server
Main_Sync_Function 2>&1 | ssh "$HOST" -T tee -a "$logname"

exit
