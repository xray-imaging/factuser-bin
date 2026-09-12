#!/bin/bash
# Kill the terminal a python server is running in.  Ported from 2-BM.
#
# $1 is the server script, e.g. start_tomoscan.py.  "ps -ef" prints full
# command lines, so the grep would otherwise match its own pipeline and this
# script's own command line; both are excluded explicitly.
for k in $(ps -ef|grep "python -i $1"|grep -v grep|grep -v kill_server.sh| sed -e 's/.* \(pts\/[0-9]\+\).*/\1/'); do
    pkill -9 -t $k
done
