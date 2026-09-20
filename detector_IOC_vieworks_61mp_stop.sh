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
BODY="
        cd ${WORK_DIR}
        ./19bmVieworks.pl stop
"

# Run locally when this script is already on the target host.  orco's own
# hostname resolves to 10.54.113.19 while its only interface is 10.54.129.13,
# so "ssh orco" from orco fails with "connect ... Invalid argument".
if [ "$(hostname -s)" = "$REMOTE_HOST" ]; then
    CMD="$BODY"
else
    CMD="ssh -t ${REMOTE_USER}@${REMOTE_HOST} '$BODY'"
fi

# gnome-terminal is a D-Bus client: it asks the session bus to activate
# gnome-terminal-server.  On a host with no graphical session -- orco, today --
# that fails with "Could not activate remote peer" and nothing opens.
#
# It cannot be detected by exit status: gnome-terminal returns 0 even when the
# activation failed.  Ask the session bus directly whether the terminal factory
# answers, and fall back to xterm, which draws its own window and needs no
# D-Bus.  If gdbus is missing the test fails and xterm is used, which is the
# safe default.
if gdbus call --session --dest org.gnome.Terminal \
        --object-path /org/gnome/Terminal/Factory0 \
        --method org.freedesktop.DBus.Peer.Ping >/dev/null 2>&1; then
    gnome-terminal --tab --title="$TAB_NAME" -- bash -c "$CMD"
else
    xterm -hold -title "$TAB_NAME" -e bash -c "$CMD" &
fi
