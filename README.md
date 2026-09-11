# factuser-bin

Helper scripts on the `PATH` of the `factuser` account at APS beamline 19-BM.

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
