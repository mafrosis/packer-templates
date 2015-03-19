#!/bin/bash -eux

# Under systemd the default SSH setup handling leaves connections
# hanging on system halt. Installing libpam-systemd seems to fix it.

# Not entirely sure why this is yet:
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=751636

if [[ -d /run/systemd/system ]]; then
	echo -e "\n==> Installing libpam-systemd to cleanly terminate SSH connections on poweroff"
	sudo aptitude install libpam-systemd
	reboot
	sleep 40
fi
