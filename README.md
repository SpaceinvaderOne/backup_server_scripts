# backup_server_scripts

These scripts are to run on 2 Unraid servers. One the source server the other the backup server.

Backup-- run on source server

This should be run using Unraids user scripts plugin from the source server on which the data is kept that you want to sync to a second (backup) server.
This script will start the backup server when it is powered off and set various flags the backup server will see when it has started and then the backup will act accordingly
