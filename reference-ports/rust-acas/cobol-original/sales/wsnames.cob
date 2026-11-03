*>
*> SALES
*>
 01  file-defs.
 copy "file00.cob".
 copy "file06.cob".
 copy "file07.cob".
 copy "file12.cob".
 copy "file13.cob".
 copy "file14.cob".
 copy "file15.cob".
 copy "file16.cob".
 copy "file17.cob".
 copy "file18.cob".
 copy "file19.cob".
 copy "file20.cob".
 copy "file21.cob".
 01  filler         redefines file-defs.
     03  System-File-Names   pic x(532)    occurs 13.
 01  File-Defs-Count         binary-short  value 13.
 01  IRS-files.
 copy "file08.cob".
