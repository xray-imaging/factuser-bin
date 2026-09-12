#!/bin/bash

# Define variables
TAB_NAME="tomoScan py server"
REMOTE_USER="factuser"
REMOTE_HOST="orco"
SCRIPT_NAME="start_tomoscan.py"

# Open a new tab in gnome-terminal, SSH into orco, and stop the tomoscan python server
gnome-terminal --tab --title="$TAB_NAME" -- bash -c "
    ssh -t ${REMOTE_USER}@${REMOTE_HOST} '
        kill_server.sh ${SCRIPT_NAME}
    ';
"
