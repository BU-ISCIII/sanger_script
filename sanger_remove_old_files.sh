#!/bin/bash
########## Configuration settings  ########
source sanger_configuration


date=`date +%Y-%m-%d`


echo "Executing script for Deleting old shared files"
echo "Date is : $date"
###  delete shared folder older than the days in RETENTION_TIME ###
echo "$SAMBA_TRANSFERED_FOLDERS"
echo "$REMOTE_SAMBA_SHARED_FOLDER"
mkdir -p tmp
find $SAMBA_TRANSFERED_FOLDERS -type f -mmin $RETENTION_TIME | xargs -I % echo "ssh $REMOTE_USER@$REMOTE_SAMBA_SERVER 'cd $REMOTE_SAMBA_SHARED_FOLDER; name=\$(basename %) ;rm -rf \$name; cd -'" > tmp/tmp.sh
bash tmp/tmp.sh
rm -rf tmp
find $SAMBA_TRANSFERED_FOLDERS -type f -mmin $RETENTION_TIME -exec rm -- '{}' \;

echo "removed old files script completed"
