#!/bin/bash

sudo echo 'SYSTEMD_PID=$(ps -efw | grep '"'"'/lib/systemd/systemd --system-unit=basic.target$'"'"' | grep -v unshare | awk '"'"'{print $2}'"'"')
 
if [ -z "$SYSTEMD_PID" ]; then
   sudo /usr/bin/daemonize /usr/bin/unshare --fork --pid --mount-proc /lib/systemd/systemd --system-unit=basic.target
   SYSTEMD_PID=$(ps -efw | grep '"'"'/lib/systemd/systemd --system-unit=basic.target$'"'"' | grep -v unshare | awk '"'"'{print $2}'"'"')
fi
 
if [ -n "$SYSTEMD_PID" ] && [ "$SYSTEMD_PID" != "1" ]; then
    exec sudo /usr/bin/nsenter -t $SYSTEMD_PID -a su - $LOGNAME
fi' > /etc/profile.d/00-wsl2-systemd.sh