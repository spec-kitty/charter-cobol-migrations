       >>source free
*>****************************************************
*>                                                   *
*>                       Day  Book                   *
*>                                                   *
*>****************************************************
*>
 identification          division.
*>===============================
*>
      program-id.         sl140.
*>**
*>    author.             Cis Cobol Conversion By V B Coen FBCS, 25/10/83
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    remarks.            Invoice Day Book.
*>
*>**
*>    version.            See Prog-Name in Ws.
*>
*>    called modules.     maps04.
*>                        maps99.
*>**
*>    Error messages used.
*>                        NONE
*>**
*>    Changes.
*> 27/04/83 vbc - modify totals to give separate tot for cn's.
*> 10/10/83 vbc - clean up printer to use line-cnt.
*> 25/10/83 vbc - cis cobol conversion.
*> 08/12/83 vbc - clean up headings-01.
*> 10/03/84 vbc - revised, using invoice file instead of openitm
*>                file as deduct-amt may be cleared by cn or paymt.
*> 03/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 19/03/09 vbc - .04 Mod to heads on totals.
*> 29/05/09 vbc - .05 Support for Page-Lines instead of fixed number.
*> 07/09/10 vbc - .06 Mod lpr.
*> 25/11/11 vbc - .07 Error msgs to SLnnn.Support for dates other than UK
*> 08/12/11 vbc - .08 Support for path+filenames.
*> 09/12/11 vbc -     Updated version to 3.01.nn
*> 11/12/11 vbc - .09 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
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
 copy "selinv.cob".
 copy "selprint.cob".
 data                    division.
*>===============================
*>
 file section.
*>------------
*>
 copy "fdsl.cob".
 copy "fdinv.cob".
 fd  print-file.
 01  print-record         pic x(132).
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "SL140 (3.01.09)".
 copy "print-spool-command.cob".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
*>
 01  ws-data.
     03  ws-reply        pic x.
     03  head-type       pic 9                  value zero.
     03  z               pic 99.
     03  line-cnt        pic 99     comp        value zero.
     03  work-1          pic s9(8)v99   comp-3  value zero.
     03  j               pic 999.
     03  k               pic 99.
     03  l               pic 99                 value zero.
     03  ws-deduct-amt   pic s9(4)v99   comp-3  value zero.
*>
     03  group-totals   occurs 4 comp-3.
      05 total-gds       pic s9(8)v99.
      05 total-car       pic s9(8)v99.
      05 total-ded       pic s9(8)v99.
      05 total-net       pic s9(8)v99.
      05 total-vat       pic s9(8)v99.
      05 total-grs       pic s9(8)v99.
      05 total-dis       pic s9(8)v99.
*>
     03  group-lits.
      05 filler          pic x(17) value "Receipts".
      05 filler          pic x(17) value "Invoices".
      05 filler          pic x(17) value "Credit Notes".
      05 filler          pic x(17) value "    Totals".
     03  filler redefines group-lits.
      05 total-literal   pic x(17)       occurs 4.
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
 01  error-code          pic 999         value zero.
*>
 copy "wsinv.cob".
*>
 01  line-1.
     03  l1-version      pic x(62)       value spaces.
     03  filler          pic x(62)       value "Day Book".
     03  filler          pic x(5)        value "Page ".
     03  l3-page         pic zz9.
*>
 01  line-2.
     03  l3-user         pic x(62).
     03  filler          pic x(8)        value spaces.
     03  filler          pic x(52)       value spaces.
     03  l1-date         pic x(10).
*>
 01  line-4.
     03  filler          pic x(66)       value " Number   ---Date--- <------------Customer------------>".
     03  filler          pic x(8)        value spaces.
     03  filler          pic x(58)       value "<---Net-->  <---Vat-->  <--Gross->".
*>
 01  line-5.
     03  l5-nos          pic z(7)9bb.
     03  l5-date         pic x(10)b.
     03  l5-cust         pic x(8).
     03  l5-name         pic x(25).
     03  filler          pic xxx         value spaces.
     03  l5-type         pic x(11).
     03  filler          pic x(6)        value spaces.
     03  l5-net          pic z(6)9.99cr.
     03  l5-vat          pic z(6)9.99cr.
     03  l5-gross        pic z(6)9.99cr.
*>
 01  line-6.
     03  l6-total        pic x(17).
     03  l6-goods        pic z(7)9.99cr.
     03  l6-disc         pic z(7)9.99cr.
     03  l6-ded          pic z(7)9.99cr.
     03  l6-carr         pic z(7)9.99cr.
     03  l6-net          pic z(7)9.99cr.
     03  l6-vat          pic z(7)9.99cr.
     03  l6-gross        pic z(7)9.99cr.
*>
 01  line-7.
     03  filler          pic x(23)      value spaces.
     03  filler          pic x(83)      value "Goods     Discount   Prompt Pay     Carriage          Net          Vat        Gross".
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
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 init01 section.
     move     Print-Spool-Name to PSN.
     move     prog-name to l1-version.
     move     usera to l3-user.
     move     to-day to u-date
     perform  zz070-Convert-Date.
     move     ws-date to l1-date.
     move     zero to z.
     perform  zeroise-totals 4 times.
*>
 menu-return.
*>**********
*>
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "Day Book" at 0136 with foreground-color 2.
     display  ws-date at 0171 with foreground-color 2.
*>
     open     input  invoice-file.
     if       fs-reply not = zero
              close invoice-file
              go to menu-call.
     open     input  sales-file.
     if       fs-reply not = zero
              close invoice-file sales-file
              go to menu-call.
     open     output print-file.
*>
     display  "Printing.......Please wait" at 1212 with foreground-color 2.
     move     zero  to  j.
     perform  headings.
*>
 loop.
     read     invoice-file next record  at end
              go to  main-end.
*>
     if       item-nos not = zero
              go to loop.
*>
     if       invoice-type > 3
              go to  loop.
*>
     move     invoice-record  to  sinvoice-header.
*>
     if       day-booked or not sapplied
              go to loop.
*>
     if       line-cnt > Page-Lines
              perform  headings.
     move     sih-customer  to  sales-key  l5-cust.
*>
     read     sales-file  record.
*>
     move     sales-name  to  l5-name.
     move     sih-invoice  to  l5-nos.
     move     sih-date  to  u-bin.
     perform  zz060-Convert-Date.
     move     ws-date  to  l5-date.
*>
     move     sih-type to z.
*>
     if       sih-type  equal  1
              move  "Receipt"  to  l5-type
     else
      if      sih-type  equal  2
              move  "Invoice"  to  l5-type
      else
              move  "Cr. Note" to  l5-type.
*>
     move     sih-deduct-amt to ws-deduct-amt.
     if       sih-type = 3
              multiply -1 by sih-vat
              multiply -1 by sih-c-vat
              multiply -1 by sih-e-vat
              multiply -1 by sih-net
              multiply -1 by sih-extra
              multiply -1 by sih-carriage
              multiply -1 by sih-discount
              multiply -1 by ws-deduct-amt.
*>
     add      sih-vat  sih-c-vat  sih-e-vat  giving  l5-vat.
     add      sih-net  sih-extra  sih-carriage  sih-discount ws-deduct-amt giving  l5-net.
     add      sih-vat  sih-c-vat  sih-e-vat  sih-discount
              sih-net  sih-extra  sih-carriage  ws-deduct-amt giving  l5-gross.
*>
     add      sih-net  to  total-gds (z).
     add      sih-net  to  total-gds (4).
     add      sih-discount  sih-extra  giving work-1.
     add      work-1  to  total-dis (z).
     add      work-1  to  total-dis (4).
     add      ws-deduct-amt to total-ded (z).
     add      ws-deduct-amt to total-ded (4).
     add      sih-carriage to total-car (z).
     add      sih-carriage to total-car (4).
     add      sih-vat  sih-c-vat  sih-e-vat  giving work-1.
     add      work-1 to  total-vat (z).
     add      work-1 to  total-vat (4).
     add      sih-net  sih-extra  sih-carriage  sih-discount ws-deduct-amt giving work-1.
     add      work-1 to  total-net (z).
     add      work-1 to  total-net (4).
     add      sih-vat sih-c-vat sih-e-vat sih-net sih-extra sih-carriage
              sih-discount ws-deduct-amt giving work-1.
     add      work-1 to  total-grs (z).
     add      work-1 to  total-grs (4).
*>
     write    print-record  from  line-5 after 1.
     add      1 to line-cnt.
     go       to loop.
*>
 main-end.
     close    sales-file
              invoice-file.
*>
     move     1 to head-type.
     perform  headings.
     write    print-record from line-7 after 2.
     move     spaces to print-record.
     write    print-record after 1.
*>
     move     zero to z.
     perform  print-totals 4 times.
*>
     close    print-file.
     call     "SYSTEM" using Print-Report.
*>
 menu-call.
     exit     program.
*>
 headings     section.
*>*******************
*>
     add      1  to  j.
     move     j  to  l3-page.
     if       j not = 1
              write print-record from line-1 after page
              write print-record from line-2 after 1
              move spaces to print-record
              write print-record after 1
     else
              write print-record from line-1 before 1
              write print-record from line-2 before 1
     end-if
     move     2 to line-cnt.
*>
 sect2.
*>
     if       head-type = zero
              add 3 to line-cnt
              write  print-record  from  line-4 after 2
              move   spaces  to  print-record
              write  print-record after 1.
*>
 zeroise-totals section.
*>*********************
*>
     add      1 to z.
     move     zero to total-gds (z) total-car (z).
     move     zero to total-net (z) total-vat (z).
     move     zero to total-grs (z) total-dis (z).
     move     zero to total-ded (z).
*>
 print-totals section.
*>*******************
*>
     add      1 to z.
     move     total-gds (z) to  l6-goods.
     move     total-net (z) to  l6-net.
     move     total-vat (z) to  l6-vat.
     move     total-grs (z) to  l6-gross.
     move     total-car (z) to  l6-carr.
     move     total-dis (z) to  l6-disc.
     move     total-ded (z) to  l6-ded.
     move     total-literal (z) to l6-total.
     write    print-record  from  line-6 after 2.
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
