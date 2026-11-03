*>
*> Sales, Purchase, Stock, General eg all but NOT IRS
*>    for use in xl150
*>
*>  Files used in Sales, Stock, Purchase, General
*>
 01  file-defs.
     02  file-defs-a.
         03  pre-trans-name      pic x(532)  value "pretrans.tmp". *> gl071
         03  post-trans-name     pic x(532)  value "postrans.tmp". *> gl071
 copy "file00.cob".    *> "system"
 copy "file02.cob".    *> "archive".
 copy "file03.cob".    *> "final".
 copy "file05.cob".    *> "ledger".
 copy "file06.cob".    *> "posting".
 copy "file07.cob".    *> "batch".
 copy "file08.cob".    *> irs posting
 copy "file09.cob".    *> "tmp-stock".
 copy "file10.cob".    *> "staudit".
 copy "file11.cob".    *> "stockctl".
 copy "file12.cob".    *> "salesled".
 copy "file13.cob".    *> "value.dat"
 copy "file14.cob".    *> "delivery.dat"
 copy "file15.cob".    *> "analysis.dat"
 copy "file16.cob".    *> "invoice ".
 copy "file17.cob".    *> "delinvno".
 copy "file18.cob".    *> "openitm2".
 copy "file19.cob".    *> "openitm3".
 copy "file20.cob".    *> "oisort".
 copy "file21.cob".    *> "work.tmp"
 copy "file22.cob".    *> "purchled"
 copy "file23.cob".    *> "delfolio.dat"
 copy "file24.cob".    *> dummy to build file-02
 copy "file26.cob".    *> "pinvoice"
 copy "file27.cob".    *> "poisort"
 copy "file28.cob".    *> "openitm4"
 copy "file29.cob".    *> "openitm5"
 copy "file32.cob".    *> "pay.dat"
 copy "file33.cob".    *> "cheque.dat"
     02  filler         redefines file-defs-a.
         03  System-File-Names   pic x(532)    occurs 31.
     02  File-Defs-Count         binary-short  value 31.    *> MUST be the same as above occurs
     02  file-defs-os-delimiter  pic x.
*>
