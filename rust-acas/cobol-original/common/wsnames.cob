*>
*> Sales, Purchase, Stock, General
*>    for use in xl150
*>
*>  Files used in Sales, Stock, Purchase, General
*>
 01  file-defs.
     03  pre-trans-name      pic x(532)  value "pretrans.tmp". *> gl071
     03  post-trans-name     pic x(532)  value "postrans.tmp". *> gl071
 copy "file00.cob".    *> "system"
 copy "file02.cob".    *> "archive".
 copy "file03.cob".    *> "final".
 copy "file05.cob".    *> "ledger".
 copy "file06.cob".    *> "posting".
 copy "file07.cob".    *> "batch".
 copy "file09.cob".
 copy "file10.cob".
 copy "file11.cob".
 copy "file12.cob".
 copy "file13.cob".    *> "value.dat"
 copy "file14.cob".    *> "delivery.dat"
 copy "file15.cob".    *> "analysis.dat"
 copy "file16.cob".
 copy "file17.cob".
 copy "file18.cob".
 copy "file19.cob".
 copy "file20.cob".
 copy "file21.cob".    *> work temp file "work.tmp"
 copy "file22.cob".    *> "purchled"
 copy "file23.cob".    *> "delfolio.dat"
 copy "file26.cob".    *> "pinvoice"
 copy "file27.cob".    *> "poisort"
 copy "file28.cob".    *> "openitm4"
 copy "file29.cob".    *> "openitm5"
 copy "file32.cob".    *> "pay.dat"
 copy "file33.cob".    *> "cheque.dat"
 01  filler         redefines file-defs.
     03  System-File-Names   pic x(532)    occurs 28.
 01  File-Defs-Count         binary-short  value 28.    *> MUST be the same as above occurs
*>
 01  IRS-files.
 copy "file08.cob".
