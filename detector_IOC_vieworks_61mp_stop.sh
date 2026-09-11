#!/bin/bash

# Define variables
TAB_NAME="19-BM Detector IOC"
REMOTE_USER="factuser"
REMOTE_HOST="orco"
WORK_DIR="/net/s19dserv/xorApps/epics/synApps_6_3/ioc/19bmVieworks/iocBoot/ioc19bmVieworks/softioc/"

# Open a new tab in gnome-terminal, SSH into orco, stop the Vieworks IOC.
# No eGrabber environment is needed here -- nothing is being started.
# Note that '.pl stop' kills the IOC process outright rather than shutting it
# down from the iocsh prompt.
gnome-terminal --tab --title="$TAB_NAME" -- bash -c "
    ssh -t ${REMOTE_USER}@${REMOTE_HOST} '
        cd ${WORK_DIR}
        ./19bmVieworks.pl stop
    ';
"
