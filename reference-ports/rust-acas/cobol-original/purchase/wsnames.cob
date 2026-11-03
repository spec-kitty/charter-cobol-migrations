*>
*> Purchase Ledger files
*>
 01  file-defs.
 copy "file00.cob".    *> "system.dat"
 copy "file06.cob".    *> "posting.dat"
 copy "file07.cob".    *> "batch.dat"
 copy "file13.cob".    *> "value.dat"
 copy "file14.cob".    *> "delivery.dat"
 copy "file15.cob".    *> "analysis.dat"
 copy "file21.cob".    *> "work.tmp"
 copy "file22.cob".    *> "purchled"
 COPY "file23.cob".    *> "delfolio.dat"
 copy "file26.cob".    *> "pinvoice"
 copy "file27.cob".    *> "poisort"
 copy "file28.cob".    *> "openitm4"
 copy "file29.cob".    *> "openitm5"
 copy "file32.cob".    *> "pay.dat"
 copy "file33.cob".    *> "cheque.dat"
 01  filler         redefines file-defs.
     03  System-File-Names   pic x(532)    occurs 15.
 01  File-Defs-Count         binary-short  value 15.
 01  IRS-files.
 copy "file08.cob".
