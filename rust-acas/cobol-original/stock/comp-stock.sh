#!/bin/bash
for i in `ls st0*.cbl`; do cobc -m -I ../copybooks $i; done
cobc -x -I ../copybooks stock.cbl
# Now make stock as a module incase user wishes to run via ACAS
cobc -m -I ../copybooks stock.cbl
exit 0
