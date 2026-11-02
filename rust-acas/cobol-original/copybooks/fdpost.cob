*>*******************************************
*>                                          *
*>  File Definition For The Posting File    *
*>                                          *
*>*******************************************
*> 98 bytes 26/03/09
*> 96 bytes 20/12/11 (leading sign removed)
 fd  posting-file.
*>
 01  posting-record.
     03  post-key.
         05  batch       pic 9(5).
         05  post-number pic 9(5).
     03  post-code       pic xx.      *> 12
     03  post-date       pic x(8).    *> 20
     03  post-dr         pic 9(6).    *> 26
     03  dr-pc           pic 99.
     03  post-cr         pic 9(6).    *> 34
     03  cr-pc           pic 99.      *> 36
     03  post-amount     pic s9(8)v99.  *> 46
     03  post-legend     pic x(32).     *> 76
     03  vat-ac          pic 9(6).      *> 82
     03  vat-pc          pic 99.
     03  post-vat-side   pic xx.        *> 86
     03  vat-amount      pic s9(8)v99.  *> 96
