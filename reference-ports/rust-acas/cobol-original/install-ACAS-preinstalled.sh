#!/bin/bash
#
# Script to be used by user. If done by admin will need changing
#     Also file/executables permissions may need changing
#
# 02/10/2011 (c) Vincent B Coen
# 02/10/2011 vbc - v1.00 primary install script for ACAS OC version
# 17/11/2011 vbc - v1.01  copy error.txt to ~/bin
# 20/12/2011 vbc - v1.02  Added creation of dir's ~/ACAS archives
#                         and ~/ACAS/temp-backups
# 30/01/2012 vbc - v1.03 Copy ACAS binary 
# 09/04/2012 vbc - v1.04 from above to reinstall newly compiled programs
#                       where install has been run before
# 04/04/2017 vbc - v1.05 Copy over bakup scripts to bin & data dirs.
#
#  NOTE  this script MUST be run from the ACAS directory containing
#        the Cobol sources which are within each sub-system directory
#         eg., irs, general, sales, stock, purchase, OE, payroll,epos etc
#
#--------------------------------------------------------------
#
if [ ! -d ~/bin ]; then
    mkdir ~/bin
fi
#
# error.txt SHOULD be the same for all of the ACAS subsystems but
#           is NOT used for irs
#
#           Now change permissions and move the executables to users
#           bin directory
chmod u+x *.sh ACAS
mv -vf ACAS ~/bin
cp -vpf acasbkup.sh ~/bin
cp -vpf irsbakup.sh ~/bin
cd common
cp -vpf error.txt ~/bin
mv -vf *.so ~/bin
cd ../sales
chmod u+x *.sh sales
mv -vf sales ~/bin
mv -vf *.so ~/bin
#cp -vf *.sh ~/bin
cd ../purchase
chmod u+x *.sh purchase
mv -vf purchase ~/bin
mv -vf *.so ~/bin
#cp -vf *.sh ~/bin
cd ../stock
chmod u+x *.sh stock
mv -vf stock ~/bin
mv -vf *.so ~/bin
#cp -vf *.sh ~/bin
cd ../general
chmod u+x *.sh general
mv -vf general ~/bin
mv -vf *.so ~/bin
#cp -vf *.sh ~/bin
#
# OE is not available at this time
#
#cd ../OE
#chmod u+x OE/*.sh
#mv -vf OE ~/bin
#mv -vf *.so ~/bin
##cp -vf *.sh ~/bin
#
# Payroll is not available at this time
#
#cd ../payroll
#chmod u+x payroll/*.sh
#mv -vf payroll ~/bin
#mv -vf *.so ~/bin
##cp -vf *.sh ~/bin
#
# EPOS is not available at this time
#
#cd ../EPOS
#chmod u+x EPOS/*.sh
#mv -vf EPOS ~/bin
#mv -vf *.so ~/bin
##cp -vf *.sh ~/bin
#
# more needed if OE, EPOS or Payroll is supplied
#
# Here copy over the backup scripts to data dirs.
#
cd ..
cp -vpf ~/bin/irsbakup.sh ~/IRS
cp -vpf ~/bin/acasbkup.sh ~/ACAS
echo "    *** ACAS re-installation complete  ***"
echo " "
exit 0

