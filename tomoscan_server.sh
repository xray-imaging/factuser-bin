#!/bin/bash

# Define variables
TAB_NAME="tomoScan py server"
REMOTE_USER="factuser"
REMOTE_HOST="orco"
CONDA_ENV="tomoscan"
CONDA_SH="/home/beams/FACTUSER/miniconda3/etc/profile.d/conda.sh"
SCRIPT_NAME="start_tomoscan.py"
WORK_DIR="/home/beams/FACTUSER/epics/synApps/support/tomoscan/iocBoot/iocTomoScan_19BM/"

# conda.sh is sourced explicitly.  "conda activate" is a shell function defined
# by the init block in ~/.bashrc, and that file is only read when this runs as
# an ssh remote command.  When the script runs on orco itself it skips ssh, so
# the body executes in a plain non-interactive bash that never reads .bashrc,
# and conda activate fails with "Run 'conda init' before 'conda activate'" --
# after which the system python is used and tomoscan is not importable.
BODY="
        cd ${WORK_DIR}
        . ${CONDA_SH}
        conda activate ${CONDA_ENV}
        kill_server.sh ${SCRIPT_NAME}
        python -i ${SCRIPT_NAME}
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
