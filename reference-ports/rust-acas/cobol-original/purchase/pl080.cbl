       >>source free
*>*************************************************
*>                                                *
*>             Payment  Data  Entry               *
*>                                                *
*>*************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl080.
*>**
*>    Author.             V B Coen FBCS, FIDPM, 17/04/84
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Payment Data Entry & Maintenance.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps04.
*>                        Maps99.
*>**
*>    Error messages used.
*>                        NONE.
*>**
*>    Changes.
*> 16/05/84 Vbc - In Pay Details Display Inv Amt O/S.
*> 22/05/84 Vbc - Support Of Indexed Open Item File.
*> 29/06/84 Vbc - Modify Late Charge Routines For Pl.
*> 25/09/84 Vbc - Check That If Next-Batch = 0,Add 1.
*> 21/02/85 Vbc - Set P-Flag-P To 1 In Value-Input.
*>                Copied over fixes from SL090, eg:
*>                Replace Usage Of Next-Batch For First-Sl-Batch,
*>                Bug/Feature 30.6 allowed out thru Escape, etc
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 15/12/11 vbc - .04 Error msgs to SLnnn.Support for dates other than UK
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
*>------------
*>
 copy "selpl.cob".
 copy "seloi5.cob".
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdpl.cob".
 copy "fdoi5.cob".

 working-storage section.
*>----------------------
  77  prog-name           pic x(15)      value "PL080 (3.01.04)".
*>
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
 copy "wsoi.cob".
*>
 01  ws-data.
     03  ws-reply        pic x.
     03  z               pic 99.
     03  to-day          pic x(10).
     03  c-check         pic 9.
         88  c-exists  value  1.
     03  work-1          pic 9(7)v99    comp-3 value zero.
     03  work-2          pic 999v99     comp-3 value zero.
     03  work-3          pic 9(7)v99    comp-3 value zero.
     03  work-net        pic s9(7)v99   comp-3 value zero.
     03  work-ded        pic 999v99     comp-3 value zero.
     03  work-av         pic s9(14)     comp-3 value zero.
     03  display-8       pic z(6)9.99.
     03  display-s       pic z(6)9.99cr.
     03  display-5       pic zz9.99.
     03  display-n       pic z(4)9.
     03  display-inv     pic z(7)9.
     03  i               pic 99.
     03  j               pic 99.
     03  k               pic 999.
     03  approp-amount   pic 9(6)v99    comp-3  value zero.
     03  deduct-taken    pic 9(6)v99    comp-3  value zero.
     03  pay-customer    pic x(7).
     03  pay-date        binary-long            value zero.
     03  pay-value       pic 9(7)v99     comp-3 value zero.
     03  batch-value     pic 9(7)v99     comp-3 value zero.
     03  pay-paid        pic s9(7)v99    comp-3 value zero.
     03  test-amount     pic s9(7)v99    comp-3 value zero.
     03  address1        pic x(96).
     03  address-line    pic x(36).
     03  ws-dash         pic x(80)       value all "-".
     03  transaction-type pic 9          value zero.
         88  trans-payment               value 5.
         88  trans-unapplied             value 6.
     03  ws-env-lines    pic 999                value zero.
     03  ws-lines        binary-char unsigned   value zero.
     03  ws-23-lines     binary-char unsigned   value zero.
*>
 01  All-My-Constants    pic 9(4).
     copy "screenio.cpy".
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
*>       NONE
*> Module specific
*>       NONE
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
 01  today               pic x(10).
*>
 procedure division using ws-calling-data system-record today file-defs.
*>=====================================================================
*>
 init01 section.
     accept   ws-env-lines   from lines.
     if       ws-env-lines < 24
              move  24 to ws-env-lines ws-lines
     else
              move  ws-env-lines   to ws-lines
     end-if
     subtract 1 from ws-lines giving ws-23-lines.
     move     today to to-day.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
*>
     if       p-flag-i = 1
              move 28 to error-code
              call "maps99" using error-code ws-calling-data
              move 15 to error-code
              call "maps99" using error-code ws-calling-data
              go to main-exit.
*>
*>  IS in SL080 but not here, why not????
*>
*>     if       file-status (29) not = 1
*>              move 25  to  error-code
*>              call "maps99"  using  error-code ws-calling-data
*>              move 15 to error-code
*>              call "maps99" using error-code ws-calling-data
*>              go to main-exit.
*>
 display-heads.
*>
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "Payment Data Entry" at 0133 with foreground-color 2.
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
     perform  display-heads.
     add      1 to bl-next-batch.
     move     "Y" to oi-5-flag.
*>
 main-exit.
     exit program.
*>
*>*********************************************
*>                Procedures                  *
*>*********************************************
*>
 new-payment  section.
*>===================
*>
     move     4  to  lin.
     perform  display-heads.
*>
     display  "****************************************" at 0441  with foreground-color 2.
     display  "*Date  [  /  /    ]*A/C Nos   [       ]*" at 0541  with foreground-color 2.
     display  "***                                  ***" at 0641  with foreground-color 2.
     display  "*Value [          ]*Batch   [     /   ]*" at 0741  with foreground-color 2.
     display  "****************************************" at 0841  with foreground-color 2.
*>
 date-input.
*>*********
*>
     perform  zz070-Convert-Date.
     display  ws-date at 0549 with foreground-color 3.
     accept   ws-date at 0549 with foreground-color 3 update.
*>
     if       ws-date = spaces
         or   cob-crt-status = cob-scr-esc
              go to  main-exit.
*>
     move     ws-date to ws-test-date.
     move     zero  to  u-bin.
     perform  zz050-Validate-Date.
     if       u-bin = zero
              go to  date-input.
*>
     move     u-bin  to  pay-date.
     move     u-date to  to-day.
*>
 customer-input.
*>*************
*>
     if       k  =  999
              display "Batch Closed........Full!  " at 1041  with foreground-color 2 blink
              go to  main-exit.
*>
     move     spaces to pay-customer.
     accept   pay-customer at 0572 with foreground-color 3.
     move     function upper-case (pay-customer) to pay-customer.
     display  pay-customer at 0572 with foreground-color 3.
*>
     if       pay-customer = spaces
              go to date-input.
     if       cob-crt-status = cob-scr-esc
              go to  main-exit.
*>
     move     1  to  c-check.
     move     pay-customer  to  purch-key.
*>
     read     purchase-file  record  invalid key
              move  zero  to  c-check.
*>
     if       not  c-exists
              go to  customer-input.
*>
     move     purch-address  to  address1.
     display  purch-name at 0401 with foreground-color 3.
*>
     move     1  to  z.
     unstring address1  delimited  by pl-delim into  address-line count z pointer  z.
     display  address-line at 0501 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address1  delimited  by pl-delim into  address-line  count z  pointer  z.
     display  address-line at 0601 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address1  delimited  by pl-delim into  address-line  count z pointer  z.
     display  address-line at 0701 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address1 into  address-line pointer  z.
     display  address-line at 0801 with foreground-color 3.
*>
     move     spaces  to  address-line.
*>
     move     purch-current  to  display-s.
     display  "Current Balance - " at 1001  with foreground-color 2.
     display  display-s at 1019 with foreground-color 3.
*>
     move     5 to transaction-type.
     if       purch-unapplied = zero
              go to value-input.
*>
     move     purch-unapplied to display-8 amt-ok.
     display  "Unapplied Balance - " at 0645  with foreground-color 2.
     display  display-8 at 0665 with foreground-color 3.
     display  "Do you wish to allocate the unapplied Balance to this account?  [Y]" at 1601 with foreground-color 2.
     move     "Y" to ws-reply.
*>
 accept-unappl-reqst.
*>------------------
*>
     move     zero to cob-crt-status.
     accept   ws-reply at 1666 with foreground-color 6 update.
     if       cob-crt-status = cob-scr-esc
              go to new-payment.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply not = "Y" and not = "N"
              go to accept-unappl-reqst.
     if       ws-reply = "N"
              display " " at 1601 with erase eol
              go to value-input.
*>
     move     6 to transaction-type.
     display  " " at 1601 with erase eol.
     move     0749 to curs.
*>
 accept-unappl-money.
*>------------------
*>
     perform  accept-money2.
     if       amt-ok = zero
              go to new-payment.
     if       amt-ok > purch-unapplied
              go to accept-unappl-money.
*>
     subtract amt-ok from purch-unapplied.
     move     amt-ok to pay-value.
     rewrite  purch-record.
     go       to set-batch-item.
*>
 value-input.
*>**********
*>
     move     0749 to curs.
     perform  accept-money.
     move     amt-ok to pay-value.
     if       pay-value = zero
              go to customer-input.
     if       cob-crt-status = cob-scr-esc
              go to  main-exit.
*>
     move     1 to p-flag-p.
     add      pay-value  to  batch-value.
     move     batch-value  to  display-s.
     display  "Batch Total - " at 1041 with foreground-color 2.
     display  display-s at 1055 with foreground-color 3.
*>
 set-batch-item.
*>-------------
*>
     if       bl-next-batch = zero
              move 1 to bl-next-batch.
     move     bl-next-batch  to  display-n.
     add      1  to  k.
     display  display-n at 0770 with foreground-color 2.
     display  k at 0776 with foreground-color 2.
*>
 data-input.
*>*********
*>
     perform  payment-appropriate.
     move     14  to  lin.
     perform  erase-screen.
*>
     display "Enter further payments? (Y/N)  [Y]" at 1629  with foreground-color 2.
*>
 more-data.
*>
     move     "Y"  to   ws-reply.
     accept   ws-reply at 1661 with foreground-color 6 update.
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
     move     zero to ws-poundsd amt-ok ws-penced.
     display  ws-amount-screen-display at curs  with foreground-color 2.
     accept   ws-amount-screen-accept at curs   with foreground-color 3 update.
     move     ws-pound to amt-wk-pds.
     move     ws-pence to amt-wk-pence.
*>
 accept-money2.
*>------------
*>
     move     amt-wk-pence to ws-pence.
     move     amt-wk-pds to ws-pound.
     display  ws-amount-screen-display at curs  with foreground-color 2.
     accept   ws-amount-screen-accept at curs   with foreground-color 2 update.
     move     ws-pound to amt-wk-pds.
     move     ws-pence to amt-wk-pence.
*>
 main-exit.   exit section.
*>
 payment-appropriate     section.
*>==============================
*>
     display   ws-dash at 1101 with foreground-color 2.
     display  "Folio No  --Date--  --Amount--" at 1201 with foreground-color 2.
     display  "Deductable  ---Paid----" at 1233        with foreground-color 2.
     display  "Deduction taken" at 1258                with foreground-color 2.
*>
     move     zero  to  approp-amount oi5-invoice.
     move     14  to  lin.
     move     pay-customer to oi5-supplier.
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
     if       oi-b-nos not = zero
              go to pay-loop.
*>
     add      oi-net oi-carriage oi-vat oi-c-vat giving work-net.
     move     oi-deduct-amt to work-ded.
     move     work-net to test-amount.
     if       test-amount = oi-paid
        and   oi-status = zero
              move pay-date to oi-date-cleared
              move 1 to oi-status
              rewrite  open-item-record-5 from oi-header
              go to pay-loop.
*>
     if       test-amount not > oi-paid
              go to  pay-loop.
*>
 pay-details.
*>**********
*>
     move     1 to cole.
     display  " " at curs with erase eol.
     move     oi-invoice to display-inv.
     display  display-inv at curs with foreground-color 3.
*>
     move     oi-date  to  u-bin.
     perform  zz060-Convert-Date.
     move     11 to cole.
     display  u-date at curs with foreground-color 3.
*>
     move     work-net to work-1.
     move     work-ded to work-2.
*>
     add      1  oi-deduct-days  to  u-bin.
     if       u-bin  >  pay-date
              subtract  work-2  from  work-1
              move work-2 to display-5
     else
              move zero   to display-5.
*>
     subtract oi-paid  from  work-1.
     move     work-1 to pay-paid.
     move     work-1 to display-8.
     move     21 to cole.
     display  display-8 at curs with foreground-color 3.
*>
     move     35 to cole.
     display  display-5 at curs with foreground-color 3.
*>
     move     65 to cole.
     if       pay-paid = zero
              display "....Fully Paid  " at curs  with foreground-color 2
     else
              display " " at curs with erase eol.
*>
     if       pay-paid > pay-value
              subtract approp-amount from pay-value  giving pay-paid.
*>
     move     46 to cole.
     move     pay-paid to amt-ok.
     perform  accept-money2.
     move     amt-ok to pay-paid.
*>
     if       pay-paid = zero
              move  zero  to  pay-paid display-s
              move 46 to cole
              display display-s at curs with foreground-color 3
              move 65 to cole
              display "....no change  " at curs  with foreground-color 2
              go to  end-line-2.
*>
     move     bl-next-batch to oi-b-nos.
     move     k             to oi-b-item.
*>
 get-agreement.
*>************
*>
*>    If payment within discount term discount has been
*>    subtracted from work-1
*>
     add      pay-paid  to  approp-amount.
*>
     if       approp-amount  >  pay-value
              go to  payment-2-high.
*>
     if       pay-paid = work-1
              move pay-date to oi-date-cleared
              move 1  to  oi-status
              if  u-bin  >  pay-date
                  subtract oi-deduct-amt from oi-net
                  move zero  to  oi-deduct-amt
                  add  work-2  to  deduct-taken
              end-if
              go to  end-line
     end-if
*>
*>    ie not paid within discount term & amt paid not = inv amt
*>     o/s (with deduct amt)
*>
     if       u-bin  not >  pay-date
              subtract  work-2  from  work-1.
     if       pay-paid > work-1
              go to payment-2-high-maybe.
     if       pay-paid not = work-1
              go to  end-line.
*>
*>   ie amt paid < inv amt o/s
*>
     move     "Y"  to  ws-reply.
     move     65 to cole.
     display  ws-reply at curs with foreground-color 6.
     accept   ws-reply at curs with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "Y"
              move pay-date to oi-date-cleared
              move 1  to  oi-status
              add  work-2  to  deduct-taken
              subtract oi-deduct-amt from oi-net
              move  zero  to  oi-deduct-amt.
*>
 end-line.
*>********
*>
     add      pay-paid  to  oi-paid.
     add      pay-paid  to  oi-p-c.
     multiply 100 by pay-paid giving oi-cr.
     subtract oi-deduct-amt from work-net.
     if       oi-paid = work-net
              move pay-date to oi-date-cleared
              move 1 to oi-status.
*>
     rewrite  open-item-record-5 from oi-header.
*>
 end-line-2.
*>
     add      1  to  lin.
     if       lin  >  23
              move  14  to  lin.
*>
     if       approp-amount  not <  pay-value
              go to  main-end.
     go       to pay-loop.
*>
 payment-2-high-maybe.
*>*******************
*>
*>   check for paying late charge within time limit.
*>
*>   Not valid; fall thru to payment-2-high
*>
 payment-2-high.
*>*************
*>
     subtract pay-paid  from  approp-amount.
     move     65 to cole.
     display  "Payment Too High" at curs with foreground-color 4.
     go       to pay-details.
*>
 main-end.
*>*******
*>
     move     zero to oi-carriage oi-vat oi-c-vat oi-status.
     move     zero to oi-cr oi-days oi-deduct-vat oi-discount oi-deduct-days oi-p-c.
     move     spaces to oi-applied.
     move     pay-customer  to  oi-supplier.
     move     pay-date  to  oi-date.
     move     transaction-type to  oi-type.
     move     pay-value to  oi-paid.
     move     approp-amount  to  oi-approp.
     move     deduct-taken   to  oi-deduct-amt.
     move     bl-next-batch  to  oi-b-nos.
     move     k           to  oi-b-item.
     multiply oi-b-nos by 1000 giving oi-invoice.
     add      oi-b-item to oi-invoice.
*>
     write    open-item-record-5 from oi-header.
     move     zero  to  approp-amount  deduct-taken.
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
 main-exit.   exit section.
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
