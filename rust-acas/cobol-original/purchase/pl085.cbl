       >>source free
*>************************************************
*>                                               *
*>           Payment  Data  Amend                *
*>                                               *
*>************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl085.
*>**
*>    Author.             V B Coen FBCS, Applewood Conputers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Payment Data Amend.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps99.
*>**
*>    Error messages used.
*>                        PL003
*>                        PL140
*>                        PL141
*>****
*>    Changes.
*> 08/05/84 Vbc - Accept-Money Routine Must Use Pounds,Pence 2.
*> 22/05/84 Vbc - Support For Indexed Open Item File.
*> 31/05/84 Vbc - Fix Bug Re Zeroise Oi-Deduct-Amt Regardless.
*> 29/06/84 Vbc - Change Deduct-Amt Routines For Pl.
*> 21/02/85 Vbc - Test P-Flag-P On Start Of Prog.
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00
*> 15/12/11 vbc - .02 Error msgs to SLnnn.Support for dates other than UK
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
 copy "seloi5.cob".
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdpl.cob".
 copy "fdoi5.cob".
*>
 working-storage section.
*>-----------------------
 77  prog-name           pic x(15) value "PL085 (3.01.02)".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
*>
 01  ws-amount-screen-display.
     03  ws-poundsd      pic 9(7).
     03  ws-period       pic x     value ".".
     03  ws-penced       pic v99.
 01  ws-amount-screen-accept redefines ws-amount-screen-display.
     03  ws-pound        pic 9(7).
     03  filler          pic x.
     03  ws-pence        pic v99.
*>
 01  ws-amount-work.
     03  amt-wk-pds      pic 9(7).
     03  amt-wk-pence    pic v99.
 01  ws-amount-ok redefines ws-amount-work.
     03  amt-ok          pic 9(7)v99.
*>
 01  ws-amount-screen-display2.
     03  ws-poundsd2     pic 999.
     03  ws-period2      pic x     value ".".
     03  ws-penced2      pic v99.
 01  ws-amount-screen-accept2 redefines ws-amount-screen-display2.
     03  ws-pound2       pic 999.
     03  filler          pic x.
     03  ws-pence2       pic v99.
*>
 01  ws-amount-work2.
     03  amt-wk-pds2     pic 999.
     03  amt-wk-pence2   pic v99.
 01  ws-amount-ok2 redefines ws-amount-work2.
     03  amt-ok2         pic 999v99.
*>
 copy "wsoi.cob".
*>
 01  ws-data.
     03  ws-reply        pic x.
     03  a               pic 99                   value zero.
     03  c-check         pic 9                    value zero.
         88  c-exists                             value 1.
     03  work-1          pic s9(6)v99.
     03  display-8       pic -(5)9.99.
     03  display-s       pic z(5)9.99cr.
     03  display-n       pic 9(5).
     03  display-inv     pic z(7)9.
     03  si-deduct-amt   pic s999v99     comp     value zero.
     03  si-display      pic -zz9.99.
     03  k               pic 999                  value zero.
     03  approp-amount   pic s9(6)v99    comp-3   value zero.
     03  pay-customer    pic x(7).
     03  pay-date        binary-long.
     03  pay-value       pic s9(6)v99    comp-3   value zero.
     03  address1        pic x(96).
     03  address-line    pic x(36).
     03  transaction-type pic 9                   value zero.
         88  trans-payment                        value 5.
         88  trans-unapplied                      value 6.
     03  hold-pay        pic s9(6)v99     comp-3  value zero.
     03  save-key.
         05 save-supplier   pic x(7).
         05 save-invoice    binary-long.
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
 01  Error-Messages.
*> System Wide
     03  PL003           pic x(28) value "PL003 Hit Return To Continue".
*> Module specific
     03  PL140           pic x(36) value "PL140 Not Yet Supporting Corrections".
     03  PL141           pic x(42) value "PL141 Amount Approp Or Deduct Amt Not Zero".
*>
 01  error-code          pic 999.
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
*>
 01  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 init01 section.
     if       p-flag-p = 0
              move 30 to error-code
              call "maps99" using error-code ws-calling-data
              move 15 to error-code
              call "maps99" using error-code ws-calling-data
              go to main-exit.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
*>
 display-heads.
*>------------
*>
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "Payment Data Amend" at 0133 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
 dh-exit.
*>
     move     zero  to  k.
     open     i-o purchase-file open-item-file-5.
     perform  new-payment.
     close    purchase-file open-item-file-5.
*>
 menu-exit.
*>********
*>
     move     "Y" to oi-5-flag.
     perform  display-heads.
*>
 main-exit.
     exit     program.
*>
*>***************************************
*>             procedures               *
*>***************************************
*>
 new-payment             section.
*>==============================
*>
     move     4  to  lin.
     perform  display-heads.
*>
     display  "****************************************" at 0441 with foreground-color 2.
     display  "*Date  [  /  /    ]*A/C Nos   [       ]*" at 0541 with foreground-color 2.
     display  "***                                  ***" at 0641 with foreground-color 2.
     display  "*Value [          ]*Batch   [     /   ]*" at 0741 with foreground-color 2.
     display  "****************************************" at 0841 with foreground-color 2.
*>
 main-display-end.
*>***************
*>
     perform  zz070-Convert-Date.
     display  ws-date at 0549 with foreground-color 3.
*>
 get-batch.
*>
     move     spaces to oi5-supplier.
     accept   oi5-supplier at 0572 with foreground-color 3 update.
     move     function upper-case (oi5-supplier) to oi5-supplier.
     display  oi5-supplier at 0572 with foreground-color 3.
     if       oi5-supplier = spaces
              go to main-exit.
*>
 customer-input.
*>*************
*>
     move     zero to display-n.
     accept   display-n at 0770 with foreground-color 3 update.
     if       display-n = zero
              go to  main-exit.
*>
     accept   k at 0776 with foreground-color 3 update.
*>
     if       k = zero
              go to customer-input.
     multiply display-n by 1000 giving oi5-invoice.
     add      k to oi5-invoice.
     move     oi5-key to save-key.
     start    open-item-file-5 key not < oi5-key.
*>
 find-trans-loop.
*>**************
*>
     read     open-item-file-5 next record at end
              go to  get-batch.
     move     open-item-record-5  to  oi-header.
*>
     if       oi-supplier not = save-supplier
         or   oi-invoice not = save-invoice
              go to get-batch.
*>
     if       oi-b-nos not = display-n
           or oi-b-item not = k
           or (oi-type not = 5 and not = 6)
              go to  find-trans-loop.
*>
     if       oi-type = 6
              display "Warning Unapplied Balance Journal" at 0645  with foreground-color 2
*>
     move     oi-type to transaction-type.
*>
     move     oi-supplier  to  pay-customer.
     move     oi-date      to  pay-date.
     move     oi-paid      to  pay-value hold-pay.
     move     oi-approp    to  approp-amount.
*>
     display  pay-customer at 0572 with foreground-color 3.
     move     pay-customer to  purch-key.
*>
     read     purchase-file  record  invalid key
              move  zero  to  c-check.
*>
     move     purch-address  to  address1.
*>
     display  purch-name at 0401 with foreground-color 3.
*>
     move     1  to  a.
     unstring address1  delimited  by pl-delim  into  address-line count a pointer  a.
     display  address-line at 0501 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address1  delimited  by pl-delim  into  address-line count a pointer  a.
     display  address-line at 0601 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address1  delimited  by pl-delim  into  address-line count a pointer  a.
     display  address-line at 0701 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address1 into address-line pointer  a.
     display  address-line at 0801 with foreground-color 3.
*>
     move     spaces  to  address-line.
*>
     move     purch-current  to  display-s.
     display  "Current Balance - " at 1001  with foreground-color 2.
     display  display-s at 1019 with foreground-color 3.
*>
 value-input.
*>**********
*>
     move     pay-value to amt-ok.
     move     0749 to curs.
     perform  accept-money2.
     move     amt-ok to pay-value.
     if       pay-value not = oi-paid
              go to value-input-2.
     display  "Confirm No action? i.e. Request cancelled (Y/N)..[ ]" at 1201 with foreground-color 2.
*>
 value-input-req.
*>
     accept   ws-reply at 1251 with foreground-color 2.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "Y"
              go to new-payment.
     if       ws-reply not = "N"
              go to value-input-req.
*>
 value-input-2.
*>
     if       pay-value not = zero
              display PL140 at 1201 with erase eol foreground-color 2
              go to value-input.
*>
     delete   open-item-file-5.
*>
     if       oi-approp = zero
              go to  skip-pay-approp.
     move     oi-deduct-amt  to si-deduct-amt.
*>
 data-input.
*>**********
*>
     perform  payment-appropriate.
*>
 skip-pay-approp.
*>
     if       trans-unapplied
              add hold-pay to purch-unapplied
              rewrite purch-record.
     move     14  to  lin.
     perform  erase-screen.
     display  "Make further corrections? (Y/N)  [Y]" at 1629 with foreground-color 2.
*>
 more-data.
*>
     move     "Y"  to   ws-reply.
     accept   ws-reply at 1663 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "Y"
              go to  new-payment.
     if       ws-reply not = "N"
              go to more-data.
     go       to main-exit.
*>
 accept-money.
*>-----------
*>
     move     zero to ws-poundsd2 amt-ok2 ws-penced2.
     display  ws-amount-screen-display2 at curs  with foreground-color 3.
     accept   ws-amount-screen-accept2 at curs   with foreground-color 3 update.
     move     ws-pound2 to amt-wk-pds2.
     move     ws-pence2 to amt-wk-pence2.
*>
 accept-money2.
*>------------
*>
     move     amt-wk-pence to ws-pence.
     move     amt-wk-pds to ws-pound.
     display  ws-amount-screen-display at curs  with foreground-color 3.
     accept   ws-amount-screen-accept at curs   with foreground-color 3 update.
     move     ws-pound to amt-wk-pds.
     move     ws-pence to amt-wk-pence.
*>
 main-exit.   exit section.
*>
 payment-appropriate     section.
*>==============================
*>
     display  "Reversing please wait" at 1101  with foreground-color 2.
     move     zero to save-invoice.
     move     save-key to oi5-key.
     start    open-item-file-5 key not < oi5-key.
*>
 pay-loop.
*>*******
*>
     read     open-item-file-5 next record  at end
              go to  main-end.
*>
     move     open-item-record-5  to  oi-header.
*>
     if       oi-type not = 2
              go to  pay-loop.
*>
     if       oi-supplier not = pay-customer
              go to main-end.
*>
     if       oi-b-nos not = display-n
        or    oi-b-item not = k
              go to pay-loop.
*>
     divide   oi-cr by 100 giving work-1.
     subtract work-1 from oi-paid.
     subtract work-1 from oi-p-c.
     subtract work-1 from approp-amount.
     move     zero to oi-b-nos oi-b-item oi-cr oi-status.
*>
     if       si-deduct-amt = zero
          or  oi-deduct-amt not = zero
              go to  by-pass-deduct.
*>
 get-deduct.
*>*********
*>
     move     si-deduct-amt  to  si-display.
     display  "For Folio  No.  " at 1301 with foreground-color 2.
     display  oi-invoice at 1317 with foreground-color 3.
     display  "Enter deduct amount - [      ]" at 1201 with foreground-color 2.
     display  "Amount Available = " at 1240            with foreground-color 2.
     display  si-display at 1259 with foreground-color 3.
     move     1224 to curs.
     perform  accept-money.
     move     amt-ok2 to oi-deduct-amt.
     if       oi-deduct-amt  >  si-deduct-amt
              go to  get-deduct
     else
              add oi-deduct-amt to oi-net
              subtract  oi-deduct-amt  from  si-deduct-amt.
*>
     display  " " at 1201 with erase eol.
     display  " " at 1301 with erase eol.
*>
 by-pass-deduct.
*>*************
*>
     rewrite  open-item-record-5 from oi-header.
     if       approp-amount = zero
        and   si-deduct-amt = zero
              go to main-end.
*>
     go       to pay-loop.
*>
 main-end.
*>
     if       approp-amount not = zero
          or  si-deduct-amt not = zero
              display PL141  at 1201 with foreground-color 2
              move approp-amount to display-8
              move si-deduct-amt to display-s
              display display-8 at 1304 with foreground-color 3
              display display-s at 1317 with foreground-color 3
              display PL003     at 1401 with foreground-color 2
              accept ws-reply at 1430 with foreground-color 2.
*>
 main-exit.   exit section.
*>********    ****
*>
 erase-screen section.
*>===================
*>
     move     1 to cole.
     display  " " at curs with erase eos.
*>
 main-exit.   exit.
*>
 zz050-Validate-Date        section.
*>*********************************
*>
*>  Converts USA/Intl to UK date format for processing.
*>*******************************
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
