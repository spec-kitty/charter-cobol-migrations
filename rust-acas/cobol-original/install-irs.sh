#!/bin/bash
#
# Script to be used by user. If done by admin will need changing
#     Also file/executables permissions may need changing
#
# 26/02/2009 (c) Vincent B Coen
# 26/02/2009 vbc - v1.01 primary install script for IRS OC version
#
#  NOTE  this script MUST be run from the ACAS directory containing
#        the Cobol sources which are within each sub-system directory
#         eg., irs, general, sales, stock, purchase, OE, payroll,epos etc
#
#       In addition we will create the directories for the user in which
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
cp -vf *.sh ~/bin
cd incomplete_records_system
chmod u+x irs *.sh
mv -vf *.so ~/bin
mv -vf irs ~/bin
#cp -vf *.sh ~/bin
#
# add exports to users bash profile
#
cat << EOF >> ~/.bashrc
export COB_SCREEN_ESC=YES
export COB_SCREEN_EXCEPTIONS=YES
export COB_LIBRARY_PATH=~/bin
#export COB_PRE_LOAD=irs010:irs020:irs030:irs040:irs050:irs055:irs060:irs065:irs070:irs080:irs085:irs090:irsub1:irsub2:irsub3:irsub4:irsub5:irsubp
# above not needed but here as a reminder in case it needs to be installed
export PATH=~/bin:.:$PATH
export ACAS_IRS=~/IRS
export ACAS_LEDGERS=~/ACAS
export TMPDIR=~/tmp
DB_HOME=~/tmp
EOF
# Now create data directory for this user if not exist
if [ ! -d ~/IRS ]; then
   mkdir ~/IRS
fi
if [ ! -d ~/tmp ]; then
   mkdir ~/tmp
fi 
#
# Now copy over the backup script
#
cp -vf ~/bin/irsbakup.sh ~/bin
cp -vf ~/bin/irsbakup.sh ~/IRS
cp -vf ~/bin/irsbakup.sh ~/IRS-practice
echo "    *** irs installation complete & new paths etc created ***"
echo " "
echo "Now exit this terminal and load another so that new paths are found"
echo " and go to the new directory = irs and start by running 'irs'"
echo " Running this script more than once will put duplicate commands into"
echo "  your .bashrc file so you might want to remove them first"
echo "    but will not cause a problem other than being messy"
exit 0
