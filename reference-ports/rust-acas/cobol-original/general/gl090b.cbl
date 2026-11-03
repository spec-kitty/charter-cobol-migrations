       >>source free
*>**********************************************************
*>                                                         *
*>                  Detail  Trial  Balance                 *
*>                                                         *
*>**********************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         gl090b.
*>**
*>    author.             V.B.Coen, FBCS,
*>                        Converted For Cis January 85,
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Detail Trial Balance.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     None
*>**
*>    Error messages used.
*>                        GL012
*>                        GL106
*>**
*>    Changes.
*> 21/02/85 vbc - Report on all accounts.
*> 28/01/09 vbc - Migration to Open Cobol.
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 07/09/10 vbc - .03 Mod lpr.
*> 21/12/11 vbc - .04 Support for dates other than UK & clean up msgs
*>                    Error msgs to GLnnn,
*>                    Support for path+filenames.
*>**
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
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdprint.cob".
 copy "fdledger.cob".
 working-storage section.
*>----------------------
*>
 77  prog-name           pic x(16) value "gl090b (3.00.04)".
 copy "print-spool-command.cob".
 01  filler.
     03  ws-reply        pic x.
     03  y               pic 999.
     03  j               pic 9.
     03  k               pic 9.
     03  totl-dr         pic 9(8)v99     value zero.
     03  totl-cr         pic 9(8)v99     value zero.
     03  prev-dr         pic 9(8)v99     value zero.
     03  prev-cr         pic 9(8)v99     value zero.
     03  page-nos        pic 999         value zero.
     03  line-cnt        binary-char     value zero.
     03  save-n          pic 9(4)        value zero.
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
*>
 01  print-lines.
     03  line-1.
       05  l1-prog         pic x(56).
       05  filler          pic x(20)     value "Detail Trial Balance".
       05  filler          pic x(48)     value spaces.
       05  filler          pic x(5)      value "Page ".
       05  l1-page         pic zz9.
*>
     03  line-3.
       05  l3-user         pic x(32).
       05  filler          pic x(90)     value spaces.
       05  l3-date         pic x(10).
*>
     03  line-4.
       05  filler          pic x(10)     value "Account   ".
       05  l4-filler-1     pic x(10)     value spaces.
       05  filler          pic x(94)     value
  "<---------Name--------->      <---Current Balance--->    <--Last Year Balance->     <-Quarter ".
       05  l4-q1           pic 9.
       05  filler          pic x(14)     value "->  <-Quarter ".
       05  l4-q2           pic 9.
       05  filler          pic xx        value "->".
*>
     03  line-5.
       05  filler          pic x(53)     value spaces.
       05  filler          pic x(43)     value "Debit      Credit          Debit     Credit".
*>
     03  line-6.
       05  l6-account      pic 9999.99    blank when zero.
       05  filler          pic x(5)       value spaces.
       05  l6-pc           pic z9bbbbbb   blank when zero.
       05  l6-name         pic x(30).
       05  l6-c-dr         pic z(7)9.99b  blank when zero.
       05  l6-c-cr         pic z(7)9.99   blank when zero.
       05  filler          pic xxxx       value spaces.
       05  l6-p-dr         pic z(7)9.99b  blank when zero.
       05  l6-p-cr         pic z(7)9.99   blank when zero.
       05  filler          pic xxxx       value spaces.
       05  l6-q1           pic z(7)9.99cr blank when zero.
       05  filler          pic xx         value spaces.
       05  l6-q2           pic z(7)9.99cr blank when zero.
*>
     03  line-7.
       05  filler          pic x(50)      value spaces.
       05  filler          pic x(50)      value "=========== ===========    =========== ===========".
*>
 copy "wsfnctn.cob".
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
 gl090b section.
*>*************
*>
     move     Print-Spool-Name to PSN.
     open     input  ledger-file.
     if       fs-reply not = zero
              display space at 0101 with erase eos
              display GL106 at 0901 with foreground-color 4
              display GL012 at 1001 with foreground-color 2
              accept ws-reply at 1026
              go to main-exit.
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
*>
     display  "Detailed Trial Balance" at 0129 with foreground-color 2.
     display  "Working.......Please wait" at 1212 with foreground-color 2 blink.
*>
     open     output  print-file.
*>
     if       profit-centres
              move  "  P/C "  to  l4-filler-1
     else
        if    branches
              move  "Branch"  to  l4-filler-1
        else
              move  spaces    to  l4-filler-1.
*>
     move     prog-name to l1-prog.
     move     ws-date   to l3-date.
     move     zero      to page-nos.
     move     usera     to l3-user.
     perform  page-heading.
*>
 p-loop.
*>*****
*>
     read     ledger-file  next record  at end
              move  255 to we-error.
*>
     if       we-error = 255
       or     ledger-n = 9999
              go to  end-report.
*>
*>    if       ledger-level  not numeric
*>             go to  p-loop.
*>
*>    if       ledger-level not = zero
*>             go to  p-loop.
*>
     if       ledger-n not = save-n
              move  ledger-n  to  save-n
              move  spaces  to  print-record
              write print-record after 1
              add 1 to line-cnt.
*>
     divide   ledger-nos   by  100  giving  l6-account.
     move     ledger-pc    to  l6-pc.
     move     ledger-name  to  l6-name.
*>
     if       ledger-balance  <  0
              move      ledger-balance  to    l6-c-cr
              subtract  ledger-balance  from  totl-cr
              move      zero            to    l6-c-dr
     else
              move  ledger-balance  to  l6-c-dr
              add   ledger-balance  to  totl-dr
              move  zero            to  l6-c-cr.
*>
     if       ledger-last  <  0
              move       ledger-last  to    l6-p-cr
              subtract   ledger-last  from  prev-cr
              move       zero         to    l6-p-dr
     else
              move  ledger-last  to  l6-p-dr
              add   ledger-last  to  prev-dr
              move  zero         to  l6-p-cr.
*>
     move     ledger-q (j)       to  l6-q1.
     move     ledger-q (k)       to  l6-q2.
*>
     write    print-record  from  line-6 after 1.
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform  page-heading.
*>
     go       to p-loop.
*>
 page-heading.
*>***********
*>
     add      1  to  page-nos.
     move     page-nos  to  l1-page.
*>
     if       current-quarter = 1
              move  4  to  j
              move  3  to  k
     else
      if      current-quarter = 2
              move  1  to  j
              move  4  to  k
      else
       if     current-quarter = 3
              move  2  to  j
              move  1  to  k
       else
        if    current-quarter = 4
              move  3  to  j
              move  2  to  k.
*>
     move     j  to  l4-q1.
     move     k  to  l4-q2.
*>
     if       page-nos not = 1
              write print-record from line-1 after page
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
 end-report.
*>*********
*>
     move     zero  to  l6-account l6-pc.
     move     "T o t a l"  to  l6-name.
     move     totl-dr  to  l6-c-dr.
     move     totl-cr  to  l6-c-cr.
     move     prev-dr  to  l6-p-dr.
     move     prev-cr  to  l6-p-cr.
     move     zero     to  l6-q1 l6-q2.
*>
     write    print-record  from  line-7 after 3.
     write    print-record  from  line-6 after 1.
     write    print-record  from  line-7 after 1.
*>
     close    print-file.
     call     "SYSTEM" using Print-Report.
*>
 main-end.
*>*******
*>
     close    ledger-file.
*>
 main-exit.   exit program.
*>********    ************
*>
 zz070-Convert-Date     section.
*>*****************************
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
