#!/bin/bash
source ./base.sh

# Disable Lid Switch Suspend
sudo sed -i \
  -e 's/^#HandleLidSwitch=.*/HandleLidSwitch=ignore/' \
  -e 's/^#HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' \
  -e 's/^#HandleLidSwitchDocked=.*/HandleLidSwitchDocked=ignore/' \
  /etc/systemd/_notifind.conf

# Firewall
# ufw-docker support
if systemctl is-active --quiet docker; then
    docker network create proxy

    wget -O /usr/bin/ufw-docker https://github.com/chaifeng/ufw-docker/raw/master/ufw-docker
    ufw-docker install
    ufw reload
fi

# Done
_notif "Arch Linux post install setup complete!" o
timeleft=3
while [ $timeleft -gt 0 ]; do
    _notif "Rebooting in $timeleft..."; _bell; sleep 1
    ((timeleft--)) # decrement the counter
done
reboot