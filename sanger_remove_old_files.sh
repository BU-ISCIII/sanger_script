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

# Remove user shared folders
#find $SAMBA_TRANSFERED_FOLDERS -type f -mtime $RETENTION_TIME_SHARED_FOLDERS | xargs -I % echo "ssh $REMOTE_USER@$REMOTE_SAMBA_SERVER 'cd $REMOTE_SAMBA_SHARED_FOLDER; name=\$(basename %) ;rm -rf \$name; cd -'" > $tmpfile
echo "Searching $SAMBA_TRANSFERED_FOLDERS"
echo "Deleting data for projects older than $RETENTION_TIME_SHARED_FOLDERS:"
find $SAMBA_TRANSFERED_FOLDERS -type f -mtime +$RETENTION_TIME_SHARED_FOLDERS
find $SAMBA_TRANSFERED_FOLDERS -type f -mtime +$RETENTION_TIME_SHARED_FOLDERS | xargs -I % echo "ssh -q $REMOTE_USER@$REMOTE_SAMBA_SERVER 'cd $REMOTE_SAMBA_SHARED_FOLDER; name=\$(basename %) ;rm -rf \$name; cd -'" > $tmpfile

# Remove already processed runs in sanger folder
find $SAMBA_TRANSFERED_FOLDERS -mtime +$RETENTION_TIME_SHARED_FOLDERS | xargs -I % echo "ssh -q $REMOTE_USER@$REMOTE_SAMBA_SERVER 'cd $REMOTE_SAMBA_SANGER_FOLDER; name=\$(basename % | cut -d "_" -f 2) ;rm -rf \$name*; cd -'" >> $tmpfile
#find $SAMBA_TRANSFERED_FOLDERS -not -name "includes.conf" -mtime +$RETENTION_TIME_SHARED_FOLDERS | xargs -I % echo "ssh -q $REMOTE_USER@$REMOTE_SAMBA_SERVER 'cd $REMOTE_SAMBA_SANGER_FOLDER; name=\$(basename % | cut -d "_" -f 2) ;rm -rf \$name*; cd -'" >> $tmpfile

# Remove configuration files for sharing.
echo "Deleting sharing for projects older than $RETENTION_TIME_CONF_FILES:"
find $SAMBA_TRANSFERED_FOLDERS -type f -mtime +$RETENTION_TIME_CONF_FILES
find $SAMBA_TRANSFERED_FOLDERS -type f -mtime +$RETENTION_TIME_CONF_FILES | xargs -I % echo "ssh -q $REMOTE_USER@$REMOTE_SAMBA_SERVER 'cd $REMOTE_SAMBA_SHARE_DIR; name=\$(basename %) ;rm -rf \${name}.conf;sed -i \"/\${name}.conf/ d\" includes.conf  ;cd -'" >> $tmpfile

# Execute commands
bash $tmpfile

# Remove script
rm -rf $tmpfile

## Remove transfered folder files in client.
find $SAMBA_TRANSFERED_FOLDERS -type f -mtime +$RETENTION_TIME_SHARED_FOLDERS -exec rm -f '{}' \;
#find $SAMBA_TRANSFERED_FOLDERS -type f -cmin $RETENTION_TIME_SHARED_FOLDERS -exec rm -- '{}' \;

echo "Restarting samba service"
## samba service restart
#Centos
ssh -q $REMOTE_USER@$REMOTE_SAMBA_SERVER 'sudo service smb restart'
#Ubuntu
#ssh $REMOTE_USER@$REMOTE_SAMBA_SERVER 'sudo service smbd restart'


echo "removed old files script completed"
