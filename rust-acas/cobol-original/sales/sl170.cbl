       >>source free
*>*************************************************
*>                                                *
*>           Sales Ledger Database Dump           *
*>                                                *
*>*************************************************
*>
 identification          division.
*>================================
*>
      program-id.         sl170.
*>**
*>    author.             Cis Cobol Conversion By V B Coen FBCS, 26/10/83
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    remarks.            Sales Ledger Customer File Dump.
*>**
*>    version.            See Prog-Name In Ws.
*>
*>    Called Modules.     Maps04.
*>
*>**
*>    Error messages used.
*>                        NONE
*>**  Changes.
*> 01/03/84 vbc - Support Sales-Unapplied In Listing Routine.
*> 03/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 13/03/09 vbc - Printing email data.
*> 07/09/10 vbc - .02 Mod lpr.
*> 25/11/11 vbc - .03 Error msgs to SLnnn.Support for dates other than UK
*>                     also removed date-in from report attributes as not used
*> 04/12/11 vbc - .04 Added Notes-tag and cleaned up email line with ',' and '.'
*>                    Temp. added system tag value for final two lines of report
*>                    BUT not Printed if no cust records present.
*> 08/12/11 vbc - .05 Support for path+filenames.
*> 09/12/11 vbc -     Updated version to 3.01.nn
*> 11/12/11 vbc - .06 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 27/02/12 vbc - .07 Changed use of array-k' in 'sales-key to sales-key (y:1) for SQL processing.
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
 copy "selprint.cob".
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdsl.cob".
*>
 fd  print-file.
*>
 01  print-record       pic x(132).
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "SL170 (3.01.07)".
 copy "print-spool-command.cob".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
*>
 01  ws-data.
     03  ws-reply        pic x.
     03  a               pic 999           value zero.
     03  y               pic 99            value zero.
     03  z               pic 9             value zero.
     03  truth           pic 9             value zero.
         88  a-true                        value  1.
         88  a-false                       value  0.
     03  Rec-Cnt         binary-char       value zero.
     03  p               binary-char       value zero.
     03  test-1          binary-long       value zero.
     03  test-2          binary-long       value zero.
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
         05  filler      pic x(13)       value " Days Overdue".
     03  address-line    pic x(32).
     03  test-address    pic x(92).
     03  customer-in.
         05  array-l     pic x    occurs 7.
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
*>     03  enter-date-in   pic x(10)       value spaces.    *>  Not needed
*>     03  enter-date-op   pic x           value space.     *>  Not used/needed
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
*>     NONE.
*> Module specific
*>     NONE
*>
 01  error-code          pic 999.
*>
 01  line-1.
     03  l1-version      pic x(57)      value spaces.
     03  filler          pic x(67)      value "Sales Ledger Dump".
     03  filler          pic x(5)       value "Page ".
     03  l1-page         pic zz9.
*>
 01  line-2.
     03  filler          pic x(57)       value spaces.
     03  filler          pic x(17)       value spaces.
*>
 01  line-3.
     03  l3-user         pic x(40).
     03  filler          pic x(12)       value  "Report On : ".
     03  l3-report       pic x(70)       value  spaces.
     03  l3-date         pic x(10).
*>
 01  line-4.
     03  l4-name-1       pic x(14).
     03  l4-value-1      pic x(56).
     03  l4-name-2       pic x(16).
     03  l4-value-2      pic z(7)9.99bbb.
     03  filler  redefines  l4-value-2.
         05  l4-d-filler pic xxx.
         05  l4-date     pic x(11).
     03  l4-name-3       pic x(18).
     03  l4-value-3      pic z(7)9.99cr.
     03  filler  redefines  l4-value-3.
         05  l4-filler   pic x(13).
*>
 01  line-5.
     03  filler          pic x(40)       value  spaces.
     03  filler          pic x           value  "<".
     03  filler          pic x(50)       value  all  "-".
     03  filler          pic x           value  ">".
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
     03  from ws-date     pic x(10)                line  1 col 71.
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
*>     03  value "Date Entered-["                    line 23 col  9.
*>     03  using enter-date-in pic x(10)                     col 23.
*>     03  value "] ["                                       col 33.
*>     03  using enter-date-op pic x                         col 36.
*>     03  value "]"                                         col 37.
*>     03  value "Enter date & operator"                     col 39.
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 init01                 section.
*>=============================
*>
     move     prog-name to l1-version.
     move     usera to l3-user.
     move     to-day to u-date.
     perform  zz070-Convert-Date.
     move     ws-date to  l3-date.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name to PSN.
*>
     perform  report-1.
*>
 menu-exit.
*>********
*>
     exit     program.
*>
*>****************************************************************
*>      p r o c e d u r e s                                      *
*>****************************************************************
*>
 report-1               section.
*>=============================
*>
     perform  report-selection.
     perform  report-heading-setup.
     perform  produce-report.
*>
 main-exit.
*>
     exit     section.
*>
 report-selection       section.
*>=============================
*>
     open     input sales-file.
     move     spaces  to  customer-in status-in credit-op
                          invoice-op average-op overdue-op.
*>
     move     zero to credit-in invoice-in average-in overdue-in.
     display  display-03.
*>
 accept-data.
*>**********
*>
     accept   display-03.
     move     function upper-case (cust-in) to cust-in.
     move     cust-in to customer-in.
     move     function upper-case (status-in) to status-in.
     if       status-in not = "L" AND not = "D" AND not = space
              go to  accept-data.
*>
     move     function upper-case (credit-op) to credit-op.
     if       credit-op not = "L" AND not = "G" and not = "E" and not = space
              go to  accept-data.
*>
     move     function upper-case (invoice-op) to invoice-op.
     if       invoice-op not = "L" AND not = "G" and not = "E" and not = space
              go to  accept-data.
*>
     move     function upper-case (average-op) to average-op.
     if       average-op not = "L" AND not = "G" and not = "E" and not = space
              go to  accept-data.
*>
     move     function upper-case (overdue-op) to overdue-op.
     if       overdue-op not = "L" AND not = "G" and not = "E" and not = space
              go to  accept-data.
*>
*> not used
*>
*>     move     function upper-case (enter-date-op) to enter-date-op.
*>     if       enter-date-op not = "L" AND not = "G" AND not = "E" and not = space
*>              go to  accept-data.
*>
 main02-end.
     exit     section.
*>
 report-heading-setup   section.
*>=============================
*>
     move     zero  to y.
     add      1     to y.
*>
     move     spaces  to  l3-report.
*>
     if       status-in = spaces  and  credit-op
                      and  invoice-op   and  average-op
                      and  overdue-op   and  customer-in
              string  "All"  delimited by size  into  l3-report  with  pointer  y
     else
              string  "Matched"  delimited by size into  l3-report  with  pointer  y.
*>
     add      1  to  y.
*>
     if       status-in = "L"
              string  "Live"  delimited by size   into  l3-report  with  pointer  y.
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
              string  overdue-heading  delimited by size  into  l3-report  with  pointer  y.
*>
     add      1  to  y.
*>
     if       customer-in not = spaces
              string  " Keys Matching - "  delimited by size  into  l3-report  with  pointer  y
              string  cust-in  delimited by size              into  l3-report  with  pointer  y.
*>
 main-exit.   exit section.
*>********
*>
 produce-report         section.
*>=============================
*>
     open     output  print-file.
     move     zero  to  a.
     move     zero  to  z.
     perform  headings-1.
     if       customer-in = spaces
              go to read-loop.
     move     cust-in to sales-key.
     read     sales-file invalid key
              move 1 to a.
     inspect  customer-in replacing all space by "Z".
*>
 read-loop.
*>********
*>
     read     sales-file  next record  at end
              go to  end-report.
*>
     if       status-in = "L"
         and  customer-dead
              go to  read-loop
     else
       if     status-in = "D"
         and  customer-live
              go to  read-loop.
*>
     if       customer-in not = spaces
         and  sales-key > customer-in
              go to end-report.
*>
     if       customer-in not = spaces
              move  1  to  truth
              perform test-array varying y from 1 by 1 until y > 6
              if    a-false
                    go to read-loop.
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
       and    sales-current  >  0.00
              move  overdue-in  to test-1
              subtract sales-last-inv from run-date giving test-2
              move  overdue-op  to test-op
              perform  test-num
              if    a-false
                    go to  read-loop.
*>
     perform  listing.
     go       to read-loop.
*>
 test-array.
*>*********
*>
     if       a-false
              next sentence
     else
      if      array-l (y) = space
              next sentence
      else
*>       if     array-l (y) not = array-k (y)
       if     array-l (y) not = Sales-Key (y:1)
              move  zero  to  truth.
*>
 test-num.
*>*******
*>
     if       test-op = " "
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
 headings-1.
*>*********
*>
     add      1  to  a.
     move     a  to  l1-page.
*>
     if       a not = 1
              write print-record from line-1 after page
              move spaces to print-record
              write print-record after 1
     else
              write print-record from line-1 before 1.
     write    print-record  from  line-3 after 2.
*>
 listing.
*>******
*>
     move     "Sales-Key"  to  l4-name-1.
     move     sales-key    to  l4-value-1.
     move     "Sales-Credit"  to  l4-name-2.
     move     sales-credit    to  l4-value-2.
     move     "Sales-Current"  to  l4-name-3.
     subtract sales-unapplied from sales-current.
     move     sales-current    to  l4-value-3.
     write    print-record  from  line-4 after 2.
*>
     move     "Sales-Name"  to  l4-name-1.
     move     sales-name    to  l4-value-1.
     move     "Sales-Discount"  to  l4-name-2.
     move     sales-discount    to  l4-value-2.
     move     "Sales-Last"  to  l4-name-3.
     move     sales-last    to  l4-value-3.
     write    print-record  from  line-4 after 1.
*>
     move     "Sales-Addr1"  to  l4-name-1.
     move     sales-addr1    to  l4-value-1.
     move     "Sales-Late-Min"  to  l4-name-2.
     move     sales-late-min    to  l4-value-2.
     move     "Turnover-Q1"  to  l4-name-3.
     move     turnover-q1    to  l4-value-3.
     write    print-record  from  line-4 after 1.
*>
     move     "Sales-Addr2"  to  l4-name-1.
     move     sales-addr2    to  l4-value-1.
     move     "Sales-Late-Max"  to  l4-name-2.
     move     sales-late-max    to  l4-value-2.
     move     "Turnover-Q2"  to  l4-name-3.
     move     turnover-q2    to  l4-value-3.
     write    print-record  from  line-4 after 1.
*>
     move     "Sales-Phone"  to  l4-name-1.
     move     sales-phone    to  l4-value-1.
     move     "Sales-Limit"  to  l4-name-2.
     move     sales-limit    to  l4-value-2.
     move     "Turnover-Q3"  to  l4-name-3.
     move     turnover-q3    to  l4-value-3.
*>
     write    print-record  from  line-4 after 1.
*>
     move     "Delivery-Tag"  to  l4-name-1.
     move     delivery-tag    to  l4-value-1.
     move     "Sales-Activety"  to  l4-name-2.
     move     sales-activety    to  l4-value-2.
     move     "Turnover-Q4"  to  l4-name-3.
     move     turnover-q4    to  l4-value-3.
     write    print-record  from  line-4 after 1.
*>
     move     "Notes Tag"    to   l4-name-1.
     move     Notes-Tag      to   l4-value-1.
     move     spaces         to   l4-d-filler
                                  l4-date
                                  l4-name-2.
     write    print-record  from  line-4 after 1.
*>
     move     "Sales-Status"  to  l4-name-1.
     if       sales-status = 1
              move  "Live"  to  l4-value-1
     else
              move  "Dead"  to  l4-value-1.
     move     "Sales-Last-Inv"  to  l4-name-2.
     move     spaces  to  l4-d-filler.
     if       sales-last-inv = zero
              move  spaces  to  l4-date
     else
              move  sales-last-inv  to  u-bin
              perform  zz060-Convert-Date
              move  ws-date  to  l4-date.
     move     spaces  to  l4-name-3
                          l4-filler.
     write    print-record  from  line-4 after 1.
*>
     move     "Sales-Late"  to  l4-name-1.
     if       sales-late = 1
              move  "Yes"  to  l4-value-1
     else
              move  "No"  to  l4-value-1.
     move     "Sales-Last-Pay"  to  l4-name-2.
     if       sales-last-pay = zero
              move  spaces  to  l4-date
     else
              move  sales-last-pay  to  u-bin
              perform  zz060-Convert-Date
              move  ws-date  to  l4-date.
     write    print-record  from  line-4 after 1.
*>
     move     "Sales-Dunning"  to  l4-name-1.
     if       sales-dunning = 1
              move  "Yes"  to  l4-value-1
     else
              move  "No"  to  l4-value-1.
     move     "Sales-Average"  to  l4-name-2.
     move     sales-average    to  l4-value-2.
     write    print-record  from  line-4 after 1.
*>
     if       sales-email not = spaces
              move   spaces to line-4
              move   1 to p
              string "Sales-Email   " delimited by size
                     sales-email    delimited by space    into line-4 with pointer p
              end-string
              if    Email-Invoicing or Email-Statementing
                 or Email-Dunning
                    string "  Used by " delimited by size into line-4 with pointer p
                    end-string
*>
                    if  Email-Invoicing
                        string "Invoicing. " delimited by size into line-4 with pointer p
                        end-string
                    end-if
*>
                    if  Email-Statementing
                        if Email-Invoicing
                           subtract 2 from p
                           string ", Statements. " delimited by size into line-4 with pointer p
                           end-string
                        else
                           string "Statements. " delimited by size into line-4 with pointer p
                           end-string
                        end-if
                    end-if
*>
                    if  Email-Dunning
                        if Email-Invoicing
                         or Email-Statementing
                           subtract 2 from p
                           string ", Dunning. " delimited by size   into line-4 with pointer p
                           end-string
                        else
                           string "Dunning. " delimited by size   into line-4 with pointer p
                           end-string
                        end-if
                    end-if
*>                    subtract 2 from p
*>                    move "." to line-4 (p:1)
              end-if
              write print-record from line-4 after 1
     end-if
     add      1  to  z
                     Rec-Cnt.
     if       z  >   3
              perform  headings-1
              move  zero to  z
     else
              write print-record from line-5 after 1.
*>
 end-report.
*>*********
*>
*> Now spool report but only if records to print exist
*>
     close    print-file sales-file.
     if       Rec-Cnt not = 0
              call     "SYSTEM" using Print-Report.
*>
 main-exit.   exit section.
*>********    ****
*>
 zz060-Convert-Date     section.
*>=============================
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
 zz070-Convert-Date     section.
*>=============================
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
 maps04                 section.
*>=============================
*>
     call     "maps04"  using  maps03-ws.
*>
 maps04-exit.
     exit     section.
*>
