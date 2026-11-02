       >>source free
*>****************************************************
*>                                                   *
*>     Purchase  Ledger  Supplier - Maintenance      *
*>                                                   *
*>****************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl010.
*>**
*>    author.             V B Coen FBCS, For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    remarks.            Purchase Ledger Supplier File Maintenance
*>                        & Print.
*>**
*>    version.            See Prog-Name In Ws.
*>
*>    called modules.     maps04.
*>                        maps09.
*>                        maps99.
*>
*>**
*>    Error messages used.
*>                        PL004
*>                        PL005
*>
*>                        pL101
*>                        PL102
*>                        PL103
*>                        PL104
*>                        PL105
*>                        PL106
*>                        PL107
*>                        PL108
*>                        PL109
*>**
*>    changes.
*> 07/05/84 vbc - Space Fill Cust-No Before Accept,Fix Escape Seq.
*> 12/07/84 Vbc - Move Escape Box 5 Chars Right, Remove Display
*>                 Headings In Menu-Input,Clear Screen On Report.
*> 01/03/85 Vbc - Support For Entry Date On Report Selection.
*> 20/03/09 vbc - Migration To Open Cobol v3.00.00, changed maps03 to 04,
*>                 and added print spooling for Linux
*> 25/03/09 vbc - New field - Notes which goes into newly added del file
*>                fixes bug 30.4 in SL so added here.
*> 25/03/09 vbc - Display & accept tidyups.
*> 01/04/09 vbc - Renamed Purch-Notes-Tag from notes-tag
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 07/09/10 vbc - .10 Mod lpr.
*> 15/09/10 vbc - .11 print spool command.
*> 11/12/11 vbc - .12 Support for dates other than UK & clean up msgs
*>                    Error msgs to SLnnn, Cleanup error/bad code in slcreate that missed testing!!
*>                    Changed delivery file to use indexed instead of relative, easier to delete un-needed
*>                    records and control size.
*>                    Support for path+filenames.
*>                    Updated version to 3.01.nn
*> 27/02/12 vbc - .13 Changed use of check-digit' in 'Purch-key to Purch-key (7:1) for SQL processing.
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
 copy "seldel.cob".
 copy "selprint.cob".
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdpl.cob".
 copy "fddel.cob".
 copy "fdprint.cob".
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "PL010 (3.01.13)".
 copy "print-spool-command.cob".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
 copy "wsmaps09.cob".
*>
 01  ws-data.
     03  menu-reply      pic 9.
     03  ws-reply        pic x.
     03  a               pic 999.
     03  y               pic 99.
     03  z               pic 9.
     03  error-flag      pic 9           value zero.
     03  escape-code     pic x.
     03  save-notes-tag  binary-long.
     03  print-out       pic x.
     03  truth           pic 9.
       88  a-true   value  1.
       88  a-false  value  0.
     03  d24-02          pic x           value space.
     03  d24-03          pic x           value space.
     03  d24-check.
         05  filler      pic x(13)       value "Check Digit {".
         05  d24-digit   pic x           value space.
         05  filler      pic x           value "}".
     03  A01-Notes.
         05  a01-Notes-1     pic x(48)       value spaces.
         05  a01-Notes-2     pic x(48)       value spaces.
     03  cust-in         pic x(6)        value spaces.
     03  status-in       pic x           value space.
     03  credit-in       pic 99          value zero.
     03  credit-op       pic x           value space.
     03  invoice-in      pic 9(5)        value zero.
     03  invoice-op      pic x           value space.
     03  average-in      pic 9(5)        value zero.
     03  average-op      pic x           value space.
     03  overdue-in      pic 9(5)        value zero.
     03  overdue-op      pic x           value space.
     03  enter-date-in   pic x(10)       value spaces.
     03  enter-date-op   pic x           value space.
     03  ws-Local-Date   pic x(10)       value spaces.
     03  ws-Test-Date    pic x(10).
     03  test-1          binary-long.
     03  test-2          binary-long.
     03  test-op         pic x.
     03  credit-heading.
       05  cr-operand    pic xx.
       05  cr-days       pic z9.
       05  filler        pic x(12)       value  " Days Credit".
     03  active-heading.
       05  act-operand   pic xx.
       05  act-days      pic zzzz9.
       05  filler        pic x(9)        value  " Invoices".
     03  average-heading.
       05  av-operand    pic xx.
       05  av-days       pic zzzz9.
       05  filler        pic x(10)       value  " Av. Value".
     03  overdue-heading.
       05  ov-operand    pic xx.
       05  ov-days       pic zzzz9.
       05  filler        pic x(13)       value " Days Overdue".
     03  enter-date-heading.
       05  ed-operand    pic xx.
       05  ed-date       pic x(8).
       05  filler        pic x(11)       value  " Entry Date".
     03  ws-enter-date   binary-long     value zero.
     03  address-line    pic x(32).
     03  display-bal     pic -(8)9.99.
     03  test-address    pic x(92).
     03  ws-spaces-30                    value spaces.
         05  ws-spaces-7 pic x(7).
         05  ws-spaces-13 pic x(13).
         05  filler      pic x(10).
     03  ws-eval-msg     pic x(25)       value spaces.
     03  intest          pic x.
     03  line-cnt        binary-char     value zero.
     03  customer-in     pic x(7).
     03  ws-env-lines    pic 999         value zero.
     03  ws-lines        binary-char unsigned value zero.
     03  ws-23-lines     binary-char unsigned value zero.
*>
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
 01  error-code          pic 999.
*>
 01  All-My-Constants    pic 9(4).
     copy "screenio.cpy".
*>
 01  Cbl-File-Details.
     03  Cbl-File-Size       pic x(8)  comp-x  value zero.
     03  Cbl-File-Date.
         05  Cbl-File-Day    pic x     comp-x  value zero.
         05  Cbl-File-Mth    pic x     comp-x  value zero.
         05  Cbl-File-Year   pic xx    comp-x  value zero.
     03  Cbl-File-time.
         05  Cbl-File-Hour   pic x     comp-x  value zero.
         05  Cbl-File-Min    pic x     comp-x  value zero.
         05  Cbl-File-Sec    pic x     comp-x  value zero.
         05  Cbl-File-Hund   pic x     comp-x  value zero.
*>
 01  Error-Messages.
*> System Wide
     03  PL004          pic x(10) value "hit return".
     03  PL005          pic x(18) value "PL005 Invalid Date".
*> Module specific
     03  PL101          pic x(14) value "PL101 Addr Err".
     03  PL102          pic x(5)  value "Error".
     03  PL103          pic x(52) value "PL103 Purchase Ledger files have not been set up yet".
     03  PL104          pic x(44) value "PL104 Do you wish to create them (Y/N) ? [ ]".
     03  PL105          pic x(40) value "PL105 Creating Purchase & Delivery Files".
     03  PL106          pic x(35) value "PL106 Opening Purchase files gives ".
     03  PL107          pic x(35) value "PL107 Opening Delivery files gives ".
     03  PL108          pic x(34) value "PL108 Abort Or Recover (A/R) : [ ]".
     03  PL109          pic x(51) value "PL109 <<<Can not Delete currently active account>>>".
*>
 01  line-1.
     03  l1-version      pic x(57)       value spaces.
     03  filler          pic x(67)       value "Supplier Listing".
     03  filler          pic x(5)        value "Page ".
     03  l1-page         pic zz9.
*>
 01  line-3.
     03  l3-user         pic x(40).
     03  filler          pic x(12)       value  "Report On : ".
     03  l3-report       pic x(70)       value  spaces.
     03  l3-date         pic x(10).
*>
 01  line-4.
     03  filler          pic x(51)       value "Supplier  Status    <----------------Name & Address".
     03  filler          pic x(51)       value "---------------->   ----Telephone---- -----Fax-----".
     03  filler          pic x(30)       value "    ----Credit----   Discount ".
*>
 01  line-5.
     03  filler          pic x(87)       value " Number   ------".
     03  filler          pic x(45)       value "                   Limit   Period       %".
*>
 01  line-6.
     03  l6-key          pic x(10).
     03  l6-status       pic x(10).
     03  l6-name         pic x(51).
     03  l6-phone        pic x(18).
     03  l6-fax          pic x(13).
     03  l6-limit        pic z(8)9          blank when zero.
     03  l6-credit       pic z(7)9          blank when zero.
     03  l6-discount     pic z(7)9.99       blank when zero.
*>
 01  line-7.
     03  filler          pic x(20)        value spaces.
     03  l7-address      pic x(112).
*>
 linkage section.
*>==============
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
*>
 01  to-day              pic x(10).
*>
 screen section.
*>=============
*>
*>   ALL Adjusted left 5 chars 11/12/11
*>
 01  display-02                  background-color cob-color-black
                                 foreground-color cob-color-green.
     03  value "Supplier Nos : ["    line  4 col  1.
*> >>>>>>>> customer no here <<<<<<<
     03  from d24-02          pic x  line  4 col 23.
     03  from d24-03          pic x          col 24.
     03  from d24-check       pic x(15)      col 26.
     03  value "Supplier Name: ["    line  6 col  1.
     03  using Purch-name  pic x(30) line  6 col 17.
     03  value "]"                   line  6 col 47.
     03  value "Addr: ["             line  7 col 10.
     03  using Purch-addr1 pic x(48)         col 17.
     03  value "]"                   line  7 col 65.
     03  value "["                   line  8 col 16.
     03  using Purch-addr2    pic x(48)      col 17.
     03  value "]"                   line  8 col 65.
     03  value "Suppliers Bank Details"
                                     line  9 col  1.
     03  value "Sort Code  : ["      line 10 col  3.
     03  using Purch-SortCode pic 9(6)       col 17.
     03  value "]"                           col 23.
     03  value "Account No : ["      line 11 col  3.
     03  using Purch-AccountNo pic 9(8)      col 17.
     03  value "]"                           col 25.
     03  value "Supplier Note: ["    line 12 col  1.
     03  using a01-Notes-1    pic x(48)      col 17.
     03  value "]"                           col 65.
     03  value "["                   line 13 col 16.
     03  using a01-Notes-2    pic x(48)      col 17.
     03  value "]"                           col 65.
     03  value "Telephone    : ["    line 14 col  1.
     03  using Purch-phone    pic x(13)      col 17.
     03  value "]"                           col 30.
     03  value "Ext: ["                      col 32.
     03  using Purch-ext      pic x(4)       col 38.
     03  value "]"                           col 42.
     03  value "Fax : ["                     col 45.
     03  using Purch-fax      pic x(13)      col 52.
     03  value "]"                           col 65.
     03  value "Email Sales  : ["    line 15 col  1.
     03  using Purch-email    pic x(30)      col 17.
     03  value "]"                           col 47.
     03  value "Credit Period: ["    line 18 col  1.
     03  using Purch-credit   pic 99         col 17.
     03  value "]"                           col 19.
     03  value "Credit limit : ["    line 19 col  1.
     03  using Purch-limit    pic 9(7)       col 17.
     03  value "] Discount : ["              col 24.
     03  using Purch-discount pic 99.99      col 38.
     03  value "]"                           col 43.
     03  value "*******************" line 19 col 56.
     03  value "Unapplied Bal: {"    line 20 col  1.
     03  value "}"                           col 29.
     03  value "* Escape Code ["     line 20 col 56.
*> value entered by individual display
     03  value "] *"                         col 72.
     03  value "Current Bal  : {"    line 21 col  1.
*> value entered by individual display
     03  value "}"                           col 29.
     03  value "* <B> = Back      *"         col 56.
     03  value "Last invoice : {"    line 22 col  1.
*> value entered by individual display
     03  value "}"                           col 27.
     03  value "* <S> = Save      *"         col 56.
     03  value "Last payment : {"    line 23 col  1.
*> value entered by individual display
     03  value "}"                           col 27.
     03  value "* <Q> = Quit      *" line 23 col 56.
     03  value "*******************" line 24 col 56.
*>
 01  display-03                  background-color cob-color-black
                                 foreground-color cob-color-green.
     03  from prog-name  pic x(15)                 line  1 col  1
                                                    blank screen.
     03  value "Supplier File"                             col 34.
     03  from ws-Local-Date   pic x(10)            line  1 col 71.
     03  value "Report Attributes"                 line  3 col 32.
*>
*> Adjusted left 6 chars 11/12/11
*>
     03  value "Supplier Number - ["               line  8 col  3.
     03  using cust-in   pic x(6)                          col 22.
     03  value "]"                                         col 28.
     03  value "Enter characters in positions to match"    col 33.
     03  value "Status          - ["               line 10 col  3.
     03  using status-in pic x                             col 22.
     03  value "]"                                         col 23.
     03  value "<L> Live;<D> Dormant;< > All"              col 33.
     03  value "Credit Period   - ["               line 12 col  3.
     03  using credit-in pic 99                            col 22.
     03  value "]  ["                                      col 24.
     03  using credit-op pic x                             col 28.
     03  value "]"                                 line 12 col 29.
     03  value "Enter number of days & operator"           col 33.
     03  value "<L>  for credit periods < than"    line 13 col 37.
     03  value "<G>  for credit periods > than"    line 14 col 37.
     03  value "<E>  for credit periods = to"      line 15 col 37.
     03  value "Invoice Activity  ["               line 17 col  3.
     03  using invoice-in pic 9(5)                         col 22.
     03  value "] ["                                       col 27.
     03  using invoice-op pic x                            col 30.
     03  value "]"                                         col 31.
     03  value "Enter number of invoices & operator"       col 33.
     03  value "Average Value   - ["               line 19 col  3.
     03  using average-in pic 9(5)                         col 22.
     03  value "] ["                                       col 27.
     03  using average-op pic x                            col 30.
     03  value "]"                                         col 31.
     03  value "Enter invoice value & operator"            col 33.
     03  value "Overdue A/Cs    - ["               line 21 col  3.
     03  using overdue-in pic 9(5)                         col 22.
     03  value "] ["                                       col 27.
     03  using overdue-op pic x                            col 30.
     03  value "]"                                         col 31.
     03  value "Enter number of days & operator"           col 33.
     03  value "Date Entered-["                    line 23 col  3.
     03  using enter-date-in pic x(10)                     col 17.
     03  value "] ["                                       col 27.
     03  using enter-date-op pic x                         col 30.
     03  value "]"                                         col 31.
     03  value "Enter date & operator"                     col 33.
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
 init01 section.
*>
     accept   ws-env-lines   from lines.
     if       ws-env-lines < 24
              move  24 to ws-env-lines ws-lines
     else
              move  ws-env-lines   to ws-lines
     end-if
     subtract 1 from ws-lines giving ws-23-lines.
     move     prog-name to l1-version.
     move     to-day to u-date.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name to PSN.
     move     space to Print-Out.
*>
     if       not p-l-exists
              perform plcreate.
*>
 menu-return.
*>**********
*>
     move     zero  to  menu-reply.
     perform  display-heading.
*>
 menu-input.
*>*********
*>
     display  "Select one of the following by number :- [ ]"   at 0701 with foreground-color 2.
     display  "(1)  Set-up Supplier records" at 1004     with foreground-color 2.
     display  "(2)  Amend Supplier records" at 1204      with foreground-color 2.
     display  "(3)  Delete Supplier records" at 1404     with foreground-color 2.
     display  "(4)  Print Supplier records" at 1604      with foreground-color 2.
     display  "(5)  Display Supplier records" at 1804    with foreground-color 2.
     display  "(9)  Return to system menu" at 2104       with foreground-color 2.
     accept   menu-reply at 0743 with foreground-color 6 auto.
*>
     if       menu-reply = 9
              go to  menu-exit.
*>
     if       menu-reply  <  1  or  >  5
              go to  menu-input.
*>
     if       menu-reply = 1
              perform setup-suppliers
     else
      if      menu-reply = 2
              perform amend-supplier
      else
       if     menu-reply = 3
              perform delete-supplier
       else
        if    menu-reply = 4
              perform  report-supplier
        else
         if   menu-reply = 5
              perform display-suppliers.
*>
     go      to menu-return.
*>
 menu-exit.
*>********
*>
     cancel   "maps09" "maps99".
*>
 menu-end.
     exit     program.
*>
 maps03.
*>*****
*>
     call     "maps04"  using  maps03-ws.
*>
 maps09.
*>*****
*>
     call     "maps09"  using  customer-code.
*>
 maps99.
*>*****
*>
     call     "maps99"  using  error-code ws-calling-data.
*>
 clear-error-line.
*>***************
*>
     display  " " at line ws-23-lines col 01 with erase eol.
*>
 Report-Supplier         section.
*>==============================
*>
     perform  Report-Selection.
     perform  Report-Heading-Setup.
     perform  Produce-Report.
*>
 main-end.
*>
     close    purchase-file delivery-file.
*>
 main-exit.   exit section.
*>********    ****
*>
 test-escape  section.
*>===================
*>
     display  escape-code at 2071 with foreground-color 6.
*>
 get-escape.
*>*********
*>
     accept   escape-code at 2071 with foreground-color 6 update.
     move     function upper-case (escape-code) to escape-code.
*>
     if       escape-code not = "B" and not = "S" and not = "Q"
                      and not = "K" and not = "D"
              go to get-escape.
*>
 main-exit.   exit section.
*>********    ****
*>
 display-heading         section.
*>==============================
*>
     display  " " at 0101 with erase eos.
*>
     move     spaces to d24-02 d24-check.
     move     "]" to d24-03.
*>
     if       menu-reply not = 4
              display prog-name at 0101 with foreground-color 2
              perform zz070-convert-date
              move    ws-date to ws-local-date
              display ws-date at 0171 with foreground-color 2.
*>
     if       menu-reply = zero
              display "Supplier File Set-Up & Maintenance" at 0124 with foreground-color 2
              display "Function  Menu" at 0434                     with foreground-color 2
              go to main-exit
     else
       if     menu-reply = 1
              display "Supplier Record Creation"  at 0129 with foreground-color 2
              move "Check Digit { }" to d24-check
              move "]" to d24-02
              move space to d24-03
       else
        if    menu-reply = 2
              display "Supplier Record Amendment" at 0129 with foreground-color 2
        else
         if   menu-reply = 3
              display "Supplier Record Deletion"  at 0129 with foreground-color 2
         else
          if  menu-reply = 5
              display "Supplier Record Display"   at 0129 with foreground-color 2.
*>
 main-exit.   exit section.
*>********    ****
*>
 customer-display   section.
*>*************************
*>
     if       menu-reply = 1
              move Purch-Key (7:1) to d24-digit
*>              move check-digit of purch-key to d24-digit
     else
              move Purch-Key (7:1) to d24-02.
*>              move check-digit of purch-key to d24-02.
*>
     display  display-02.
     if       menu-reply = 1 or 2
              go to cd-exit.
*>
     move     purch-unapplied to display-bal.
     display  display-bal at 2017 with foreground-color 3.
*>
     move     purch-current  to  display-bal.
     display  display-bal at 2117 with foreground-color 3.
*>
     if       purch-last-inv not = zero
              move purch-last-inv  to  u-bin
              perform zz060-Convert-Date
              display u-date at 2217 with foreground-color 3.
*>
     if       purch-last-pay not = zero
              move purch-last-pay  to  u-bin
              perform zz060-Convert-Date
              display u-date at 2317 with foreground-color 3.
*>
 cd-exit.
     exit     section.
*>
 display-outline         section.
*>==============================
*>
     perform  display-heading.
     initialize purch-record delivery-record.
     move     spaces to a01-Notes.
     display  display-02.
*>
 main-exit.   exit section.
*>********    ****
*>
 customer-data           section.
*>==============================
*>
     move     zero to error-flag.
     display  display-02.
     accept   display-02.
*>
     move     purch-address  to  test-address.
     perform  validate-address.
*>
     if       a-false
              display PL101 at 0766 with foreground-color 4
              move 1 to error-flag
     else
              display " " at 0766 with erase eol.
*>
     if       A01-Notes = spaces
         and  Purch-Notes-Tag not = zero
              move Purch-Key to Deliv-Purchase-Key
              move "N"       to Deliv-Key-Type
              delete delivery-file invalid key
                     move zero to Purch-Notes-Tag
     end-if
*>
*>  yes I know, but just in case!!
*>
     if       A01-Notes = spaces
              move zero to Purch-Notes-Tag
     else
              move 1 to Purch-Notes-Tag
     end-if.
*>
     if       error-flag not = zero
              go to customer-data.
*>
 main-exit.   exit section.
*>********    ****
*>
 validate-address        section.
*>==============================
*>
     move     zero  to  a.
*>
     inspect  test-address  tallying a for all pl-delim.
*>
     if       a  >  4  or  <  1
              move  zero  to  truth
     else
              move  1  to  truth.
*>
     move     zero  to  a.
     inspect  test-address tallying a for characters before initial pl-delim.
*>
*> Check for basic report/label limits
*>
     if       a  >  30
              move  zero  to  truth.
*>
 main-exit.   exit section.
*>********    ****
*>
 accept-key              section.
*>==============================
*>
     move     spaces to purch-key.
*>
     accept   purch-key at 0417 with foreground-color 3.
     move     function upper-case (purch-key) to purch-key.
*>
     move     zero  to  error-code.
*>
     if       purch-key = spaces
              move  999  to  error-code
              go to  main-exit.
*>
     move     zero to save-notes-tag.               *> force clear
     read     purchase-file record invalid key
              move  3  to  error-code
              perform  maps99
              move  spaces to  customer-code
              go to  main-exit.
*>
     perform  clear-error-line.
     move     purch-key  to  customer-code.
*>
*>  Check for Notes
*>
     if       Purch-Notes-Tag not = zero
              move     Purch-Key to Deliv-Purchase-Key
              move     "N"       to Deliv-Key-Type
              read     delivery-file record
                       invalid key
                          move zero  to  Purch-Notes-tag
                          move "Record Not Found" to A01-Notes-1
                          move spaces             to A01-Notes-2
                       not invalid key
                          move Deliv-Address to A01-Notes
                          move 1     to save-notes-tag
                                        Purch-Notes-tag
              end-read
     end-if.
*>
 main-exit.   exit section.
*>********    ****
*>
 setup-suppliers         section.
*>==============================
*>
     open     i-o purchase-file.
     open     i-o delivery-file.
     if       fs-reply not = zero
              close delivery-file
              open output delivery-file        *> OC doesnt create in i-o mode
              close delivery-file
              open  i-o delivery-file.
*>
 customer-input.
*>*************
*>
     move     spaces to a01-Notes.
     perform  display-outline.
*>
 customer-accept.
*>**************
*>
     move     spaces to customer-nos.
     accept   customer-nos at 0417 with foreground-color 3.
     if       customer-nos = spaces
              go to  main-end.
     move     function upper-case (customer-nos) to customer-nos.
     display  customer-nos at 0417 with foreground-color 3.
*>
     perform  clear-error-line.
*>
     move     "C"  to  maps09-reply.
     perform  maps09.
     if       maps09-reply not = "Y"
              go to  customer-accept.
*>
     move     customer-code  to  purch-key.
     read     purchase-file  not invalid key        *>    Therefore, Record already exists
              move     22  to  error-code
              perform  maps99
              perform  customer-display
              go to customer-accept.
*>
 customer-details.
*>***************
*>
     if       menu-reply = 1
              display check-digit of maps09-ws at 0444  with foreground-color 3.
*>
*>  this bit is different from sl010 as well ??
*>
     subtract 2 from ws-23-lines giving y.
     display  ws-spaces-30 at line y col 6.
     add      1 to y.
     display  ws-spaces-30 at line y col 6.
     display  ws-spaces-30 at line ws-23-lines col 6.
     initialize Purch-Record  delivery-record.
     move     1              to purch-status.
     move     customer-code  to purch-key.
     move     run-date       to purch-create-date.
     move     age-to-pay     to purch-credit.
*>
 get-details.
*>***********
*>
     perform  customer-display.
     perform  customer-data.
*>
     move     "S"  to   escape-code.
     perform  test-escape.
*>
 main-output.
*>***********
*>
     if       escape-code = "B"
              go to get-details.
*>
     if       escape-code = "Q"
              go to  main-end.
*>
     write    purch-record.
*>
     if       Purch-Notes-Tag not = zero
              move   purch-key to deliv-Purchase-key
              move   "N"       to deliv-Key-Type
              move   spaces    to deliv-name
              move   A01-Notes to deliv-address
              write  delivery-record.
*>
     initialize purch-record
                delivery-record.
     go       to customer-input.
*>
 main-end.
*>*******
*>
     close    purchase-file delivery-file.
*>
 main-exit.   exit section.
*>********    ****
*>
 amend-supplier         section.
*>=============================
*>
     open     i-o  purchase-file.
     open     i-o  delivery-file.
     if       fs-reply not = zero
              close delivery-file
              open output delivery-file
              close delivery-file
              open i-o delivery-file.
*>
 customer-input.
*>**************
*>
     perform  display-outline.
*>
 customer-accept.
*>
     perform  accept-key.
*>
     if       error-code = 999
              go to  main-end.
*>
     if       customer-code = spaces
              go to  customer-accept.
*>
     move     Purch-Notes-Tag     to  save-Notes-Tag.
*>
 get-details.
*>**********
*>
     perform  customer-display.
     perform  customer-data.
     move     "S"  to   escape-code.
     perform  test-escape.
*>
 main-output.
*>**********
*>
     if       escape-code = "B"
              go to get-details.
*>
     if       escape-code = "Q"
              go to  customer-input.
*>
     rewrite  purch-record.
*>
     move     "N"         to deliv-Key-Type.
     move     Purch-Key   to deliv-Purchase-key.
     move     spaces      to deliv-name.
     move     A01-Notes   to deliv-address.
*>
     if       Purch-Notes-Tag not = zero
        and   save-notes-tag = zero
              write  delivery-record invalid key      *> THIS STUFF FOR DEBUGGING, REMOVE AFTER
                     display "write notes tag " at line ws-23-lines col 1
                     display fs-reply  at line ws-23-lines col 20
                     perform evaluate-message
                     display ws-Eval-Msg at line ws-23-lines col 23
                     display "Note and hit return" at line ws-lines col 1
                     accept  Accept-Reply at line ws-lines col 20
                     display " " at line ws-23-lines col 1 with erase eos
              end-write
     else
      if      Purch-Notes-Tag not = zero
              rewrite delivery-record invalid key      *> THIS STUFF FOR DEBUGGING, REMOVE AFTER
                      display "Rewrite notes tag " at line ws-23-lines col 1
                      display fs-reply
                      perform evaluate-message
                      display ws-Eval-Msg at line ws-23-lines col 23
                      display "Note and hit return" at line ws-lines col 1
                      accept  Accept-Reply at line ws-lines col 20
                      display " " at line ws-23-lines col 1 with erase eos
              end-rewrite.
*>
     if       Purch-Notes-Tag = zero
       and    save-notes-tag  not = zero
              delete  delivery-file record invalid key      *> THIS STUFF FOR DEBUGGING, REMOVE AFTER
                      display "Delete notes tag " at line ws-23-lines col 1
                      display fs-reply
                      perform evaluate-message
                      display ws-Eval-Msg at line ws-23-lines col 23
                      display "Note and hit return" at line ws-lines col 1
                      accept  Accept-Reply at line ws-lines col 20
                      display " " at line ws-23-lines col 1 with erase eos
              end-delete.
*>
     rewrite  Purch-record invalid key                                 *> tags should be set already
              display "Rewrite Sales Rec " at line ws-23-lines col 1
              display fs-reply
              perform evaluate-message
              display ws-Eval-Msg at line ws-23-lines col 23
              display "Note and hit return" at line ws-lines col 1
              accept  Accept-Reply at line ws-lines col 20
              display " " at line ws-23-lines col 1 with erase eos
     end-rewrite
     go       to customer-input.
*>
 main-end.
*>*******
*>
     close    purchase-file delivery-file.
*>
 main-exit.   exit section.
*>********    ****
*>
 Evaluate-Message        Section.
*>==============================
*>
 copy "FileStat-Msgs.cpy" replacing MSG by ws-Eval-Msg
                                    STATUS by fs-reply.
*>
 Eval-Msg-Exit.  exit section.
*>************   ************
*>
 delete-supplier         section.
*>==============================
*>
     open     i-o  purchase-file delivery-file.
*>
 customer-input.
*>*************
*>
     perform  display-outline.
     display  "D> = Dormant" at 2159 with foreground-color 2.
     display  "K> = Kill " at 2259 with foreground-color 2.
*>
 customer-accept.
*>**************
*>
     perform  accept-key.
*>
     if       error-code = 999
              go to  main-end.
*>
     if       customer-code = spaces
              go to  customer-accept.
*>
 get-details.
*>**********
*>
     perform  customer-display.
*>
     move     "K"  to   escape-code.
     perform  test-escape.
*>
     if       escape-code = "Q"
              go to  main-end.
*>
     if       purch-current not = zero
           or purch-unapplied not = zero
              display PL109  at 0501 with foreground-color 4
              go to  customer-accept.
*>
     display  " " at 0501 with erase eol.
*>
     if       escape-code = "D"
              move  zero  to  purch-status
              rewrite  purch-record.
*>
     if       escape-code not =  "K"
              go to  customer-input.
*>
 main-output.
*>**********
*>
     if       Purch-Notes-tag  not = zero
              move     "N"       to Deliv-Key-Type.
              move     Purch-Key to Deliv-Purchase-Key.
              delete   delivery-file.
*>
     delete   purchase-file.
*>
 main-end.
*>*******
*>
     close    purchase-file delivery-file.
*>
 main-exit.   exit section.
*>********    ****
*>
 display-suppliers       section.
*>==============================
*>
     open     input  purchase-file delivery-file.
*>
 customer-input.
*>*************
*>
     perform  display-outline.
*>
 customer-accept.
*>
     perform  accept-key.
*>
     if       error-code = 999
              go to  main-end.
*>
     if       customer-code = spaces
              go to  customer-accept.
*>
     perform  customer-display.
*>
 accept-of-show.
*>*************
*>
     move     "S" to escape-code.
     perform  test-escape.
     if       ws-reply not = "Q"
              go to  customer-input.
*>
 main-end.
*>*******
*>
     close    purchase-file delivery-file.
*>
 main-exit.   exit section.
*>********    ****
*>
 report-selection        section.
*>==============================
*>
     open     input  purchase-file delivery-file.
*>
     move     spaces to cust-in status-in credit-op invoice-op
                        average-op overdue-op enter-date-op
                        enter-date-in print-out.
*>
     move     zero to credit-in invoice-in average-in overdue-in ws-enter-date.
     display  display-03.
*>
 accept-data.
*>**********
*>
     accept   display-03.
     move     function upper-case (cust-in) to cust-in.
     move     cust-in to customer-in.
     move     function upper-case (status-in) to status-in.
     if       status-in  not = "L" and not = "D" and not = space
              go to  accept-data.
*>
     move     function upper-case (credit-op) to credit-op.
     if       credit-op not = "L" and not = "G" and not = "E" and not = space
              go to  accept-data.
*>
     move     function upper-case (invoice-op) to invoice-op.
     if       invoice-op not = "L" and not = "G" and not = "E" and not = space
              go to  accept-data.
*>
     move     function upper-case (average-op) to average-op.
     if       average-op not = "L" and not = "G" and not = "E" and not = space
              go to  accept-data.
*>
     move     function upper-case (overdue-op) to overdue-op.
     if       overdue-op not = "L" and not = "G" and not = "E" and not = space
              go to  accept-data.
*>
     move     function upper-case (enter-date-op) to enter-date-op.
     if       enter-date-op not = "L" and not = "G" and not = "E" and not = space
              go to  accept-data.
*>
     if       enter-date-in = spaces
              go to main-end.
     move     zero          to u-bin.
     move     enter-date-in to ws-test-date.  *> was u-date
     perform  zz050-Validate-Date.
     if       u-bin = zero
              display PL005 at 2362 with foreground-color 4
              go to accept-data.
     display  " " at 2362 with erase eol.
     move     u-bin  to ws-enter-date.
*>     move     u-date to enter-date-in.     *> not sure about this, means that say intl date is now uk????
*>
 main-end.    exit section.
*>*******     ****
*>
 produce-report          section.
*>==============================
*>
     open     output  print-file.
     move     zero to a.
     perform  headings.
*>
     if       customer-in = spaces
              go to read-loop.
     move     customer-in to purch-key.
     start    purchase-file key not < purch-key invalid key
              move 1 to a.
     inspect  customer-in replacing all space by "Z".
*>
 read-loop.
*>********
*>
     read     purchase-file  next record  at end
              go to  end-report.
     if       fs-reply not = zero
              go to end-report.
*>
     if       status-in = "L"
        and   supplier-dead
              go to  read-loop.
     if       status-in = "D"
        and   supplier-live
              go to  read-loop.
*>
     if       customer-in not = spaces
        and   purch-key > customer-in
              go to end-report.
*>
     if       credit-op not = space
              move  credit-in     to  test-1
              move  purch-credit  to  test-2
              move  credit-op     to  test-op
              perform  test-num
              if    a-false
                    go to  read-loop.
*>
     if       invoice-op not = space
              move  invoice-in     to  test-1
              move  purch-activety to  test-2
              move  invoice-op     to  test-op
              perform  test-num
              if    a-false
                    go to  read-loop.
*>
     if       average-op not = space
              move  average-in    to  test-1
              move  purch-average to  test-2
              move  average-op    to  test-op
              perform  test-num
              if    a-false
                    go to  read-loop.
*>
     if       overdue-op not = space
       and    purch-current > 0.00
              move  overdue-in    to  test-1
              subtract purch-last-inv from run-date giving test-2
              move  overdue-op    to  test-op
              perform  test-num
              if    a-false
                    go to  read-loop.
*>
     if       enter-date-op not = space
              move  ws-enter-date     to  test-1
              move  purch-create-date to  test-2
              move  enter-date-op     to  test-op
              perform  test-num
              if    a-false
                    go to  read-loop.
*>
     perform  listing.
     go       to read-loop.
*>
 test-num.
*>*******
*>
     if       test-op = space
              move  1  to  truth
     else
              move  0  to  truth.
*>
     if       test-op = "L"
          and test-2  <  test-1
              move  1  to  truth.
*>
     if       test-op = "G"
          and test-2  >  test-1
              move  1  to  truth.
*>
     if       test-op = "E"
          and test-2  =  test-1
              move  1  to  truth.
*>
 headings.
*>*******
*>
     add      1  to  a.
     move     a  to  l1-page.
     if       a not = 1
              write print-record  from  line-1 after page
              write print-record  from  line-3 after 1
              move  spaces  to  print-record
              write print-record after 1
     else
              write print-record  from  line-1 before 1
              write print-record  from  line-3 before 1
     end-if
     write    print-record  from  line-4 after 1.
     write    print-record  from  line-5 after 1.
     move     spaces  to  print-record.
     write    print-record after 1.
     move     6 to line-cnt.
*>
 listing.
*>******
*>
     if       line-cnt > Page-Lines
              perform  headings.
     move     purch-key  to  l6-key.
*>
     if       supplier-live
              move  "Active"  to  l6-status
     else
              move  "Dormant" to  l6-status.
*>
     move     spaces         to  l6-phone.
     move     purch-name     to  l6-name.
     move     purch-address  to  l7-address.
     inspect  l7-address  replacing  all  sl-delim  by  ",".
     if       purch-ext = spaces
              move purch-phone to l6-phone
     else
              move  1 to y
              string purch-phone delimited by "  " into l6-phone with pointer y
              subtract 1 from y
              string "x"         delimited by size
                     purch-ext   delimited by size  into l6-phone with pointer y.
*>
     move     purch-fax      to l6-fax.
     move     purch-limit    to l6-limit.
     move     purch-credit   to l6-credit.
     move     purch-discount to l6-discount.
*>
     if       line-cnt > Page-Lines - 3
              perform headings.
     write    print-record  from  line-6 after 1.
     write    print-record  from  line-7 after 1.
*>
     if       Purch-Notes-Tag > zero
              perform  notes-print.
*>
     move     spaces  to  print-record.
     write    print-record after 1.
     add      3 to line-cnt.
     move     "Y" to Print-Out.
*>
 notes-print.
     move     "N"       to Deliv-Key-Type.
     move     Purch-Key to Deliv-Purchase-Key.
     read     delivery-file invalid key
              move "Record Not Found" to deliv-Address.
*>
     move     spaces to l7-address.
     string   "Notes: " delimited by size
              deliv-address delimited by "  " into l7-address.
     write    print-record from line-7 after 1.
     add      1 to line-cnt.
*>
 end-report.
*>*********
*>
 main-end.
*>*******
*>
     close    print-file.
     if       Print-Out = "Y"
              call     "SYSTEM" using Print-Report.
*>
 main-exit.   exit section.
*>********    ****
*>
 report-heading-setup    section.
*>==============================
*>
     perform  zz070-convert-date.
     move     ws-date to l3-date.
     move     usera  to  l3-user.
     move     1      to  y.
     move     spaces to  l3-report.
*>
     if       status-in = spaces  and  credit-op
         and  invoice-op   and  average-op
         and  overdue-op   and  customer-in
              string  "All"  delimited by size     into  l3-report  with  pointer  y
     else
              string  "Matched"  delimited by size into  l3-report  with  pointer  y.
*>
     add      1  to  y.
*>
     if       status-in = "L"
              string  "Live"  delimited by size    into  l3-report  with  pointer  y.
     if       status-in = "D"
              string  "Dormant"  delimited by size into  l3-report  with  pointer  y.
*>
     add      1  to  y.
*>
     if       credit-op = "L"
              move    "< "  to  cr-operand.
     if       credit-op = "G"
              move    "> "   to  cr-operand.
     if       credit-op = "E"
              move    "= "  to  cr-operand.
*>
     if       credit-op not = " "
              move  credit-in  to  cr-days
              string  credit-heading  delimited by size into  l3-report  with  pointer  y.
*>
     add      1  to  y.
*>
     if       invoice-op = "L"
              move    "< "  to  act-operand.
     if       invoice-op = "G"
              move    "> "   to  act-operand.
     if       invoice-op = "E"
              move    "= "  to  act-operand.
*>
     if       invoice-op not = " "
              move  invoice-in  to  act-days
              string  active-heading  delimited by size into  l3-report  with  pointer  y.
*>
     add      1  to  y.
*>
     if       average-op = "L"
              move    "< "  to  av-operand.
     if       average-op = "G"
              move    "> "   to  av-operand.
     if       average-op = "E"
              move    "= "  to  av-operand.
*>
     if       average-op not = " "
              move  average-in  to  av-days
              string  average-heading  delimited by size into  l3-report  with  pointer  y.
*>
     add      1  to  y.
*>
     if       overdue-op = "L"
              move    "< "  to  ov-operand.
     if       overdue-op = "G"
              move    "> "   to  ov-operand.
     if       overdue-op = "E"
              move    "= "  to  ov-operand.
*>
     if       overdue-op not = " "
              move  overdue-in  to  ov-days
              string  overdue-heading  delimited by size into  l3-report  with  pointer  y.
*>
     add      1  to  y.
*>
     if       enter-date-op = "L"
              move    "< "  to  ed-operand.
     if       enter-date-op = "G"
              move    "> "   to  ed-operand.
     if       enter-date-op = "E"
              move    "= "  to  ed-operand.
*>
     if       enter-date-op  not = space
              move  enter-date-in  to  ed-date
              string  enter-date-heading  delimited by size into  l3-report  with  pointer  y.
*>
     add      1  to  y.
*>
     if       customer-in not =  spaces
              string  " Keys Matching - " delimited by size
                      customer-in         delimited by size into  l3-report  with  pointer  y.
*>
 main-exit.   exit section.
*>********    ****
*>
 plcreate                section.
*>==============================
*>
     perform  display-heading.
     display  PL103 at 1201  with foreground-color 4.
     display  PL104 at 1301  with foreground-color 2.
     move     space to ws-reply.
     accept   ws-reply at 1343 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "N"
              exit program.
     if       ws-reply not = "Y"
              go to plcreate.
*>
     display  PL105  at 1506  with foreground-color 2.
     open     output purchase-file.
     if       fs-reply not = zero
              display PL106    at 1201 with erase eol
              display fs-reply at 1237
              display PL004    at 1240
              close Purchase-File
              go to main-exit.
     open     output delivery-file.
     if       fs-reply not = zero
              display PL107    at 1201 with erase eol
              display fs-reply at 1237
              display PL004    at 1240
              close delivery-file
              go to main-exit.
*>
     close    purchase-file delivery-file.
     move     1 to file-status (22) file-status (14).
     move     "Y" to purchase-ledger.
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
     inspect  ws-test-date replacing all "." by "/".
     inspect  ws-test-date replacing all "," by "/".
     inspect  ws-test-date replacing all "-" by "/".
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
     perform  maps03.
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
     perform  maps03.
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
