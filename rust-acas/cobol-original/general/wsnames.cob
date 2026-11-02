*>
*> General
*>
 01  file-defs-os-delimiter  pic x.
 01  file-defs.
     03  pre-trans-name      pic x(532)  value "pretrans.tmp". *> gl071
     03  post-trans-name     pic x(532)  value "postrans.tmp". *> gl071
 copy "file00.cob".    *> "system"
 copy "file03.cob".    *> "final".
 copy "file05.cob".    *> "ledger".
 copy "file06.cob".    *> "posting".
 copy "file07.cob".    *> "batch".
 copy "file21.cob".    *> work temp file "work.tmp"
 copy "file24.cob".    *> dummy to build file-02
 01  filler         redefines file-defs.
     03  System-File-Names   pic x(532)    occurs 9.
 01  File-Defs-Count         binary-short  value 9.    *> MUST be the same as above occurs
*> 01  IRS-files.
*> copy "file08.cob".
