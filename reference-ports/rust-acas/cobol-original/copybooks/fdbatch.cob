*>*****************************************
*>                                        *
*>  file definition for the batch file    *
*>                                        *
*>*****************************************
*> 96 bytes 26/03/09
*> 98 bytes 20/12/11 (no, dont understand as I count 96)
*>   but function length (batch-record) says 98?
 fd  batch-file.
*>
 01  batch-record.
     03  batch-key.
         05  ledger          pic 9.
             88  gl-batch                   value 1.
             88  pl-batch                   value 2.
             88  sl-batch                   value 3.
         05  batch-nos       pic 9(5).
     03  items               pic 99.
*>
     03  batch-status        pic 9.
         88  status-open                    value 0.
         88  status-closed                  value 1.
*>
     03  cleared-status      pic 9.
         88  waiting                        value 0.
         88  processed                      value 1.
         88  archived                       value 2.
*>
     03  bcycle              pic 99.
     03  dates.
         05  entered         binary-long.
         05  proofed         binary-long.
         05  posted          binary-long.
         05  stored          binary-long.
     03  amounts                         comp-3.
         05  input-gross     pic 9(9)v99.
         05  input-vat       pic 9(9)v99.
         05  actual-gross    pic 9(9)v99.
         05  actual-vat      pic 9(9)v99.
     03  description         pic x(24).
*>
     03  posting-data.
         05  bdefault        pic 99.
         05  convention      pic xx.
         05  batch-def-ac    pic 9(6).
         05  batch-def-pc    pic 99.
         05  batch-def-code  pic xx.
         05  batch-def-vat   pic x.
     03  batch-start         pic 9(5).
*>
