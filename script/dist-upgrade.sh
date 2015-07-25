#!/bin/bash -eux

if [[ $DIST_UPGRADE =~ true ]]; then
	echo -e "\n==> Performing dist-upgrade (all packages and kernel)"

	if [[ -f /etc/centos-release ]]; then
		yum -y upgrade
	else
		apt-get -y dist-upgrade --force-yes
	fi

	echo -e "\n==> Rebooting..."
	reboot
	sleep 40
fi
