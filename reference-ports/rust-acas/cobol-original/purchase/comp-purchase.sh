#!/bin/bash
for i in `ls pl*.cbl`; do cobc -m -I ../copybooks $i; done
cobc -x -I ../copybooks purchase.cbl
# Now make purchase as a module incase user wishes to run via ACAS
cobc -m -I ../copybooks purchase.cbl
exit 0
