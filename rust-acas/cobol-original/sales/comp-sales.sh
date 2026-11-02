#!/bin/bash
for i in `ls sl*.cbl`; do cobc -m -I ../copybooks $i; done
cobc -x -I ../copybooks sales.cbl
#Now make sales as a module incase user wishes to run via ACAS
cobc -m -I ../copybooks sales.cbl
exit 0
