# backup_server_scripts

These scripts are made to be run on 2 Unraid servers. One on the source server the others on the backup server.
Their purpose is to automatically backup selected data from a source server to a backup server. The backup server will be automatically powered on and started from the script running on the source server.
Once the backup server has started it will sync the user selected shares/folders from the source server to the backup server.

Once the sync has been completed various actions can be done.

1. The backup server can be shut down after the sync has completed. This is useful if you want to have a backup server only running when needed for the backup job. This saves both electricity and wear and tear on the backup server's hard disks.

2. The source server can be shutdown after the sync has completed. 
After the source server has shut down the backup server if enabled can start a docker container. This is useful for 2 media servers for example running Emby. For example the media can be synced from the source to the backup server. Also the Emby appdata or database can be synced from source server to backup server. Then the synced Emby container automatically started on the Backup server 

These should be run using Unraid's User Scripts plugin.

There are 3 scripts
 from the source server on which the data is kept that you want to sync to a second (backup) server. This script will start the backup server when it is powered off and set various flags the backup server will see when it has started and then the backup will act accordingly.
