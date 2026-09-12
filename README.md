# factuser-bin

Helper scripts on the `PATH` of the `factuser` account at APS beamline 19-BM.

The authoritative copy of this repository is
[xray-imaging/factuser-bin](https://github.com/xray-imaging/factuser-bin).
The beamline working tree tracks a personal fork and is reconciled with
upstream by pull request, so changes made on the beamline are not published
until that pull request is merged. Open pull requests against the upstream
repository, not the fork.

`~/bin` is on an NFS-shared home directory, so these are available from every
workstation that mounts it — `orco`, `txmthree` and the rest — with no
per-machine installation.

## Detector IOC control

The 19-BM Micro-CT detector is a Vieworks VP-61MX on a Euresys Coaxlink Quad
CXP-12 frame grabber, driven by the areaDetector `ADEuresys` driver. Its IOC
(`19bmVieworks`) runs on `orco`, the host holding the grabber card.

| Script | Effect |
| --- | --- |
| `detector_IOC_vieworks_61mp.sh` | Stop the IOC, wait 2 s, then run it |
| `detector_IOC_vieworks_61mp_stop.sh` | Stop the IOC |

Each opens a `gnome-terminal` tab and runs `ssh -t factuser@orco` inside it.
Run them as `factuser`; `~/.ssh/id_ed25519` is listed in the account's own
`authorized_keys`, which is what makes `factuser` → `factuser` ssh passwordless
from any machine sharing the home directory.

The start script sources the Euresys eGrabber environment before starting the
IOC. This is required, not incidental: `19bmVieworks.pl` sets `IOC_CMD` to the
IOC binary directly and so bypasses `softioc/run`, the only thing that sources
`setup_gentl_paths.sh`. Over ssh `GENICAM_GENTL64_PATH` is unset and nothing in
`/etc/profile.d` supplies it, so without it the IOC starts normally but the
driver never finds the camera.

Both use `run` rather than `start`, so the IOC stays in the foreground of the
terminal tab where its console is visible — closing the tab stops the IOC.
Change `run` to `start` to detach it into a `screen` session instead.

## Tomoscan IOC and server

Tomographic scans are run by [tomoscan](https://github.com/tomography/tomoscan),
which needs two processes besides the detector IOC: an EPICS soft IOC holding
the scan records, and a python server that arms the camera, programs the stage
and writes the HDF5 file. Both run on `orco` from
`~/epics/synApps/support/tomoscan/iocBoot/iocTomoScan_19BM`.

| Script | Effect |
| --- | --- |
| `tomoscan_IOC.sh` | Stop the tomoScan IOC, then start it |
| `tomoscan_IOC_stop.sh` | Stop the tomoScan IOC |
| `tomoscan_server.sh` | Stop the python server, then start it in the `tomoscan` conda environment |
| `tomoscan_server_stop.sh` | Stop the python server |

These are modelled on the 2-BM scripts of the same name and use the same two
helpers, which find the terminal a process is running in and kill it:

| Helper | Purpose |
| --- | --- |
| `kill_IOC.sh <app>` | Kill the terminal running IOC executable `<app>` |
| `kill_server.sh <script>` | Kill the terminal running `python -i <script>` |

The two match differently on purpose. `kill_IOC.sh` greps `ps -all`, whose CMD
column is the command name only, so the pattern can only match a process
actually named `<app>`. `kill_server.sh` greps `ps -ef`, which shows full
command lines, so it has to exclude its own pipeline and itself explicitly.

Start the IOC before the server: the server attaches to the IOC's records at
construction and logs *PV not connected* for every one of them if the IOC is
not up yet.

## Other scripts

| Script | Purpose |
| --- | --- |
| `softIOC <name> <action>` | Start/stop/restart/status/console for the 19-BM and 7-BM soft IOCs (`Grasshopper3`, `TomoScan`, `LabJack`, `Dante`, `Hexapod`, …) |
| `set_epics_arch.sh` | `export EPICS_HOST_ARCH=rhel9-x86_64` |
| `set_francesco` | Set `git config user.name` / `user.email` for this account |

## Not in this repository

`projects/` holds a clone of
[autonomous-ct-experimentation](https://github.com/tekinbicer/autonomous-ct-experimentation),
which has its own history and remote and is excluded in `.gitignore`.
