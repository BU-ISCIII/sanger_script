#!/bin/bash
########## Configuration settings  ########
source sanger_configuration


date=`date +%Y-%m-%d`


echo "Executing script for Deleting old shared files"
echo "Date is : $date"
###  delete shared folder older than the days in RETENTION_TIME ###
echo "$SAMBA_TRANSFERED_FOLDERS"
find $SAMBA_TRANSFERED_FOLDERS* -type f  -mmin $RETENTION_TIME -exec ssh $REMOTE_USER@$REMOTE_SAMBA_SERVER "cd $REMOTE_SHARED_FOLDER; rm -rf' -- '{}" \; -exec rm -- '{}' \;

echo "removed old files script completed"
