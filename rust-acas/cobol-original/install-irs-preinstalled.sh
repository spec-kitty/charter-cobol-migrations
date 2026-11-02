#!/bin/bash
#
# Script to be used by user. If done by admin will need changing
#     Also file/executables permissions may need changing
#
# 26/02/2009 (c) Vincent B Coen
# 26/02/2009 vbc - v1.01 primary install script for IRS OC version
# 09/04/2012 vbc - v1.00 Secondary install script if init. has been run. 
# 04/04/2017 vbc - v1.02 Force copy of backup scripts to bin & data dirs.
#
#  NOTE  this script MUST be run from the ACAS directory containing
#        the Cobol sources which are within each sub-system directory
#         eg., irs, general, sales, stock, purchase, OE, payroll,epos etc
#
#   AS this process was done on initial install this section will NOT
#      be done again.
#########################
# In addition we will create the directories for the user in which
#       the data will reside other than in a common directory such as /opt
#         so you will need to change this script if needed.
#--------------------------------------------------------------
#  Does not matter if both scripts are run other than duplicate
#   lines will be added to the .bashrc file
#--------------------------------------------------------------
#
if [ ! -d ~/bin ]; then
    mkdir ~/bin
fi
#           Now change permissions and move the executables to users
#           bin directory
#  We, are in the ACAS source directory !
chmod u+x *.sh
cp -vfp irsbakup.sh ~/bin
cp -vfp acasbkup.sh ~/bin
cp -fp  irsbakup.sh ~/IRS
cp -fp  acasbkup.sh ~/ACAS
cd incomplete_records_system
chmod u+x irs *.sh
mv -vf *.so ~/bin
mv -vf irs ~/bin
echo "    *** irs reinstallation complete ***"
echo "    ***  No Paths has been changed  ***"
echo "    ***  No other changes           ***" 
exit 0
