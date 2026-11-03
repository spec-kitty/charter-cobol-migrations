#!/bin/bash
for i in `ls maps0*.cbl`; do cobc -m -I ../copybooks $i; done
cobc -m -I ../copybooks maps99.cbl
#cobc -x -I ../copybooks mapserup.cbl
cobc -m -free -I ../copybooks xl150.cbl
cobc -m -I ../copybooks sys002.cbl
#
exit 0
