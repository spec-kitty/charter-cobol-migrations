       >>source free
*>****************************************************
*>                                                   *
*>           Purchase  Ledger  Alpha - List          *
*>                                                   *
*>****************************************************
*>
 identification          division.
*>================================
*>
*>**
      program-id.         pl160.
*>**
*>    Author.             Cis Cobol Conversion By V B Coen FBCS, 17/04/84
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Purchase Ledger Supplier Alpha Print.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps04.
*>**
*>    Error messages used.
*>                        PL005
*>                        PL170
*>**
*>    Changes.
*> 01/03/85 Vbc - Support For Entry Date In Report Selection.
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 07/09/10 vbc - .04 Mod lpr.
*> 16/12/11 vbc - .05 Error msgs to SLnnn.Support for dates other than UK
*>                    Support for path+filenames. clear sort file.
*>                    Updated version to 3.01.nn & adjust code for IS delivery file
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
 copy "fdprint.cob".
 fd  sales-sort.
*>
 01  sales-sort-record.
     03  sales-sort-key       pic x(7).
*>
 working-storage section.
*>-----------------------
 77  prog-name           pic x(15) value "PL160 (3.01.05)".
 copy "print-spool-command.cob".
 copy "wsfnctn.cob".
 copy "wsmaps03.cob".
 01  fn-sales        pic x(12)       value "suppsort.inx".
*>
 01  ws-data.
     03  ws-reply        pic x.
     03  a               pic 99.
     03  y               pic 99.
     03  z               pic 9.
     03  print-out       pic x.
     03  truth           pic 9.
         88  a-true                        value  1.
         88  a-false                       value  zero.
     03  test-1          binary-long.
     03  test-2          binary-long.
     03  test-op         pic x.
     03  credit-heading.
         05  cr-operand  pic xx.
         05  cr-days     pic z9.
         05  filler      pic x(12)       value  " Days Credit".
     03  active-heading.
         05  act-operand pic xx.
         05  act-days    pic zzzz9.
         05  filler      pic x(9)        value  " Invoices".
     03  average-heading.
         05  av-operand  pic xx.
         05  av-days     pic zzzz9.
         05  filler      pic x(10)       value  " Av. Value".
     03  overdue-heading.
         05  ov-operand  pic xx.
         05  ov-days     pic zzzz9.
         05  filler      pic x(13)       value
           " days overdue".
     03  enter-date-heading.
         05  ed-operand  pic xx.
         05  ed-date     pic x(8).
         05  filler      pic x(11)       value  " Entry Date".
     03  ws-enter-date   binary-long     value zero.
     03  address-line    pic x(32).
     03  test-address    pic x(92).
     03  line-cnt        binary-char     value zero.
     03  customer-in     pic x(7).
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
     03  PL005          pic x(18) value "PL005 Invalid Date".
*> Module specific
     03  PL170          pic x(18) value "PL170 Not Found - ".
*>
 01  error-code          pic 999.
*>
 01  line-1.
     03  l1-name         pic x(51).
     03  filler          pic x(73)       value "Supplier Alphabetical Listing".
     03  filler          pic x(5)        value  "Page ".
     03  l3-page         pic zz9.
*>
 01  line-3.
     03  l3-user         pic x(40).
     03  filler          pic x(12)       value  "Report on : ".
     03  l3-report       pic x(70)       value  spaces.
     03  l1-date         pic x(10).
*>
 01  line-4.
     03  filler          pic x(51)       value "Supplier  Status    <----------------Name & Address".
     03  filler          pic x(51)       value "---------------->   ----Telephone----    ----Fax---".
     03  filler          pic x(30)       value "    ----Credit----   Discount ".
*>
 01  line-5.
     03  filler          pic x(87)       value " Number   ------".
     03  filler          pic x(45)       value "                   Limit   Period".
*>
 01  line-6.
     03  l6-key          pic x(10).
     03  l6-status       pic x(10).
     03  l6-name         pic x(51).
     03  l6-phone        pic x(17).
     03  l6-fax          pic x(14).
     03  l6-limit        pic z(9)9bbbb   blank when zero.
     03  l6-credit       pic z9bbbbbb    blank when zero.
     03  l6-discount     pic z9.99       blank when zero.
*>
 01  line-7.
     03  filler          pic x(20)       value spaces.
     03  l7-address      pic x(96).
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
 screen section.
*>**************
*>
 01  display-03                  background-color cob-color-black
                                 foreground-color cob-color-green.
     03  from prog-name  pic x(15)                 line  1 col  1
                                                    blank screen.
     03  value "Supplier File"                             col 34.
     03  from to-day     pic x(10)                 line  1 col 71.
     03  value "Report Attributes"                 line  3 col 32.
     03  value "Supplier Number - ["               line  8 col  9.
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
     move     prog-name to l1-name.
     perform  zz070-Convert-Date.
     move     ws-date to  l1-date.
     move     usera   to  l3-user.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name to PSN.
*>
     perform  report1.
*>
 menu-exit.
     exit     program.
*>
*>*************************************************
*>               Procedures                       *
*>*************************************************
*>
 report1      section.
*>===================
*>
     open     input  purchase-file.
*>
     perform  report-selection.
     perform  report-heading-setup.
     perform  report-produce.
*>
     close    print-file sales-sort.
     close    purchase-file.
     call     "SYSTEM" using Print-Report.
     open     output sales-sort.       *> make it a null file
     close    sales-sort.
*>
 main-exit.   exit section.
*>
*>****************************************************************
*>       S E R V I C E    R O U T I N E S                        *
*>****************************************************************
*>
 report-selection section.
*>***********************
*>
     move     spaces to overdue-op  status-in credit-op invoice-op
                        average-op cust-in print-out.
     move     zero to credit-in invoice-in average-in overdue-in.
     display  display-03.
*>
 accept-data.
*>**********
*>
     accept   display-03.
     move     function upper-case (cust-in) to cust-in.
     move     cust-in to customer-in.
     inspect  customer-in replacing all space by "Z".
*>
     move     function upper-case (status-in) to status-in.
     if       status-in  not = "L" and not "D" and not = space
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
              go to main-exit.
     move     enter-date-in to ws-test-date.
     perform  zz050-Validate-Date.
     if       u-bin = zero
              display PL005 at 2368 with foreground-color 2   *> this msg may NOT get seen
              go to accept-data.
     display  " " at 2368 with erase eol.
     move     u-bin to ws-enter-date.
*>
 main-exit.   exit section.
*>
 report-produce              section.
*>==================================
*>
     open     input   sales-sort.
     open     output  print-file.
     move     zero  to  a.
     perform  headings.
*>
 read-loop.
*>********
*>
     read     sales-sort record
              at end  go to  end-report.
*>
     move     sales-sort-key  to  purch-key.
*>
     if       customer-in not = spaces
         and  purch-key < cust-in
              go to read-loop.
*>
     if       customer-in not = spaces
         and  purch-key > customer-in
              go to read-loop.
*>
     read     purchase-file   invalid key
              display PL170 at 2301 with foreground-color 4
              display purch-key at 2313 with foreground-color 4
              go to  read-loop.
     display  " " at 2301 with erase eol
*>
     if       status-in = "L"
         and  supplier-dead
              go to  read-loop
      else
       if    status-in = "D"
         and  supplier-live
              go to  read-loop.
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
        and   purch-current  >  0.00
              move  overdue-in    to  test-1
              subtract  purch-last-inv  from  run-date giving  test-2
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
 headings.
*>*******
*>
     add      1  to  a.
     move     a  to  l3-page.
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
              perform headings.
     move     purch-key  to  l6-key.
     move     1 to y.
     if       supplier-live
              move  "Active"  to  l6-status
     else
              move  "Dormant" to  l6-status.
     move     spaces to l6-phone.
     move     purch-name     to  l6-name.
     move     purch-address  to  l7-address.
     inspect  l7-address  replacing  all  pl-delim  by  ",".
     if       purch-ext = spaces
              move purch-phone to l6-phone
     else
              string purch-phone delimited by "  "
                     "x"         delimited by size
                     purch-ext   delimited by size  into l6-phone with pointer y.
*>
     move     purch-fax to l6-fax.
     move     purch-limit   to  l6-limit.
     move     purch-credit  to  l6-credit.
     move     purch-discount to l6-discount.
*>
     if       line-cnt > Page-Lines - 3
              perform headings.
*>
     write    print-record  from  line-6 after 1.
     write    print-record  from  line-7 after 1.
     move     spaces to print-record.
     write    print-record after 1.
     add      3 to line-cnt.
*>
 end-report.
*>*********
*>
 main-exit.   exit section.
*>********    ****
*>
 report-heading-setup  section.
*>=============================
*>
     move     1  to  y.
     move     spaces  to  l3-report.
*>
     if       space = status-in  and  credit-op
               and  invoice-op   and  average-op
               and  overdue-op   and  customer-in
              string  "All"  delimited by size  into  l3-report  with  pointer  y
     else
              string  "Matched"  delimited by size into  l3-report  with  pointer  y.
*>
     add      1  to  y.
*>
     if       status-in = "L"
              string  "Live"  delimited by size  into  l3-report  with  pointer  y.
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
     if       credit-op not = space
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
     if       invoice-op not = space
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
     if       average-op not = space
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
     if       overdue-op not = space
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
     if       enter-date-op not = space
              move  enter-date-in  to  ed-date
              string  enter-date-heading  delimited by size into  l3-report  with  pointer  y.
*>
     add      1  to  y.
*>
     if       cust-in not = spaces
              string  " Keys Matching - "  delimited by size
                      cust-in              delimited by size into  l3-report  with  pointer  y.
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
