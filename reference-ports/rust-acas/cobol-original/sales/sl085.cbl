       >>source free
*>***********************************************
*>                                              *
*>              Payment Data Amend              *
*>                                              *
*>***********************************************
*>
 identification          division.
*>===============================
*>
      program-id.         sl085.
*>**
*>    Author.             Cis Cobol Conversion By V B Coen FBCS, 18/10/83
*>                        For Applewood Computers.
*>
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Payment Data Amend.
*>
*>**
*>    Version.            See Prog-Name & Date-Comped In Ws.
*>**
*>
*>    Called Modules.     Maps99.
*>**
*>    Error messages used.
*>                        SL003
*>                        SL140
*>                        SL141
*>**
*>    Changes.
*> 09/02/83 Vbc - 301162-66.
*> 18/02/83 Vbc - Drastic, Large Sections Removed.
*> 26/02/83 Vbc - Force Sl115 To Sort By Move Y To Oi-3-Flag Before
*>                & After,Also Check For 7 On Pass-Value.
*> 01/03/83 Vbc - Display Invoice No. At Get-Deduct.
*> 30/04/83 Vbc - Remove Averaging & Movement Change Code.
*> 23/09/83 Vbc - Supports Openitm Types 6 & 9,Make Extra Checks
*>                For Value & Deduct Amounts.
*> 24/10/83 Vbc - Conversion To Cis Cobol.
*> 21/11/83 Vbc - Batch Nos 3 Digits.
*> 05/01/83 Vbc - Zeriose Oi-Status After Reversing Out Payment.
*> 02/03/84 Vbc - Support For Sales-Unapplied.
*> 08/05/84 Vbc - Accept-Money Routine Not Using Pounds/Pence 2.
*> 10/05/84 Vbc - Support For Indexed Openitm File.
*> 31/05/84 Vbc - Fix Bug: Moving Zero To Oi-Deduct-Amt Regardless
*>                Of The Fact- Oi-Deduct-Amt Not Zero.
*> 03/03/09 vbc - .02 Migration to Open Cobol v3.00.00.
*> 25/11/11 vbc - .03 Error msgs to SLnnn.Support for dates other than UK
*> 08/12/11 vbc - .04 Support for path+filenames.
*> 09/12/11 vbc -     Updated version to 3.01.nn
*> 11/12/11 vbc - .05 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 18/05/13 vbc - .06 Change save-invoice to binary-long from comp, wonder if there are more in SL?
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of the Applewood Computers Accounting System
*> and is copyright (c) Vincent B Coen. 1976 - 2013 and later.
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
 copy "selsl.cob".
 copy "seloi3.cob".
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdsl.cob".
 copy "fdoi3.cob".
*>
 working-storage section.
*>-----------------------
 77  prog-name           pic x(15) value "SL085 (3.01.06)".
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
     03  a               pic 99.
     03  c-check         pic 9.
         88  c-exists                       value  1.
     03  work-1          pic s9(6)v99.
     03  display-8       pic -(5)9.99.
     03  display-s       pic z(5)9.99cr.
     03  display-n       pic 9(5).
     03  display-inv     pic z(7)9.
     03  si-deduct-amt   pic s999v99     comp  value zero.
     03  si-display      pic -zz9.99.
     03  k               pic 999.
     03  approp-amount   pic s9(6)v99    comp-3 value zero.
     03  pay-customer    pic x(7).
     03  pay-date        binary-long.
     03  pay-value       pic s9(6)v99    comp-3 value zero.
     03  address-A       pic x(96).
     03  address-line    pic x(36).
     03  transaction-type pic 9                 value zero.
         88  trans-payment                      value 5.
         88  trans-unapplied                    value 6.
     03  hold-pay        pic s9(6)v99    comp-3 value zero.
     03  save-key.
         05 save-customer pic x(7).
         05 save-invoice  binary-long.    *> was pic 9(8)       comp.
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
     03  SL003           pic x(28) value "SL003 Hit Return To Continue".
*> Module specific
     03  SL140           pic x(36) value "SL140 Not Yet Supporting Corrections".
     03  SL141           pic x(42) value "SL141 Amount Approp Or Deduct Amt Not Zero".
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
     if       s-flag-p = zero
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
     display  prog-name at 0202 with foreground-color 2.
     display  "Payment Data Amend" at 0233 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0271 with foreground-color 2.
*>
 dh-exit.
*>
     move     zero  to  k.
     open     i-o sales-file open-item-file-3.
     perform  new-payment.
     close    sales-file open-item-file-3.
*>
 menu-exit.
*>********
*>
     move     "Y" to oi-3-flag.
     perform  display-heads.
*>
 main-exit.
     exit program.
*>
*>****************************************
*>               Procedures	         *
*>****************************************
*>
 new-payment             section.
*>==============================
*>
     move     4  to  lin.
     perform  display-heads.
*>
     display  "****************************************" at 0441 with foreground-color 2.
     display  "*Date    [  /  /    ]                  *" at 0541 with foreground-color 2.
     display  "*A/C Nos    [       ]                ***" at 0641 with foreground-color 2.
     display  "*Value   {          }*Batch [     /   ]*" at 0741 with foreground-color 2.
     display  "****************************************" at 0841 with foreground-color 2.
*>
 date-input.
*>*********
*>
     perform  zz070-Convert-Date.
     display  ws-date at 0551 with foreground-color 3.
*>
 get-batch.
*>
     move     spaces to oi3-customer.
     accept   oi3-customer at 0654 with foreground-color 3.
     move     function upper-case (oi3-customer) to oi3-customer.
     display  oi3-customer at 0654 with foreground-color 3.
     if       oi3-customer = spaces
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
     multiply display-n by 1000 giving oi3-invoice.
     add      k to oi3-invoice.
     move     oi3-key to save-key.
     start    open-item-file-3 key not < oi3-key.
*>
 find-trans-loop.
*>**************
*>
     read     open-item-file-3 next record at end
              go to  get-batch.
     move     open-item-record-3  to  oi-header.
*>
     if       oi-customer not = save-customer
          or  oi-invoice not = save-invoice
              go to get-batch.
*>
     if       oi-b-nos  not equal  display-n
           or oi-b-item not equal  k
           or (oi-type not = 5 and not = 6)    *> payment or unappled journal
              go to  find-trans-loop.
*>
     if       oi-type = 6                                                 *> 25.11.11 this looks like wrong place to put msg
              display "Warning Unapplied Balance Journal" at 0645 with foreground-color 2.
*>
     move     oi-type to transaction-type.
*>
     move     oi-customer  to  pay-customer.
     move     oi-date      to  pay-date.
     move     oi-paid      to  pay-value hold-pay.
     move     oi-approp    to  approp-amount.
*>
     display  pay-customer at 0572 with foreground-color 2.
     move     pay-customer  to  sales-key.
*>
     read     sales-file  record  invalid key
              move  zero  to  c-check.
*>
     move     sales-address  to  address-a.
*>
     display  sales-name at 0401 with foreground-color 2.
*>
     move     1  to  a.
     unstring address-a  delimited  by sl-delim into address-line count a pointer a.
     display  address-line at 0501 with foreground-color 2.
*>
     move     spaces  to  address-line.
     unstring address-a  delimited  by sl-delim into address-line count a pointer a.
     display  address-line at 0601 with foreground-color 2.
*>
     move     spaces  to  address-line.
     unstring address-a  delimited  by sl-delim into  address-line  count a  pointer  a.
     display  address-line at 0701 with foreground-color 2.
*>
     move     spaces  to  address-line.
     unstring address-a into  address-line  pointer  a.
     display  address-line at 0801 with foreground-color 2.
*>
     move     spaces  to  address-line.
*>
     move     sales-current  to  display-s.
     display  "Current Balance - " at 1001  with foreground-color 2.
     display  display-s at 1019 with foreground-color 2.
*>
 value-input.
*>**********
*>
     move     pay-value to amt-ok.
     move     0751 to curs.
     perform  accept-money2.
     move     amt-ok to pay-value.
     if       pay-value not = oi-paid
              go to value-input-2.
     display  "Confirm No Action? i.e. Request Cancelled (Y/N)..[ ]" at 1201 with foreground-color 2.
*>
 value-input-req.
*>
     accept   ws-reply at 1251 with foreground-color 6.
     move     function upper-case (ws-reply) to ws-reply
     if       ws-reply = "Y"
              go to new-payment.
     if       ws-reply not = "N"
              go to value-input-req.
*>
 value-input-2.
*>
     if       pay-value not = zero
              display SL140  at 1201 with erase eol
              go to value-input.
*>
     delete   open-item-file-3.
*>
     if       oi-approp = zero
              go to  skip-pay-approp.
     move     oi-deduct-amt  to si-deduct-amt.
*>
 data-input.
*>*********
*>
     perform  payment-appropriate.
*>
 skip-pay-approp.
*>
     if       trans-unapplied
              add hold-pay to sales-unapplied
              rewrite sales-record.
     move     14  to  lin.
     perform  erase-screen.
     display  "Make Further Corrections (Y/N) ? [Y]" at 1629 with foreground-color 2.
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
     display  ws-amount-screen-display2 at curs with foreground-color 2.
     accept   ws-amount-screen-accept2 at curs  with foreground-color 2 update.
     move     ws-pound2 to amt-wk-pds2.
     move     ws-pence2 to amt-wk-pence2.
*>
 accept-money2.
*>------------
*>
     move     amt-wk-pence to ws-pence.
     move     amt-wk-pds to ws-pound.
     display  ws-amount-screen-display at curs with foreground-color 3.
     accept   ws-amount-screen-accept at curs  with foreground-color 3 update.
     move     ws-pound to amt-wk-pds.
     move     ws-pence to amt-wk-pence.
*>
 main-exit.   exit section.
*>
 payment-appropriate     section.
*>==============================
*>
     display  "Reversing Please Wait" at 1101  with foreground-color 2.
     move     zero to save-invoice.
     move     save-key to oi3-key.
     start    open-item-file-3 key not < oi3-key.
*>
 pay-loop.
*>*******
*>
     read     open-item-file-3 next record  at end
              go to  main-end.
*>
     move     open-item-record-3  to  oi-header.
*>
     if       oi-type  not = 2            *> invoices
              go to pay-loop.
*>
     if       oi-customer  not = pay-customer
              go to  main-end.
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
          or  oi-deduct-amt not zero
              go to  by-pass-deduct.
*>
 get-deduct.
*>*********
*>
     move     si-deduct-amt  to  si-display.
     display  "For Invoice No. " at 1301 with foreground-color 2.
     move     oi-invoice to display-inv.
     display  display-inv at 1317 with foreground-color 2.
     display  "Enter Deduct Amount - [      ]" at 1201  with foreground-color 2.
     display  "Amount Available = " at 1240  with foreground-color 2.
     display  si-display at 1259 with foreground-color 3.
     move     1224 to curs.
     perform  accept-money.
     move     amt-ok2 to oi-deduct-amt.
     if       oi-deduct-amt  >  si-deduct-amt
              go to  get-deduct
     else
              subtract  oi-deduct-amt  from  si-deduct-amt.
     display  " " at 1201 with erase eol.
     display  " " at 1301 with erase eol.
*>
 by-pass-deduct.
*>*************
*>
     rewrite  open-item-record-3 from oi-header.
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
              display SL141 at 1201 with foreground-color 4
              move approp-amount to display-8
              move si-deduct-amt to display-s
              display display-8 at 1304 with foreground-color 2
              display display-s at 1317 with foreground-color 2
              display SL003     at 1331 with foreground-color 4
              accept ws-reply at 1354  with foreground-color 2.
*>
 main-exit.   exit section.
*>********    ****.
*>
 erase-screen            section.
*>==============================
*>
     move     1 to cole.
     display  " " at curs with erase eos.
*>
 main-exit.   exit section.
*>
 zz050-Validate-Date        section.
*>*********************************
*>
*>  Converts USA/Intl to UK date format for processing.
*>****************************************************
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
