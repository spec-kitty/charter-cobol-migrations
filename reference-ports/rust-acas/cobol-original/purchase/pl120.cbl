       >>source free
*>***************************************************
*>                                                  *
*>            Aged  Creditor  Analysis              *
*>                                                  *
*>***************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl120.
*>**
*>    Author.             V B Coen FBCS, 17/04/84
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Aged Trial Balance.
*>**
*>    Version.            See Prog-Name & Date-Comped In Ws.
*>**
*>    Called Modules.     Maps04.
*>                        Maps99.
*>                        PL165  sort.
*>**
*>    Error messages used.
*>                        NONE
*>**
*>    Changes.
*> 17/04/84 Vbc - If Openitm Record Skipped Perform Bypass-Ageing.
*> 01/05/84 Vbc - Unapplied Cash=Sales-Unapplied If Unapp&Current
*>                Not Zero
*> 25/09/84 Vbc - Support For Pl-Payments.
*> 09/10/84 Vbc - Chg Read-Sales-Test 2 C If Recpts Present.
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 04/04/09 vbc - Support: Report by Supplier name instead of account no.
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 07/09/10 vbc - .07 Mod lpr.
*> 15/12/11 vbc - .08 Error msgs to SLnnn.Support for dates other than UK
*>                    Support for path+filenames.
*>                    Updated version to 3.01.nn
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of the Applewood Computers Accounting System
*> and is copyright (c) Vincent B Coen. 1976-2012 and later.
*>
*> This program is free software; you can redistribute it and/or modify it
*> under the terms of the GNU General Public License as published by the
*> Free Software Foundation; version 2 ONLY.
*>
*> ACAS is distributed in the hope that it will be useful, but WITHOUT
*> ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
*> FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
*> for more details. If it breaks, you own both pieces but I will endevor
*> to fix it, providing you tell me about the problem.
*>
*> You should have received a copy of the GNU General Public License along
*> with ACAS; see the file COPYING.  If not, write to the Free Software
*> Foundation, 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
*>*************************************************************************
*>
 environment             division.
*>===============================
*>
 copy "envdiv.cob".
 input-output            section.
*>------------------------------
*>
 file-control.
*>-----------
*>
 copy "selpl.cob".
 copy "selois.cob".
 copy "selprint.cob".
*>
     select  sales-sort      assign        fn-sales,
                             access        sequential,
                             status        fs-reply.
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdpl.cob".
 copy "fdois.cob".
 fd  sales-sort.
*>
 01  sales-sort-record.
     03  sales-sort-key       pic x(7).
*>
 fd  print-file.
*>
 01  print-record            pic x(132).
*>
 working-storage section.
*>-----------------------
 77  prog-name           pic x(15) value "PL120 (3.01.08)".
 copy "print-spool-command.cob".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
 copy "wsoi.cob".
*>
 01  ws-data.
     03  menu-reply      pic 9.
     03  ws-reply        pic x.
     03  report-type     pic x              value space.
         88  sorted-report                  value "S".
     03  z               pic 99.
     03  y               pic 99.
     03  truth           pic 9.
         88  a-true                         value 1.
         88  a-false                        value zero.
     03  first-time      pic 9            value zero.
     03  ws-spaces       pic x(80)        value spaces.
     03  st-date         pic x(8)         value spaces.
     03  work-1          pic s9(7)v99     value zero.
     03  work-2          pic s9(7)v99.
     03  display-8       pic z(5)9.99.
     03  display-5       pic zz9.99.
     03  a               binary-long      value zero.
     03  b               binary-long      value zero.
     03  i               pic 99.
     03  j               pic 99.
     03  k               pic 99.
     03  l-p             pic 99           value zero.
     03  customer-in     pic x(7)         value spaces.
     03  filler  redefines  customer-in.
         05  array-l     pic x  occurs  7.
     03  pay-date        binary-long      .
     03  pay-value       pic s9(6)v99     value zero.
     03  pay-paid        pic s9(6)v99.
     03  last-read       pic x(7)         value spaces.
     03  page-nos        binary-char      value zero.
     03  line-cnt        binary-char      value 66.
     03  inv-amount      pic s9(7)v99     value zero.
     03  amount-out      pic s9(7)v99     value zero.
     03  entered-date    binary-long      value zero.
*>
 01  ws-amount-screen-display.
     03  ws-poundsd      pic 9(6).
     03  ws-period       pic x     value ".".
     03  ws-penced       pic v99.
 01  ws-amount-screen-accept redefines ws-amount-screen-display.
     03  ws-pound        pic 9(6).
     03  filler          pic x.
     03  ws-pence        pic v99.
*>
 01  ws-amount-work.
     03  amt-wk-pds      pic 9(6).
     03  amt-wk-pence    pic v99.
 01  ws-amount-ok redefines ws-amount-work.
     03  amt-ok          pic 9(6)v99.
*>
 01  ws-Test-Date            pic x(10).
 01  ws-date-formats.
     03  ws-swap             pic xx.
     03  ws-Conv-Date        pic x(10).
     03  ws-date             pic x(10).
     03  ws-UK redefines ws-date.
         05  ws-days         pic xx.
         05  filler          pic x.
         05  ws-month        pic xx.
         05  filler          pic x.
         05  ws-year         pic x(4).
     03  ws-USA redefines ws-date.
         05  ws-usa-month    pic xx.
         05  filler          pic x.
         05  ws-usa-days     pic xx.
         05  filler          pic x.
         05  filler          pic x(4).
     03  ws-Intl redefines ws-date.
         05  ws-intl-year    pic x(4).
         05  filler          pic x.
         05  ws-intl-month   pic xx.
         05  filler          pic x.
         05  ws-intl-days    pic xx.
*>
*> 01  Error-Messages.
*> System Wide
*> Module specific
*>
 01  error-code          pic 999.
*>
 01  All-My-Constants    pic 9(4).
     copy "screenio.cpy".
*>
 01  fn-sales        pic x(12)       value "suppsort.inx".
*>
 01  analysis                                   comp-3.
     03  inv-0              pic s9(6)     value zero.
     03  inv-30             pic s9(6)     value zero.
     03  inv-60             pic s9(6)     value zero.
     03  inv-90             pic s9(6)     value zero.
     03  tot-bal-0          pic s9(8)v99  value zero.
     03  tot-bal-30         pic s9(8)v99  value zero.
     03  tot-bal-60         pic s9(8)v99  value zero.
     03  tot-bal-90         pic s9(8)v99  value zero.
     03  tot-os-bal         pic s9(8)v99  value zero.
     03  tot-no-pay         pic s9(5)     value zero.
     03  tot-no-cr-bal      pic s9(5)     value zero.
     03  tot-acct-active    pic s9(5)     value zero.
     03  tot-acct-live      pic s9(5)     value zero.
     03  tot-no-late        pic s9(5)     value zero.
     03  tot-no-unapp-pay   pic s9(5)     value zero.
     03  tot-prompt-lost-no pic s9(5)     value zero.
     03  tot-amt-late       pic s9(7)v99  value zero.
     03  tot-amt-pay        pic s9(7)v99  value zero.
     03  tot-amt-cr-bal     pic s9(7)v99  value zero.
     03  tot-amt-unapp-pay  pic s9(7)v99  value zero.
     03  tot-unappl-credits pic s9(7)v99  value zero.
     03  tot-sales-bal      pic s9(7)v99  value zero.
     03  tot-prompt-lost-amt pic s9(7)v99 value zero.
*>
 01  balances                            comp-3.
     03  bal-0           pic s9(7)v99 value zero.
     03  bal-30          pic s9(7)v99 value zero.
     03  bal-60          pic s9(7)v99 value zero.
     03  bal-90          pic s9(7)v99 value zero.
     03  bal-t           pic s9(7)v99 value zero.
     03  bal-pay         pic s9(7)v99 value zero.

 01  line-1.
     03  l1-version      pic x(56)       value spaces.
     03  filler          pic x(22)       value "Aged Creditors Report".
     03  l1-sorted       pic x(8)        value spaces.
     03  filler          pic x(38)       value spaces.
     03  filler          pic x(5)        value "Page ".
     03  l1-page         pic zz9.
*>
 01  line-3.
     03  l3-user         pic x(56)       value spaces.
     03  l3-list.
         05  l3-lcur     pic x(18)       value "Current Period is ".
         05  l3-period   pic z9          blank when zero.
     03  filler          pic x(46)       value spaces.
     03  l3-date         pic x(10).
*>
 01  line-4.
     03  filler          pic x(132)       value
         "Supplier              Name                 Telephone " &
         "    Folio      Date       Current         30         60    90 & over   Payments".
*>
 01  line-5  value spaces.
     02  l5-f1.
         03  l5-account   pic x(9).
         03  l5-name      pic x(32).
         03  l5-telephone pic x(13).
     02  l5-title.
         03  l5-invoice   pic z(7)9       blank when zero.
         03  l5-hold      pic x.
         03  l5-late      pic x.
         03  l5-date      pic x(10).
     02  l5-f2.
         03  l5-less      pic x.
         03  l5-bal-0     pic zzzzzz9.99cr.
         03  l5-greater   pic x.
         03  l5-bal-30    pic zzzzzzz9.99.
         03  l5-bal-60    pic zzzzzzz9.99.
         03  l5-bal-90    pic zzzzzz9.99.
         03  l5-less-1    pic x.
         03  l5-payments  pic zzzzzz9.99.
         03  l5-greater-1 pic x.
*>
 01  line-6.
     03  l6-lover        pic x(5)        value spaces.
     03  l6-over         pic zzz,zz9.99bb  blank when zero.
     03  filler          pic x(7)        value "Terms:".
     03  l6-credit       pic z9bb.
     03  filler          pic x(13)       value "Credit Limit:".
     03  l6-limit        pic zzzz,zz9.
     03  filler          pic x(6)        value spaces.
     03  l6-lbalance     pic x(8)        value "Balance:".
     03  l6-balance      pic zzzz,zz9.99.
     03  l6-bal-0        pic zzzz,zz9.99cr.
     03  l6-bal-30       pic zzzz,zz9.99.
     03  l6-bal-60       pic zzzz,zz9.99.
     03  l6-bal-90       pic zzzz,zz9.99.
     03  l6-payments     pic zzzz,zz9.99.
*>
 01  line-7.
     03  filler          pic x(29)       value spaces.
     03  filler          pic x(103)      value "Total       Current         30           60       90 & over".
*>
 01  line-8.
     03  l8-head.
      05 l8-hd1          pic x.
      05 l8-hd2          pic x(24).
     03  l8-tot          pic zzzz,zz9.99cr.
     03  l8-0            pic zzzz,zz9.99cr.
     03  l8-30           pic zzzz,zz9.99cr.
     03  l8-60           pic zzzz,zz9.99cr.
     03  l8-90           pic zzzz,zz9.99cr.
*>
 01  line-10 redefines line-8.
     03  l10-head        pic x(25).
     03  l10-tot         pic zzzz,zz9bbbbb.
     03  l10-0           pic zzzz,zz9bbbbb.
     03  l10-30          pic zzzz,zz9bbbbb.
     03  l10-60          pic zzzz,zz9bbbbb.
     03  l10-90          pic zzzz,zz9.
*>
 01  line-9.
     03  filler          pic x(29) value spaces.
     03  filler          pic x(19) value "Number       Amount".
*>
 01  line-11.
     03  filler          pic x(25) value spaces.
     03  l11-f1          pic x(13) value all "-".
     03  l11-f2          pic x(13) value all "-".
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wssys4.cob".
 copy "wsnames.cob".
*>
 01  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record system-record-4 to-day file-defs.
*>======================================================================================
 init01 section.
*>
     if       p-flag-p = 1
              move 24 to error-code
              call "maps99" using error-code ws-calling-data
              move 15 to error-code
              call "maps99" using error-code ws-calling-data
              go to menu-ent.
*>
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name to PSN.
*>
     move     to-day to u-date.
     if       file-status (29) not = 1
              move 25  to  error-code
              call "maps99"  using  error-code ws-calling-data
              move 15 to error-code
              call "maps99" using error-code ws-calling-data
              go to menu-ent.
*>
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "Aged Creditors Report" at 0131 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
     perform  trail-balance.
     perform  report-analysis.
     close    print-file.
     call     "SYSTEM" using Print-Report.
*>
 menu-ent.
     exit     program.
*>
*>****************************************************************
*>      P R O C E D U R E S                                      *
*>****************************************************************
*>
 trail-balance           section.
*>==============================
*>
     display  "****************************************" at 0441 with foreground-color 2.
     display  "*Date  [  /  /    ]*A/C Nos   [       ]*" at 0541 with foreground-color 2.
     display  "***                                  ***" at 0641 with foreground-color 2.
     display  "*Value  [         ]*                   *" at 0741 with foreground-color 2.
     display  "****************************************" at 0841 with foreground-color 2.
*>
 main-display-end.
*>
     display  "Notes" at 1201 with foreground-color 2.
     display  "*****" at 1301 with foreground-color 2.
     display  " (1)  -  <Date>  :  Appears on listing" at 1501         with foreground-color 2.
     display  " (2)  -  <A/C>   :  A/Cs to match for printing" at 1601 with foreground-color 2.
     display  " (3)  -  <Value> :  Minimum o/s to print" at 1701       with foreground-color 2.
     display  " (4)  -  F1 pressed gives Alphabetic Sort" at 1801      with foreground-color 2.
*>
 date-input.
     move     zero to cob-crt-status.
     display  ws-date at 0549 with foreground-color 3.
     accept   ws-date at 0549 with foreground-color 3 update.
     move     ws-date to ws-test-date.
     perform  zz050-Validate-Date.
     if       u-bin = zero
              go to  date-input.
*>
     move     ws-date  to  l3-date.
     move     u-bin to entered-date.
     if       Cob-Crt-Status = Cob-Scr-F1
              move "S" to Report-Type.
*>
 customer-input.
*>*************
*>
     accept   customer-in at 0572 with foreground-color 3.
     move     function upper-case (customer-in) to customer-in.
     if       Cob-Crt-Status = Cob-Scr-F1
              move "S" to Report-Type.
*>
 value-input.
*>**********
*>
     move     0750 to curs.
     perform  accept-money.
     move     amt-ok to pay-value.
     if       Cob-Crt-Status = Cob-Scr-F1
              move "S" to Report-Type.
*>
     open     output print-file.
     move     zero  to  page-nos.
     if       Sorted-Report
              move "(Sorted)" to l1-sorted
              open input sales-sort.
     perform  headings.
     open     input purchase-file.
     open     input open-item-file-s.
     if       fs-reply not = zero
              go to main-end.
*>
     if       customer-in = spaces
              go to read-perform.
     move     customer-in to purch-key.
     start    purchase-file key not < purch-key invalid key
              move 1 to y.
     inspect  customer-in replacing all spaces by "Z".
*>
 read-perform.
*>***********
*>
     perform  read-sales.
*>
     if       fs-reply = 99
              go to  main-end.
*>
     if       last-read = purch-key
              go to roi-1.
*>
 read-open-item.
*>*************
*>
     if       last-read > purch-key
              go to read-perform.
*>
     read     open-item-file-s at end
              perform  end-statement
              go to    item-end.
*>
     move     open-item-record-s  to  oi-header.
     move     oi-supplier  to  last-read.
*>
     if       last-read  >  purch-key
              go to  end-statement.
*>
     if       last-read  not equal  purch-key
              perform bypass-ageing
              go to  read-open-item.
 roi-1.
*>
*> if here then o-i transaction is for this customer.
*>
     if       oi-type = 1
              go to  read-open-item.
*>
*> can safely ignore receipts.
*>
     if       line-cnt > Page-Lines - 5
              perform headings.
     if       oi-type = 5 or 6
              move zero to oi-invoice.
     move     oi-invoice  to  l5-invoice.
     move     oi-hold-flag to l5-hold.
*>
     move     oi-date  to  u-bin.
     perform  zz060-Convert-Date.
     move     ws-date  to l5-date.
*>
*> invoices only here
*>
     add     oi-net oi-carriage oi-vat oi-c-vat giving inv-amount.
*>
     if       oi-type = 2
              subtract   oi-paid  from  inv-amount giving  amount-out.
*>
*> cr. notes only here.
*>
     if       oi-type = 3
              add  oi-paid  to  inv-amount
              move  inv-amount  to  l5-bal-0
              perform check-zero
              go to bypass-ageing.
*>
*> payments  only here.
*>
     if       oi-type = 5  or  6
              add   oi-paid  to  bal-pay
              perform check-zero
              go to bypass-ageing.
*>
     subtract oi-date  from  entered-date  giving  work-1.
*>
     if       work-1 not > oi-deduct-days
         and  oi-deduct-amt not = zero
              subtract oi-deduct-amt from inv-amount
              move "*" to l5-late.
*>
     if       work-1 > oi-deduct-days
       and    oi-deduct-amt > zero
              add 1 to tot-prompt-lost-no
              add oi-deduct-amt to tot-prompt-lost-amt.
*>
*> now work out ageing
*> (dont worry if paid in full - routine still works ok)
*>   Also force credit balance into current
*>
     if       amount-out = zero
              move 0 to b
        else  move 1 to b.
*>
     if       amount-out is negative
              move 1 to work-1.
*>
     if       work-1  <  30
              add  amount-out  to  bal-0
              move amount-out to l5-bal-0
              perform check-zero
              add amount-out to tot-bal-0
              add b to inv-0
     else
      if      work-1  <  60
              add  amount-out  to  bal-30
              move amount-out to l5-bal-30
              add amount-out to tot-bal-30
              add b to inv-30
      else
       if     work-1  <  90
              add  amount-out  to  bal-60
              move amount-out to l5-bal-60
              add amount-out to tot-bal-60
              add b to inv-60
       else
              move amount-out to l5-bal-90
              add  amount-out to tot-bal-90
              add b to inv-90
              add  amount-out  to  bal-90.
*>
     add      amount-out  to  bal-t.
*>
 bypass-ageing.
*>
*> ie payment
*>
     if       (oi-type = 5 or = 6)
         and  oi-deduct-amt not = zero
              add oi-deduct-amt to tot-amt-late.
     if       oi-type = 5 or 6
              add  oi-paid  to  tot-amt-pay
              add  1  to  tot-no-pay.
*>
 bypass-age-go.
     if       oi-type = 3 and
              inv-amount not = zero
              add inv-amount to tot-unappl-credits.
*>
     move     zero to amount-out.
*>
*> now to print. what joy!!!!!!.
*>
     if       l5-account not = spaces
              write print-record from ws-spaces after 1
              add 1 to line-cnt.
     write    print-record  from  line-5 after 1.
     add      1 to line-cnt.
*>
*> now loop back for next item.
*>
     move     spaces  to  line-5.
     go to    read-open-item.
*>
*> can only get here at the end of a statement.
*>
 end-statement.
*>************
*>
     move     bal-0   to  l6-bal-0.
     move     bal-30  to  l6-bal-30.
     move     bal-60  to  l6-bal-60.
     move     bal-90  to  l6-bal-90.
     move     bal-pay to  l6-payments.
*>
     if       l6-lbalance not = spaces
              write print-record  from  line-6 after 1
              write print-record  from  ws-spaces after 1
              move spaces to l6-lbalance
              add 2 to line-cnt.
*>
*> now set-up for the next one then zeroise counter fields.
*>
*> now as promised some zeroising.
*>
     move     zero  to  bal-0   bal-30
                        bal-60  bal-90
                        bal-pay bal-t.
*>
*> loop time.......get another punter.
*>
 end-statement-end.
*>
 item-end.
*>
     go to    read-perform.
*>
*> above forces all sales records to be read & counted
*>
 accept-money.
*>-----------
*>
     move     zero to ws-poundsd amt-ok ws-penced.
     display  ws-amount-screen-display at curs with foreground-color 3.
     accept   ws-amount-screen-accept at curs  with foreground-color 3 update.
     move     ws-pound to amt-wk-pds.
     move     ws-pence to amt-wk-pence.
*>
 main-end.
*>*******
*>
     close    open-item-file-s purchase-file.
     if       Sorted-Report
              close sales-sort.
*>
 main-exit.   exit section.
*>********    ****
*>
 headings     section.
*>===================
*>
     if       line-cnt < Page-Lines - 5
              go to main-exit.
     add      1  to  page-nos.
     move     page-nos  to  l1-page.
     move     prog-name to  l1-version.
     move     usera     to  l3-user.
     if       line-cnt not = 99
              move scycle to  l3-period.
*>
     if       page-nos not = 1
              write print-record from line-1 after page
              move  spaces  to  print-record
              write print-record after 1
     else
              write print-record from line-1 before 1
     end-if
     write    print-record  from  line-3 after 1.
     write    print-record  from  line-4 after 2.
     move     zero to line-cnt.
*>
 main-exit.   exit section.
*>********    ****
*>
 report-analysis          section.
*>===============================
*>
     move     " Account Statistics " to l3-list.
     move     spaces to line-4 l1-Sorted.
     move     99 to line-cnt.
     perform  headings.
     write    print-record from line-7 after 1.
     write    print-record from ws-spaces after 1.
     move     "Number of Invoices" to l10-head.
     move     inv-0  to l10-0.
     move     inv-30 to l10-30.
     move     inv-60 to l10-60.
     move     inv-90 to l10-90.
     add      inv-0 inv-30 inv-60 inv-90 giving a.
     move     a to l10-tot.
     write    print-record from line-10 after 1.
     move     "Amount" to l8-head.
     move     tot-bal-0  to l8-0.
     move     tot-bal-30 to l8-30.
     move     tot-bal-60 to l8-60.
     move     tot-bal-90 to l8-90.
     add      tot-bal-0 tot-bal-30 tot-bal-60 tot-bal-90
              giving tot-os-bal.
*>
*>    note that tot-os-bal does not include credit balances.
*>
     move     tot-os-bal to l8-tot work-2.
     write    print-record from line-8 after 1.
     move     "% of O/S Invoices" to l8-head.
     move     100 to l8-tot.
     compute  work-1 rounded = (tot-bal-0 * 100) / work-2.
     move     work-1 to l8-0.
     compute  work-1 rounded = (tot-bal-30 * 100) / work-2.
     move     work-1 to l8-30.
     compute  work-1 rounded = (tot-bal-60 * 100) / work-2.
     move     work-1 to l8-60.
     compute  work-1 rounded = (tot-bal-90 * 100) / work-2.
     move     work-1 to l8-90.
     write    print-record from line-8 after 1.
     move     "Average O/S Amount" to l8-head.
     move     zero to l8-0 l8-30 l8-60 l8-90.
     if       inv-0 not = zero
              divide tot-bal-0 by inv-0 giving l8-0.
     if       inv-30 not = zero
              divide tot-bal-30 by inv-30 giving l8-30.
     if       inv-60 not = zero
              divide tot-bal-60 by inv-60 giving l8-60.
     if       inv-90 not = zero
              divide tot-bal-90 by inv-90 giving l8-90.
     divide   work-2 by a giving l8-tot.
     write    print-record from line-8 after 1.
     write    print-record from line-9 after 3.
     move     spaces to line-8.
     move     "Unapplied Cash" to l8-head.
     move     tot-amt-unapp-pay to l8-0.
     move     tot-no-unapp-pay to l10-tot.
     write    print-record from line-8 after 2.
     move     "Payments" to l8-head.
     move     pl-payments to l8-0.
     move     tot-no-pay  to l10-tot.
     write    print-record from line-8 after 1.
     move     "Credit Balances" to l8-head.
     move     tot-no-cr-bal to l10-tot.
     move     tot-amt-cr-bal to l8-0.
     write    print-record from line-8 after 1.
     move     "Prompt Payment Disc. lost" to l8-head.
     move     tot-prompt-lost-amt to l8-0.
     move     tot-prompt-lost-no to l10-tot.
     write    print-record from line-8 after 1.
     move     spaces to line-8.
     move     "Number of Live Accounts" to l10-head.
     move     tot-acct-live to l10-tot.
     write    print-record from line-10 after 1.
     move     "Number of Active Accounts" to l10-head.
     move     tot-acct-active to l10-tot.
     write    print-record from line-10 after 1.
     move     "% Active" to l8-head.
     compute  work-1 = (tot-acct-active * 100) / tot-acct-live.
     move     work-1 to l8-tot.
     write    print-record from line-8 after 1.
*>
     if       customer-in not = spaces
              go to main-exit.
*>
     move     spaces to line-10.
     move     "  Reconciliation Data:" to l10-head.
     write    print-record from line-10 after 3.
     move     spaces to l10-head.
     write    print-record from line-10 after 1.
     move     pl-os-bal-last-month to l8-tot.
     move     "Balance Brought Forward" to l10-head.
     write    print-record from line-10 after 1.
     move     pl-invoices-this-month to l8-tot.
     move     "Plus: Invoices Posted" to l10-head.
     write    print-record from line-10 after 1.
*>     move     "      Unapplied CN Bal's" to l10-head.
*>     multiply -1 by pl-cn-unappl-this-month giving tot-bal-60.
*>     move     tot-bal-60 to l8-tot.
*>     write    print-record from line-10 after 1.
*>     move  zero to Tot-Bal-60
     add      pl-os-bal-last-month
              pl-invoices-this-month
*> tot-bal-60
                     giving tot-bal-0.
     write    print-record from line-11 after 1.
     move     spaces to line-10.
     move     tot-bal-0 to l8-0.
     write    print-record from line-10 after 1.
     move     spaces to line-10.
     move     pl-credit-notes-this-month to l8-tot.
     move     "Less: Credit Notes Posted" to l10-head.
     write    print-record from line-10 after 2.
     move     pl-payments to l8-tot.
     move     "      Payments Posted" to l10-head.
     write    print-record from line-10 after 1.
     move     tot-amt-late to l8-tot.
     move     "      Prompt pay taken" to l10-head.
     write    print-record from line-10 after 1.
*>    move     "      CN Late Chgs Taken" to l10-head.
*>    move     pl-credit-deductions to l8-tot.
*>    write    print-record from line-10 after 1.
     write    print-record from line-11 after 1.
     add      tot-amt-late pl-payments
               pl-credit-notes-this-month
*>              pl-credit-deductions
                 giving tot-bal-30.
     move     spaces to line-10.
     move     tot-bal-30 to l8-0.
     write    print-record from line-10 after 1.
     move     spaces to l11-f1.
     write    print-record from line-11 after 2.
     subtract tot-bal-30 from tot-bal-0.
     move     "Balance Carried Forward" to l10-head.
     move     tot-bal-0 to l8-0 pl-os-bal-this-month.
     write    print-record from line-10 after 1.
     move     all "=" to l11-f2.
     write    print-record from line-11 after 1.
     move     spaces to line-8.
     subtract tot-bal-0 from tot-sales-bal giving pl-variance.
     move     pl-variance to l8-tot.
     if       pl-variance not = zero
              move "Out of Balance" to l8-hd2
              add pl-variance to pl-os-bal-this-month
              write print-record from line-10 after 2.
*>
 main-exit.
     exit    section.
*>
 read-sales   section.
*>*******************
*>
     if       not Sorted-Report
              go to Read-Purch-File.
*>
     read     sales-sort record at end
              move 99 to fs-reply
              go to main-end.
*>
     move     sales-sort-key to purch-key.
     read     purchase-file  invalid key
              display "Not Found - " at 2301 with foreground-color 4
              display purch-key at 2313 with foreground-color 4
              go to  read-sales.
     go       to Purch-Rec-Wanted.
*>
 Read-Purch-File.
     read     purchase-file  next  record at end
              move 99  to  fs-reply
              go to  main-end.
*>
     if       fs-reply not = zero
              move 99 to fs-reply
              go to main-end.
*>
 Purch-Rec-Wanted.
     if       customer-in not = spaces
        and   purch-key > customer-in
              move 99 to fs-reply
              go to main-end.
*>
     add      1 to tot-acct-live.
     add      purch-current to tot-sales-bal.
*>
     if       purch-unapplied not = zero
        and   purch-current not = zero
              add purch-unapplied to tot-amt-unapp-pay
              add 1 to tot-no-unapp-pay.
*>
     if       purch-unapplied not = zero
              subtract purch-unapplied from tot-sales-bal
              subtract purch-unapplied from purch-current.
*>
     if       purch-current negative
              add 1 to tot-no-cr-bal
              add purch-current to tot-amt-cr-bal.
*>
     perform  read-sales-test.
     if       a-false
              go to read-sales.
*>
     move     purch-name  to  l5-name.
     add      1 to tot-acct-active.
     move     purch-key  to  l5-account.
     move     purch-phone  to  l5-telephone.
     move     purch-current  to  l6-balance.
     move     "Balance:" to l6-lbalance.
     move     spaces     to l6-lover.
     move     purch-credit  to  l6-credit.
     move     purch-limit   to  l6-limit.
     if       purch-current > purch-limit
              subtract purch-limit from purch-current giving l6-over
              move "Over:" to l6-lover
     else     move zero to l6-over.
     if       purch-current is negative
              move "Cr Bal:" to l6-lbalance.
     perform  headings.
     if       purch-unapplied = zero
              go to main-end.
     move     purch-unapplied to l5-payments.
     move     "Unapplied Cash" to l5-title.
     add      purch-unapplied to bal-pay.
     write    print-record from line-5 after 2.
     move     spaces to line-5.
     add      2 to line-cnt.
     if       last-read not = purch-key
              perform  end-statement.
     go       to main-end.
*>
 read-sales-test.
*>**************
*>
     move     1 to truth.
*>
     if       purch-current = zero
              move zero to truth.
*>
     if       purch-last-pay > purch-last-inv
              move purch-last-pay to pay-date
     else     move purch-last-inv to pay-date.
*>
     if       purch-current = zero
      and     pay-date > s-end-cycle-date
              move 1 to truth.
*>
     if       purch-current = zero and
              purch-last-pay not = zero and
              purch-last-pay = purch-last-inv
              move zero to truth
              perform test-for-inv.
*>
     if       pay-value not = zero
       and    purch-current  <  pay-value
              move zero to truth.
*>
 main-end.
*>*******
*>
     go       to main-exit.
*>
 test-for-inv.
*>***********
*>
     if       last-read = purch-key
              move 1 to truth.
*>
 main-exit.   exit section.
*>********
*>
 check-zero   section.
*>===================
*>
     if       oi-type = 3
              go to test2.
     if       oi-type = 5 or 6
              go to test3.
     if       amount-out = zero
              move "<" to l5-less
              move ">" to l5-greater
              move oi-paid to l5-bal-0.
     go       to main-exit.
*>
 test2.
*>
     if       inv-amount = zero
              move "<" to l5-less
              move ">" to l5-greater
              multiply oi-paid by -1 giving l5-bal-0.
     go       to main-exit.
*>
 test3.
     if       oi-paid = oi-approp
              move "<" to l5-less-1
              move ">" to l5-greater-1
              move oi-paid to l5-payments
      else
              subtract oi-approp from oi-paid giving l5-payments.
 main-exit.   exit section.
 zz050-Validate-Date        section.
*>*********************************
*>
*>  Converts USA/Intl to UK date format for processing.
*>*****************************************************
*> Input:   ws-test-date
*> output:  u-date/ws-date as uk date format
*>          u-bin not zero if valid date
*>
     move     ws-test-date to ws-date.
     if       Date-Form = zero
              move 1 to Date-Form.
     if       Date-UK
              go to zz050-test-date.
     if       Date-USA                *> swap month and days
              move ws-days to ws-swap
              move ws-month to ws-days
              move ws-swap to ws-month
              go to zz050-test-date.
*>
*> So its International date format
*>
     move     "dd/mm/ccyy" to ws-date.  *> swap Intl to UK form
     move     ws-test-date (1:4) to ws-Year.
     move     ws-test-date (6:2) to ws-Month.
     move     ws-test-date (9:2) to ws-Days.
*>
 zz050-test-date.
     move     ws-date to u-date.
     move     zero to u-bin.
     perform  maps04.
*>
 zz050-exit.
     exit     section.
*>
 zz060-Convert-Date        section.
*>********************************
*>
*>  Converts date in binary to UK/USA/Intl date format
*>****************************************************
*> Input:   u-bin
*> output:  ws-date as uk/US/Inlt date format
*>          u-date & ws-Date = spaces if invalid date
*>
     perform  maps04.
     if       u-date = spaces
              move spaces to ws-Date
              go to zz060-Exit.
     move     u-date to ws-date.
*>
     if       Date-Form = zero
              move 1 to Date-Form.
     if       Date-UK
              go to zz060-Exit.
     if       Date-USA                *> swap month and days
              move ws-days to ws-swap
              move ws-month to ws-days
              move ws-swap to ws-month
              go to zz060-Exit.
*>
*> So its International date format
*>
     move     "ccyy/mm/dd" to ws-date.  *> swap Intl to UK form
     move     u-date (7:4) to ws-Intl-Year.
     move     u-date (4:2) to ws-Intl-Month.
     move     u-date (1:2) to ws-Intl-Days.
*>
 zz060-Exit.
     exit     section.
*>
 zz070-Convert-Date        section.
*>********************************
*>
*>  Converts date in to-day to UK/USA/Intl date format
*>****************************************************
*> Input:   to-day
*> output:  ws-date as uk/US/Inlt date format
*>
     move     to-day to ws-date.
*>
     if       Date-Form = zero
              move 1 to Date-Form.
     if       Date-UK
              go to zz070-Exit.
     if       Date-USA                *> swap month and days
              move ws-days to ws-swap
              move ws-month to ws-days
              move ws-swap to ws-month
              go to zz070-Exit.
*>
*> So its International date format
*>
     move     "ccyy/mm/dd" to ws-date.  *> swap Intl to UK form
     move     to-day (7:4) to ws-Intl-Year.
     move     to-day (4:2) to ws-Intl-Month.
     move     to-day (1:2) to ws-Intl-Days.
*>
 zz070-Exit.
     exit     section.
*>
 maps04       section.
*>*******************
*>
     call     "maps04"  using  maps03-ws.
*>
 maps04-exit.
     exit     section.
*>
