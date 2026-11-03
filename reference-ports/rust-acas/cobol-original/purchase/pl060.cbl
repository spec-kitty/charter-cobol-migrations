       >>source free
*>************************************************
*>                                               *
*>             Invoice  Posting                  *
*>                                               *
*>************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl060.
*>**
*>    Author.             V B Coen FBCS, Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Invoice Posting.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps04.
*>**
*>    Error messages used.  Note that these msgs are also same in sl100
*>                        PL002
*>                        PL003
*>                        PL130
*>                        PL131
*>                        PL132
*>                        PL133
*>                        PL134
*>**
*>    Changes.
*> 21/05/84 Vbc - Support For Indexed Open Item Files.
*> 14/07/84 Vbc - Fix Bug In Cr-Notes On Invalid Key On Starts.
*> 19/09/84 Vbc - Fix Bug In Cr-Notes Supply Oi-Customer To Key.
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 28/03/09 vbc - Added support for IRS instead of GL for new post file.
*> 09/04/09 vbc - New feature Env variable ACAS_IRS.
*> 13/04/09 vbc - move p-creditors to post-cr instead of post-dr.
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 07/09/10 vbc - .06 Mod lpr.
*> 13/12/11 vbc - .07 Error msgs to SLnnn.Support for dates other than UK (Neither used here)
*>                    Support for path+filenames. increased size of ACAS_IRS to 500 bytes
*>                    Updated version to 3.01.nn
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
 copy "seloi4.cob".
 copy "seloi5.cob".
 copy "selprint.cob".
 copy "selbatch.cob".
 copy "selpost.cob".
 copy "selpost-irs.cob".
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdpl.cob".
 copy "fdoi4.cob".
 copy "fdoi5.cob".
 copy "fdprint.cob".
 copy "fdbatch.cob".
 copy "fdpost.cob".
 copy "fdpost-irs.cob".
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15)    value "PL060 (3.01.07)".
 copy "print-spool-command.cob".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
*>
 01  ws-data.
     03  save-level-1    pic 9                  value zero.
     03  ws-reply        pic x.
     03  ws-error        pic 9                  value zero.
         88  purchase-missing                   value 1.
     03  wx-reply        pic xxx.
     03  xx              pic 99.
     03  c-check         pic 9.
         88  c-exists                           value 1.
     03  ws-eval-msg     pic x(25)       value spaces.
     03  work-1          pic s9(7)v99  comp-3   value zero.
     03  work-2          pic s9(14)    comp-3.
     03  work-a          pic s9(7)v99  comp-3   value zero.
     03  work-b          pic s9(7)v99  comp-3   value zero.
     03  first-pass      pic x.
     03  i               pic 999.
     03  j               pic 999.
     03  k               pic 9(5).
     03  m               pic z(7)9.
     03  a               pic 9                 value zero.
     03  b               binary-char           value zero.
     03  c               binary-char           value zero.
     03  work-net        pic s9(7)v99   comp-3.
     03  work-vat        pic s9(7)v99   comp-3.
     03  work-goods      pic s9(7)v99   comp-3.
     03  total-group    occurs 3        comp-3.
         05 total-net    pic s9(7)v99.
         05 total-vat    pic s9(7)v99.
     03  line-cnt        binary-char           value zero.
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
     03  PL002          pic x(31) value "PL002 Note error and hit return".
     03  PL003          pic x(28) value "PL003 Hit Return To Continue".
*> Module specific
     03  PL130          pic x(17) value "PL130 Open-IT5 = ".
     03  PL131          pic x(38) value "PL131 PE - CR SWOP: Return to continue".
     03  PL132          pic x(32) value "PL132 Err on Batch file write : ".
     03  PL133          pic x(15) value "PL133 PE 060-01".
     03  PL134          pic x(47) value "PL134 Warning Record/s missing in Purchase File".
*>
 01  error-code          pic 999.
*>
 copy "wsoi.cob".
 copy "wssoi.cob".
*>
 01  total-lits.
     03  filler          pic x(17)      value "Receipts".
     03  filler          pic x(17)      value "Invoices".
     03  filler          pic x(17)      value "Credit Notes".
 01  filler  redefines total-lits.
     03  ws-lits         pic x(17)   occurs 3.
*>
 01  line-1.
     03  l1-name         pic x(54).
     03  filler          pic x(70)       value "Invoice Posting Report".
     03  filler          pic x(5)        value "Page ".
     03  l3-page         pic zz9.
*>
 01  line-1a.
     03  filler          pic x(56)       value spaces.
     03  filler          pic x(18)       value "Un-Applied Credits".
*>
 01  line-2.
     03  l3-user         pic x(54)       value spaces.
     03  filler          pic x(22)       value spaces.
     03  filler          pic x(46)       value spaces.
     03  l1-date         pic x(10).
*>
 01  line-4.
     03  filler          pic x(64)       value " Number     Date    <------------Supplier------------>    Type  ".
     03  filler          pic x(68)       value " Old Balance  New Balance            Net         Vat       Gross".
*>
 01  line-4a.
     03  filler          pic x(82)       value "--Supplier--   Invoice      Bal C/F        Applied      Cr. Note          Type    ".
*>
 01  line-5.
     03  l5-nos          pic z(7)9b.
     03  l5-date         pic x(11).
     03  l5-cust         pic x(9).
     03  l5-name         pic x(25).
     03  filler          pic x(2)        value spaces.
     03  l5-type         pic x(9).
     03  l5-old-bal      pic z(6)9.99cr.
     03  l5-new-bal      pic z(6)9.99cr.
     03  filler          pic x(7).
     03  l5-net          pic z(6)9.99cr.
     03  l5-vat          pic z(6)9.99cr.
     03  l5-gross        pic z(6)9.99cr.
*>
 01  line-6.
     03  filler          pic x(11)       value spaces.
     03  filler          pic x(14)       value "Total  Posted".
     03  l6-lit          pic x(18)       value spaces.
     03  l6-net          pic z(7)9.99cr.
     03  l6-vat          pic z(7)9.99cr.
     03  l6-gross        pic z(7)9.99cr.
*>
 01  line-7.
     03  l7-cust         pic x(12).
     03  l7-trans        pic z(7)9bb     blank when zero.
     03  filler          pic x(4)        value spaces.
     03  l7-bal          pic z(7)9.99    blank when zero.
     03  filler          pic x(4)        value spaces.
     03  l7-appl         pic z(7)9.99    blank when zero.
     03  filler          pic x(4)        value spaces.
     03  l7-cr-note      pic z(7)9bb     blank when zero.
     03  filler          pic x(4)        value spaces.
     03  l7-type         pic x(12).
*>
 01  line-8.
     03  filler          pic x(24)       value spaces.
     03  l8-desc         pic x(32).
     03  l8-tot          pic z(7)9.99    blank when zero.
*>
 linkage section.
*>***************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wssys4.cob".
 copy "wsnames.cob".
*>
 01  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record system-record-4 to-day file-defs.
*>======================================================================================
*>
 init01  section.
     move     prog-name to l1-name.
     move     to-day to l1-date.
     move     Print-Spool-Name to PSN.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
*>
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "Invoice Posting Report" at 0131  with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
 acpt-xrply.
     display  "OK to post Purchase Transactions (YES/NO) ?  [   ]" at 0812 with foreground-color 2.
     move     spaces to  wx-reply.
     accept   wx-reply at 0858 with foreground-color 6 update.
     move     function upper-case (wx-reply) to wx-reply.
     if       wx-reply = "NO"
              go to exit-prog.
     if       wx-reply not = "YES"
              go to acpt-xrply.
*>
     display  " " at 0801 with erase eol.
     move     2  to  P-Flag-I.
     move     1  to  P-Flag-A.
     move     zero to File-Status (28).
     move     "Y" to Oi-5-Flag.
     if       File-Status (29) = zero
              open  output  Open-Item-File-5
              close  Open-Item-File-5
              move 1 to File-Status (29).
*>
*>*****************************************************
*>* >>>>> BYPASS CODE TO SEND TOTALS TO GL <<<<<<     *
*>*                                                   *
*>     move     level-1 to save-level-1.
*>     move     0 to level-1.
*>*                                                   *
*>*****************************************************
*>
     if       g-l
              perform  bl-open.
*>
     open     i-o purchase-file.
*>
     open     output print-file.
     display  " " at 1201 with erase eos.
     display  "Posting......Please Wait" at 1201  with foreground-color 2.
     display  "Phase 1" at 1401        with foreground-color 2.
*>
     move     zero  to  j.
     perform  headings.
*>
     move     zeros to total-net (1) total-net (2) total-net (3).
     move     zeros to total-vat (1) total-vat (2) total-vat (3).
*>
     open     input  open-item-file-4.
     open     i-o    open-item-file-5.
*>
 loop.
     read     open-item-file-4 at end
              go to  main-end.
*>
     move     open-item-record-4  to  oi-header.
*>
     move     oi-supplier  to  purch-key  l5-cust.
     move     space to ws-reply.
     read     purchase-file  record invalid key
              move "X" to ws-reply.
*>
     if       ws-reply = "X"
              move 1 to ws-error
              initialize purch-record
              move "Supplier Unknown" to l5-name purch-name
              move oi-supplier to purch-key
     else
              move purch-name  to  l5-name.
*>
     move     oi-invoice  to  l5-nos.
*>
     move     oi-date  to  u-bin.
     perform  zz060-Convert-Date.
     move     ws-date  to  l5-date.
*>
     move     oi-type to a.
*>
     if       oi-type = 2
              move "Invoice"  to  l5-type
     else
      if      oi-type = 3
              move "Cr. Note" to  l5-type
      else
       if     oi-type = 1
              move  "Receipt" to  l5-type.
*>
     add      oi-vat oi-c-vat giving work-vat.
     move     oi-net to work-goods.
     move     work-vat to l5-vat.
     add      oi-net oi-carriage giving work-net.
     move     work-net to l5-net.
*>
     add      work-vat to total-vat (a).
     add      work-net to total-net (a).
*>
     move     work-net to work-1.
     add      work-vat to work-1.
     move     work-1 to l5-gross.
*>
     if       G-L
              perform  BL-Write.
*>
     subtract purch-unapplied from purch-current giving l5-old-bal.
     if       oi-type = 1 or 2
              perform purch-comp.
*>
*> Receipts
*>
     if       oi-type = 1
              add  work-goods to  pturnover-q (current-quarter)
              move  oi-date  to  purch-last-inv purch-last-pay.
*>
*> Accounts
*>
     if       oi-type = 2
              add work-goods to  pturnover-q (current-quarter)
              add work-vat work-net to  purch-current
              move  oi-date  to  purch-last-inv.
*>
*> CR. Notes
*>
     if       oi-type = 3
              add work-goods to pturnover-q (current-quarter)
              add work-vat work-net to  purch-current
              move oi-date to purch-last-pay
              perform  cr-notes
              perform credit-comp.
*>
     if       supplier-dead
              move  1  to  purch-status.
*>
     if       purch-current is negative
              multiply -1 by purch-current
              add purch-current to purch-unapplied
              move zero to purch-current.
*>
*>    At this point only current OR unapplied can be non zero
*>    and current will be = or > zero
*>
     subtract purch-unapplied from purch-current  giving l5-new-bal.
     if       ws-reply = "X"
              move 1 to purch-status
              write purch-record
     else
              rewrite purch-record.
*>
     write    open-item-record-5 from oi-header invalid key
              display PL130        at 1601
              display oi5-supplier at 1701
              move oi5-invoice to l5-nos
              display l5-nos at 1801
              display "fs-reply = " at 1901
              display fs-reply at 1912
              perform evaluate-message
              display ws-Eval-Msg at 1915
              display PL133       at 2401 with foreground-color 4
              display PL002       at 2412
              accept ws-reply at 2450.
*>
     write    print-record from line-5 after 1.
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform  headings.
     go       to loop.
*>
 main-end.
*>*******
*>
     close    purchase-file open-item-file-4 open-item-file-5.
     move     total-net (1) to  l6-net.
     move     total-vat (1) to  l6-vat.
     add      total-net (1) total-vat (1) giving  l6-gross.
     move     ws-lits (1) to l6-lit.
*>
     if       line-cnt > Page-Lines - 7
              perform headings.
*>
     write    print-record  from  line-6 after 3.
*>
     move     total-net (2) to  l6-net.
     move     total-vat (2) to  l6-vat.
     add      total-net (2) total-vat (2) giving  l6-gross.
     move     ws-lits (2) to l6-lit.
     write    print-record  from  line-6 after 2.
*>
     move     total-net (3) to  l6-net.
     move     total-vat (3) to  l6-vat.
     add      total-net (3) total-vat (3) giving  l6-gross.
     move     ws-lits (3) to l6-lit.
     write    print-record  from  line-6 after 2.
*>
     if       G-L
              perform  BL-Close.
*>
*>************************************************************
*>    Routine To Close Un-Applied CR. Notes                  *
*>************************************************************
*>
     open     i-o     open-item-file-5.
*>
     move     zero  to  work-b.
     display  "2" at 1407 with foreground-color 2.
*>
 end-loop.
*>*******
*>
     read     open-item-file-5 next record at end
              go to  end-loop-end.
*>
     move     open-item-record-5  to  oi-header.
*>
     if       s-closed
              go to  end-loop.
*>
     if       oi-type = 3
              perform  cr-swop.
*>
     go       to end-loop.
*>
 end-loop-end.
*>***********
*>
     open     output  open-item-file-4.
     close    open-item-file-4 open-item-file-5.
*>
     if       line-cnt > Page-Lines - 6 and
              file-status (28) = 1
              perform new-heading.
*>
     if       file-status (28) = 1
              move  "Un-Applied Credits C/F " to  l8-desc
              move  work-b  to  l8-tot
              write  print-record  from  line-8 after 3.
*>
     add      work-b to pl-cn-unappl-this-month.
*>
     if       purchase-missing
              move PL134 to print-record
              write print-record after 3.
*>
     close    print-file.
     call     "SYSTEM" using Print-Report.
     move     zero to file-status (28).
*>
*>*******************************************
*>*  >>> BYPASS CODE FOR G-L
*>*
*>     move     save-level-1 to level-1.
*>*
*>*******************************************
*>
 exit-prog.
     exit     program.
*>
 cr-swop      section.
*>===================
*>
     add      oi-net oi-carriage oi-vat oi-c-vat giving  work-1.
     add      oi-paid   to   work-1.
     if       work-1 = zero
              display PL131 at 2401 with foreground-color 4
              accept ws-reply at 2434.
*>
*> Above should NOT happen
*>
     if       file-status (28) = zero
              perform  new-heading.
*>
     move     1  to  oi-status.
*>
     move     oi-supplier  to  l7-cust.
     move     oi-invoice   to  l7-trans.
     move     oi-cr        to  l7-cr-note.
     move     "Cr. Note"   to  l7-type.
     move     work-1       to  l7-bal.
     move     oi-paid      to  l7-appl.
     write    print-record  from  line-7 after 1.
*>
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform  new-heading.
*>
     add      work-1   to  work-b.
     multiply -1 by work-1.
     add      work-1 to oi-paid.
     rewrite  open-item-record-5  from  oi-header.
*>
 main-exit.   exit section.
*>********    ****
*>
 new-heading  section.
*>===================
*>
     if       file-status (28) = zero
              move  1  to  file-status (28).
*>
     add      1  to  j.
     move     j  to  l3-page.
     move     usera  to  l3-user.
*>
     if       j not = 1
              write print-record from line-1 after page
              write print-record from line-2 after 1
              write print-record from line-1a after 1
              move  spaces to print-record
              write print-record after 1
     else
              write print-record from line-1 before 1
              write print-record from line-2 before 1
              write print-record from line-1a before 1
     end-if
     write    print-record from line-4a after 1.
     move     spaces  to  print-record.
     write    print-record after 1.
     move     6 to line-cnt.
*>
 main-exit.   exit section.
*>********    ****
*>
 headings     section.
*>===================
*>
     add      1  to  j.
     move     j  to  l3-page.
     move     usera  to  l3-user.
*>
     if       j not = 1
              write print-record from line-1 after page
              write print-record from line-2 after 1
              move  spaces to print-record
              write print-record after 1
     else
              write print-record from line-1 before 1
              write print-record from line-2 before 1
     end-if
     write    print-record  from  line-4 after 1.
     move     spaces  to  print-record.
     write    print-record  after  1.
     move     5 to line-cnt.
*>
 main-exit.   exit section.
*>
 purch-comp   section.
*>===================
*>
     if       purch-activety not = zero
        and   purch-average not = zero
              multiply purch-activety by purch-average giving work-2
     else
              move zero to work-2
     end-if
     add      1 to purch-activety.
     add      work-goods to work-2.
     divide   purch-activety into work-2 giving purch-average.
*>
 main-exit.   exit section.
*>
 credit-comp  section.
*>===================
*>
     if       purch-activety not = zero
       and    purch-average not = zero
              multiply purch-activety by purch-average giving work-2
     else
              move zero to work-2
     end-if
     if       work-2 not = zero
              add work-goods to work-2
              divide purch-activety into work-2 giving purch-average.
*>
 main-exit.   exit section.
*>
 cr-notes     section.
*>===================
*>
     move     oi-header  to  si-header.
     move     "Y"  to  first-pass.
     move     oi-supplier to oi5-supplier.
     move     oi-cr to oi5-invoice.
     start    open-item-file-5 key not < oi5-key invalid key
              go to end-loop.
     move     zero to work-b.
     if       work-1  <  zero
              multiply  -1  by  work-1.
     subtract si-paid  from  work-1.
*>
 read-loop.
*>********
*>
     read     open-item-file-5 next record  at end
              go to  end-loop.
*>
     move     open-item-record-5  to  oi-header.
     if       oi-type not = 2
              go to read-loop.
*>
     if       oi-supplier  not = si-supplier
              go to  end-loop.
     if       s-closed
              go to  read-loop.
*>
     if       si-cr = oi-invoice
        or    first-pass = "N"
              perform  apportion.
*>
     if       work-1  not equal  zero
              go to  read-loop.
*>
 end-loop.
*>*******
*>
     if       work-1 = zero
       or     first-pass not = "Y"
              go to  main-end.
     move     "N"  to  first-pass.
     move     si-supplier to oi5-supplier.
     move     zero to oi5-invoice.
     start    open-item-file-5 key not < oi5-key invalid key
              go to main-end.
     go       to  read-loop.
*>
 main-end.
*>*******
*>
     move     si-header  to  oi-header.
*>
 main-exit.   exit section.
*>********    ****
*>
 apportion    section.
*>===================
*>
     add      oi-net oi-carriage oi-vat oi-c-vat giving  work-a.
     subtract oi-paid  from  work-a.
*>
     if       work-a = zero
              move 1 to oi-status
              go to main-rewrite.
*>
     if       work-a  not >  zero
              go to  main-exit.
*>
     if       work-a = work-1
              add  work-1  to  oi-paid
              add  work-1  to  si-paid
              add  work-1 to oi-p-c
              move  zero  to  work-1
              move  1  to  oi-status  si-status
     else
      if      work-a  >  work-1
              add  work-1  to  oi-paid
              add  work-1  to  si-paid
              add  work-1 to oi-p-c
              move  zero  to  work-1
              move  1  to  si-status
      else
              add  work-a  to  oi-paid
              add  work-a  to  si-paid
              add  work-a to oi-p-c
              subtract  work-a  from  work-1
              move  1  to  oi-status.
*>
     if       work-1 = zero
              move  1  to  si-status.
*>
 main-rewrite.
*>-----------
*>
     move     oi-header  to  open-item-record-5.
     rewrite  open-item-record-5.
*>
 main-exit.   exit section.
*>
 BL-Open      section.
*>===================
*>
     open     i-o  batch-file.
     if       fs-reply not = zero
              close batch-file
              open output batch-file.
*>
     move     next-batch  to  batch-nos.
     move     2  to  ledger.
     add      1  to  next-batch.
*>
     move     zero  to  batch-status
                        cleared-status.
     move     scycle to bcycle.
     move     run-date  to  entered.
*>
     move     "Purchase Ledger Invoices" to description.
     move     zero  to  bdefault
                        batch-def-ac
                        batch-def-pc
                        items
                        input-gross  input-vat
                        actual-gross actual-vat.
*>
     move     "DR"  to  convention.
     move     "PL"  to  batch-def-code.
     move     "I"   to  batch-def-vat.
     add      postings  1  giving  batch-start.
*>
     if       irs-used
              open extend irs-post-file
              if fs-reply not = zero
                 close irs-post-file
                 open output irs-post-file
              end-if
     else
              open i-o  posting-file
              if  fs-reply not = zero
                  close posting-file
                  open output posting-file.
     move     batch-start  to  rrn.
*>
 main-exit.   exit section.
*>********    ****
*>
 bl-write     section.
*>===================
*><<<<<<<<<<<<<<<<<<<<<<<<<<< READ THIS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*>**********************************************************************
*>  This will write a posting record to GL or IRS for EACH invoice     *
*> so, to use it, you MUST have set up the GL account number for EVERY *
*>  analysis code via pl070. It also assumes that you have followed    *
*>  the convention in IRS that default a/c 31 points to VAT input      *
*>  and default a/c 32 is VAT output tax.                              *
*>**********************************************************************
*>
     move     u-date (1:6) to post-date (1:6).
     move     u-date (9:2) to post-date (7:2).
     move     batch-nos  to  batch.
     add      1        to  items.
     move     items    to post-number.
     move     work-net to post-amount.
*>
*> using folio/invoice no + ' : ' supplier name instead of batch/item
*>  on posting file for both IRS & GL.
*>
     move     oi-invoice to m.
     move     zero to b.
     inspect  m tallying b for leading space.
     subtract b from 8 giving c.
     add      1 to b.
*>
     move     1  to  xx.
     string   m (b:c)     delimited by size
              " : "       delimited by size
              purch-name  delimited by size  into post-legend pointer  xx.
*>
     move     p-creditors  to  post-cr.
     move     bl-purch-ac  to  post-dr.
*>
     move     zero  to  dr-pc
                        cr-pc
                        vat-pc
                        vat-amount.
*>
     move     vat-ac of system-record
              to  vat-ac of posting-record
*>
     add      oi-vat oi-c-vat  to  vat-amount.
     move     "DR" to post-vat-side.
     move     "PL" to post-code in posting-record.
*>
     add      post-amount  to  input-gross.
     add      post-amount  to  actual-gross.
     add      vat-amount   to  input-vat.
     add      vat-amount   to  actual-vat.
*>
     if       irs-used
              move post-key      to irs-post-key
              move post-code  in posting-record to irs-post-code
              move post-date     to irs-post-date
              move post-dr       to irs-post-dr
              move post-cr       to irs-post-cr
              move post-amount   to irs-post-amount
              move post-legend   to irs-post-legend
              move 31            to irs-vat-ac-def
              move post-vat-side to irs-post-vat-side
              move vat-amount    to irs-vat-amount
              write irs-posting-record
     else
              write posting-record
     end-if
     if       not irs-used
              add 1 to rrn.
*>
     if       items = 99
              perform  bl-close
              perform  bl-open.
*>
 main-exit.   exit section.
*>********    ****
*>
 bl-close     section.
*>===================
*>
     write    batch-record.
     if       fs-reply not = zero
              display PL132       at 2301
              display fs-reply    at 2333
              perform evaluate-message
              display ws-Eval-Msg at 2336
              display PL002       at 2401 with foreground-color 2
              accept ws-reply     at 2430.
     if       not irs-used
              move rrn to postings.
     close    batch-file.
     if       irs-used
              close irs-post-file
     else
              close posting-file.
*>
 main-exit.   exit section.
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
