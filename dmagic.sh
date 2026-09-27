#!/bin/bash
# Open a DMagic terminal to tag the current experiment -- write the user name,
# email and proposal into the tomoscan user-info PVs, where they are picked up
# as HDF5 metadata.
#
# Unlike 2-BM's equivalent, this does NOT ssh anywhere.  2-BM's button hops to
# 2bmb@arcturus because MEDM there may be running somewhere else; at 19-BM
# MEDM runs on radon and radon is the console, so the hop would be a no-op at
# best.  Running DMagic on radon also matters for a second reason: /dm/19bm is
# mounted there and not everywhere, and without it the DM SDK cannot
# authenticate.
#
# The work happens inside a login shell (bash -l) on purpose.  A MEDM shell
# command inherits whatever environment started MEDM, which may never have
# read .bashrc.  DMagic needs three things from there: conda, the DM_*
# variables, and EPICS_CA_ADDR_LIST.  The DM_* ones are the trap -- the SDK
# reads them from the environment and silently falls back to 127.0.0.1 when
# they are missing, so it would import cleanly and then fail at the first DM
# call.  Sourcing .bashrc via -l is what makes them present.
#
# Like 2-BM, this tags immediately -- no confirmation.  There is nothing to
# confirm: when no proposal is scheduled, dmagic tag returns before it writes
# anything, and when one is scheduled, applying it is the whole point of the
# button.
#
# A press that cannot tag now says so on the MEDM screen rather than only in
# this window, which the operator has no reason to be watching: dmagic writes
# "No proposal found <date>" (or "No proposal active <date>") into
# $(TS)$(TS_R)UserInfoUpdate, the same field that otherwise carries the
# success timestamp.  The date shown is the one actually searched, today
# shifted by --set, so a forgotten --set reads as the wrong day rather than as
# an unexplained blank.

TITLE="DMagic"
CONDA_ENV="dm"
PREFIX="19bm:TomoScan:"

# --- outer: spawn a terminal -------------------------------------------------
# Everything below runs in the spawned login shell, so the operator sees the
# output and is left at a prompt inside the environment to carry on working.
if [ "${DMAGIC_INNER:-}" != "1" ]; then
    LOG=/tmp/dmagic-$(id -un).log
    { echo "--- $(date '+%F %T')  DISPLAY=${DISPLAY:-<unset>}  on $(hostname -s)"; } >>"$LOG"

    if [ -z "$DISPLAY" ]; then
        echo "No DISPLAY: this opens a terminal window." | tee -a "$LOG" >&2
        exit 1
    fi

    export DMAGIC_INNER=1
    # Activate in the spawned shell, not only inside this script, so the
    # prompt the operator is left at is already in the environment.
    CMD="conda activate $CONDA_ENV; '$0'; exec bash -i"

    # xterm, not gnome-terminal, and deliberately so.  gnome-terminal draws
    # nothing itself: it asks gnome-terminal-server over D-Bus, and the server
    # renders on ITS OWN display, not on $DISPLAY.  MEDM here runs on radon but
    # displays over SSH X11 forwarding (DISPLAY=localhost:NN.0), while the
    # servers already running are attached to :1 (the physical console) and to
    # whatever other forwarded display came first.  The window therefore opens
    # on a screen nobody is looking at, silently and with exit status 0 --
    # which is exactly how this button appeared to "do nothing".  "--tab" made
    # it worse by attaching to an existing window elsewhere.
    #
    # xterm has no server indirection and honours $DISPLAY directly, so it
    # lands where MEDM is, whether that is the console or a forwarded session.
    if command -v xterm >/dev/null; then
        exec xterm -title "$TITLE" -geometry 100x32 -sb -sl 5000 \
             -e bash -lic "$CMD" 2>>"$LOG"
    elif command -v gnome-terminal >/dev/null; then
        echo "xterm not found; falling back to gnome-terminal (may open on the wrong display)" >>"$LOG"
        exec gnome-terminal --window --title="$TITLE" -- bash -lic "$CMD"
    else
        echo "No xterm or gnome-terminal found." | tee -a "$LOG" >&2
        exit 1
    fi
fi

# --- inner: the actual work --------------------------------------------------
# .bashrc has been read by now (bash -l), so conda is a function and the DM_*
# variables are exported.

: "${EPICS_CA_ADDR_LIST:=164.54.129.12 10.54.129.12 10.54.129.13 10.54.129.24:16661}"
export EPICS_CA_ADDR_LIST
export EPICS_CA_CONN_TMO=0.2

echo "DMagic on $(hostname -s)"
echo

# Is the tomoscan IOC actually there?  Tagging a dead prefix fails in a way
# that reads like a DMagic problem, so say plainly which it is.
if ! caget -t -w 1 "${PREFIX}UserInfoUpdate" >/dev/null 2>&1; then
    echo "ERROR: no TomoScan IOC responding at ${PREFIX}" >&2
    echo "       Start the tomoscan server before tagging." >&2
    exit 1
fi

# "conda" is a shell function, and functions are not inherited by a child
# process, so a script run from a shell that has conda still has to source
# the hook itself.  Harmless if the parent already activated the env.
CONDA_SH="$HOME/miniconda3/etc/profile.d/conda.sh"
[ -f "$CONDA_SH" ] && . "$CONDA_SH"

if ! conda activate "$CONDA_ENV" 2>/dev/null; then
    echo "ERROR: could not activate the '$CONDA_ENV' conda environment." >&2
    exit 1
fi

dmagic tag --tomoscan-prefix "$PREFIX"
