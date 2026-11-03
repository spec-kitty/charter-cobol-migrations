       >>source free
*>**************************************************
*>                                                 *
*>              Invoice  Deletion                  *
*>                                                 *
*>**************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl040.
*>**
*>    Author.             Cis Cobol Conversion By V B Coen FBCS, 15/04/84
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
*>                        PL187
*>                        PL188
*>****
*> Changes:
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00
*> 13/12/11 vbc - .01 Error msgs to SLnnn.Support for dates other than UK
*>                    Support for path+filenames.
*>                    Updated version to 3.01.nn, support for IS delivery file
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
*>
 environment       division.
*>=========================
*>
 copy "envdiv.cob".
 input-output      section.
*>------------------------
*>
 file-control.
*>------------
*>
 copy "selpl.cob".
 copy "selpinv.cob".
 copy "selpdnos.cob".
*>
 data              division.
*>=========================
*>
 file section.
*>-----------
*>
 copy "fdpl.cob".
 copy "fdpinv.cob".
 copy "fdpdnos.cob".
 working-storage section.
*>-----------------------
 77  prog-name           pic x(15) value "PL040 (3.01.01)".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
 copy "wspinv.cob".
*>
 01  ws-data.
     03  menu-reply      pic 9.
     03  ws-reply        pic x.
     03  a               pic 99.
     03  c-check         pic 9.
         88  c-exists                    value 1.
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
*>     03  PL003          pic x(28) value "PL003 Hit Return To Continue".
*> Module specific
     03  PL187          pic x(27) value "PL187 Invoice Not Found!!!!".
     03  PL188          pic x(56) value "PL188 Invoice Details Already Passed To Purchase Ledger!".
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
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
*>
     perform  program-start.
     open     i-o  invoice-file.
     open     input purchase-file.
     open     extend  del-inv-nos-file.
*>
 done-open.
     move     spaces to escape-code.
     perform  invoice-details.
*>
     if       escape-code = "Q"
              go to  main-exit.
*>
     move     16  to  lin.
     move     1 to cole.
     display  " " at curs with erase eos.
*>
 data-input.
*>**********
*>
     display  "Delete further invoices? (Y/N)  [Y]"  at 1629 with foreground-color 2.
*>
     move     "Y"  to   ws-reply.
     accept   ws-reply at 1662 with foreground-color 6.
     move     function upper-case (ws-reply) to ws-reply.
     display  " " at 1601 with erase eos.
     if       ws-reply = "Y"
              go to done-open.
*>
 main-exit.
*>********
*>
     close    purchase-file del-inv-nos-file invoice-file.
     exit     program.
*>
*>************************************************
*>                 Procedures                    *
*>************************************************
*>
 delete-details section.
*>=====================
*>
     move     zero  to  j.
     perform  ih-lines times
              add    1 to j
              move   ih-invoice to invoice-nos
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
     if       file-status (26)  not equal 1
              move 17  to  error-code
              perform  maps99
              move 15 to error-code
              perform maps99
              exit program.
     move     to-day to u-date.
*>
 menu-return.
*>**********
*>
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "Invoice Data Deletion" at 0131 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
 main-exit.   exit section.
*>********    ****
*>
 invoice-details section.
*>======================
*>
     display  "****************************************" at 0441 with erase eol foreground-color 2.
     display  "*Date [  /  /    ]*A/C Nos    [       ]*" at 0541 with erase eol foreground-color 2.
     display  "**                *Order   [          ]*" at 0641 with erase eol foreground-color 2.
     display  "*Folio  [        ]*Invoice [          ]*" at 0741 with erase eol foreground-color 2.
     display  "****************************************" at 0841 with erase eol foreground-color 2.
*>
     display  "Type [ ]  <1> = Receipt; <2> = Account; <3> = Credit Note"
                                                         at 1001 with foreground-color 2.
*>
 invoice-enter.     *> Invoice is the folio-no in PL
*>************
*>
     accept   ih-invoice at 0750 with foreground-color 3.
     display  " " at 1640 with erase eol.
     if       ih-invoice = zero
              move  "Q"  to  escape-code
              go to  main-exit.
*>
     move     ih-invoice  to  invoice-nos.
     move     zero  to  item-nos.
*>
     read     invoice-file  invalid key
              display PL187 at 1640  with foreground-color 4
              go to  invoice-enter.
*>
     move     invoice-record  to  invoice-header.
*>
     if       ih-status = "z"
              display PL188 at 1601 with foreground-color 4
              go to  invoice-enter.
     move     ih-date to u-bin.
     perform  zz060-Convert-Date.                          *> in ws-date
     display  ih-supplier at 0572 with foreground-color 3.
*>
     move     1  to  c-check.
     move     ih-supplier  to  purch-key.
     read     purchase-file record invalid key
              move zero to c-check.
*>
     display  purch-name at 0401 with foreground-color 3.
*>
     move     1  to  a.
     unstring purch-address  delimited by  pl-delim  into  address-line  count a  pointer  a.
     display  address-line at 0501 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring purch-address  delimited by  pl-delim  into  address-line  count a  pointer  a.
     display  address-line at 0601 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring purch-address  delimited by  pl-delim  into  address-line  count a  pointer  a.
     display  address-line at 0701 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring purch-address   into  address-line  pointer  a.
     display  address-line at 0801 with foreground-color 3.
*>
     move     spaces  to  address-line.
*>
     display  ws-date at 0548 with foreground-color 3.
     display  ih-order at 0669 with foreground-color 3.
     display  ih-ref at 0769 with foreground-color 3.
     display  ih-type at 1007 with foreground-color 3.
*>
     display  "Invoice to be deleted (Y/N) - [ ]" at 1601  with foreground-color 2.
     move     "N" to ws-reply.
     accept   ws-reply at 1632 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply not = "Y"
              go to  main-exit.
*>
     delete   invoice-file.
     perform  delete-details.
*>
     move     ih-invoice  to  del-inv-nos.
     move     ih-date     to  del-inv-dat.
     move     ih-supplier to  del-inv-cus.
     write    del-inv-nos-record.
*>
 main-exit.   exit section.
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
