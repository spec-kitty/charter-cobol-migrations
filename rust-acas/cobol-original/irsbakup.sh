#!/bin/bash
# *** backup script for IRS v3 OC versions ***
#  WARNING: this scripts filename 'irsbakup.sh' is fixed inside the irs menu
#     Don't change it unless you know what you are doing
#
# 26/02/2009 vbc - temp backup dir and filename prefix change
#
if [ ! -d temp-backups ]; then
    mkdir `pwd`"/temp-backups"
#temp-backups
fi
#cd temp-backups
tar cvfz `pwd`"/temp-backups/irs-bkup-"`date +%Y%m%d%H%M%S`.tar.gz *.dat
#
# place here commands to copy file build above to
#       offline storage ie usb memory stick
# cp -vpf irs-bkup-"`date +%Y%m%d%H*`.tar.gz /mnt/sdd1/irs-backups
#
exit 0
