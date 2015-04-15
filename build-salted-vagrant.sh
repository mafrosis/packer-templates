#! /bin/bash

USAGE="build-salted-vagrant.sh [-h] [-t] [-d] [-f] -v <version> <flavour>

  flavour           release codename {'wheezy','trusty','debian','ubuntu'} ('debian' will default to latest release)
  -v version        salt version tag to install
  -t (optional)     test mode (don't dist_upgrade; leave box available for test)
  -d (optional)     debug mode; print all vagrant output
  -h (optional)     print this help message
  -f (optional)     overwrite existing boxes without input
"

VERSION=''
TEST=0
DEBUG=0
FORCE=0

red='\033[0;91m'
green='\033[0;92m'
white='\033[0;97m'
reset='\033[0m'

while getopts "v:tdhf" options
do
	case $options in
		v ) VERSION=$OPTARG;;
		t ) TEST=1;;
		d ) DEBUG=1;;
		f ) FORCE=1;;
		h ) echo "$USAGE" && exit 1;;
	esac
done
shift $(($OPTIND-1))

if [[ $# -ne 1 ]]; then
	echo "${red}You must choose either ubuntu or debian as the flavour${reset}\n  $USAGE"
	exit 1
fi

if [[ -z $VERSION ]]; then
	echo "${red}Version number is required${reset}\n  $USAGE"
	exit 1
else
	# ensure 'v' prefix
	if [[ ${VERSION:0:1} != 'v' ]]; then
		VERSION="v$VERSION"
	fi
fi


# redirect stdout/stderr to new descriptors
# this means anything that MUST be echoed needs '1>&3 2>&4'
exec 3>&1
exec 4>&2

if [[ $DEBUG -eq 0 ]]; then
	# display no output from anything which is not redirected
	exec 1>/dev/null
	exec 2>/dev/null
fi


function create_vagrantfile {
	if [[ $2 -eq 1 ]]; then
		BOOTSTRAP_OPTIONS='-D -K'
	fi

	tee Vagrantfile > /dev/null <<EOF
Vagrant.configure("2") do |config|
  config.vm.box = "$1"
  config.vm.synced_folder "/tmp", "/tmp/host_machine"
  config.vm.provision :salt do |salt|
    salt.run_highstate = false
    salt.bootstrap_options = "$BOOTSTRAP_OPTIONS"
  end
end
EOF
}

function build {
	local OS=$1			# ubuntu/debian
	local FLAVOUR=$2	# wheezy/jessie/trusty
	local VERSION=$3	# v2014.7.1

	echo "Building Vagrant box for $FLAVOUR at version $VERSION" 1>&3 2>&4

	# pass debug flag onto packer
	if [[ $DEBUG -eq 1 ]]; then PACKER_DEBUG=true; else PACKER_DEBUG=false; fi

	# don't run full dist-upgrade in test mode
	if [[ $TEST -eq 1 ]]; then DIST_UPGRADE=false; else DIST_UPGRADE=true; fi

	# build box image with packer
	packer build -only=vmware-iso -force \
		-var debug=$PACKER_DEBUG \
		-var dist_upgrade=$DIST_UPGRADE \
		-var salt_version="$VERSION" \
		"$OS/$FLAVOUR".json 1>&3 2>&4

	if [[ $? -gt 0 ]]; then
		return 4
	fi

	# create local Vagrantfile for testing
	create_vagrantfile "$FLAVOUR-packer" $DEBUG

	# stop and destroy an old test build
	VSTATUS="$(vagrant status)"
	if [[ ! -z "$(echo $VSTATUS | grep 'default.*run')" ]] || [[ ! -z "$(echo $VSTATUS | grep 'default.*susp')" ]]; then
		echo "${white}==> Destroying existing running VM${reset}"
		vagrant destroy -f
	fi

	# add the box for testing
	echo "\n${white}==> Adding box to vagrant for testing${reset}" 1>&3 2>&4
	vagrant box add -f "$FLAVOUR-packer" box/$FLAVOUR-packer.box

	# show Vagrant debugging output
	if [[ $DEBUG -eq 1 ]]; then
		export VAGRANT_LOG=info
	fi

	# bring up testing box
	echo "${white}==> Bringing up testing VM with Vagrant${reset}" 1>&3 2>&4
	vagrant up
	if [[ $? -gt 0 ]]; then
		echo "${red}Failed bringing up the vagrant box!!${reset}" 1>&3 2>&4
		cleanup "$FLAVOUR-packer" 1
		return $?
	fi

	# ensure box is comes up after reboot
	echo "${white}==> Reloading VM to be sure it works${reset}" 1>&3 2>&4
	vagrant reload
	if [[ $? -gt 0 ]]; then
		echo "${red}Failed reloading the vagrant box!!${reset}" 1>&3 2>&4
		cleanup "$FLAVOUR-packer" 1
		return $?
	fi

	# verify salt version
	INSTALLED=$(vagrant ssh -c 'salt-call --version' | awk -v version=${VERSION:1} '$1 ~ $version')
	if [[ -z $INSTALLED ]]; then
		echo "${red}Failed verifying salt version $VERSION installed on target box!!${reset}" 1>&3 2>&4
		cleanup "$FLAVOUR-packer" 1
		return $?
	fi

	# remove the testing bits
	cleanup "$FLAVOUR-packer" 0

	echo "==> ${green}Verified Salt $VERSION installed on box/$FLAVOUR-packer${reset}" 1>&3 2>&4

	# exit now if using test mode (cleanup was aborted)
	if [[ $TEST -eq 1 ]]; then
		echo "==> Test mode enabled: box $OS left running in current directory" 1>&3 2>&4
		return 3
	fi

	if [[ $FORCE -eq 0 ]] && [[ -f "box/${FLAVOUR}64-au-salt-${VERSION}.box" ]]; then
		read -p "A box exists at box/${FLAVOUR}64-au-salt-${VERSION}.box. Overwrite it? [y/N] " -n1 -s 1>&3 2>&4
		echo ''
	else
		REPLY=y
	fi

	if [[ $REPLY =~ ^[Yy]$ ]]; then
		mv -f "box/$FLAVOUR-packer.box" "box/${FLAVOUR}64-au-salt-${VERSION}.box"
		echo "${white}==> Box moved to box/${FLAVOUR}64-au-salt-${VERSION}.box${reset}" 1>&3 2>&4
	else
		echo "${white}==> Box left at box/$FLAVOUR-packer.box${reset}" 1>&3 2>&4
	fi

	echo "==> ${green}Completed build for $FLAVOUR with Salt ${VERSION}${reset}" 1>&3 2>&4

	return 0
}

function cleanup {
	if [[ $TEST -eq 1 ]]; then
		return 3
	fi

	export VAGRANT_LOG=''

	# destroy local VM, remove Vagrantfile & delete test box
	vagrant destroy -f
	rm -f Vagrantfile
	vagrant box remove "$1"
	if [[ $2 -eq 1 ]]; then
		rm -f "box/${1}.box"
	fi

	return 2
}


# main build dispatch
if [[ $1 == 'ubuntu' ]]; then
	build ubuntu trusty $VERSION
elif [[ $1 == 'trusty' ]]; then
	build ubuntu trusty $VERSION

elif [[ $1 == 'debian' ]]; then
	build debian wheezy $VERSION
elif [[ $1 == 'wheezy' ]]; then
	build debian wheezy $VERSION
elif [[ $1 == 'jessie' ]]; then
	build debian jessie $VERSION
else
	echo "Unsupported flavour: $1"
	exit 1
fi

exit $?
