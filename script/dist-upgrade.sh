#!/bin/bash -eux

if [[ $DIST_UPGRADE =~ true ]]; then
	echo -e "\n==> Performing dist-upgrade (all packages and kernel)"
	apt-get -y dist-upgrade --force-yes
	reboot
	sleep 40
fi
