#!/bin/bash
for i in `ls *.c*`; do changeformat $i -copybooks-fixed/
       	tofixed; done
exit 0

