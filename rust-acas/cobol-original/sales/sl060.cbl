       >>source free
*>******************************************
*>                                         *
*>           Invoice Posting               *
*>                                         *
*>      Takes input from sl055 (OTM2)      *
*>          as a 2 step process            *
*>                                         *
*>******************************************
*>
*>
 identification          division.
*>===============================
*>
      program-id.         sl060.
*>**
*>    Author.             Cis Cobol Conversion By V B Coen FBCS, 18/10/83
*>                        For Applewood Computers.
*>*
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Invoice Posting.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps04.
*>**
*>    Files Used.
*>                        Sales
*>                        OTM2 i
*>                        OTM3 i-o
*>                        Batch
*>                        Value (anal)
*>                        Posting (GL)
*>                        Posting (irs)
*>                        Printer
*>**
*>    Error messages used.  Note that these msgs are also same in sl100
*>                        SL002
*>                        SL003
*>                        SL130
*>                        SL131
*>                        SL132
*>                        SL133
*>                        SL134
*>                        SL135
*>**
*>    Changes.
*> 19/01/83 Vbc - 4292-4320,4600-40,5140-5030,100480-90,100767-8.
*>                100807,101050-75,101120-101110,101042-50d.
*> 13/02/83 Vbc - 100390-100474,500196-98,207,140500-140990,100510,
*>                100595-100625d.
*> 19/02/83 Vbc - Fix Bug; When Processing Credit Notes Against
*>                Invoices Allow For Deduct Amounts Etc.
*> 19/03/83 Vbc - Update Oi-P-C On Invoice,If Appling Credit Note.
*> 09/04/83 Vbc - Allow For Totals Of Cr.Notes.
*> 03/10/83 Vbc - Fix Bug,Clear Deduct Amts On Inv If Cn Clears
*>                Inv Within 28 Days, & - From Sales-Current.
*> 23/10/83 Vbc - Conversion To Cis Cobol.
*> 04/03/84 Vbc - Support Of Sales-Unapplied.
*> 02/04/84 Vbc - Add Total-Deduct'S To Value File.
*> 09/05/84 Vbc - Support For Indexed Openitm File.
*> 14/07/84 Vbc - Fix Bug In Cr-Notes Invalid Key For Starts.
*> 19/09/84 Vbc - Fix Bug In Cr-Notes Supply Customer To Key.
*> 03/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 03/04/09 vbc - Added support for IRS instead of GL for new post file.
*> 10/04/09 vbc - New feature Env variable ACAS_IRS.
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 07/09/10 vbc - .10 Mod lpr.
*> 24/11/11 vbc - .11 Error msgs to SLnnn.Support for dates other than UK
*> 08/12/11 vbc - .12 Support for path+filenames and removed code dealing with Env vars
*>                    & setting up IRS path etc, as now done in menu program (sales)
*> 09/12/11 vbc -     Updated version to 3.01.nn
*> 11/12/11 vbc - .13 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 02/06/13 vbc - .14 As a started for 10 clean up para & section names so can merge sl055 into 060 & kill
*>                    use of OTM2. More to do.
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
 copy "seloi2.cob".
 copy "seloi3.cob".
 copy "selprint.cob".
 copy "selval.cob".
 copy "selbatch.cob".
 copy "selpost.cob".
 copy "selpost-irs.cob".
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdsl.cob".
 copy "fdoi2.cob".
 copy "fdoi3.cob".
 copy "fdprint.cob".
 copy "fdval.cob".
 copy "fdbatch.cob".
 copy "fdpost.cob".
 copy "fdpost-irs.cob".
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "SL060 (3.01.14)".
 copy "print-spool-command.cob".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
*>
 01  ws-data.
     03  ws-reply        pic x.
     03  ws-error        pic 9                  value zero.
         88  sales-missing                      value 1.
     03  wx-reply        pic xxx.
     03  xx              pic 99.
     03  c-check         pic 9.
         88  c-exists                           value  1.
     03  ws-eval-msg     pic x(25)              value spaces.
     03  work-1          pic s9(7)v99  comp-3   value zero.
     03  work-2          pic s9(14)    comp-3.
     03  work-a          pic s9(7)v99  comp-3   value zero.
     03  work-b          pic s9(7)v99  comp-3   value zero.
     03  first-pass      pic x.
     03  i               pic 999.
     03  j               pic 999.
     03  k               pic 9(5).
     03  m               pic z(7)9.
     03  b               binary-char           value zero.
     03  c               binary-char           value zero.
     03  work-net        pic s9(7)v99  comp-3.
     03  work-vat        pic s9(7)v99  comp-3.
     03  work-goods      pic s9(7)v99  comp-3.
     03  total-group    occurs 3       comp-3.
         05 total-net    pic s9(7)v99.
         05 total-vat    pic s9(7)v99.
     03  a               pic 9                 value zero.
     03  line-cnt        pic 99        comp    value zero.
     03  ws-deduction    pic s9(7)v99  comp-3  value zero.
     03  total-deduct    pic s9(7)v99  comp-3  value zero.
     03  total-mov-ded   pic s9(5)     comp    value zero.
     03  save-level-1    pic 9                 value zero.
     03  ws-env-lines    pic 999               value zero.
     03  ws-lines        binary-char unsigned  value zero.
     03  ws-23-lines     binary-char unsigned  value zero.
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
     03  SL002          pic x(31) value "SL002 Note error and hit return".
     03  SL003          pic x(28) value "SL003 Hit Return To Continue".
*> Module specific
     03  SL130          pic x(17) value "SL130 Open-IT3 = ".
     03  SL131          pic x(38) value "SL131 PE - CR SWOP: Return to continue".
     03  SL132          pic x(32) value "SL132 Err on Batch file write : ".
     03  SL133          pic x(15) value "SL133 PE 060-01".
     03  SL134          pic x(44) value "SL134 Warning Record/s missing in Sales File".
     03  SL135          pic x(34) value "SL135 Error On Re/write Sales File".
     03  SL136          pic x(40) value "SL136 Error writing to Open Item 3 File ".
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
     03  filler          pic x(64)       value " Number     Date    <------------Customer------------>   Type  ".
     03  filler          pic x(68)       value " Old Balance  New Balance   Dedn     Net         Vat       Gross".
*>
 01  line-4a.
     03  filler          pic x(82)       value "--Customer--   Invoice      Bal C/F        Applied      Cr. Note          Type    ".
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
     03  l5-deduction    pic zzz9.99     blank when zero.
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
*>**************
*>
 01  to-day              pic x(10).
 copy "wsnames.cob".
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wssys4.cob".
*>
 procedure division using ws-calling-data
                          system-record
                          system-record-4
                          to-day
                          file-defs.
*>=======================================
*>
 Declaratives.
*>
 File-Error-On-OTM2 section.
*>
     use after error procedure on Sales-File.
 a00-Sales-Error-1.
     if       fs-reply not = zero
              perform  Eval-Status
              display  SL135         at line ws-23-lines col 1
              display  fs-reply      at line ws-23-lines col 37
              display  ws-Eval-Msg   at line ws-23-lines col 40
              display  SL002         at line ws-lines col 01
              accept   ws-reply      at line ws-lines col 33
     end-if
     goback.
*>
 Eval-Status.
*>==========
*>
     move     spaces to ws-Eval-Msg.
 copy "FileStat-Msgs.cpy"  replacing STATUS by fs-reply
                                     msg    by ws-Eval-Msg.
*>
 main-exit.   exit.
*>
 end declaratives.
*>
 aa000-Main-Process  section.
     accept   ws-env-lines   from lines.
     if       ws-env-lines < 24
              move  24 to ws-env-lines ws-lines
     else
              move  ws-env-lines   to ws-lines
     end-if
     subtract 1 from ws-lines giving ws-23-lines.
     move     prog-name to l1-name.
     perform  zz070-Convert-Date.
     move     ws-date to l1-date.
     move     Print-Spool-Name to PSN.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Invoice Posting & Report" at 0131 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
 aa010-Acpt-Xrply.
     display  "OK to post Sales transactions (YES/NO) ?  [   ]" at 0812 with foreground-color 2.
     move     spaces to  wx-reply.
     accept   wx-reply at 0855 with foreground-color 6 update.
     move     function upper-case (wx-reply) to wx-reply.
     if       wx-reply = "NO"
              go to aa999-Exit-Prog.
     if       wx-reply not = "YES"
              go to aa010-Acpt-Xrply.
*>
     display  " " at 0801 with erase eol.
     move     2 to S-Flag-I.				*> No idea
     move     1 to S-Flag-A.				*> No idea
     move     "Y" to oi-3-flag.				*> sets changes to file so sl115 sort needed.
     if       file-status (19) not = 1
              open output open-item-file-3
              close open-item-file-3
              move  1 to file-status (19).			*> No idea
*>
*>****************************************************		*> yes we will
*> >>>>> Bypass code to send totals to gl <<<<<<     *
*>                                                   *
*>     move     level-1 to save-level-1.
*>     move     0 to level-1.
*>                                                   *
*>****************************************************
*>
     if       g-l
              perform  ca000-BL-Open.
*>
     open     i-o  sales-file.
     open     output print-file.
     display  "Posting......Please Wait" at 1201 with foreground-color 2 erase eol.
     display  "Phase 1 - Building OTM3 from OTM2" at 1401 with foreground-color 2 erase eol.
*>
     move     zero  to  j.
     perform  ba000-Headings.
*>
     move     zeros to total-net (1) total-net (2) total-net (3).
     move     zeros to total-vat (1) total-vat (2) total-vat (3).
*>
     open     input  open-item-file-2.
     open     i-o    open-item-file-3.
*>
 aa020-Read-Loop.
     read     open-item-file-2 at end                         *> only has headers
              go to aa030-Main-End.
*>
     move     open-item-record-2  to  oi-header.
*>
     move     oi-customer  to  sales-key  l5-cust.
     move     space to ws-reply.
     read     sales-file  record invalid key
              move "X" to ws-reply.
*>
     if       ws-reply = "X"
              move 1 to ws-error
              initialize sales-record
              move "*** Customer Unknown ***" to l5-name sales-name
              move oi-customer to sales-key
     else
              move sales-name  to  l5-name.
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
              move  "Invoice"  to  l5-type
     else
      if      oi-type = 3
              move  "CR. Note" to  l5-type
      else
       if     oi-type = 1
              move  "Receipt" to  l5-type.
*>
     add      oi-vat oi-c-vat oi-e-vat oi-deduct-vat giving work-vat.
     add      oi-net oi-extra giving work-goods.
     move     work-vat  to l5-vat.
     add      oi-net  oi-extra  oi-carriage  oi-discount oi-deduct-amt giving work-net.
     move     work-net  to l5-net.
*>
     add      work-vat  to  total-vat (a).
     add      work-net to  total-net (a).
*>
     move     work-net to work-1.
     add      work-vat to work-1.
     move     work-1 to l5-gross.
*>
     move     zero to l5-deduction ws-deduction.
*>
     if       g-l
              perform  ca000-BL-Write.
*>
     subtract sales-unapplied from sales-current giving l5-old-bal.
     if       oi-type = 1 or 2
              perform ba000-Sales-Comp.
*>
*> receipts
*>
     if       oi-type = 1
              add  work-goods to  STurnover-Q (current-quarter)
              move  oi-date  to  sales-last-inv sales-last-pay.
*>
*> accounts
*>
     if       oi-type = 2
              add work-goods to  STurnover-Q (current-quarter)
              add work-vat work-net to  sales-current
              move  oi-date  to  sales-last-inv.
*>
*> cr. notes values are negative
*>
     if       oi-type = 3
              add work-goods to STurnover-Q (current-quarter)
              add work-vat work-net to  sales-current
              move oi-date to sales-last-pay
              perform ba000-CR-Notes
              perform ba000-Credit-Comp.
*>
     move     ws-deduction to l5-deduction.
     add      ws-deduction to total-deduct.
*>
     if       customer-dead                         *> as cust now has an invoice, make it Live if not already
              move  1  to  sales-status.
*>
     if       sales-current is negative
              multiply -1 by sales-current
              add sales-current to sales-unapplied
              move zero to sales-current.
*>
*>    At this point only current OR unapplied can be non zero
*>    and current will be = or > zero
*>
     subtract sales-unapplied from sales-current giving l5-new-bal.
     if       ws-reply = "X"
              move 1 to sales-status
              write sales-record
     else
              rewrite sales-record.
*>
     write    open-item-record-3 from oi-header invalid key       *> THIS  SHOULD NOT HAPPEN, short of a HDD problem
              display SL130         at 1601
              display oi3-customer  at 1701
              move oi3-invoice to l5-nos
              display l5-nos        at 1801
              display "fs-reply = " at 1901
              display fs-reply      at 1912
              perform zz040-Evaluate-Message
              display ws-Eval-Msg   at 1915
              display SL133         at 2401 with foreground-color 4
              display SL002         at 2412
              accept ws-reply       at 2450.		*> Well I did say should NOT happen!!
*>*              rewrite    open-item-record-3.
*>              stop run.
     write    print-record  from  line-5 after 1.
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform ba000-Headings.
     go       to aa020-Read-Loop.
*>
 aa030-Main-End.
     close    sales-file open-item-file-2 open-item-file-3.
     move     total-net (1) to  l6-net.
     move     total-vat (1) to  l6-vat.
     add      total-net (1) total-vat (1) giving  l6-gross.
     move     ws-lits (1) to l6-lit.
*>
     if       line-cnt > Page-Lines - 7
              perform ba000-Headings.
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
     move    "           Total  Amount Late Deductions" to line-6.
     move     total-deduct to l6-net.
     write    print-record from line-6 after 2.
     add      total-deduct to sl-credit-deductions.
*>
     if       total-deduct not = zero
              open i-o value-file
              perform ba000-Analise-Deductions
              close value-file.
*>
     if       g-l
              perform  ca000-BL-Close.
*>
*>************************************************************
*>    Routine To Close Un-Applied Cr. Notes                  *
*>************************************************************
*>
     open     i-o  open-item-file-3.
*>
     move     zero  to  work-b.
     display  "2 - Applying Cr. Notes to OTM3" at 1407 with foreground-color 2 erase eol.    *> Posting Phase 2
*>
 aa040-End-Loop.
     read     open-item-file-3 next record at end
              go to aa050-End-Loop-End.
*>
     move     open-item-record-3  to  oi-header.
*>
     if       s-closed
              go to aa040-End-Loop.
*>
     if       oi-type = 3
              perform  ba000-Cr-Swop.
*>
     go       to aa040-End-Loop.
*>
 aa050-End-Loop-End.
     open     output  open-item-file-2.		*> Clear down IO2 file data now transferred to IO3
     close    open-item-file-2.
     close    open-item-file-3.
*>
     if       line-cnt > Page-Lines - 6 and
              file-status (18) = 1
              perform ba000-New-Heading.
*>
     if       file-status (18) = 1
              move  "Un-Applied Credits C/F " to  l8-desc
              move  work-b  to  l8-tot
              write  print-record  from  line-8 after 3.
*>
     add      work-b to sl-cn-unappl-this-month.
*>
     if       sales-missing
              move SL134 to print-record
              write print-record after 3.
*>
     close    print-file.
     call     "SYSTEM" using Print-Report.
     move     zero to file-status (18).		*> clearing OTM2 status
*>
*>****************************************
*>*  >>> bypass code for g-l
*>*
*>     move     save-level-1 to level-1.
*>*
*>****************************************
*>
 aa999-Exit-Prog.
     exit     program.
*>
 ba000-Cr-Swop           section.
*>==============================
*>
     add      oi-net         oi-extra  oi-carriage  oi-vat
              oi-discount    oi-e-vat  oi-c-vat
              oi-deduct-amt  oi-deduct-vat          giving  work-1.
     add      oi-paid   to   work-1.
     if       work-1 = zero
              display SL131   at 2401 with foreground-color 4
              accept ws-reply at 2434.
*>
*> Above should NOT ever happen as there is no such thing as a zero value Cr. Note  or is there !!
*>
     if       file-status (18) = zero
              perform  ba000-New-Heading.
*>
     move     1  to  oi-status.
*>
     move     oi-customer  to  l7-cust.
     move     oi-invoice   to  l7-trans.
     move     oi-cr        to  l7-cr-note.
     move     "Cr. Note"   to  l7-type.
     move     work-1       to  l7-bal.
     move     oi-paid      to  l7-appl.
     write    print-record  from  line-7 after 1.
*>
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform  ba000-New-Heading.
*>
     add      work-1   to  work-b.
     multiply -1 by work-1.
     add      work-1 to oi-paid.
     rewrite  open-item-record-3  from  oi-header.
*>
 main-exit.
     exit     section.
*>
 ba000-New-Heading       section.
*>==============================
*>
     if       file-status (18) = zero
              move  1  to  file-status (18).
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
     write    print-record  after  1.
     move     6 to line-cnt.
*>
 main-exit.
     exit     section.
*>
 ba000-Headings          section.
*>==============================
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
 main-exit.
     exit     section.
*>
 ba000-Sales-Comp        section.
*>==============================
*>
     if       sales-activety not = zero
         and  sales-average not = zero
              multiply sales-activety by sales-average giving work-2
     else
              move zero to work-2
     end-if
     add      1 to sales-activety.
     add      work-goods to work-2.
     divide   sales-activety into work-2 giving sales-average.
*>
 main-exit.
     exit section.
*>
 ba000-Credit-Comp       section.
*>==============================
*>
     if       sales-activety not = zero
        and   sales-average not = zero
              multiply sales-activety by sales-average giving work-2
     else
              move zero to work-2
     end-if
     if       work-2 not = zero
              add work-goods to work-2
              divide sales-activety into work-2 giving sales-average.
*>
 main-exit.
     exit     section.
*>
 ba000-CR-Notes          section.
*>==============================
*>
     move     oi-header  to  si-header.
     move     "Y"  to  first-pass.
     move     oi-customer to oi3-customer.
     move     oi-cr to oi3-invoice.
     start    open-item-file-3 key not < oi3-key invalid key
              go to ba020-end-loop.
     move     zero to work-b.
     if       work-1 < zero
              multiply -1 by work-1.
     subtract si-paid from work-1.
*>
 ba010-read-loop.
*>**************
*>
     read     open-item-file-3 next record  at end
              go to ba020-end-loop.
*>
     move     open-item-record-3  to  oi-header.
     if       oi-type not = 2
              go to ba010-read-loop.
*>
     if       oi-customer not = si-customer	*> Cr note customer not exist?  should not normally happen but...
              go to ba020-end-loop.
     if       s-closed
              go to ba010-read-loop.
*>
*>  check if credit note can clear late charge amount
*>
     add      oi-deduct-amt oi-deduct-vat giving work-b.
     move     oi-date        to  u-bin.
     add      1 oi-deduct-days to  u-bin.
     if       u-bin  not >  si-date
              move  zero  to  work-b.
*>
     if       si-cr = oi-invoice
        or    first-pass = "N"
              perform  ba000-Apportion.
*>
     if       work-1 not = zero
              go to  ba010-read-loop.
*>
 ba020-end-loop.
*>*************
*>
     if       work-1 = zero
        or    first-pass not = "Y"
              go to ba030-main-end.
     move     "N"  to  first-pass.
     move     si-customer to oi3-customer.
     move     zero to oi3-invoice.
     start    open-item-file-3 key not < oi3-key invalid key
              go to ba030-main-end.
     go       to ba010-read-loop.
*>
 ba030-main-end.
*>*************
*>
     move     si-header  to  oi-header.
*>
 ba040-main-exit.
     exit     section.
*>
 ba000-Apportion         section.
*>==============================
*>
     add      oi-net         oi-extra  oi-carriage  oi-vat
              oi-discount    oi-e-vat  oi-c-vat
              oi-deduct-amt  oi-deduct-vat       giving  work-a.
     subtract oi-paid  from  work-a.
*>
     if       work-a = zero
              move 1 to oi-status
              go to ba000-Main-Rewrite.
*>
     if       work-a  not >  zero
              exit section.
*>
     subtract work-b from work-a.
*>
     if       work-a = work-1
              add  work-1  to  oi-paid
              add  work-1  to  si-paid
              add  work-1 to oi-p-c
              move  zero  to  work-1
              perform ba000-Clear-Invoice-Deduct
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
              perform ba000-Clear-Invoice-Deduct
              move  1  to  oi-status.
*>
     if       work-1 = zero
              move  1  to  si-status.
*>
 ba000-Main-Rewrite.
     move     oi-header  to  open-item-record-3.
     rewrite  open-item-record-3.
     exit     section.
*>
 ba000-Clear-Invoice-Deduct.
     if       work-b > zero
              subtract work-b from sales-current
              add work-b to ws-deduction
              add 1 to total-mov-ded
              move zero to oi-deduct-amt oi-deduct-vat.
 ba000-cid-exit.
*>
 main-exit.
     exit     section.
*>
 ba000-Analise-Deductions section.
*>===============================
*>
     move     "Szd" to va-code.
     read     value-file  invalid key
              exit section.
*>
     subtract total-mov-ded from va-t-this.
     subtract total-mov-ded from va-t-year.
     subtract total-deduct from va-v-this.
     subtract total-deduct from va-v-year.
*>
     rewrite  value-record.
*>
     move     space  to  va-second.
     read     value-file  invalid key
              exit section.
*>
     subtract total-mov-ded from va-t-this.
     subtract total-mov-ded from va-t-year.
     subtract total-deduct from va-v-this.
     subtract total-deduct from va-v-year.
     rewrite  value-record.
*>
 ba999-main-exit.
     exit section.
*>
 ca000-BL-Open           section.
*>==============================
*>
     open     i-o  batch-file.
     if       fs-reply not = zero
              close batch-file
              open output batch-file.
*>
     move     next-batch to batch-nos.
     move     3 to ledger.                               *> Sales Ledger
     add      1 to next-batch.
*>
     move     zero to batch-status
                      cleared-status.
     move     scycle to bcycle.
     move     run-date to entered.
*>
     move     "Sales Ledger Invoices" to description.
     move     zero to bdefault     batch-def-ac
                      batch-def-pc items
                      input-gross  input-vat
                      actual-gross actual-vat.
*>
     move     "CR" to convention.
     move     "SL" to batch-def-code.
     move     "O"  to batch-def-vat.
     add      postings  1  giving  batch-start.
*>
     if       irs-used                                  *> Prepare to write GL or IRS posting records
              open extend irs-post-file                 *> needed: -  bug/feature in OC
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
 ca997-main-exit.
     exit section.
*>
 ca000-BL-Write section.
*>=====================
*><<<<<<<<<<<<<<<<<<<<<<<<<<< READ THIS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*>**********************************************************************
*>  This will write a posting record to GL or IRS for EACH line item   *
*>   in EACH invoice                                                   *
*> so, to use it, you MUST have set up the GL account number for EVERY *
*>  analysis code via sl070. It also ASSUMES that you have followed    *
*>  the convention in IRS/GL that default a/c 31 points to VAT input   *
*>  and default a/c 32 is VAT output tax.                              *
*>**********************************************************************
*>
     move     u-date (1:6) to post-date (1:6).
     move     u-date (9:2) to post-date (7:2).
     move     batch-nos  to  batch.
     add      1  to  items.
     move     items    to post-number.
     move     work-net to post-amount.
*>
     move     1  to  xx.
     move     oi-b-nos to k.
     move     oi-b-item to i.
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
     string   m (b:c)     delimited by size
              " : "       delimited by size
              sales-name  delimited by size
                           into post-legend pointer  xx.
*>
*>     string   k          delimited by size
*>              "/"        delimited by size
*>              i          delimited by size
*>              " : "      delimited by size
*>              sales-name delimited by size
*>                   into post-legend  pointer xx.
*>
     move     s-debtors    to  post-dr.
     move     sl-sales-ac  to  post-cr.
*>
     move     zero  to  dr-pc
                        cr-pc
                        vat-pc
                        vat-amount.
*>
     move     vat-ac of system-record
              to  vat-ac of posting-record
*>
     add      oi-vat  oi-e-vat  oi-c-vat  to  vat-amount.
     move     "CR" to post-vat-side.
     move     "SL" to post-code in posting-record.
*>
     add      post-amount  to  input-gross.
     add      post-amount  to  actual-gross.
     add      vat-amount   to  input-vat.
     add      vat-amount   to  actual-vat.
*>
     if       irs-used
              move batch         to irs-batch
              move post-number   to irs-post-number
              move post-code in posting-record  to irs-post-code
              move post-date     to irs-post-date
              move post-dr       to irs-post-dr
              move post-cr       to irs-post-cr
              move post-amount   to irs-post-amount
              move post-legend   to irs-post-legend
              move 32            to irs-vat-ac-def
              move post-vat-side to irs-post-vat-side
              move vat-amount    to irs-vat-amount
              write irs-posting-record
     else
              write posting-record
     end-if
*>     if       not irs-used    *> THIS IS IN PURCHASE
     add      1  to  rrn.
*>
     if       items = 99
              perform  ca000-BL-Close
              perform  ca000-BL-Open.
*>
 ca998-main-exit.
     exit section.
*>
 ca000-BL-Close section.
*>=====================
*>
     write    batch-record.
     if       fs-reply not = zero
              display SL132       at 2301
              display fs-reply    at 2333
              perform zz040-Evaluate-Message
              display ws-Eval-Msg at 2336
              display SL002       at 2401 with foreground-color 2
              accept ws-reply     at 2433.
*>     if       not irs-used     *> THIS IS IN PURCHASE PL060
     move     rrn  to  postings.
     close    batch-file.
     if       irs-used
              close irs-post-file
     else
              close posting-file.
*>
 ca999-main-exit.
     exit section.
*>
 zz040-Evaluate-Message Section.
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
