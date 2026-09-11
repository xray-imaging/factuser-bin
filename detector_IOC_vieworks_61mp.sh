#!/bin/bash

# Define variables
TAB_NAME="19-BM Detector IOC"
REMOTE_USER="factuser"
REMOTE_HOST="orco"
WORK_DIR="/net/s19dserv/xorApps/epics/synApps_6_3/ioc/19bmVieworks/iocBoot/ioc19bmVieworks/softioc/"
EGRABBER="/opt/euresys/egrabber/shell/setup_gentl_paths.sh"

# Open a new tab in gnome-terminal, SSH into orco, restart the Vieworks IOC.
#
# The eGrabber environment must be sourced first.  softioc/run does this, but
# 19bmVieworks.pl sets IOC_CMD to the IOC binary directly and so bypasses it;
# over ssh GENICAM_GENTL64_PATH is unset, and without it the ADEuresys driver
# cannot load the GenTL producer and the camera is never found.
#
# '.pl run' keeps the IOC in the FOREGROUND of this tab so its console is
# visible.  Closing the tab, or losing the network, therefore stops the IOC.
# Use '.pl start' instead if you want it detached in a screen session.
gnome-terminal --tab --title="$TAB_NAME" -- bash -c "
    ssh -t ${REMOTE_USER}@${REMOTE_HOST} '
        [ -r ${EGRABBER} ] && . ${EGRABBER}
        cd ${WORK_DIR}
        ./19bmVieworks.pl stop
        sleep 2
        ./19bmVieworks.pl run
    ';
"
