*>*******************************************
*>                                          *
*>  file definition for the ledger file     *
*>                                          *
*>*******************************************
*> 27/01/09 vbc - file-id to select
*>
 fd  ledger-file.
*>
 01  ledger-record.
     03  ledger-key.
         05  ledger-nos     pic 9(6).
*>*******************************************
         05  filler  redefines  ledger-nos.
             07  ledger-n   pic 9(4).
             07  ledger-s   pic 9(2).
*>*******************************************
       05  ledger-pc        pic 9(2).
     03  ledger-type       pic 9.
     03  ledger-place      pic x.
     03  ledger-level      pic 9.
     03  filler            pic x(5).
     03  ledger-name       pic x(24).
     03  ledger-balance    pic s9(8)v99   comp-3.
     03  ledger-last       pic s9(8)v99   comp-3.
     03  quarters.
         05  ledger-q1     pic s9(8)v99   comp-3.
         05  ledger-q2     pic s9(8)v99   comp-3.
         05  ledger-q3     pic s9(8)v99   comp-3.
         05  ledger-q4     pic s9(8)v99   comp-3.
     03  filler redefines quarters.
         05  ledger-q      pic s9(8)v99   comp-3   occurs  4.
     03  filler            pic x(50).
