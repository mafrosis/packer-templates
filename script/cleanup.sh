#!/bin/bash -eux

CLEANUP_PAUSE=${CLEANUP_PAUSE:-0}
echo "==> Pausing for ${CLEANUP_PAUSE} seconds..."
sleep ${CLEANUP_PAUSE}

echo "==> Disk usage before minimization"
df -h

echo "==> Installed packages before cleanup"
dpkg --get-selections | grep -v deinstall

# Make sure udev does not block our network - http://6.ptmc.org/?p=164
echo "==> Cleaning up udev rules"
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

echo "==> Cleaning up leftover dhcp leases"
# Ubuntu 10.04
if [ -d "/var/lib/dhcp3" ]; then
	rm /var/lib/dhcp3/*
fi
# Debian, Ubuntu 12.04 & 14.04
if [ -d "/var/lib/dhcp" ]; then
	rm /var/lib/dhcp/*
fi

echo "==> Cleaning up tmp"
rm -rf /tmp/*

# Remove some packages to get a minimal install
if [[ -f /etc/centos-release ]]; then
	echo "==> Purging yum package caches"
	yum -y clean all

else
	echo "==> Removing all linux kernels except the current one"
	dpkg --list | awk '{ print $2 }' | grep 'linux-image-3.*-generic' | grep -v $(uname -r) | xargs apt-get -y purge
	echo "==> Removing linux source"
	dpkg --list | awk '{ print $2 }' | grep linux-source | xargs apt-get -y purge
	echo "==> Removing development packages"
	dpkg --list | awk '{ print $2 }' | grep -- '-dev$' | xargs apt-get -y purge
	echo "==> Removing documentation"
	dpkg --list | awk '{ print $2 }' | grep -- '-doc$' | xargs apt-get -y purge
	echo "==> Removing development tools"
	apt-get -y purge build-essential
	echo "==> Removing default system Ruby"
	apt-get -y purge ruby ri doc
	echo "==> Removing default system Python"
	apt-get -y purge python-dbus libnl1 python-smartpm python-twisted-core libiw30 python-twisted-bin libdbus-glib-1-2 python-pexpect python-pycurl python-serial python-gobject python-pam python-openssl libffi5
	echo "==> Removing X11 libraries"
	apt-get -y purge libx11-data xauth libxmuu1 libxcb1 libx11-6 libxext6
	echo "==> Removing obsolete networking components"
	apt-get -y purge ppp pppconfig pppoeconf
	echo "==> Removing other oddities"
	apt-get -y purge popularity-contest installation-report wireless-tools wpasupplicant
	echo "==> Removing groff info lintian linda"
	rm -rf /usr/share/groff/* /usr/share/info/* /usr/share/lintian/* /usr/share/linda/*

	echo "==> Removing man pages"
	find /usr/share/man -type f -delete
	echo "==> Removing APT files"
	find /var/lib/apt -type f -exec rm -f {} +
	echo "==> Removing anything in /usr/src, except linux headers"
	find /usr/src -mindepth 1 -maxdepth 1 -not -name 'linux-headers-*' -exec rm -rf {} +
	echo "==> Removing any docs"
	find /usr/share/doc -type f -delete
	echo "==> Removing caches"
	find /var/cache -type f -exec rm -f {} +

	# Cleanup apt cache
	echo "==> Purging apt package caches"
	apt-get -y autoremove --purge
	apt-get -y clean
	apt-get -y autoclean
fi

# Remove Bash history
unset HISTFILE
rm -f /root/.bash_history
rm -f /home/vagrant/.bash_history

# Clean up log files
find /var/log -type f | while read f; do echo -ne '' > $f; done;

# Whiteout root
count=$(df --sync -kP / | tail -n1  | awk -F ' ' '{print $4}')
let count--
dd if=/dev/zero of=/tmp/whitespace bs=1024 count=$count
rm /tmp/whitespace

# Whiteout /boot
count=$(df --sync -kP /boot | tail -n1 | awk -F ' ' '{print $4}')
let count--
dd if=/dev/zero of=/boot/whitespace bs=1024 count=$count
rm /boot/whitespace

# Zero out the free space to save space in the final image
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Make sure we wait until all the data is written to disk, otherwise
# Packer might quite too early before the large files are deleted
sync

echo "==> Disk usage after cleanup"
df -h
