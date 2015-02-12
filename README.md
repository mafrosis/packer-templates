packer-templates
================

Packer templates based on the excellent work by the Veewee community, @box-cutter, @timsutton et al & @joefitzgerald et al.

Everything as part of this repo (and sub-repos) are tested using Vagrant 1.6+ and VMWare 6+.

All `packer` commands as part of this repo (and sub-repos) accept `-var headless=false` to show VMWare whilst the build is in progress.


Prerequisites
=============

 - packer (duh)


Build
=====

From the root directory, run the following commands:


Debian
------

    packer build -only=vmware-iso -force debian/wheezy.json


Ubuntu
------

    packer build -only=vmware-iso -force ubuntu/trusty.json


OSX
---

This is a whole separate repo forked from timsutton/osx-vm-templates:

    cd osx
    cat README.md


Windows
-------

Another separate repo included as a submodule from joefitzgerald/packer-windows:

    cd windows
    packer build -force -only=vmware-iso windows_7.json
