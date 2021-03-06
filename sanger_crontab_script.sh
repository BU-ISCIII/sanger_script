#!/bin/bash
########## Configuration settings  ########
#set -x
source /opt/sanger_script/sanger_configuration
export PATH="/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin"

time=$(date +%T-%m%d%y)
echo "Initiating crontab - $time"

proc_file="$PROCESSED_FILE_DIRECTORY/$PROCESSED_FILE_NAME"
echo "$proc_file"
if [ ! -f $proc_file ]; then
	touch $proc_file
	echo "Created $proc_file"
fi


files=$(ls -t1 $PATH_SANGER_FOLDER/*.txt)

if [[ $files == ''  ]]; then
	echo "There are no files to process on folder $INPUT_DIRECTORY"
	echo "Exiting the script "
	echo "------------------------------------------"
	exit 1
fi

while read -r line ; do
	if [ ! -d tmp ]; then
	    mkdir -p tmp
	fi
	bn_file=$(basename $line)
	if ! grep -q $bn_file "$proc_file"; then
		echo "echo line :$line - $bn_file"
		path_folder=$(echo "$bn_file" | cut -d "." -f 1)
		if [[ ! -d $PATH_SANGER_FOLDER/$path_folder ]];then
			echo "Run folder $path_folder missing. Run not being processed..."
		    continue
		fi
		time=$(date +%T-%m%d%y)
		echo "Executing script $time: $SANGER_SCRIPT -f $PATH_SANGER_FOLDER/$bn_file -r $PATH_SANGER_FOLDER/$path_folder  -o $SHARED_FOLDER"
		$SANGER_SCRIPT -f $PATH_SANGER_FOLDER/$bn_file -r $PATH_SANGER_FOLDER/$path_folder  -o $REMOTE_SAMBA_SHARED_FOLDER
		# include the file into procesed file
		error_code=$?
		echo "Error code: $error_code"
		if [ $error_code == 0 ]; then
			echo "$bn_file" >> $proc_file
		else
  			echo -e "Something unexpected went wrong in sanger script" | sendmail -f "bioinformatica@isciii.es" -t "bioinformatica@isciii.es" -v "soporte.hpc@isciii.es"
		fi

	else
		echo "Run already processed."
	fi

	# Delete temporary folder
	rm -rf $PROCESSED_FILE_DIRECTORY/tmp

done <<<"$files"
# Restart samba
echo "Restarting Samba service"
# Ubuntu
#ssh $REMOTE_USER@$REMOTE_SAMBA_SERVER 'sudo /usr/sbin/service smbd restart'
# CestOS
#ssh -q $REMOTE_USER@$REMOTE_SAMBA_SERVER 'sudo /usr/sbin/service smb restart'

if [ $? -eq 0 ]; then
	echo "Samba restarting succesfully"
else
	echo -e "Something unexpected went wrong in samba restarting" | sendmail -f "bioinformatica@isciii.es" -t "bioinformatica@isciii.es"
fi

time=$(date +%T-%m%d%y)
echo "End crontab - $time"
