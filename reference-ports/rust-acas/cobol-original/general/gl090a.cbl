       >>source free
*>*****************************************************
*>                                                    *
*>            Structured  Trial  Balance              *
*>                                                    *
*>*****************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         gl090a.
*>**
*>    author.             V.B.Coen, FBCS,
*>                        Converted For Cis January 85,
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Structured Trial Balance.
*>                        This code is slightly different from the
*>                        listings in that a specific ledger-pc is
*>                        reported on. This version does them all.
*>                        (See gl090b.cbl)
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     None
*>**
*>    Error messages used.
*>                        None
*>****
*>  Changes:
*> 28/01/09 vbc - Migration to Open Cobol.
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 07/09/10 vbc - .03 mod lpr.
*> 21/12/11 vbc - .04 Support for dates other than UK & clean up msgs
*>                    Error msgs to GLnnn,
*>                    Support for path+filenames.
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
 copy "seledger.cob".
 copy "selprint.cob".
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdledger.cob".
 copy "fdprint.cob".
 working-storage section.
*>----------------------
*>
 77  prog-name           pic x(16)    value "gl090a (3.00.04)".
 copy "print-spool-command.cob".
*>
 copy "wsfnctn.cob".
*>
 01  filler.
     03  l-dr            pic 9(8)v99  comp   occurs  5.
     03  l-cr            pic 9(8)v99  comp   occurs  5.
     03  store-ledger    pic 9(6)     comp   occurs  5.
     03  page-cnt        binary-char        value zero.
     03  line-cnt        binary-char        value zero.
     03  y               pic 99             value zero.
     03  z               pic 99             value zero.
     03  tot-dr          pic 9(8)v99  comp  value zero.
     03  tot-cr          pic 9(8)v99  comp  value zero.
     03  redef-ac.
         05  pr-ac       pic 9999.99.
     03  xx              pic 9.
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
 01  line-1.
     03  l1-prog             pic x(50).
     03  filler              pic x(27)   value "Profit Centre Trial Balance".
     03  filler              pic x(47)   value spaces.
     03  filler              pic x(5)    value "Page ".
     03  l1-page             pic zz9.
*>
 01  line-3.
     03  l3-user             pic x(32).
     03  filler              pic x(25)   value spaces.
     03  l3-report           pic x(16).
     03  filler              pic x(49)   value spaces.
     03  l3-date             pic x(10).
*>
 01  line-4.
     03  filler              pic x(50)   value "Account      <----Detail   Level----><-------Level".
     03  filler              pic x(54)   value "  4-------><-------Level  3-------><-------Level  2---".
     03  filler              pic x(28)   value "----><-------Level  1------>".
*>
 01  line-5.
     03  filler              pic x(53)   value "               Debit        Credit      Debit       C".
     03  filler              pic x(56)   value "Redit      Debit       Credit      Debit       Credit   ".
     03  filler              pic x(23)   value "   Debit       Credit  ".
*>
 01  line-6.
     03  l6-account          pic x(12).
     03  l6-amount           pic z(7)9.99b  blank when zero occurs  10.
 01  line-7.
     03  filler              pic x(108)   value spaces.
     03  filler              pic x(23)    value " ==========  ==========".
*>
 01  line-8.
     03  filler              pic x(20)    value spaces.
     03  filler              pic x(88)    value "t o t a l".
     03  l8-dr               pic z(7)9.99b.
     03  l8-cr               pic z(7)9.99.
*>
 linkage section.
*>--------------
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
 gl090a section.
*>*************
*>
     move     Print-Spool-Name to PSN.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Structured Trial Balance" at 0129 with foreground-color 2.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
*>
     open     output print-file.
     move     ws-date to l3-date.
     move     usera   to l3-user.
     move     "Condensed Report"  to  l3-report.
     move     prog-name to l1-prog.
     open     input  ledger-file.
*>
     move     zero  to  l-cr (1)  l-dr (1)  store-ledger (1).
     move     zero  to  l-cr (2)  l-dr (2)  store-ledger (2).
     move     zero  to  l-cr (3)  l-dr (3)  store-ledger (3).
     move     zero  to  l-cr (4)  l-dr (4)  store-ledger (4).
     move     zero  to  l-cr (5)  l-dr (5)  store-ledger (5).
     move     zero  to  y  we-error  tot-dr  tot-cr.
     perform  headings.
*>
 Read-Ledger.
*>**********
*>
     read     ledger-file  next
              at end  move  255  to  we-error.
*>
     if       we-error = 255
       or     ledger-n = 9999
              perform  detail-print
              perform  total4-print
              perform  total3-print
              perform  total2-print
              perform  total1-print
              go to    end-run.
*>
     if       ledger-nos not = store-ledger (5)
       and    store-ledger (5) not = zero
              perform  detail-print
              move  zero  to  l-cr (5)
                              l-dr (5)
              if ledger-level = zero
                 move  ledger-nos  to  store-ledger (5).

*>
     if       ledger-nos = store-ledger (4)
       or                  store-ledger (3)
       or                  store-ledger (2)
       or                  store-ledger (1)
              go to  Read-Ledger.
*>
     if       ledger-level = 4
       and    store-ledger (4) = zero
              move  ledger-nos  to  store-ledger (4)
              go to  Read-Ledger.
*>
     if       ledger-level = 4
              perform  total4-print
              move  ledger-nos  to  store-ledger (4)
              go to  Read-Ledger.
*>
     if       ledger-level = 3
       and    store-ledger (3) = zero
              move  ledger-nos  to  store-ledger (3)
              go to  Read-Ledger.
*>
     if       ledger-level = 3
              perform  total4-print
              perform  total3-print
              move  ledger-nos  to  store-ledger (3)
              go to  Read-Ledger.
*>
     if       ledger-level = 2
       and    store-ledger (2) = zero
              move  ledger-nos  to  store-ledger (2)
              go to  Read-Ledger.
*>
     if       ledger-level = 2
              perform  total4-print
              perform  total3-print
              perform  total2-print
              move  ledger-nos  to  store-ledger (2)
              go to  Read-Ledger.
*>
     if       ledger-level = 1
       and    store-ledger (1) = zero
              move  ledger-nos  to  store-ledger (1)
              go to  Read-Ledger.
*>
     if       ledger-level = 1
              perform  total4-print
              perform  total3-print
              perform  total2-print
              perform  total1-print
              move  ledger-nos  to  store-ledger (1)
              go to  Read-Ledger.
*>
     if       ledger-nos  = store-ledger (5)
              perform  accumulate
              go to  Read-Ledger.
*>
     if       ledger-balance  <  0
              move  ledger-balance  to  l-cr (5)
     else
              move  ledger-balance  to  l-dr (5).
*>
     move     ledger-nos  to  store-ledger (5).
     go       to Read-Ledger.
*>
 end-run.
*>******
*>
     write    print-record  from  line-7 after 3.
     move     tot-dr  to  l8-dr.
     move     tot-cr  to  l8-cr.
*>
     write    print-record  from  line-8 after 1.
     write    print-record  from  line-7 after 1.
*>
     close    print-file ledger-file.
     call     "SYSTEM" using Print-Report.
*>
 main-exit.   exit program.
*>********    ************
*>
 headings.
*>*******
*>
     add      1  to  page-cnt.
     move     page-cnt  to  l1-page.
*>
     if       page-cnt not = 1
              write print-record  from  line-1 after page
              write print-record  from  line-3 after 1
              move spaces to print-record
              write print-record after 1
     else
              write print-record  from  line-1 before 1
              write print-record  from  line-3 before 1.
     write    print-record  from  line-4 after 1.
     write    print-record  from  line-5 after 1.
     move     spaces  to  print-record.
     write    print-record after 1.
     move     6 to line-cnt.
*>
 accumulate.
*>*********
*>
     if       ledger-balance  <  0
              subtract  ledger-balance  from  l-cr (5)
     else
              add       ledger-balance  to    l-dr (5).
*>
 detail-print.
*>***********
*>
     divide   store-ledger (5)  by  100  giving  pr-ac.
*>
     move     spaces  to  l6-account.
     move     5  to  xx.
     string   redef-ac delimited by size into l6-account with pointer xx.
*>
     move     l-dr (5)  to  l6-amount (1).
     move     l-cr (5)  to  l6-amount (2).
*>
     move     zero      to  l6-amount (3)  l6-amount (4)
                            l6-amount (5)  l6-amount (6)
                            l6-amount (7)  l6-amount (8)
                            l6-amount (9)  l6-amount (10).
*>
     write    print-record  from  line-6 after 1.
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform  headings.
*>
     if       store-ledger (4) not = zero
              add  l-dr (5)  to  l-dr (4)
              add  l-cr (5)  to  l-cr (4)
     else
      if store-ledger (3) not = zero
              add  l-dr (5)  to  l-dr (3)
              add  l-cr (5)  to  l-cr (3)
      else
       if store-ledger (2) not = zero
              add  l-dr (5)  to  l-dr (2)
              add  l-cr (5)  to  l-cr (2)
       else
        if store-ledger (1) not = zero
              add  l-dr (5)  to  l-dr (1)
              add  l-cr (5)  to  l-cr (1)
        else
         if l-dr (5)  >  l-cr (5)
              add  l-dr (5)  to  tot-dr
              subtract l-cr (5) from tot-dr
         else
              add  l-cr (5)  to  tot-cr
              subtract l-dr (5) from tot-cr.

*>
     move     zero  to  l-dr (5)  l-cr (5).
*>
 total4-print.
*>***********
*>
     divide   store-ledger (4)  by  100  giving  pr-ac.
*>
     move     spaces  to  l6-account.
     move     4  to  xx.
     string   redef-ac delimited by size into l6-account with pointer xx.
*>
     if       l-dr (4)  >  l-cr (4)
              subtract  l-cr (4)  from  l-dr (4) giving  l6-amount (3)
              move  zero  to  l6-amount (4)
     else
              subtract l-dr (4)  from  l-cr (4) giving  l6-amount (4)
              move  zero  to  l6-amount (3).
*>
     move     zero to  l6-amount (1)  l6-amount (2)
                       l6-amount (5)  l6-amount (6)
                       l6-amount (7)  l6-amount (8)
                       l6-amount (9)  l6-amount (10).
*>
     if       store-ledger (4) not = zero
              write  print-record  from  line-6 after 1
              add 1 to line-cnt
              if  line-cnt > Page-Lines
                  perform  headings.
*>
     if       store-ledger (3) not = zero
              add  l-dr (4)  to  l-dr (3)
              add  l-cr (4)  to  l-cr (3)
     else
      if store-ledger (2) not = zero
              add  l-dr (4)  to  l-dr (2)
              add  l-cr (4)  to  l-cr (2)
      else
       if store-ledger (1) not = zero
              add  l-dr (4)  to  l-dr (1)
              add  l-cr (4)  to  l-cr (1)
       else
        if l-dr (4)  >  l-cr (4)
              add  l-dr (4)  to  tot-dr
              subtract l-cr (4) from tot-dr
        else
              add  l-cr (4)  to  tot-cr
              subtract l-dr (4) from tot-cr.
*>
     move     zero  to  store-ledger (4)  l-dr (4)  l-cr (4).
*>
 total3-print.
*>***********
*>
     divide   store-ledger (3)  by  100  giving  pr-ac.
*>
     move     spaces  to  l6-account.
     move     3  to  xx.
     string   redef-ac delimited by size into l6-account with pointer xx.
*>
     if       l-dr (3)  >  l-cr (3)
              subtract  l-cr (3)  from  l-dr (3) giving  l6-amount (5)
              move  zero  to  l6-amount (6)
     else
              subtract l-dr (3)  from  l-cr (3) giving  l6-amount (6)
              move  zero  to  l6-amount (5).
*>
     move     zero to  l6-amount (1)  l6-amount (2)
                       l6-amount (3)  l6-amount (4)
                       l6-amount (7)  l6-amount (8)
                       l6-amount (9)  l6-amount (10).
*>
     if       store-ledger (3) not = zero
              write  print-record  from  line-6 after 1
              add 1 to line-cnt
              if  line-cnt > Page-Lines
                  perform  headings.
*>
     if       store-ledger (2) not = zero
              add  l-dr (3)  to  l-dr (2)
              add  l-cr (3)  to  l-cr (2)
     else
              if store-ledger (1) not = zero
                 add  l-dr (3)  to  l-dr (1)
                 add  l-cr (3)  to  l-cr (1)
              else
               if  l-dr (3)  >  l-cr (3)
                   add  l-dr (3)  to  tot-dr
                   subtract l-cr (3) from tot-dr
               else
                   add  l-cr (3)  to  tot-cr
                   subtract l-dr (3) from tot-cr.
*>
     move     zero  to  store-ledger (3)  l-dr (3)  l-cr (3).
*>
 total2-print.
*>***********
*>
     divide   store-ledger (2)  by  100  giving  pr-ac.
*>
     move     spaces  to  l6-account.
     move     2  to  xx.
     string   redef-ac delimited by size into l6-account with pointer xx.
*>
     if       l-dr (2)  >  l-cr (2)
              subtract  l-cr (2)  from  l-dr (2) giving  l6-amount (7)
              move  zero  to  l6-amount (8)
     else
              subtract l-dr (2)  from  l-cr (2) giving  l6-amount (8)
              move  zero  to  l6-amount (7).
*>
     move     zero to  l6-amount (1)  l6-amount (2)
                       l6-amount (3)  l6-amount (4)
                       l6-amount (5)  l6-amount (6)
                       l6-amount (9)  l6-amount (10).
*>
     if       store-ledger (2) not = zero
              write  print-record  from  line-6 after 1
              add 1 to line-cnt
              if  line-cnt > Page-Lines
                  perform  headings.
*>
     if       store-ledger (1) not = zero
              add  l-dr (2)  to  l-dr (1)
              add  l-cr (2)  to  l-cr (1)
     else
              if l-dr (2)  >  l-cr (2)
                 add  l-dr (2)  to  tot-dr
                 subtract l-cr (2) from tot-dr
              else
                 add  l-cr (2)  to  tot-cr
                 subtract l-dr (2) from tot-cr.
*>
     move     zero  to  store-ledger (2)  l-dr (2)  l-cr (2).
*>
 total1-print.
*>***********
*>
     divide   store-ledger (1)  by  100  giving  pr-ac.
*>
     move     redef-ac  to  l6-account.
*>
     if       l-dr (1)  >  l-cr (1)
              subtract l-cr (1) from l-dr (1) giving l6-amount (9)
              move  zero  to  l6-amount (10)
     else
              subtract l-dr (1) from l-cr (1) giving l6-amount (10)
              move  zero  to  l6-amount (9).
*>
     move     zero to  l6-amount (1)  l6-amount (2)
                       l6-amount (3)  l6-amount (4)
                       l6-amount (5)  l6-amount (6)
                       l6-amount (7)  l6-amount (8).
*>
     write    print-record  from  line-6 after 1.
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform  headings.
*>
     move     spaces  to  print-record.
     write    print-record after 1.
     if       l-dr (1)  >  l-cr (1)
              add  l-dr (1)  to  tot-dr
              subtract l-cr (1) from tot-dr
     else
              add  l-cr (1)  to  tot-cr
              subtract l-dr (1) from tot-cr.
*>
     move     zero  to  store-ledger (1)  l-dr (1)  l-cr (1).
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
