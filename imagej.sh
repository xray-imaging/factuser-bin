#!/bin/bash
# Open ImageJ with the EPICS areaDetector viewer plugins, to watch the 19-BM
# Vieworks camera live.
#
# Unlike the IOC wrappers in this directory, this does NOT ssh anywhere.
# ImageJ is a GUI and belongs on whatever machine the operator is sitting at;
# ~/Software/ImageJ is on the shared home, so it is visible from all of them.
#
# WHERE YOU RUN THIS DECIDES WHERE THE IMAGES TRAVEL.  One full Vieworks frame
# is 9568 x 6380 x 2 = 122,087,680 bytes.  Started on orco the stream stays on
# the loopback interface; started anywhere else every frame crosses the network
# off the machine that is also running the camera IOC, tomoScan and its server.
# Prefer orco unless there is a reason not to.
#
# The installation came from 2-BM (Software/ImageJ_2bm, rsync'd 2026-09-19) and
# carries EPICS_AD_Viewer (Channel Access) and EPICS_NTNDA_Viewer (pvAccess),
# both already compiled.  Note ImageJ.sh inside that tree is dead -- it is csh,
# points at /home/beams/TOMO/Software/ImageJ_2bmb/ which exists nowhere, and
# sets EPICS_CA_MAX_ARRAY_BYTES to 12000000.  Do not use it.
#
# USE THE NTNDA VIEWER.  A full frame will not fit through Channel Access here.
#     Plugins -> EPICS areaDetector -> EPICS NTNDA Viewer
#     channel:  19bmVieworks:Pva1:Image
# Verified 2026-09-19: that channel is an epics:nt/NTNDArray:1.0 served from
# 10.54.129.13:5075 and resolves from both orco and the public network.

IJ_HOME=/home/beams/FACTUSER/Software/ImageJ
LOG=/tmp/imagej-$(id -un).log

# --- checks ----------------------------------------------------------------
[ -n "$DISPLAY" ] || { echo "No DISPLAY: ImageJ is a GUI. Use a desktop session or ssh -X." >&2; exit 1; }
[ -x "$IJ_HOME/ImageJ" ] || { echo "ImageJ not found at $IJ_HOME" >&2; exit 1; }
pgrep -f 'ij\.ImageJ' >/dev/null && { echo "ImageJ is already running on $(hostname -s)."; exit 0; }

# --- EPICS environment -----------------------------------------------------
# Set only what the caller has not.  A MEDM shell command inherits the
# environment of whatever started MEDM, which may never have read .bashrc --
# which is exactly how 2-BM's equivalent button gets its settings, and why it
# would break the moment MEDM were started from a bare environment.
: "${EPICS_CA_ADDR_LIST:=164.54.129.12 10.54.129.12 10.54.129.13 10.54.129.24:16661}"
: "${EPICS_PVA_ADDR_LIST:=10.54.129.13}"

# The CA viewer needs a ceiling above one frame.  Raising it here does not by
# itself make Channel Access work at full resolution -- the IOC has its own
# limit and the smaller of the two wins -- it only stops the client being what
# refuses.  Use the NTNDA viewer instead; pvAccess has no such limit.
: "${EPICS_CA_MAX_ARRAY_BYTES:=160000000}"

export EPICS_CA_ADDR_LIST EPICS_PVA_ADDR_LIST EPICS_CA_MAX_ARRAY_BYTES

# --- launch ----------------------------------------------------------------
# ImageJ.cfg names "." as its working directory and also carries the heap
# ceiling, so the -Xmx setting lives there, not here.
cd "$IJ_HOME" || exit 1
./ImageJ >"$LOG" 2>&1 &
echo "ImageJ started on $(hostname -s)  (log: $LOG)"
