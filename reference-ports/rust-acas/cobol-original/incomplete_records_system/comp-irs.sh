#!/bin/bash
for i in `ls irs0*.cbl`; do cobc -m $i; done
for i in `ls irsu*.cbl`; do cobc -m $i; done
cobc -x irs.cbl
# Now make irs as a module incase user wishes to run via ACAS
cobc -m irs.cbl
#
exit 0
