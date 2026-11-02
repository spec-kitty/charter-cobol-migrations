*>
*> Stock
*>
 01  file-defs.
 copy "file00.cob" suppress.
 copy "file09.cob" suppress printing.
 copy "file10.cob".
 copy "file11.cob".
 copy "file15.cob".
 copy "file22.cob".
 01  filler         redefines file-defs.
     03  System-File-Names   pic x(532)    occurs 6.
 01  File-Defs-Count         binary-short  value 6.    *> MUST be the same as above occurs
*> 01  IRS-files.
*> copy "file08.cob".
