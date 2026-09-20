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
BODY="
        [ -r ${EGRABBER} ] && . ${EGRABBER}
        cd ${WORK_DIR}
        ./19bmVieworks.pl stop
        sleep 2
        ./19bmVieworks.pl run
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
