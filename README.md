Packer Templates
================

Packer templates based on the excellent work by the Veewee community, @boxcutter, @timsutton et al & @joefitzgerald et al.

[Saltstack](https://github.com/saltstack/salt) comes installed on everything.

Everything as part of this repo (and sub-repos) are tested using Vagrant 1.6+ and VMWare 6.


Prerequisites
=============

 - `packer` (duh)


On OSX, the following will do the job:

    brew tap homebrew/binary
    brew install packer


Build
=====

The [`build-salted-vagrant.sh`](https://github.com/mafrosis/packer-templates/blob/master/build-salted-vagrant.sh) script wraps `packer` to provide a simple interface to building Vagrant boxes with specific versions of Salt installed. After packer has finished, the script also tests the outputted box to ensure it's behaving as expected:

    ./build-salted-vagrant.sh -v 2014.7.5 jessie

The full usage for this script:

    build-salted-vagrant.sh [-h] [-t] [-d] [-f] [-p platform] -v <version> <flavour>

      flavour           release codename {'wheezy','trusty','debian','ubuntu'} ('debian' will default to latest release)
      -v version        salt version tag to install
      -p (optional)     platform: either virtualbox or vmware
      -t (optional)     test mode (don't dist_upgrade; leave box available for test)
      -d (optional)     debug mode; print all vagrant output
      -h (optional)     print this help message
      -f (optional)     overwrite existing boxes without input


Packer
------

From the root directory, the following you can run `packer` commands directly. For example:

    packer build -only=vmware-iso -force debian/wheezy.json
    packer build -only=vmware-iso -force ubuntu/trusty.json


All `packer` commands as part of this repo (and sub-repos) accept `-var headless=false` to show VMWare whilst the build is in progress.


OSX
---

This is a whole separate repo forked from [`timsutton/osx-vm-templates`](http://github.com/timsutton/osx-vm-templates):

    cd osx
    cat README.md


Windows
-------

Another separate repo included as a submodule from [`joefitzgerald/packer-windows`](http://github.com/joefitzgerald/packer-windows):

    cd windows
    packer build -force -only=vmware-iso windows_7.json
