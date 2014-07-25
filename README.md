packer-templates
================

Packer templates based on the excellent work by box-cutter


Prerequisites
=============

 - packer (duh)


Build
=====

From the root directory, run the following commands:

debian
------

    packer build -only=vmware-iso -force debian/wheezy76.json

Ubuntu
------

    packer build -only=vmware-iso -force ubuntu/trusty.json
