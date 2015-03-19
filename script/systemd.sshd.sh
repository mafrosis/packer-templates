#!/bin/bash -eux

echo -e "\n==> Switching SSH connection handling behaviour"
systemctl disable ssh.service
systemctl enable ssh.socket
reboot
sleep 40
