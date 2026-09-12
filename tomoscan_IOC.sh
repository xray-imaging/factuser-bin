#!/bin/bash

# Define variables
TAB_NAME="tomoScan IOC"
REMOTE_USER="factuser"
REMOTE_HOST="orco"
APP_NAME="tomoScanApp"
WORK_DIR="/home/beams/FACTUSER/epics/synApps/support/tomoscan/iocBoot/iocTomoScan_19BM/"

# Open a new tab in gnome-terminal, SSH into orco, and start the tomoScan IOC
gnome-terminal --tab --title="$TAB_NAME" -- bash -c "
    ssh -t ${REMOTE_USER}@${REMOTE_HOST} '
        kill_IOC.sh ${APP_NAME}
        cd ${WORK_DIR}
        ./start_IOC;
    ';
"
