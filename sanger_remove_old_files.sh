#!/bin/bash
########## Configuration settings  ########
source /opt/sanger_script/sanger_configuration
export PATH="/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin"

date=`date +%Y-%m-%d`
tmpfile="/opt/sanger_script/tmp/tmp.sh"

echo "Executing script for Deleting old shared files"
echo "Date is : $date"

###  delete shared folder older than the days in RETENTION_TIME ###
echo "$SAMBA_TRANSFERED_FOLDERS"
echo "$REMOTE_SAMBA_SHARED_FOLDER"
mkdir -p $(dirname $tmpfile)
find $SAMBA_TRANSFERED_FOLDERS -type f -mtime $RETENTION_TIME | xargs -I % echo "ssh $REMOTE_USER@$REMOTE_SAMBA_SERVER 'cd $REMOTE_SAMBA_SHARED_FOLDER; name=\$(basename %) ;rm -rf \$name; cd -'" > $tmpfile
find $SAMBA_TRANSFERED_FOLDERS -type f -mtime $RETENTION_TIME | xargs -I % echo "ssh $REMOTE_USER@$REMOTE_SAMBA_SERVER 'cd $REMOTE_SAMBA_SHARE_DIR; name=\$(basename %) ;rm -rf \${name}.conf;sed -i \"/\${name}.conf/ d\" includes.conf  ;cd -'" >> $tmpfile
bash $tmpfile
rm -rf $tmpfile
find $SAMBA_TRANSFERED_FOLDERS -type f -mtime $RETENTION_TIME -exec rm -- '{}' \;

echo "Restarting samba service"
## samba service restart
ssh $REMOTE_USER@$REMOTE_SAMBA_SERVER 'sudo service smb restart'

echo "removed old files script completed"
