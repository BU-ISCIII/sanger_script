#!/bin/bash

# Exit immediately if a pipeline, which may consist of a single simple command, a list,
#or a compound command returns a non-zero status: If errors are not handled by user
set -e
# Treat unset variables and parameters other than the special parameters ‘@’ or ‘*’ as an error when performing parameter expansion.

#Print everything as if it were executed, after substitution and expansion is applied: Debug|log option
#set -x

#=============================================================
# HEADER
#=============================================================

#INSTITUTION:ISCIII
#CENTRE:BU-ISCIII
#AUTHOR: Sara Monzon (smonzon@isciii.es)
#	 Luis Chapado (lchapado@externos.isciii.es)
VERSION=0.0.2
#CREATED: 23 April 2019
#
#ACKNOWLEDGE: longops2getops.sh: https://gist.github.com/adamhotep/895cebf290e95e613c006afbffef09d7
#
#DESCRIPTION: Reshare projects script reshares a already splitted set of users sequences from a specific run.
#
#
#================================================================
# END_OF_HEADER
#================================================================

#SHORT USAGE RULES
#LONG USAGE FUNCTION
usage() {
	cat << EOF
This script reshares sequences splitted in different folders for different users, sharing it with samba shares.
usage : $0 <-f file> <-r folder> -o <output_dir> [options]
	Mandatory input data:
	-f | Path to reshare info file.ej. /Path/to/reshare.txt
	-v | version
	-h | display usage message
example: ./reshare_projects.sh -f ../sanger/reshare.txt
EOF
}

#================================================================
# OPTION_PROCESSING
#================================================================
#Make sure the script is executed with arguments
if [ $# = 0 ]; then
	echo "NO ARGUMENTS SUPPLIED"
	usage >&2
	exit 1
fi

# Error handling
error(){
  local parent_lineno="$1"
  local script="$2"
  local message="$3"
  local code="${4:-1}"

	RED='\033[0;31m'
	NC='\033[0m'

  if [[ -n "$message" ]] ; then
    echo -e "\n---------------------------------------\n"
    echo -e "${RED}ERROR${NC} in Script $script on or near line ${parent_lineno}; exiting with status ${code}"
    echo -e "MESSAGE:\n"
    echo -e "$message"
    echo -e "\n---------------------------------------\n"
  else
    echo -e "\n---------------------------------------\n"
    echo -e "${RED}ERROR${NC} in Script $script on or near line ${parent_lineno}; exiting with status ${code}"
    echo -e "\n---------------------------------------\n"
  fi

  #Mail admins
  echo -e "Subject:Sanger script error\nError in Script $script on or near line $parent_lineno: ${message}" | sendmail -f "bioinformatica@isciii.es" -t "bioinformatica@isciii.es"

  exit "${code}"
}

mail_user_error(){
	local parent_lineno="$1"
	local message="$2"

	RED='\033[0;31m'
	NC='\033[0m'

	content="ERROR on or near line ${parent_lineno}: \
			MESSAGE:\n \
			$message"
# 	mkdir -p tmp
	sed "s/##ERROR##/$content/g" ./template_error_sanger.htm > tmp/error_mail.htm
	sendmail -t < tmp/error_mail.htm || error ${LINENO} $(basename $0) "Sending error mail error."
}

#DECLARE FLAGS AND VARIABLES
script_dir=$(dirname $(readlink -f $0))
cwd="$(pwd)"
is_verbose=false
########## Configuration settings  ########
source $script_dir/sanger_configuration
export PATH="/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin"

#SET COLORS

YELLOW='\033[0;33m'
WHITE='\033[0;37m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

#PARSE VARIABLE ARGUMENTS WITH getops
#common example with letters, for long options check longopts2getopts.sh
options=":f:r:o:Vvh"
while getopts $options opt; do
	case $opt in
		f )
			reshare_file=$OPTARG
			;;
		V )
			is_verbose=true
			log_file="/dev/stdout"
			;;
		h )
		  	usage
		  	exit 1
		  	;;
		v )
		  	echo $VERSION
		  	exit 1
		  	;;
		\?)
			echo "Invalid Option: -$OPTARG" 1>&2
			usage
			exit 1
			;;
		: )
      		echo "Option -$OPTARG requires an argument." >&2
      		exit 1
      		;;
      	* )
			echo "Unimplemented option: -$OPTARG" >&2;
			exit 1
			;;

	esac
done
shift $((OPTIND-1))

#================================================================
# MAIN_BODY
#================================================================

function join_by { local IFS="$1"; shift; echo "$*"; }


printf "\n\n%s"
printf "${YELLOW}------------------${NC}\n"
printf "%s"
printf "${YELLOW}Starting Resharing sanger script version:${VERSION}${NC}\n"
printf "%s"
printf "${YELLOW}------------------${NC}\n\n"


date=`date +%Y%m%d`

echo "Fetching samba includes file from filesystem file server."
## Create samba shares.
if [ ! -d $TMP_SAMBA_SHARE_DIR ]; then
    mkdir -p $TMP_SAMBA_SHARE_DIR
fi
scp -q $REMOTE_USER@$REMOTE_SAMBA_SERVER:$REMOTE_SAMBA_SHARE_DIR/includes.conf $TMP_SAMBA_SHARE_DIR/ || error ${LINENO} $(basename $0) "Failed fetching of samba includes file"

while read -r line ;do
	run=$(echo $line | cut -d "," -f 1 )
    emails=$(echo $line | cut -d "," -f 2 | sed "s/:/,/g")
    user=$(echo $line | cut -d "," -f 2 | sed "s/@externos\.isciii\.es//g" | sed "s/@isciii\.es//g")
    # print an error in case the comment column contains more than 1 username and it is not sepparated by ":" but space
    if  [[ $users == *" "* ]] ; then
        mail_user_error ${LINENO} "Unable to process the sample on the line $line.There are spaces in comment field"
        error ${LINENO} $(basename $0) "Unable to process the sample on the line $line.There are spaces in comment field"
        continue
    fi
	## Change to mtime if needed!
	echo "find $SAMBA_TRANSFERED_FOLDERS -mtime +$RETENTION_TIME_CONF_FILES -mtime -$RETENTION_TIME_SHARED_FOLDERS | grep -P \".*$run.*$user.*\""
	echo "number_folders=$(find $SAMBA_TRANSFERED_FOLDERS -mtime +$RETENTION_TIME_CONF_FILES -mtime -$RETENTION_TIME_SHARED_FOLDERS | grep -P \".*$run.*$user.*\" | wc -l)"
	number_folders=$(find $SAMBA_TRANSFERED_FOLDERS -mtime +$RETENTION_TIME_CONF_FILES -mtime -$RETENTION_TIME_SHARED_FOLDERS | grep -P ".*$run.*$user.*" | wc -l)
    if [ $number_folders -gt 0 ]; then
		folders=$(find $SAMBA_TRANSFERED_FOLDERS -mtime +$RETENTION_TIME_CONF_FILES -mtime -$RETENTION_TIME_SHARED_FOLDERS | grep -P ".*$run.*$user.*")
		echo $folders
		for folder in $folders;
		do
			folder=$(basename $folder)
			echo "Folder $folder is accesible for users: $user"
			echo "sed \"s/##FOLDER##/$folder/g\" $SAMBA_SHARE_TEMPLATE | sed \"s/##USERS##/$user/g\""

			sed "s/##FOLDER##/$folder/g" $SAMBA_SHARE_TEMPLATE | sed "s/##USERS##/$user/g" > $TMP_SAMBA_SHARE_DIR/$folder".conf"
			echo "include = $REMOTE_SAMBA_SHARE_DIR/${folder}.conf" >> $TMP_SAMBA_SHARE_DIR/includes.conf
			echo -e "$folder\t$date\t$users" >> $script_dir/logs/reshare_samba_folders
    		touch $SAMBA_TRANSFERED_FOLDERS/$folder

			echo "Sending email"
			sed "s/##FOLDER##/$folder/g" $TEMPLATE_EMAIL | sed "s/##USERS##/$user/g" | sed "s/##MAILS##/$emails/g" | sed "s/##RUN_NAME##/$run_name/g"> tmp/mail.tmp
			## Send mail to users
			sendmail -t < tmp/mail.tmp

			echo "mail sended"

			echo "Deleting mail temp file"
		done
	else
        mail_user_error ${LINENO} "Unable to process the run on the line $line. The run is older than the maximum time for storage, or the run is already been shared at the moment."
        error ${LINENO} $(basename $0) "Unable to process the sample on the line $line.The run is older than the maximum time for storage, or the run is already been shared at the moment."
        continue
	fi

done < "$reshare_file"

echo "Copying samba shares configuration to remote filesystem server"
rsync -rlv -e "ssh -q" $TMP_SAMBA_SHARE_DIR/ $REMOTE_USER@$REMOTE_SAMBA_SERVER:$REMOTE_SAMBA_SHARE_DIR/ || error ${LINENO} $(basename $0) "Shared samba config files couldn't be copied to remote filesystem server."
echo "Deleting temporal local share folder"
rm -rf tmp/*
echo "Restarting samba service"
## samba service restart
# Ubuntu
#ssh $REMOTE_USER@$REMOTE_SAMBA_SERVER 'sudo service smbd restart'
#Centos
ssh -q $REMOTE_USER@$REMOTE_SAMBA_SERVER 'sudo service smb restart'

echo "File $reshare_file process has been completed"
