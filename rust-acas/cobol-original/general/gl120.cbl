       >>source free
*>*******************************************************
*>                                                      *
*>            Profit & Loss and Balance Sheet           *
*>                                                      *
*>*******************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         gl120.
*>**
*>    Author.             V.B.Coen, FBCS,
*>                        Converted For Cis January 85,
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            P&L And Balance Sheet.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Modules Called.     maps04.
*>**
*>    Error messages used.
*>                        GL012
*>                        GL106
*>**
*>   Changes:
*> 28/01/09 vbc - Migration to Open Cobol.
*> 17/04/09 vbc - Clean up write's to printer (added after 1).
*> 14/03/10 vbc - Clean up clear screen at start of program.
*> 07/09/10 vbc - Mod lpr.
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
 copy "selprint.cob".
 copy "seledger.cob".
*>
     select  final-file      assign        file-3
                             access        dynamic
                             organization  indexed
                             status        fs-reply
                             record key    final-key.
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdprint.cob".
 copy "fdledger.cob".
*>
*> Temporary IS file
*>
 fd  final-file.
*>
 01  final-record.
     03  final-key.
         05  l-place     pic x.
         05  l-nos       pic 9(6).
         05  l-pc        pic 99.
     03  l-name          pic x(24).
     03  l-balance       pic s9(8)v99   comp-3.
     03  l-last          pic s9(8)v99   comp-3.
*>
 working-storage section.
*>----------------------
*>
 77  prog-name           pic x(15) value "gl120 (3.00.04)".
 copy "print-spool-command.cob".
 01  filler.
     03  total-this      pic s9(8)v99    value zero.
     03  total-last      pic s9(8)v99    value zero.
     03  ws-reply        pic x.
     03  date-pl         pic x(10).
     03  run-this        pic s9(8)v99    value zero.
     03  run-last        pic s9(8)v99    value zero.
     03  gp-this         pic s9(8)v99    value zero.
     03  gp-last         pic s9(8)v99    value zero.
     03  np-this         pic s9(8)v99    value zero.
     03  np-last         pic s9(8)v99    value zero.
     03  net-this        pic s9(8)v99    value zero.
     03  net-last        pic s9(8)v99    value zero.
     03  xx              pic 99          value zero.
     03  v               pic 9(5)        comp.
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
    03  GL012           pic x(24) value "GL012 Hit Return to Quit".
*> Module specific
    03  GL106           pic x(32) value "GL106 Ledger File Does Not Exist".

 copy "wsfnctn.cob".
 copy "wsmaps03.cob".
*>
 01  filler.
     03  l-dr            pic 9(8)v99     occurs  5.
     03  l-cr            pic 9(8)v99     occurs  5.
     03  store-ledger    pic 9(6)        occurs  5.
     03  read-ledger     pic x           value space.
     03  store-place     pic x.
     03  store-name      pic x(30).
     03  y               pic 99          value zero.
     03  tot-dr          pic 9(8)v99     value zero.
     03  tot-cr          pic 9(8)v99     value zero.
     03  a               pic 99.
     03  alphabat        pic x(26)       value "ABCDEFGHIJKLMNOPQRSTUVWXYZ".
     03  filler  redefines  alphabat.
         05  place-table pic x           occurs 26  indexed by j.
     03  alpha-nos       pic x(26)    value "11112222334444555666778888".
     03  filler  redefines  alpha-nos.
         05  place-number pic 9          occurs 26.
     03  alpha-names.
         05  filler        pic x(19)  value "Sales Income       ".
         05  filler        pic x(19)  value "Direct Costs       ".
         05  filler        pic x(19)  value "Sundry Income      ".
         05  filler        pic x(19)  value "Indirect Costs     ".
         05  filler        pic x(19)  value "Fixed Assets       ".
         05  filler        pic x(19)  value "Current Assets     ".
         05  filler        pic x(19)  value "Current Liabilities".
         05  filler        pic x(19)  value "Shareholders Funds ".
     03  filler  redefines  alpha-names.
         05  place-name    pic x(19)       occurs 8.
*>
 01  line-0.
     03  l0-user         pic x(32).
*>
 01  line-1.
     03  filler          pic x(32)       value spaces.
     03  filler          pic x(43)       value "Profit & Loss Account    For the period to ".
     03  l1-date         pic x(10).
*>
 01  line-2.
     03  filler          pic x(33)       value spaces.
     03  filler          pic x(52)       value all "*".
*>
 01  line-3.
     03  filler          pic x(42)       value spaces.
     03  filler          pic x(22)       value "Balance Sheet  as at  ".
     03  l3-date         pic x(10).
*>
 01  line-4.
     03  filler          pic x(44)       value spaces.
     03  filler          pic x(30)       value all "*".
*>
 01  line-5.
     03  filler          pic x(50)       value spaces.
     03  filler          pic x(40)       value "<--------This  Year-------->".
     03  filler          pic x(28)       value "<--------Last  Year-------->".
*>
 01  line-6.
     03  l6-name         pic x(24).
*>
 01  line-7.
     03  filler          pic x(20)       value spaces.
     03  l7-name         pic x(30).
     03  l7-this         pic z(7)9.99cr.
     03  filler          pic x(27)       value spaces.
     03  l7-last         pic z(7)9.99cr  blank when zero.
*>
 01  line-8.
     03  filler          pic x(50)       value spaces.
     03  filler          pic x(11)       value all "=".
     03  filler          pic x(29)       value spaces.
     03  filler          pic x(11)       value all "=".
*>
 01  line-9.
     03  filler          pic x(50)       value spaces.
     03  l9-this-total   pic z(7)9.99cr.
     03  filler          pic xxx         value spaces.
     03  l9-this-carry   pic z(7)9.99cr.
     03  filler          pic x(11)       value spaces.
     03  l9-last-total   pic z(7)9.99cr  blank when zero.
     03  filler          pic xxx         value spaces.
     03  l9-last-carry   pic z(7)9.99cr  blank when zero.
*>
 01  line-10.
     03  filler          pic x(66)       value spaces.
     03  filler          pic x(11)       value all "=".
     03  filler          pic x(29)       value spaces.
     03  filler          pic x(11)       value all "=".
*>
 01  line-11.
     03  l11-name        pic x(66).
     03  l11-this        pic z(7)9.99cr.
     03  filler          pic x(27)       value spaces.
     03  l11-last        pic z(7)9.99cr  blank when zero.
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
 77  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 gl120 section.
*>************
*>
     move     Print-Spool-Name to PSN.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "P&L and Balance Sheet" at 0131 with foreground-color 2.
     perform  zz070-convert-date.
     move     ws-date to l3-date date-pl.
     display  ws-date at 0171 with foreground-color 2.
*>
 get-date.
*>*******
*>
     display  "Enter P&L Date  (space to abort) - [" at 0521 with foreground-color 2.
     display  "]" at 0567 with foreground-color 2.
     accept   date-pl at 0557 with foreground-color 3 update.
*>
     if       date-pl = spaces
              go to  main-exit.
*>
     move     ws-date to date-pl.
     move     date-pl  to  ws-test-date.
     perform  zz050-Validate-Date.
     if       u-bin = zero
              go to  get-date.
     move     ws-test-date to l3-date date-pl.
*>
     display  "Ok to continue ? (Y/N)" at 0721 with foreground-color 2.
     display  "[Y]" at 0746 with foreground-color 2.
     move     "Y"  to  ws-reply.
     accept   ws-reply at 0747 with foreground-color 3 update.
     if       ws-reply = "N"  or  "n"
              go to  get-date.
*>
     open     input  ledger-file.
     if       fs-reply not = zero
              display space
              display GL106 at 0901 with foreground-color 4 blink
              display GL012 at 1001 with foreground-color 2
              accept ws-reply at 1026
              go to main-exit.
*>
     open     output  final-file.
*>
     move     zero  to  l-cr (1)  l-dr (1)  store-ledger (1).
     move     zero  to  l-cr (2)  l-dr (2)  store-ledger (2).
     move     zero  to  l-cr (3)  l-dr (3)  store-ledger (3).
     move     zero  to  l-cr (4)  l-dr (4)  store-ledger (4).
     move     zero  to  l-cr (5)  l-dr (5)  store-ledger (5).
*>
     move     zero  to  y  we-error  tot-dr  tot-cr.
*>
 loop.
*>***
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
              go to  loop.
*>
     if       ledger-level = 4
       and    store-ledger (4) = zero
              move  ledger-nos  to  store-ledger (4)
              go to  loop.
*>
     if       ledger-level = 4
              perform  total4-print
              move  ledger-nos  to  store-ledger (4)
              go to  loop.
*>
     if       ledger-level = 3
       and    store-ledger (3) = zero
              move  ledger-nos  to  store-ledger (3)
              go to  loop.
*>
     if       ledger-level = 3
              perform  total4-print
              perform  total3-print
              move  ledger-nos  to  store-ledger (3)
              go to  loop.
*>
     if       ledger-level = 2
       and    store-ledger (2) = zero
              move  ledger-nos  to  store-ledger (2)
              go to  loop.
*>
     if       ledger-level = 2
              perform  total4-print
              perform  total3-print
              perform  total2-print
              move  ledger-nos  to  store-ledger (2)
              go to  loop.
*>
     if       ledger-level = 1
       and    store-ledger (1) = zero
              move  ledger-nos  to  store-ledger (1)
              move  ledger-place  to  store-place
              move  ledger-name   to  store-name
              go to  loop.
*>
     if       ledger-level = 1
              perform  total4-print
              perform  total3-print
              perform  total2-print
              perform  total1-print
              move  ledger-nos  to  store-ledger (1)
              move  ledger-place  to  store-place
              move  ledger-name   to  store-name
              go to  loop.
*>
     if       ledger-nos  = store-ledger (5)
              perform  accumulate
              go to    loop.
*>
     if       ledger-balance  <  0
              move  ledger-balance  to  l-cr (5)
       else
              move  ledger-balance  to  l-dr (5).
*>
     move     ledger-nos  to  store-ledger (5).
     go       to loop.
*>
 accumulate.
*>*********
*>
     if       ledger-balance  <  0
              subtract  ledger-balance  from  l-cr (5)
     else
              add ledger-balance  to    l-dr (5).
*>
 detail-print.
*>***********
*>
     if       store-ledger (4) not = zero
              add  l-dr (5)  to  l-dr (4)
              add  l-cr (5)  to  l-cr (4)
     else
      if      store-ledger (3) not = zero
              add  l-dr (5)  to  l-dr (3)
              add  l-cr (5)  to  l-cr (3)
      else
       if     store-ledger (2) not = zero
              add  l-dr (5)  to  l-dr (2)
              add  l-cr (5)  to  l-cr (2)
       else
        if     store-ledger (1) not = zero
              add  l-dr (5)  to  l-dr (1)
              add  l-cr (5)  to  l-cr (1)
        else
         if    l-dr (5)  >  l-cr (5)
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
     if       store-ledger (3) not = zero
              add  l-dr (4)  to  l-dr (3)
              add  l-cr (4)  to  l-cr (3)
     else
      if      store-ledger (2) not = zero
              add  l-dr (4)  to  l-dr (2)
              add  l-cr (4)  to  l-cr (2)
      else
       if     store-ledger (1) not = zero
              add  l-dr (4)  to  l-dr (1)
              add  l-cr (4)  to  l-cr (1)
       else
        if    l-dr (4)  >  l-cr (4)
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
     if       store-ledger (2) not = zero
              add  l-dr (3)  to  l-dr (2)
              add  l-cr (3)  to  l-cr (2)
     else
      if      store-ledger (1) not = zero
              add  l-dr (3)  to  l-dr (1)
              add  l-cr (3)  to  l-cr (1)
      else
       if     l-dr (3)  >  l-cr (3)
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
     if       store-ledger (1) not = zero
              add  l-dr (2)  to  l-dr (1)
              add  l-cr (2)  to  l-cr (1)
     else
      if      l-dr (2)  >  l-cr (2)
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
     move     store-place  to  l-place.
     move     store-ledger (1)  to  l-nos.
     move     zero  to  l-pc.
     move     store-name  to  l-name.
     subtract l-cr (1)  from  l-dr (1)  giving  l-balance.
     move     zero  to  l-last.
*>
     write    final-record.
*>
     move     zero  to  store-ledger (1)  l-dr (1)  l-cr (1).
*>
 end-run.
*>******
*>
     close    final-file ledger-file.
     open     output  print-file.
     open     input  final-file.
*>
     move     usera  to  l0-user.
     move     date-pl  to  l1-date.
*>
     write    print-record  from  line-0 after 1.
     write    print-record  from  line-1 after 2.
     write    print-record  from  line-2 after 1.
     write    print-record  from  line-5 after 3.
*>
     move     space  to  store-place.
*>
 pl-loop.
*>******
*>
     read     final-file  next record
              at end  go to  main-end.
*>
     if       l-place not = store-place
              perform  place-change.
*>
     move     l-name  to  l7-name.
     if       a = 1  or  3  or  5
              multiply  -1  by  l-balance
              multiply  -1  by  l-last.
*>
     move     l-balance  to  l7-this.
     move     l-last     to  l7-last.
*>
     add      l-balance  to  total-this.
     add      l-last     to  total-last.
*>
     write    print-record  from  line-7 after 1.
     go       to pl-loop.
*>
 place-change.
*>***********
*>
     set      j  to  1.
     search   place-table
              when  l-place = place-table (j)
              next sentence.
*>
     move     l-place  to  store-place.
*>
     set      v  to  j.
     move     place-number (v)  to  a.
     if       a not = xx
        and   xx not = zero
              perform  number-change through number-change-end.
*>
     if       a not = xx
              move  place-name (a)  to  l6-name
              write  print-record  from  line-6 after 1
              move  a  to  xx
              move  zero  to  total-this total-last.
*>
 number-change.
*>************
*>
     move     total-this  to  l9-this-total
                              l9-this-carry.
     move     total-last  to  l9-last-total
                              l9-last-carry.
*>
     write    print-record  from  line-8 after 2.
     write    print-record  from  line-9 after 1.
     write    print-record  from  line-8 after 1.
*>
     if       xx = 1  or  3  or  5
              add  total-this  to  run-this
              add  total-last  to  run-last
     else
              subtract  total-this  from  run-this
              subtract  total-last  from  run-last.
*>
     if       a = 3
              move  "Gross Profit"  to  l11-name
              move  run-this  to  l11-this  gp-this
              move  run-last  to  l11-last  gp-last.
*>
     if       a = 5
              move  "Net Profit  "  to  l11-name
              add  run-this  gp-this  giving  np-this
              add  run-last  gp-last  giving  np-last
              move  np-this  to  l11-this
              move  np-last  to  l11-last.
*>
     if       a = 8
              move  "Net Current Value"  to  l11-name
              move  run-this  to  l11-this
              move  run-last  to  l11-last.
*>
     if       a = 3  or  5  or  8
              next sentence
     else
              go to  number-change-end.
*>
     write    print-record  from  line-10 after 2.
     write    print-record  from  line-11 after 1.
*>
     if       a = 5
              write  print-record  from  line-10 after 1
              perform  b-heading
     else
              move  spaces  to  print-record
              write  print-record after 2.
*>
     move     zero  to  run-this  run-last.
*>
 number-change-end.
*>****************
*>
 b-heading.
*>********
*>
     write    print-record  from  line-0 after 1.
     write    print-record  from  line-3 after 2.
     write    print-record  from  line-4 after 1.
     write    print-record  from  line-5 after 3.
*>
     if       a = 5
              move  run-this  to  net-this
              move  run-last  to  net-last.
*>
 main-end.
*>*******
*>
     move     "Net Profit  "  to  l7-name.
     move     np-this  to  l7-this.
     move     np-last  to  l7-last.
     write    print-record  from  line-7 after 1.
*>
     add      np-this  to  run-this.
     add      np-last  to  run-last.
     move     run-this  to  l11-this.
     move     run-last  to  l11-last.
     write    print-record  from  line-10 after 2.
*>
     write    print-record  from  line-11 after 1.
     write    print-record  from  line-10 after 1.
*>
     close    print-file final-file.
     call     "SYSTEM" using Print-Report.
*>
 main-exit.
     exit     program.
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
