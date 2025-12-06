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
fi

ufw allow from 192.168.0.0/16 to any port 2222 proto tcp comment "SSH LAN" # Allow SSH on port 2222 only from LAN
ufw reload

# Done
_notif "Arch Linux post install setup complete!" o
_reboot