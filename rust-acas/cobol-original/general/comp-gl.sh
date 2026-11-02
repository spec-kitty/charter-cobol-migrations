#!/bin/bash
for i in `ls gl*.cbl`; do cobc -m -I ../copybooks $i; done
cobc -x -I ../copybooks general.cbl
# Now make general as a module incase user wishes to run via ACAS
cobc -m -I ../copybooks general.cbl
#
exit 0
