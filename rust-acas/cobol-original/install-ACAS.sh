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
# 04/04/2017 vbc - v1.04 Fix missing ../ in cd sales & cp acasbkup.sh to ~/bin
#                        force copy of irsbakup.sh as well but its done 
#                        with install-irs.sh
#
#  NOTE  this script MUST be run from the ACAS directory containing
#        the Cobol sources which are within each sub-system directory
#         eg., irs, general, sales, stock, purchase, OE, payroll,epos etc
#
#       In addition we will create the directories for the user in which
#       the data will reside other than in a common directory such as /opt
#         so you will need to change this script if needed.
#--------------------------------------------------------------
#  Does not matter if both acas & irs scripts are run, other than duplicate
#   lines will be added to the .bashrc file.
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
chmod u+x *.sh
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
chmod u+x purchase *.sh
mv -vf purchase ~/bin
mv -vf *.so ~/bin
#cp -vf *.sh ~/bin
cd ../stock
chmod u+x stock *.sh
mv -vf stock ~/bin
mv -vf *.so ~/bin
#cp -vf *.sh ~/bin
cd ../general
chmod u+x general *.sh
mv -vf general ~/bin
mv -vf *.so ~/bin
#
# Back to top level.
#
cd ..
#cp -vf *.sh ~/bin
#
# OE is not available at this time for OS vers.
#
#cd ../OE
#chmod u+x OE *.sh
#mv -vf OE ~/bin
#mv -vf *.so ~/bin
#
# Payroll is not available at this time for OS vers.
#
#cd ../payroll
#chmod u+x payroll *.sh
#mv -vf payroll ~/bin
#mv -vf *.so ~/bin
#
# EPOS is not available at this time for OS vers.
#
#cd ../EPOS
#chmod u+x EPOS/*.sh
#mv -vf EPOS ~/bin
#mv -vf *.so ~/bin
#
# add exports to users bash profile
#
cat << EOF >> ~/.bashrc
export COB_SCREEN_ESC=YES
export COB_SCREEN_EXCEPTIONS=YES
export COB_LIBRARY_PATH=~/bin
#
export PATH=~/bin:.:$PATH
export ACAS_IRS=~/IRS
export ACAS_LEDGERS=~/ACAS
export ACAS_BIN=~/bin
export TMPDIR=~/tmp
# the next one is an issue as ALL data files will go there regardless
#    so remarked out
#export DB_HOME=~/ACAS
EOF
#
#  NOW create the directories for the ACAS and IRS data for this user
#   but we use the system defaults for directories, scripts so 
#       mkdir kept seperate, in case if an error on one then rest can
#             still complete 
#
if [ ! -d ~/IRS ]; then
   mkdir ~/IRS
fi
if [ ! -d ~/IRS-practice ]; then
   mkdir ~/IRS-practice
fi
if [ ! -d ~/ACAS ]; then
   mkdir ~/ACAS 
   mkdir ~/ACAS/temp-backups
   mkdir ~/ACAS/archives
fi
if [ ! -d ~/ACAS/temp-backups ]; then
   mkdir ~/ACAS/temp-backups
   mkdir ~/ACAS/archives
fi	
if [ ! -d ~/ACAS/archives ]; then
   mkdir ~/ACAS/archives
fi
if [ ! -d ~/ACAS-practice ]; then
   mkdir ~/ACAS-practice
   mkdir ~/ACAS-practice/temp-backups
   mkdir ~/ACAS-practice/archives
fi
if [ ! -d ~/tmp ]; then
   mkdir ~/tmp
fi
#
# Now copy over the error text file
#
cp -vf ~/bin/error.txt ~/ACAS
cp -vf ~/bin/error.txt ~/ACAS-practice
#
# Now the backup scripts to working dir.
#
cp -vf ~/bin/acasbkup.sh ~/ACAS
cp -vf ~/bin/irsbakup.sh ~/IRS
# more needed if OE, EPOS or Payroll is supplied
echo "    *** ACAS installation complete & new paths etc created ***"
echo " "
echo "Now exit this terminal and load another so that new paths are found"
echo " and go to the new directory = ACAS and start running your chosen element/s" 
echo " Running this script more than once will put duplicate commands into"
echo "  your .bashrc file so you might want to remove them first"
echo "    but will not cause a problem other than being messy"
exit 0

