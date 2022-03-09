# backup_server_scripts

These scripts are made to be run on 2 Unraid servers. One on the source server the other two on the backup server.
Their purpose is to automatically backup selected data and/or appdata from a source server to a backup server. The backup server will be automatically powered on and started from the script running on the source server.
Once the backup server has started it will sync the user selected shares/folders from the source server to the backup server.

Once the sync has been completed various actions can be done.

1. Backup only. -- The backup server can be automatically shut down after the sync has completed. This is useful if you want to have a backup server only running when needed for the backup job. This saves both electricity and wear and tear on the backup server's hard disks.

2. Switch server. -- The source server can be shutdown after the sync has completed leaving only the backup server running.
Both data and container appdata (from selected containers) is synced from the source server to the backup server. Then selected containers are started on the backup server taking over the duties of the (now shutdown) source server. This is useful for 2 media servers for example running Emby. For example the media can be synced from the source to the backup server. Also the Emby appdata or database can be synced from source server to backup server. Then the synced Emby container is automatically started on the Backup server. So all watch history ect is transfered from one server to the other.

3. Switch server back. The source server can be automatically started at a later time. Then the appdata and/or main data synced back to the source server. The backup server is then shutdown and the containers (used in '2. switch server') are started back up on the source server. So again with a media server running for example emby, the watch history etc is synced back to the main server.

These scripts should be run using Unraid's User Scripts plugin. 

There are 3 scripts
1. source server backup script.sh  - This is the only script used on the source server. All variables are set in this script for both source and backup server.
   This script is creates a config file that is used by all 3 scripts so to make configuration easier. This script can be set to run on a cron schedule. When run 
   it is this script which will start the backup/destination server automatically then run the backup as selected in the variables in this script.

2. destination server backup script.sh  - This script is run on the destination server. Being set to autorun on the start of the destination/backup server. 
   However it will only execute if the destination server has been started by the script on the source server. If the backup/destination server had been manually
   powered on / started then the script will not run. When the script executes it will sync the data and or appdata that was set in the variables in the source 
   server script.  - only one variable needs setting in this script -- that is to specify the source servers ip address.
   
3. start source server - destination server script.  - This script is also run on the destination server. This script has no variables that need to be set.
   This script should be set to run at the time you want the source server to be autostarted. It will then do this and sync the data and or appdata back to the
   source server.
   
   For these scripts to work you must create ssh keys on the destination server and import them to the source server so the destination server can make an
   ssh connection to the source server.
   
   A video will be released very soon showing in detail how to configure and use these scripts. A link will be put here soon.
   
