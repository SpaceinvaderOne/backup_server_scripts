#!/bin/bash
umask 0000

# backup server script -- needs source server script setup on source server to work

############# Basic settings ##############################################################
# these must be set
remotelocation="/mnt/remotes/prime/appdata/backupserver" # set remote mounted location

sourcelocation1="/mnt/remotes/prime/Movies/"    # set first source directory to sync
backuplocation1="/mnt/user/Movies/"             # destination location for above
sourcelocation2="/mnt/remotes/prime/TV Shows/"  # set second source directory to sync
backuplocation2="/mnt/user/TV Shows/"           # destination location for above

# remove '#' and fill in to add locations below for more directories to sync
# also remove '#' for each new location under function 'syncdata' in basic functions

# sourcelocation3="xxxxxxxxxxxxxxxx"            # set third source directory to sync
# backuplocation3="xxxxxxxxxxxxxxxx"            # destination location for above
# sourcelocation4="xxxxxxxxxxxxxxxx"            # set fourth source directory to sync
# backuplocation4="xxxxxxxxxxxxxxxx"            # destination location for above

############# Basic functions ##############################################################

# this function syncs data from source server to backup server
syncdata() {
# the locations below will be synced (these are defined in basic settings)
rsync -avhP --delete "$sourcelocation1" "$backuplocation1"    # first location to sync
rsync -avhP --delete "$sourcelocation2" "$backuplocation2"    # second location to sync

# rsync -avhP --delete "$sourcelocation3" "$backuplocation3"  # third location to sync
# rsync -avhP --delete "$sourcelocation4" "$backuplocation4"  # forth location to sync
# add additional locations if needed
}

# this function checks the power off setting which is set on source script on source server
shutdownstatus () {
if [ -d $remotelocation/backupoff ] ; then
poweroff="backup"
containerstart="no"
rm -r $remotelocation/backupoff
elif [ -d $remotelocation/sourceoff ] ; then
poweroff="source"
rm -r $remotelocation/sourceoff
else
poweroff="none"
fi
}

# this function cleans up and exits script shutting down server if that has been set
endandshutdown () {
rm -r $remotelocation/start  # delete 'start' folder created by main server now process has finished

if [ "$poweroff" == "backup"  ] ; then
echo "Shutting down backup server"
poweroff # shutdown backup server

elif [ "$poweroff" == "source"  ] ; then
mkdir -vp $remotelocation/sourceoffnow  # create flag for source server to shutdown
echo "source server will shut off shortly"

else
echo "Neither Source nor backup server set to turn off"
fi
}

# this function plays completion tune when sync finished (will not work without beep speaker)
completiontune () {
beep -l 600 -f 329.627556913 -n -l 400 -f 493.883301256 -n -l 200 -f 329.627556913 -n -l 200 -f 493.883301256 -n -l 200 -f 659.255113826 -n -l 600 -f 329.627556913 -n -l 400 -f 493.883301256 -n -l 200 -f 329.627556913 -n -l 200 -f 493.883301256 -n -l 200 -f 659.255113826 -n -l 600 -f 329.627556913 -n -l 360 -f 493.883301256 -n -l 200 -f 329.627556913 -n -l 200 -f 493.883301256 -n -l 640 -f 659.255113826 -n -l 160 -f 622.253967444 -n -l 200 -f 329.627556913 -n -l 200 -f 554.365261954 -n -l 200 -f 329.627556913 -n -l 200 -f 622.253967444 -n -l 200 -f 493.883301256 -n -l 200 -f 830.60939516 -n -l 200 -f 415.30469758 -n -l 80 -f 739.988845423 -n -l 40 -f 783.990871963 -n -l 80 -f 739.988845423 -n -l 200 -f 415.30469758 -n -l 200 -f 659.255113826 -n -l 200 -f 622.253967444 -n -l 400 -f 554.365261954 -n -l 1320 -f 415.30469758 -n -l 40 -f 7458.62018429 -n -l 40 -f 7040.0 -n -l 40 -f 4186.00904481 -n -l 40 -f 3729.31009214 -n -l 40 -f 6644.87516128 -n -l 40 -f 7902.1328201 -n -l 40 -f 16.3515978313 -n -l 200 -f 830.60939516 -n -l 200 -f 415.30469758 -n -l 40 -f 739.988845423 -n -l 80 -f 783.990871963 -n -l 80 -f 739.988845423 -n -l 200 -f 415.30469758 -n -l 200 -f 659.255113826 -n -l 200 -f 622.253967444 -n -l 400 -f 554.365261954 -n -l 1320 -f 415.30469758 -n -l 40 -f 4698.63628668
}


############# Advanced settings ###########################################################
#optional - do not need to be set

copyappdata="yes"         # set to copy appdata for specific containers to backup server

dockersource1="/mnt/remotes/prime/appdata/EmbyServer/data/"    # set first appdata source directory to sync
dockerbackup1="/mnt/user/appdata/EmbyServer/data/"             # destination location for above

# remove '#' and fill in to add locations below for more directories to sync
# also remove '#' for each new location under function 'syncdata' in basic functions
# dockersource2="/mnt/remotes/prime/TV Shows/"  # set second appdata source directory to sync
# dockerbackup2="/mnt/user/TV Shows/"           # destination location for above
# dockersource3="xxxxxxxxxxxxxxxx"              # set third appdata source directory to sync
# dockerbackup3="xxxxxxxxxxxxxxxx"              # destination location for above
# dockersource4="xxxxxxxxxxxxxxxx"              # set fourth appdata source directory to sync
# dockerbackup4="xxxxxxxxxxxxxxxx"              # destination location for above


############# Advanced functions ##############################################################

copyappdata () {
if [ -d $remotelocation/containerstart ] ; then
rm -r $remotelocation/containerstart # delete flag
# the locations below will be synced (these are defined in advanced settings)
rsync -avhP --delete   "$dockerbackup1" "$dockersource1" # first appdata to sync

# rsync -avhP --delete "$dockersource2" "$dockerbackup2"    # second appdata to sync
# rsync -avhP --delete "$dockersource3" "$dockerbackup3"   # third appdata to sync
# rsync -avhP --delete "$dockersource4" "$dockerbackup4"  # forth appdata to sync
# add additional locations if needed
fi
}

startcontainers () {
if [ "$containerstart" == "yes"  ] ; then
docker start EmbyServerBeta # change container to startup to suit
docker start swag
# add other conatiners to suit
fi
}

############# Start process ###################################################################

# check if main server started process by making start directory, then start sync
sleep 30   #waits to be sure unassigned devices has made connection to source server
if [ -d $remotelocation/start ] ; then
shutdownstatus
syncdata
copyappdata
completiontune
startcontainers
endandshutdown

else
echo "Source server didn't request sync job"
echo "Normal start of backup server so exiting script"

fi
