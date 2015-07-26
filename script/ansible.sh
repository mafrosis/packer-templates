#!/bin/bash -eux

if [[ -f /etc/centos-release ]]; then
	# setup EPEL 7
	rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

	yum -y install ansible
else
	apt-get install -y ansible
fi
