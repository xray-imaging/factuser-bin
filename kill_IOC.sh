#!/bin/bash
# Kill the terminal an IOC is running in.  Ported from 2-BM.
#
# $1 is the IOC executable name, e.g. tomoScanApp.  "ps -all" prints the CMD
# column as the command name only, not the argument list, so the pattern can
# only match a process actually named $1 -- which is why no "grep -v grep"
# guard is needed here, unlike in kill_server.sh, which uses "ps -ef".
echo $1
for k in $(ps -all|grep $1 | sed -e 's/.*\(pts\/[0-9]\+\).*/\1/'); do
    pkill -9 -t $k
done
