#!/bin/bash
# *** backup script for ACAS v3 OC versions ***
#  WARNING: this scripts filename 'acasbkup.sh' is fixed inside the ACAS menus
#     Don't change it unless you know what you are doing
#
# 09/04/2009 vbc - temp backup dir and filename prefix change
#
if [ ! -d temp-backups ]; then
    mkdir `pwd`"/temp-backups"
#temp-backups
fi
#cd temp-backups
tar cvfz `pwd`"/temp-backups/acas-bkup-"`date +%Y%m%d%H%M%S`.tar.gz *.dat
#
# place here commands to copy file build above to
#       offline storage ie usb memory stick
# cp -vpf acas-bkup-"`date +%Y%m%d%H*`.tar.gz /mnt/sdd1/acas-backups
#
exit 0
