#!/bin/bash
####################################################
#### CONFIGURATION FILES ON LOCAL SERVER
####################################################
#
# Location of the sanger script
SANGER_SCRIPT="/home/smonzon/Documents/desarrollo/sanger_script/sanger_script.sh"
#
# Directory where the processed items will be located
PROCESSED_FILE_DIRECTORY="/home/smonzon/Documents/desarrollo/sanger_script"
#
# File name for the processed runs
PROCESSED_FILE_NAME="run_processed"
#
# Path of the mounted samba folder
PATH_SANGER_FOLDER="/processing_Data/bioinfoshare/sanger_seq"
#
# TEMPORARY DIRECTORY WHERE SHARED CONFIGURATION FILE ARE SAVED BEFORE COPYING TO REMOTE SERVER
TMP_SAMBA_SHARE_DIR=/home/smonzon/Documents/desarrollo/sanger_script/tmp/shares
#
# LOCATION OF THE TEMPLATE FILE FOR CONFIG SAMBA SHARED FOLDERS
SAMBA_SHARE_TEMPLATE=/home/smonzon/Documents/desarrollo/sanger_script/template.conf
#
# FOLDER TO KEEP TRACK OF THE SHARED FOLDER FOR REMOVING AFTER RETENTION PERIOD
SAMBA_TRANSFERED_FOLDERS=/home/smonzon/Documents/desarrollo/sanger_script/transfered_folder/
#
# LOCATION OF THE TEMPLATE FILE FOR SENDING EMAILS
TEMPLATE_EMAIL=/home/smonzon/Documents/desarrollo/sanger_script/template_mail.htm
#

####################################################
#### CONFIGURATION FILES ON REMOTE SERVER
####################################################
#
# DIRECTORY ON THE REMOTE SERVER, WHERE THE SHARED FILES WILL BE COPY
REMOTE_SAMBA_SHARE_DIR=/etc/samba/shares
# 
# Remote Folder where to put the shared files
REMOTE_SAMBA_SHARED_FOLDER="/processing_Data/sanger_seq_users"
#
# USER USED FOR REMOTE LOGIN
REMOTE_USER="root"
#
# REMOTE SERVER WHERE TO COPY THE OUTPUT FILES
REMOTE_SAMBA_SERVER="barbarroja"

####################################################
########## Configuration settings for deleting old folders ########
####################################################
#
RETENTION_TIME="+1"
#
