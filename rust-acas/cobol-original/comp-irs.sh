#!/bin/bash
cd incomplete_records_system
for i in `ls irs0*.cbl`; do cobc -m $i; done
for i in `ls irsu*.cbl`; do cobc -m $i; done
cobc -x irs.cbl
# Now make irs as a module incase user wishes to run via ACAS
cobc -m irs.cbl
#
cd ..
exit 0
