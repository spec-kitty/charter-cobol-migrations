#!/bin/bash
#
# This will compile ALL subsystems using the scripts within each directory
####
# and this to set up cobcpy
export COBCPY=../copybooks
export COB_COPY_DIR==../copybooks
# comp top level as might be wanted
cobc -x -I copybooks ACAS.cbl
# now compile all sub-systems ...
cd incomplete_records_system
./comp-irs.sh
echo "irs done"
cd ../common
./comp-common.sh
echo "common done"
cd ../general
./comp-gl.sh
echo "general done"
cd ../purchase
./comp-purchase.sh
echo "purchase done"
cd ../sales
./comp-sales.sh
echo "sales done"
cd ../stock
./comp-stock.sh
echo "stock done"
#   Not yet released under Open Source
#cd ../OE
#./comp-OE.sh
#echo "OE done"
#cd ../payroll
#./comp-payroll.sh
#echo "payroll done"
#cd ../epos
#./comp-epos.sh
#echo "Epos done"
#
echo "We Are all done but check for any error or warning messages"
exit 0
