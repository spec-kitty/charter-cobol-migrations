*>*******************************************
*>                                          *
*>  File Definition For The Sales Ledger    *
*>                                          *
*>*******************************************
*> rec size 300 bytes ** 02/11/10 plus cleanup
*>
 fd  Sales-File.
*>
 01  Sales-Record.
     03  Sales-Key          pic x(7).
*>     03  filler    redefines Sales-Key.
*>         05  Array-K        pic x  occurs 6.
*>         05  Check-Digit    pic 9.
     03  Sales-Name         pic x(30).
     03  Sales-Address.
         05  Sales-Addr1    pic x(48).
         05  Sales-Addr2    pic x(48).
     03  Sales-Phone        pic x(13).
     03  Sales-Ext          pic x(4).
     03  Sales-Email        pic x(30).
     03  Sales-Fax          pic x(13).
     03  Sales-Status       pic 9.
         88  Customer-Live                value 1.
         88  Customer-Dead                value zero.
     03  Sales-Late         pic 9.
         88  Late-Charges                 value 1.
     03  Sales-Dunning      pic 9.                     *> Reminder letters
         88  Dunning-Letters              value 1.
     03  Email-Invoice      pic 9.
         88  Email-Invoicing              value 1.
     03  Email-Statement    pic 9.
         88  Email-Statementing           value 1.
     03  Email-Letters      pic 9.
         88  Email-Dunning                value 1.
     03  Delivery-Tag       pic 9.
     03  Notes-Tag          pic 9.
     03  filler             pic xxx.
     03  Sales-Credit       pic 99.                    *> In days
     03  Sales-Discount     pic 99v99          comp.
     03  Sales-Late-Min     binary-short.
     03  Sales-Late-Max     binary-short.
     03  Sales-Limit        binary-long.
     03  Sales-Activety     binary-long.
     03  Sales-Last-Inv     binary-long.
     03  Sales-Last-Pay     binary-long.
     03  Sales-Average      binary-long.
     03  Sales-Pay-Activety binary-long.
     03  Sales-Pay-Average  binary-long.
     03  Sales-Pay-Worst    binary-long.
     03  Sales-Create-Date  binary-long.
     03  Sales-Current      pic s9(8)v99       comp-3.
     03  Sales-Last         pic s9(8)v99       comp-3.
     03  Quarters.
         05  Turnover-Q1    pic s9(8)v99   comp-3.
         05  Turnover-Q2    pic s9(8)v99   comp-3.
         05  Turnover-Q3    pic s9(8)v99   comp-3.
         05  Turnover-Q4    pic s9(8)v99   comp-3.
     03  filler redefines Quarters.
         05  STurnover-Q    pic s9(8)v99   comp-3 occurs  4.
     03  Sales-Unapplied    pic s9(8)v99   comp-3.
     03  filler             pic x(10).

