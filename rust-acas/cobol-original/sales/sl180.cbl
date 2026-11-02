       >>source free
*>********************************************************
*>                                                       *
*>           Sales  Ledger  Turnover  Report             *
*>                                                       *
*>********************************************************
*>
 identification division.
 program-id.              sl180.
*>
*>    Author.             V.B.Coen, FBCS
*>                        Cis Cobol Conversion 26/10/83
*>                        For Applewood Computers.
*>**
*>    Remarks.            Sales Ledger Customer Turnover Report.
*>**
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Version.            See Prog-Name & Date-Comped In Ws.
*>**
*>    Called Modules.     Maps04.
*>
*>**
*>    Error messages used.
*>                        SL005
*>**
*>    changes.
*> 10/10/83 vbc - Chg printer to use line-cnt.
*> 26/10/83 vbc - Cis Cobol Conversion.
*> 01/03/84 vbc - Support sales-unapplied in listing routine.
*> 28/02/85 vbc - Support for enter-date on report selection.
*> 03/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 07/09/10 vbc - .04 Mod lpr.
*> 25/11/11 vbc - .05 Error msgs to SLnnn.Support for dates other than UK
*> 08/12/11 vbc - .06 Support for path+filenames.
*> 09/12/11 vbc -     Updated version to 3.01.nn
*> 11/12/11 vbc - .07 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 18/05/13 vbc - .08 Test for bugs, found section inside section, daft
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
*>------------
*>
 copy "selsl.cob".
 copy "selprint.cob".
*>
 data                    division.
*>===============================
*>
 file section.
*>------------
*>
 copy "fdsl.cob".
*>
 fd  print-file.
 01  print-record         pic x(132).
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "SL180 (3.01.08)".
 copy "print-spool-command.cob".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
*>
 01  ws-data.
     03  ws-reply        pic x.
     03  a               pic 999.
     03  y               pic 99.
     03  z               pic 9.
     03  truth           pic 9.
         88  a-true                       value  1.
         88  a-false                      value  zero.
     03  test-1          binary-long.
     03  test-2          binary-long.
     03  test-op         pic x.
     03  ws-enter-date   binary-long value zero.
     03  address-line    pic x(32).
     03  test-address    pic x(92).
     03  line-cnt        pic 99      comp value zero.
     03  customer-in.
         05  array-l     pic x  occurs 7.
     03  ws-spaces-10    pic x(10)        value spaces.
*>
     03  cust-in         pic x(6)         value spaces.
     03  status-in       pic x            value space.
     03  credit-in       pic 99           value zero.
     03  credit-op       pic x            value space.
     03  invoice-in      pic 9(5)         value zero.
     03  invoice-op      pic x            value space.
     03  average-in      pic 9(5)         value zero.
     03  average-op      pic x            value space.
     03  overdue-in      pic 9(5)         value zero.
     03  overdue-op      pic x            value space.
     03  enter-date-in   pic x(10)        value spaces.
     03  enter-date-op   pic x            value space.
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
 01  Error-Messages.
*> System Wide
     03  SL005          pic x(18) value "SL005 Invalid Date".
*> Module specific
*>     NONE
*>
 01  error-code          pic 999.
*>
 01  line-1.
     03  l1-version      pic x(51)        value spaces.
     03  filler          pic x(73)        value "Sales Ledger Turnover Report".
     03  filler          pic x(5)         value "Page ".
     03  l3-page         pic zz9.
*>
 01  line-2.
     03  l3-user         pic x(51).
     03  filler          pic x(28)       value spaces.
     03  filler          pic x(43)       value spaces.
     03  l1-date         pic x(10).
*>
 01  line-3.
     03  filler          pic x(38)       value  spaces.
     03  filler          pic x(94)       value
     "Credit Terms  <------------- T u r n o v e r ------------> <--S A L E S-->  <--Date Of Last-->".
*>
 01  line-4.
     03  filler          pic x(38)       value "Acct No          Name".
     03  filler          pic x(94)       value
     "Days   Limit  Mvmt Average   Qtr 1   Qtr 2   Qtr 3   Qtr 4 Current    Last  Invoice    Payment".
*>
 01  line-5.
     03  l5-acct         pic x(8).
     03  l5-name         pic x(30).
     03  l5-credit       pic zzz9.
     03  l5-limit        pic z(7)9.
     03  l5-activety     pic -(5)9.
     03  l5-average      pic -(7)9. *> 64
     03  l5-quarters     pic -(7)9   occurs 4. *> 32+ = 96
     03  l5-current      pic -(7)9.
     03  l5-last         pic -(7)9. *> 112
     03  filler          pic xx          value spaces.
     03  l5-last-inv     pic x(10).
     03  l5-last-pay     pic x(8).  *> 132
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
 screen section.
*>
 01  display-03                  background-color cob-color-black
                                 foreground-color cob-color-green.
     03  from prog-name  pic x(15)                 line  1 col  1
                                                    blank screen.
     03  value "Customer File"                             col 34.
     03  from ws-date    pic x(10)                 line  1 col 71.
     03  value "Report Attributes"                 line  3 col 32.
     03  value "Customer Number - ["               line  8 col  9.
     03  using cust-in   pic x(6)                          col 28.
     03  value "]"                                         col 34.
     03  value "Enter characters in positions to match"    col 39.
     03  value "Status          - ["               line 10 col  9.
     03  using status-in pic x                             col 28.
     03  value "]"                                         col 29.
     03  value "<L> Live;<D> Dormant;< > All"              col 39.
     03  value "Credit Period   - ["               line 12 col  9.
     03  using credit-in pic 99                            col 28.
     03  value "]  ["                                      col 30.
     03  using credit-op pic x                             col 34.
     03  value "]"                                 line 12 col 35.
     03  value "Enter number of days & operator"           col 39.
     03  value "<L>  for credit periods < than"    line 13 col 43.
     03  value "<G>  for credit periods > than"    line 14 col 43.
     03  value "<E>  for credit periods = to"      line 15 col 43.
     03  value "Invoice Activity  ["               line 17 col  9.
     03  using invoice-in pic 9(5)                         col 28.
     03  value "] ["                                       col 33.
     03  using invoice-op pic x                            col 36.
     03  value "]"                                         col 37.
     03  value "Enter number of invoices & operator"       col 39.
     03  value "Average Value   - ["               line 19 col  9.
     03  using average-in pic 9(5)                         col 28.
     03  value "] ["                                       col 33.
     03  using average-op pic x                            col 36.
     03  value "]"                                         col 37.
     03  value "Enter invoice value & operator"            col 39.
     03  value "Overdue A/Cs    - ["               line 21 col  9.
     03  using overdue-in pic 9(5)                         col 28.
     03  value "] ["                                       col 33.
     03  using overdue-op pic x                            col 36.
     03  value "]"                                         col 37.
     03  value "Enter number of days & operator"           col 39.
     03  value "Date Entered-["                    line 23 col  9.
     03  using enter-date-in pic x(10)                     col 23.
     03  value "] ["                                       col 33.
     03  using enter-date-op pic x                         col 36.
     03  value "]"                                         col 37.
     03  value "Enter date & operator"                     col 39.
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 init01 section.
*>
     move     prog-name to l1-version.
     move     usera   to l3-user.
     perform  zz070-Convert-Date.
     move     ws-date to l1-date.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name to PSN.
*>
     open     input sales-file.
     open     output print-file.
*>
     perform  report-selection.
     perform  produce-report.
*>
     close    sales-file print-file.
     call     "SYSTEM" using Print-Report.
*>
 menu-exit.
     exit     program.
*>
 produce-report          section.
*>==============================
*>
     move     zero  to  a z.
     perform  p-headings.
     if       customer-in = spaces
              go to read-loop.
     move     customer-in to sales-key.
     start    sales-file key not < sales-key invalid key
              move 1 to a.
     inspect  customer-in replacing all space by "Z".
*>
 read-loop.
*>********
*>
     read     sales-file  next record  at end
              go to  end-report.
*>
     if       fs-reply not = zero
              go to end-report.
*>
     if       status-in = "L" and  customer-dead
              go to read-loop
     else
       if     status-in = "D" and  customer-live
              go to  read-loop.
*>
     if       customer-in not = spaces
         and  sales-key > customer-in
              go to end-report.
*>
     if       credit-op not = space
              move  credit-in     to  test-1
              move  sales-credit  to  test-2
              move  credit-op     to  test-op
              perform  test-num
              if    a-false
                    go to  read-loop.
*>
     if       invoice-op not = space
              move  invoice-in     to  test-1
              move  sales-activety to  test-2
              move  invoice-op     to  test-op
              perform  test-num
              if    a-false
                    go to  read-loop.
*>
     if       average-op not = space
              move  average-in    to  test-1
              move  sales-average to  test-2
              move  average-op    to  test-op
              perform  test-num
              if    a-false
                    go to  read-loop.
*>
     if       overdue-op not = space
       and    sales-current > 0.00
              move  overdue-in to test-1
              subtract  sales-last-inv  from  run-date  giving  test-2
              move  overdue-op    to  test-op
              perform  test-num
              if    a-false
                    go to  read-loop.
*>
     if       enter-date-op not = space
              move  ws-enter-date     to  test-1
              move  sales-create-date to  test-2
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
     move     function upper-case (test-op) to test-op.
     if       test-op = space
              move  1  to  truth
     else
              move  0  to  truth.
*>
     if       test-op = "L"
       and    test-2  <  test-1
              move  1  to  truth.
*>
     if       test-op = "G"
       and    test-2  >  test-1
              move  1  to  truth.
*>
     if       test-op = "E"
       and    test-2  =  test-1
              move  1  to  truth.
*>
 p-headings.
*>*********
*>
     add      1  to  a.
     move     a  to  l3-page.
*>
     if       a not = 1
              write print-record  from  line-1 after page
              write print-record  from  line-2 after 1
              move  spaces to print-record
              write print-record after 1
     else
              write print-record  from  line-1 before 1
              write print-record  from  line-2 before 1
     end-if
     write    print-record  from  line-3 after 2.
     write    print-record  from  line-4 after 1.
     move     spaces to print-record.
     write    print-record after 1.
     move     6 to line-cnt.
*>
 listing.
*>******
*>
     move     sales-key    to  l5-acct.
     subtract sales-unapplied from sales-current.
     move     sales-credit    to  l5-credit.
     move     sales-current    to  l5-current.
     move     sales-name    to  l5-name.
     move     sales-last    to  l5-last.
     move     turnover-q1    to  l5-quarters (1).
     move     turnover-q2    to  l5-quarters (2).
     move     sales-limit    to  l5-limit.
     move     turnover-q3    to  l5-quarters (3).
     move     sales-activety    to  l5-activety.
     move     turnover-q4    to  l5-quarters (4).
     if       sales-last-inv = zero
              move  spaces  to  l5-last-inv
     else
              move  sales-last-inv  to  u-bin
              perform  zz060-Convert-Date
              perform shorten-ws-date
              move  ws-date  to  l5-last-inv.
*>
     if       sales-last-pay = zero
              move  spaces  to  l5-last-pay
       else
              move  sales-last-pay  to  u-bin
              perform  zz060-Convert-Date
              perform shorten-ws-date
              move  ws-date  to  l5-last-pay.
*>
     move     sales-average    to  l5-average.
*>
     write    print-record  from  line-5 after 1.
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform p-headings.
*>
 end-report.
     exit     section.
*>
 shorten-ws-date   section.
*>***********************
*>
     if       Date-UK or Date-USA
              move ws-date (9:2) to ws-date (7:2)
              move spaces to ws-date (9:2)
     else
*> So its International date format
              move  ws-date (3:2) to ws-date (1:2)
              move  ws-date (5:2) to ws-date (3:2)
              move  ws-date (7:2) to ws-date (5:2)
              move  ws-date (9:2) to ws-date (7:2)
              move spaces to ws-date (9:2).
*>
 shorten-ws-date-exit.
     exit     section.
*>
 report-selection section.
*>***********************
*>
     move     spaces to overdue-op  status-in credit-op invoice-op
                        average-op cust-in enter-date-in
                        enter-date-op.
     move     zero to credit-in invoice-in average-in overdue-in.
     display  display-03.
*>
 accept-data.
*>**********
*>
     accept   display-03 with update.
     move     cust-in to customer-in.
*>
     move     function upper-case (status-in) to status-in.
     if       status-in not = "L" and not = "D" and not = space
              go to  accept-data.
*>
     move     function upper-case (credit-op) to credit-op.
     if       credit-op not = "L" and not = "G" and not = "E"  and not = space
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
              go to main-exit.
*>
     move     enter-date-in to ws-test-date.
     perform  zz050-Validate-Date.
     if       u-bin = zero
              display SL005 at 2361                                 *> this msg will NOT get seen
              go to accept-data.
*>
     display  " " at 2368 with erase eol.
     move     u-bin  to ws-enter-date.
*>     move     u-date to enter-date-in.                           *> its now a UK formatted date so dont overwrite
*>
 main-exit.
     exit     section.
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
