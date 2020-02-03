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
#DESCRIPTION: Sanger_script split the data sequencing to allow each user
#            get access of the sample information
#
#
#================================================================
# END_OF_HEADER
#================================================================

#SHORT USAGE RULES
#LONG USAGE FUNCTION
usage() {
	cat << EOF
This script reads sanger sequencing data and splits results into different folders for different users, sharing it with samba shares.
usage : $0 <-f file> <-r folder> -o <output_dir> [options]
	Mandatory input data:
	-f | Path to sanger run configuration file.ej. /Path/to/GN18-176A.txt
	-r | Path to sanger run folder. ej. /Path/to/GN18-176A
	-o | Output on remote dir. ej. /path/to/sanger_seq_users
	-v | version
	-h | display usage message
example: ./sanger_script.sh -f ../sanger_seq/GN18-176A.txt -r ../sanger_seq/GN18-176A -o ../sanger_seq_users/
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
# 	mkdir -p $PROCESSED_FILE_DIRECTORY/tmp
	sed "s/##ERROR##/$content/g" $PROCESSED_FILE_DIRECTORY/template_error_sanger.htm > $PROCESSED_FILE_DIRECTORY/tmp/error_mail.htm
	sendmail -t < $PROCESSED_FILE_DIRECTORY/tmp/error_mail.htm || error ${LINENO} $(basename $0) "Sending error mail error."
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
			sanger_file=$OPTARG
			;;
		r )
			run_folder=$OPTARG
			;;
		o )
			remote_ouput_dir=$OPTARG
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
printf "${YELLOW}Starting Sanger Script version:${VERSION}${NC}\n"
printf "%s"
printf "${YELLOW}------------------${NC}\n\n"


date=`date +%Y%m%d`

run_name=$(basename $sanger_file | sed 's/.txt//g')
if [ ! -f "$sanger_file" ] ; then
    echo "$0: File '${sanger_file}' not found "
    exit 1
fi
# remove the heading lines from file and replace tabs by commas
tmp=$(tail -n+6 "$sanger_file")
var_file="${tmp//$'\t'/,}"

## Read txt file line by line and create folders per user, copying the files in each respective folder.
while read -r line ;do
	# Ignore empty lines
	line=${line//[$'\r\n']}
	if [[ -z $line ]] ; then
		echo "Remove empty line"
		continue
	fi
    comment=$(echo $line | cut -d "," -f 3 )
    # remove the space at the end if exists
    comment=$(sed 's/ *$//' <<<$comment)
    # print an error in case the comment column contains more than 1 username and it is not sepparated by ":" but space
    if  [[ $comment == *" "* ]] ; then
        mail_user_error ${LINENO} "Unable to process the sample on the line $line.There are spaces in comment field"
        error ${LINENO} $(basename $0) "Unable to process the sample on the line $line.There are spaces in comment field"
        continue
    fi
    emails=$(echo $comment | sed 's/:/,/g')
	IFS=',' read -ra mails <<< $emails

	## Validate emails
	for mail in ${mails[@]}
	do
		i=$mail
		IFS="@" read -ra domain <<< $mail
		if [ "${domain[1]}" != "isciii.es" ] && [ "${domain[1]}" != "externos.isciii.es" ];then
			mail_user_error ${LINENO} "Emails provided in line $line are not an isciii domain (isciii.es or externos.isciii.es)"
			error ${LINENO} $(basename $0) "Emails provided in line $line are not an isciii domain (isciii.es or externos.isciii.es)"
		fi
	done

    user_names=$(echo $comment | sed 's/@isciii.es//g' | sed 's/@externos.isciii.es//g')

    IFS=':' read -r -a users <<< "$user_names"
    allowed_users=$(join_by _ "${users[@]}")

    well=$(echo $line | cut -d "," -f 1)
    sample_name=$(echo $line | cut -d "," -f 2)

    folder_name=$PROCESSED_FILE_DIRECTORY/tmp/$date"_"$run_name"_"$allowed_users
    if [ ! -d $folder_name ]; then
        mkdir -p $folder_name
        echo "Creating directory for $date"_"$run_name"_"$allowed_users"
        echo $emails > $folder_name/user_allowed.txt
    fi

	echo "Copying files for $sample_name from $run_folder to temporary user share folder"
    rsync -rlv $run_folder/*"_"$well"_"$sample_name* $folder_name || error ${LINENO} $(basename $0) "Sequencing files couldn't be copied to tmp folder"

    if [ ! -d $SAMBA_TRANSFERED_FOLDERS ]; then
		mkdir -p $SAMBA_TRANSFERED_FOLDERS
    fi
    touch $SAMBA_TRANSFERED_FOLDERS/$date"_"$run_name"_"$allowed_users

done <<< "$var_file"

## Copy created shared folders to remote file system server
rsync -vr -e "ssh -q" $PROCESSED_FILE_DIRECTORY/tmp/ $REMOTE_USER@$REMOTE_SAMBA_SERVER:$remote_ouput_dir/ || error ${LINENO} $(basename $0) "Shared folders couldn't be copied to remote filesystem server."

## Create samba shares.
if [ ! -d $TMP_SAMBA_SHARE_DIR ]; then
    mkdir -p $TMP_SAMBA_SHARE_DIR
fi

# fetch the remote Samba includes file
echo "Fetching samba includes file from filesystem file server."
scp -q $REMOTE_USER@$REMOTE_SAMBA_SERVER:$REMOTE_SAMBA_SHARE_DIR/includes.conf $TMP_SAMBA_SHARE_DIR || error ${LINENO} $(basename $0) "Failed fetching of samba includes file"

for folder in $(ls $PROCESSED_FILE_DIRECTORY/tmp | grep $run_name);do
	echo "Processing folder: $folder"
	users=$(echo $folder | cut -d "_" -f3- | sed 's/_/,/g')
	echo "Folder $folder is accesible for users: $users"
	sed "s/##FOLDER##/$folder/g" $SAMBA_SHARE_TEMPLATE | sed "s/##USERS##/$users/g" > $TMP_SAMBA_SHARE_DIR/$folder".conf"
	echo "include = $REMOTE_SAMBA_SHARE_DIR/${folder}.conf" >> $TMP_SAMBA_SHARE_DIR/includes.conf
	emails=$(cat $PROCESSED_FILE_DIRECTORY/tmp/$folder/user_allowed.txt)
	number_files=$( ls -t1 $PROCESSED_FILE_DIRECTORY/tmp/$folder | wc -l )
	echo -e "$folder\t$date\t$users\t$number_files" >> $script_dir/logs/samba_folders
done

# Copy shared configuration files to remote
echo "Copying samba shares configuration to remote filesystem server"
rsync -rlv -e "ssh -q" $TMP_SAMBA_SHARE_DIR/ $REMOTE_USER@$REMOTE_SAMBA_SERVER:$REMOTE_SAMBA_SHARE_DIR/ || error ${LINENO} $(basename $0) "Shared samba config files couldn't be copied to remote filesystem server."

#echo "Restarting samba service"
## samba service restart
ssh $REMOTE_USER@$REMOTE_SAMBA_SERVER 'sudo /usr/sbin/service smbd restart'


## Email sending
for folder in $(ls tmp | grep $run_name);do
	echo "Sending email"
	sed "s/##FOLDER##/$folder/g" $TEMPLATE_EMAIL | sed "s/##USERS##/$users/g" | sed "s/##MAILS##/$emails/g" | sed "s/##RUN_NAME##/$run_name/g"> tmp/mail.tmp
	## Send mail to users
	sendmail -t < tmp/mail.tmp
	echo "mail sended"
	echo "Deleting mail temp file"
	rm $PROCESSED_FILE_DIRECTORY/tmp/mail.tmp
done
echo "File $sanger_file process has been completed"
