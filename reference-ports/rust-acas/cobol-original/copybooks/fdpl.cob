*>**********************************************
*>                                             *
*>  File Definition For The Purchase Ledger    *
*>                                             *
*>**********************************************
*> rec size 299 bytes  26/03/09
*> rec size 300 bytes  22/12/11
*>
 fd  Purchase-File.
*>
 01  Purch-Record.
     03  Purch-Key           pic x(7).
*>     03  filler   redefines Purch-Key.
*>         05  array-k         pic x  occurs 6.
*>         05  check-digit     pic 9.
     03  purch-status        pic 9.
         88  supplier-live               value 1.
         88  supplier-dead               value 0.
     03  Purch-Notes-Tag     pic 9.
     03  purch-name          pic x(30).
     03  purch-address.
         05  purch-addr1     pic x(48).
         05  purch-addr2     pic x(48).
     03  purch-phone         pic x(13).
     03  purch-ext           pic x(4).
     03  purch-fax           pic x(13).
     03  purch-email         pic x(30).
     03  purch-discount      pic 99v99      comp.
     03  purch-credit        binary-char.
     03  purch-sortcode      binary-long.
     03  purch-accountno     binary-long.
     03  purch-limit         binary-long.
     03  purch-activety      binary-long.
     03  purch-last-inv      binary-long.
     03  purch-last-pay      binary-long.
     03  purch-average       binary-long.
     03  purch-create-date   binary-long.
     03  purch-pay-activety  binary-long.
     03  purch-pay-average   binary-long.
     03  purch-pay-worst     binary-long.
     03  purch-current       pic s9(8)v99   comp-3.
     03  purch-last          pic s9(8)v99   comp-3.
     03  quarters.
         05  turnover-q1     pic s9(8)v99   comp-3.
         05  turnover-q2     pic s9(8)v99   comp-3.
         05  turnover-q3     pic s9(8)v99   comp-3.
         05  turnover-q4     pic s9(8)v99   comp-3.
     03  filler redefines quarters.
         05  pturnover-q     pic s9(8)v99   comp-3 occurs  4.
     03  purch-unapplied     pic s9(8)v99   comp-3.
     03  filler              pic x(16).
*>
