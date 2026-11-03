       >>source free
*>****************************************************************
*>                                                               *
*>           I N V O I C E   D E L E T I O N                     *
*>                                                               *
*>****************************************************************
*>
 identification          division.
*>===============================
*>
      program-id.         sl940.
*>**
*>    Author.             Cis Cobol Conversion By V B Coen FBCS, 28/10/83
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Invoice Deletion.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps04.
*>                        Maps99.
*>**
*>    Error messages used.
*>                        SL194
*>                        SL195
*>**
*> Changes
*> 03/03/09 vbc - .01 Migration to Open Cobol v3.00.00.
*> 26/11/11 vbc - .02 Error msgs to SLnnn.Support for dates other than UK
*> 08/12/11 vbc - .03 Support for path+filenames.
*> 09/12/11 vbc -     Updated version to 3.01.nn, support for IS delivery file
*> 11/12/11 vbc - .04 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of the Applewood Computers Accounting System
*> and is copyright (c) Vincent B Coen. 1976 - 2012 and later.
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
 copy "selinv.cob".
 copy "seldel.cob".
 copy "seldnos.cob".
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdsl.cob".
 copy "fdinv.cob".
 copy "fddel.cob".
 copy "fddnos.cob".
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "SL940 (3.01.04)".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
 copy "wsinv.cob".
*>
 01  ws-data.
     03  menu-reply      pic 9.
     03  ws-reply        pic x.
     03  a               pic 99.
     03  c-check         pic 9.
         88  c-exists                    value 1.
     03  address-A       pic x(96).
     03  address-line    pic x(36).
     03  i               pic 99.
     03  j               pic 99.
     03  k               pic 99.
     03  escape-code     pic x.
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
*>     03  SL003          pic x(28) value "SL003 Hit Return To Continue".
*> Module specific
     03  SL194          pic x(27) value "SL194 Invoice Not Found!!!!".
     03  SL195          pic x(53) value "SL195 Invoice Details Already Passed To Sales Ledger!".
*>
 01  error-code          pic 999.
*>
 linkage section.
*>***************
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
*>
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
*>
     perform  program-start.
     open     i-o  invoice-file.
     open     input  sales-file.
     open     input  delivery-file.
     open     extend  del-inv-nos-file.
     if       fs-reply not = zero
              close       del-inv-nos-file
              open output del-inv-nos-file.
*>
 done-open.
     move     spaces to escape-code.
     perform  invoice-details.
*>
     if       escape-code = "Q"
              go to  main-exit.
*>
     move     1 to cole.
     display  " " at 1601 with erase eos.
*>
 data-input.
*>**********
*>
     display  "Delete Further Invoices (Y/N) ? [Y]" at 1629 with foreground-color 2.
*>
     move     "Y"  to   ws-reply.
     accept   ws-reply at 1662 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     display  " " at 1601 with erase eol.
     if       ws-reply = "Y"
              go to done-open.
*>
 main-exit.
*>********
*>
     close    sales-file delivery-file del-inv-nos-file
              invoice-file.
     exit     program.
*>
*>****************************************************
*>                    Procedures                     *
*>****************************************************
*>
 delete-details section.
*>=====================
*>
     move     zero  to  j.
     perform  sih-lines times
              add    1 to j
              move   sih-invoice to invoice-nos
              move   sih-letter to invoice-let
              move   j to item-nos
              delete invoice-file
     end-perform.
*>
 main-exit.   exit section.
*>********    ****
*>
 maps99         section.
*>=====================
*>
     call     "maps99"  using  error-code ws-calling-data.
*>
 main-exit.   exit section.
*>********    ****
*>
 program-start  section.
*>=====================
*>
     if       file-status (16)  not equal 1
              move 17  to  error-code
              perform  maps99
              move 15 to error-code
              perform maps99
              exit program.
*>
     move     to-day to u-date.
*>
 menu-return.
*>**********
*>
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "Invoicing Data Deletion" at 0131 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
 main-exit.   exit section.
*>********    ****
*>
 invoice-details         section.
*>==============================
*>
     display  "****************************************" at 0441 with erase eol foreground-color 2.
     display  "*Date   [  /  /    ]*                  *" at 0541 with erase eol foreground-color 2.
     display  "*A/C Nos   [       ]*                 **" at 0641 with erase eol foreground-color 2.
     display  "*Invoice [         ]*Order [          ]*" at 0741 with erase eol foreground-color 2.
     display  "****************************************" at 0841 with erase eol foreground-color 2.
*>
     display  "Type [ ]  <1> = Receipt; <2> = Account; <3> = CrediT Note; <4> = Pro-Forma"
                                                         at 1001 with foreground-color 2.
*>
 invoice-enter.
*>************
*>
     accept   sih-invoice at 0751 with foreground-color 3 update.
     display  " " at 1601 with erase eol.
     if       sih-invoice = zero
              move  "Q"  to  escape-code
              go to  main-exit.
*>
     move     " "  to  sih-letter.
     display  "Now give Invoice letter (A, B, C or return for space)" at 1601 with foreground-color 2.
     accept   sih-letter at 0759 with foreground-color 6 update.
     move     sih-letter  to  invoice-let.
*>
     display  " " at 1601 with erase eol.
     move     sih-invoice  to  invoice-nos.
     move     zero  to  item-nos.
*>
     read     invoice-file  invalid key
              display SL194 at 1640 with foreground-color 4
              go to  invoice-enter.
*>
     move     invoice-record  to  sinvoice-header.
*>
     if       sih-status = "z"
              display SL195 at 1601 with foreground-color 4 erase eol
              go to  invoice-enter.
     move     sih-date to u-bin.
     perform  zz060-Convert-Date.                          *> in ws-date
     display  sih-customer at 0653 with foreground-color 3.
*>
     move     1  to  c-check.
     move     sih-customer  to  sales-key.
     read     sales-file  record  invalid key
              move  zero  to  c-check.
*>
     if       delivery-tag = zero
              go to  customer-setup.
*>
     move     "D"       to Deliv-Key-Type.
     move     Sales-Key to Deliv-Sales-Key.
     read     delivery-file  invalid
              move  zero  to  delivery-tag
              go to  customer-setup.
*>
     move     deliv-address to  address-a.
     go       to customer-display.
*>
 customer-setup.
*>*************
*>
     move     sales-address  to  address-a.
*>
 customer-display.
*>***************
*>
     if       delivery-tag = zero
              display sales-name at 0401 with foreground-color 3
     else
              display deliv-name at 0401 with foreground-color 3
     end-if
     move     1  to  a.
     unstring address-a  delimited  by  sl-delim into  address-line count a pointer  a.
     display  address-line at 0501 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address-a  delimited  by  sl-delim into  address-line count a pointer  a.
     display  address-line at 0601 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address-a  delimited  by  sl-delim into  address-line count a pointer  a.
     display  address-line at 0701 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address-a              into  address-line  pointer  a.
     display  address-line at 0801 with foreground-color 3.
*>
     move     spaces  to  address-line.
*>
     display  ws-date at 0550 with foreground-color 3.
     display  sih-order at 0769 with foreground-color 3.
     display  sih-type at 1007 with foreground-color 3.
     display  "Invoice To Be Deleted (Y/N) - [ ]" at 1601 with foreground-color 2.
     move     "N" to ws-reply.
     accept   ws-reply at 1632 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply not = "Y"
              go to  main-exit.
*>
     delete   invoice-file.
     perform  delete-details.
*>
     move     sih-invoice  to  del-inv-nos.
     move     sih-date     to  del-inv-dat.
     move     sih-customer to  del-inv-cus.
*>
     write    del-inv-nos-record.
*>
 main-exit.   exit.
*>********    ****
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
