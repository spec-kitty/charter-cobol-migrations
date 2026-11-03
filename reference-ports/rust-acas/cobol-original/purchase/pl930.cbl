       >>source free
*>*******************************************************
*>                                                      *
*>         Payments - Due  File  Proof - Report         *
*>                                                      *
*>*******************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl930.
*>**
*>    Author.             V B Coen FBCS, 18/04/84
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Payments Due Report.
*>**
*>    Version.            See Prog-Name In Ws.
*>
*>    Called Modules.     Maps04.
*>**
*>    Error messages used.
*>                        NONE
*>**
*>    Changes.
*> 13/11/82 Vbc - Paging On Report. Remove Page Flip At Eoj.
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00
*> 04/04/09 vbc - Printing of payment method under 'M' C=cheque, B=Bacs.
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 07/09/10 vbc - .05 Mod lgr.
*> 15/09/10 vbc - .06 global mods for print command
*> 16/12/11 vbc - .07 Error msgs to SLnnn.Support for dates other than UK
*>                    Support for path+filenames.
*>                    Updated version to 3.01.nn
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
*>**
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
 copy "selpay.cob".
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdpl.cob".
 copy "fdprint.cob".
 copy "fdpay.cob".
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "PL930 (3.01.07)".
 copy "print-spool-command.cob".
*>
 copy "wsfnctn.cob".
 copy "wsoi.cob".
*>
 01  ws-data.
     03  a               pic 99.
     03  z               pic 99.
     03  p               pic 99       value zero.
     03  line-cnt        binary-char  value zero.
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
 copy "wsmaps03.cob".
*>
*> 01  Error-Messages.
*> System Wide
*>     03  PL005          pic x(18) value "PL005 Invalid Date".
*> Module specific
*>     NONE
*>
 01  balances.
     03  bal-0           pic 9(7)v99  value zero.
     03  bal-30          pic 9(7)v99  value zero.
     03  bal-60          pic 9(7)v99  value zero.
     03  bal-90          pic 9(7)v99  value zero.
     03  bal-t           pic 9(7)v99  value zero.
     03  tot-0           pic 9(7)v99  value zero.
     03  tot-30          pic 9(7)v99  value zero.
     03  tot-60          pic 9(7)v99  value zero.
     03  tot-90          pic 9(7)v99  value zero.
     03  tot-t           pic 9(7)v99  value zero.

 01  line-1.
     03  l1-prog         pic x(53)       value spaces.
     03  filler          pic x(71)       value "Payments Due Proof Report".
     03  filler          pic x(5)        value "Page ".
     03  l3-page         pic zz9.
*>
 01  line-2.
     03  l2-user         pic x(53)       value spaces.
     03  filler          pic x(25)       value spaces.
     03  filler          pic x(44)       value spaces.
     03  l1-date         pic x(10).
*>
 01  line-4.
     03  filler          pic x(38)       value spaces.
     03  filler          pic x(94)       value
         "Folio M    Date     Invoice      Current       30 +" &
         "        60 +        90 +       Total to Pay".
*>
 01  line-5.
     03  l5-key          pic x(12).
     03  l5-supplier     pic x(23).
     03  l5-folio        pic z(7)9b.
     03  l5-method       pic xb          value space.
     03  l5-date         pic x(12).
     03  l5-invoice      pic x(11).
     03  l5-0            pic z(6)9.99cr  blank when zero.
     03  l5-30           pic z(6)9.99cr  blank when zero.
     03  l5-60           pic z(6)9.99cr  blank when zero.
     03  l5-90           pic z(6)9.99cr  blank when zero.
     03  filler          pic xxxx        value spaces.
     03  l5-pay          pic z(6)9.99    blank when zero.
*>
 01  line-6.
     03  filler          pic x(69)       value "    Total".
     03  l6-0            pic z(6)9.99cr  blank when zero.
     03  l6-30           pic z(6)9.99cr  blank when zero.
     03  l6-60           pic z(6)9.99cr  blank when zero.
     03  l6-90           pic z(6)9.99cr  blank when zero.
     03  filler          pic xxxx        value spaces.
     03  l6-pay          pic z(6)9.99    blank when zero.
*>
 01  line-7.
     03  filler          pic x(69)       value spaces.
     03  filler          pic x(12)       value "  --------  ".
     03  filler          pic x(12)       value "  --------  ".
     03  filler          pic x(12)       value "  --------  ".
     03  filler          pic x(12)       value "  --------  ".
     03  filler          pic x(4)        value spaces.
     03  filler          pic x(12)       value "  ========".
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
 procedure  division using ws-calling-data system-record to-day file-defs.
*>=======================================================================
*>
 init-process section.
*>===================
*>     display  prog-name at 0101 with foreground-color 2 erase eos.
*>     display  "Payment Due Proof Report" at 0130 with foreground-color 2.
*>     perform  zz070-Convert-Date.
*>     display  ws-date at 0171    with foreground-color 2.
*>
     move     prog-name  to  l1-prog.
     perform  zz070-Convert-Date.
     move     ws-date     to  l1-date.
     move     usera to  l2-user.
*>
     move     Print-Spool-Name to PSN.
     open     input purchase-file  pay-file.
     open     output print-file.
     perform  headings.
*>
 read-purchase.
     read     pay-file  next  record
              at end  go to  main-end.
*>
 skip-pay-read.
*>
     if       line-cnt not = 5
              move  spaces  to  print-record
              write print-record after 1.
     add      1 to line-cnt.
     move     pay-supl-key  to  purch-key.
     read     purchase-file invalid key
              move all "Z" to purch-key purch-name.
     move     purch-key  to  l5-key.
     move     purch-name to  l5-supplier.
*>
     move     spaces  to  l5-key.
     move     1  to  z.
     move     pay-nos to a.
     string   pay-supl-key delimited by size
              "/"          delimited by size
               a           delimited by size into l5-key with pointer z.
     move     1  to  z.
*>
 print-loop.
     if       pay-value (z) = zero
              go to  loop-back.
*>
     if       pay-sortcode not = zero
              move "B" to l5-method
     else
              move "C" to l5-method
     end-if
     move     pay-invoice (z) to l5-invoice.
     move     pay-folio (z)   to l5-folio.
     move     pay-date        to u-bin.
     perform  zz060-Convert-Date.
     move     ws-date  to  l5-date.
*>
     if       pay-period (z) = zero
              move  pay-value (z)  to  bal-0
     else
      if      pay-period (z) = 30
              move  pay-value (z)  to  bal-30
      else
       if     pay-period (z) = 60
              move  pay-value (z)  to  bal-60
       else
        if    pay-period (z) = 90
              move  pay-value (z)  to  bal-90.
*>
     add      pay-value (z)  to  bal-t.
*>
*> now to print. What joy!!!!!!.
*>
     move     bal-0  to  l5-0.
     move     bal-30 to  l5-30.
     move     bal-60 to  l5-60.
     move     bal-90 to  l5-90.
     move     bal-t  to  l5-pay.
*>
     add      bal-0  to  tot-0.
     add      bal-30 to  tot-30.
     add      bal-60 to  tot-60.
     add      bal-90 to  tot-90.
*>
     write    print-record  from  line-5 after 1.
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform  headings.
*>
     move     zero  to  bal-0  bal-30  bal-60  bal-90.
     move     space to  l5-key  l5-supplier.
*>
*> now loop back for next item....
*>
 loop-back.
     add      1  to  z.
     if       z  <  10
              go to  print-loop.
     if       pay-cont = "C"
              go to process-cont.
*>
     add      bal-t  to  tot-t.
     move     zero   to  bal-t.
     go       to read-purchase.
*>
 process-cont.
     read     pay-file next record at end
              add bal-t to tot-t
              go to main-end.
*>
     if       purch-key not = pay-supl-key
              go to skip-pay-read.
     move     1 to z.
     go       to print-loop.
*>
 main-end.
     move     tot-0  to  l6-0.
     move     tot-30 to  l6-30.
     move     tot-60 to  l6-60.
     move     tot-90 to  l6-90.
     move     tot-t  to  l6-pay.
*>
     write    print-record  from  line-7 after 1.
     write    print-record  from  line-6 after 1.
     close    print-file purchase-file pay-file.
     call     "SYSTEM" using Print-Report.
     exit     program.
*>
 headings     section.
*>===================
*>
     add      1  to p.
     move     p to  l3-page.
*>
     if       p not = 1
              write print-record from line-1 after page
              write print-record from line-2 after 1
              move  spaces  to  print-record
              write print-record after 1
     else
              write print-record from line-1 before 1
              write print-record from line-2 before 1
     end-if
     write    print-record  from  line-4 after 1.
     move     spaces  to  print-record.
     write    print-record  after advancing 1.
     move     5 to line-cnt.
*>
 main-exit.   exit.
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
