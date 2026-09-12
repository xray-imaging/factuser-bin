#!/bin/bash

# Define variables
TAB_NAME="tomoScan IOC"
REMOTE_USER="factuser"
REMOTE_HOST="orco"
APP_NAME="tomoScanApp"

# Open a new tab in gnome-terminal, SSH into orco, and stop the tomoScan IOC
gnome-terminal --tab --title="$TAB_NAME" -- bash -c "
    ssh -t ${REMOTE_USER}@${REMOTE_HOST} '
        kill_IOC.sh ${APP_NAME}
    ';
"
