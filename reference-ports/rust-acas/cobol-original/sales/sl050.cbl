       >>source free
*>*****************************************************************
*>                                                                *
*>             I N V O I C E   P R O O F  R E P O R T             *
*>                                                                *
*>*****************************************************************
*>
 identification          division.
*>===============================
*>
      program-id.         sl050.
*>**
*>    Author.             Cis Cobol Conversion By V B Coen FBCS, 18/10/83
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Invoice Proof Report and Analysis.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps04.
*>**
*>    Files Used.
*>                        Sales
*>                        Invoice
*>                        Printer
*>**
*>    Error messages used.
*>                        SL120
*>***
*>   Changes.
*> 08/01/83 vbc - 100215,500421+,005280,005360-90,101062-64.
*> 19/01/83 vbc - 005365-70,005140-200,500412-415,428-430
*>                500438,480,860,765,890,900,850-60,765,890,900.
*>                101350d,60,500120,1304286-8,4380-4400,4500-40.
*>                5400-6000,5330-35,5350d,5362,100160-70.
*>                500540-50,100777,100930,101046-51,101050-17000.
*>                520000-522700,004350d-,100290.
*> 09/04/83 Vbc - Allow For Credit Notes Totals.
*> 23/09/83 Vbc - Mod Print Writes To Use Line-Cnt.
*> 01/10/83 Vbc - On Reading Sales Check If Rec Missing.
*> 22/10/83 Vbc - Conversion To Cis Cobol.
*> 11/05/84 Vbc - Report On Vat Codes.
*> 03/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 14/03/09 vbc - Tidy up totals & keep on same page if enough space.
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 07/09/10 vbc - .06 Mod lpr.
*> 24/11/11 vbc - .07 Error msgs to SLnnn.Support for dates other than UK
*> 08/12/11 vbc - .08 Support for path+filenames.
*> 09/12/11 vbc -     Updated version to 3.01.nn
*> 11/12/11 vbc - .09 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 01/06/13 vbc - .10 Minor tidy up of code with no functional changes eg replace zeroise by initialize etc
*>                    Increase VAT codes reporting from 3 to 5 with test for non zero, just in case
*>                    tax codes [options 4 & 5] are used.
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
*>-----------
*>
 copy "selsl.cob".
 copy "selinv.cob".
 copy "selprint.cob".
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdsl.cob".
 copy "fdinv.cob".
 copy "fdprint.cob".
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "SL050 (3.01.10)".
 copy "print-spool-command.cob".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
 01  ws-data.
     03  test-product.
         05  filler      pic x.
             88  il-comment              value "/".
         05  filler      pic x(11).
     03  ws-reply        pic x.
     03  ws-error        pic 9           value zero.
         88  sales-missing               value 1.
     03  i               pic 99.
     03  j               pic 999.
     03  k               pic 99.
     03  l               pic 99          value zero.
     03  first-time      pic x           value "Y".
     03  a               pic 9           value zero.
     03  total-group    occurs 3     comp-3.
         05 total-ded    pic s9(8)v99.
         05 total-gds    pic s9(8)v99.
         05 total-car    pic s9(8)v99.
         05 total-net    pic s9(8)v99.
         05 total-vat    pic s9(8)v99.
         05 total-grs    pic s9(8)v99.
         05 total-dis    pic s9(8)v99.
         05 total-cvat   pic s9(8)v99    occurs 5.
     03  ws-deduct-amt   pic s999v99 comp-3 value zero.
     03  ws-deduct-vat   pic s999v99 comp-3 value zero.
     03  line-cnt        binary-char        value zero.
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
*>       NONE
*> Module specific
     03  SL120          pic x(57) value "SL120 No Transactions to proof! ...Press return for menu.".
*>
 copy "wsinv.cob".
*>
 01  error-code          pic 999         value zero.
*>
 01  ws-group-lits.
     03  filler          pic x(17)      value "Receipts".
     03  filler          pic x(17)      value "Invoices".
     03  filler          pic x(17)      value "Credit Notes".
 01  filler  redefines ws-group-lits.
     03  ws-lit          pic x(17)   occurs 3.
*>
 01  line-1.
     03  l1-version      pic x(49)       value spaces.
     03  filler          pic x(75)       value "Unapplied Sales Transaction Report".
     03  filler          pic x(5)        value "Page ".
     03  l3-page         pic zz9.
*>
 01  line-2.
     03  l3-user         pic x(49)       value spaces.
     03  filler          pic x(34)       value spaces.
     03  filler          pic x(39)       value spaces.
     03  l1-date         pic x(10).
*>
 01  line-4.
     03  filler          pic x(66)       value "  Number ---Date--- <------------Customer------------>  --Type--".
     03  filler          pic x(9)        value spaces.
     03  filler          pic x(57)       value "Goods                 <---Net-->  <---Vat-->  <--Gross->".
*>
 01  line-5.
     03  l5-nos          pic z(7)9b.
     03  l5-date         pic x(11).
     03  l5-cust         pic x(8).
     03  l5-name         pic x(25).
     03  l5-marker       pic xxxxx        value spaces.
     03  l5-type         pic x(14).
     03  l5-goods        pic z(6)9.99cr.
     03  filler          pic x(13)       value spaces.
     03  l5-net          pic z(6)9.99cr.
     03  l5-vat          pic z(6)9.99cr.
     03  l5-gross        pic z(6)9.99cr.
*>
 01  line-6.
     03  filler          pic x(7)         value spaces.
     03  filler          pic x(6)         value "Total".
     03  l6-lit          pic x(18).
     03  l6-goods        pic z(6)9.99cr.
     03  l6-disc         pic z(6)9.99cr.
     03  l6-ded          pic z(6)9.99cr.
     03  l6-carr         pic z(6)9.99cr.
     03  l6-net          pic z(6)9.99cr.
     03  l6-vat          pic z(6)9.99cr.
     03  l6-gross        pic z(6)9.99cr.
*>
 01  line-7.
     03  filler          pic x(36)      value spaces.
     03  filler          pic x(78)      value "Goods    Discount  Prompt Pay    Carriage         Net         Vat       Gross".
*>
 01  line-8.
     03  filler          pic x(9)        value "Vat Code".
     03  l8-vat-code     pic 9.
     03  filler          pic xxx         value spaces.
     03  l8-vat-rate     pic z9.99.
     03  filler          pic x(5)        value "%".
     03  l8-amount1      pic z(7)9.99cr.
     03  l8-amount2      pic z(9)9.99cr.
     03  l8-amount3      pic z(9)9.99cr.
*>
 01  line-9.
     03  filler          pic x(70)      value "V.A.T. Reconciliation       Receipts       Invoices   Credit Notes".
*>
 01  line-a.
     03  filler          pic x(46)       value spaces.
     03  la-a            pic x(12).
     03  la-code         pic x(6).
     03  la-b            pic x(8).
     03  la-amount       pic z(6)9.99cr.
     03  filler          pic x(2)        value spaces.
     03  la-c            pic x(9).
     03  la-vat          pic 9.
*>
 01  line-b.
     03  filler          pic x(46)       value spaces.
     03  lb-a            pic x(12)       value spaces.
     03  lb-code         pic x(6).
     03  lb-b            pic x(8)        value spaces.
     03  lb-amount       pic z(6)9.99cr.
*>
 01  line-c.
     03  filler          pic x(46)       value spaces.
     03  lc-a            pic x(12).
     03  lc-code         pic x(6)        value spaces.
     03  lc-b            pic x(8)        value spaces.
     03  lc-amount       pic z(6)9.99cr.
     03  filler          pic x(2)        value spaces.
     03  lc-c            pic x(9).
     03  lc-vat          pic 9.
*>
 01  line-d.
     03  filler          pic x(46)       value spaces.
     03  ld-a            pic x(12).
     03  ld-code         pic x(6)        value spaces.
     03  ld-b            pic x(8)        value spaces.
     03  ld-amount       pic z(6)9.99cr.
     03  filler          pic x(2)        value spaces.
     03  ld-c            pic x(9).
     03  ld-vat          pic 9.
*>
 01  line-e.
     03  filler          pic x(46)       value spaces.
     03  le-a            pic x(12).
     03  le-code         pic x(6)        value spaces.
     03  le-b            pic x(8)        value spaces.
     03  le-amount       pic z(6)9.99cr.
     03  filler          pic x(2)        value spaces.
     03  le-c            pic x(9).
     03  le-vat          pic 9.
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
 01  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 init01 section.
     move     Print-Spool-Name to PSN.
     move     prog-name to l1-version.
     perform  3 times
              add  1 to a
              initialize Total-Group (a)
*>              move zeros to total-gds (a)     total-car (a)
*>              move zeros to total-vat (a)     total-grs (a)
*>              move zeros to total-ded (a)     total-net (a)
*>              move zeros to total-cvat (a, 1) total-cvat (a, 2)
*>                            total-cvat (a, 3) total-cvat (a, 4)
*>                            total-cvat (a, 5) total-dis (a)
     end-perform
*>
     perform  zz070-Convert-Date.
     move     ws-date to l1-date.
*>
 menu-return.
*>**********
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Invoice Proof Report" at 0132  with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
     if       file-status (16) = zero
              display SL120 at 0501 with foreground-color 4
              accept ws-reply at 0563 with foreground-color 6
              goback.
*>
     open     input  sales-file.
     open     output print-file.
*>
     move     zero  to  j.
     perform  headings-1.
*>
     open     input  invoice-file.
*>
 loop.
*>***
*>
     read     invoice-file  next record  at end
              go to  main-end.
*>
     move     invoice-record  to sinvoice-header.
*>
     if       sih-test not = zero			*> Headers only
              go to  loop.
*>
*> trap transactions which are already on the sales ledger & OTM file.
*>
     if       sapplied
              go to loop.

     if       sih-type = 4   				*> Proformas
              go to  loop.
*>
*> if here set test-invoice back to zero.
*>
     move     zero to l.
*>
     move     sih-customer to sales-key  l5-cust.
*>
     move     space to ws-reply.
     read     sales-file  record invalid key
              move "X" to ws-reply.
*>
     if       ws-reply = "X"
              move "!! Customer Unknown" to l5-name
              move 1 to ws-error
     else
              move sales-name  to  l5-name.
*>
     move     sih-invoice  to  l5-nos.
*>
     move     sih-date  to  u-bin.
     perform  zz060-Convert-Date.
*>
     move     ws-date  to  l5-date.
*>
     move     sih-deduct-amt to ws-deduct-amt.
     move     sih-deduct-vat to ws-deduct-vat.
*>
     if       sih-type = 3                		*> Cr. Note
              multiply  -1  by  sih-net
              multiply  -1  by  sih-extra
              multiply  -1  by  sih-carriage
              multiply  -1  by  sih-vat
              multiply  -1  by  sih-c-vat
              multiply  -1  by  sih-e-vat
              multiply  -1  by  sih-discount
              multiply  -1  by  ws-deduct-amt
              multiply  -1  by  ws-deduct-vat.
*>
     if       ws-deduct-amt = zero
              move  spaces  to  lb-a  lb-code
              move  zero    to  lb-amount
     else
              move  "Late Charge "  to  lb-a
              move  spaces          to  lb-code
              move  ws-deduct-amt   to  lb-amount.
*>
     if       sih-discount = zero
              move  spaces  to  lc-a  lc-code  lc-c
              move  zero    to  lc-amount  lc-vat
     else
              move  "Discount    "  to lc-a
              move  spaces          to lc-code  lc-c
              move  sih-discount    to lc-amount
              move  zero            to lc-vat.
*>
     if       sih-carriage = zero
              move  spaces  to  ld-a  ld-code  ld-c
              move  zero    to  ld-amount  ld-vat
     else
              move  "Carriage    "  to  ld-a
              move  spaces          to  ld-code  ld-c
              move  sih-carriage    to  ld-amount
              if    sih-c-vat = zero
                    move  zero  to  ld-vat
              else
                    move  1  to  ld-vat.
*>
     if       sih-extra = zero
              move  spaces  to  le-a  le-code  le-c
              move  zero    to  le-amount  le-vat
     else
              move  extra-desc to  le-a
              move  spaces     to  le-code
              move  sih-extra  to  le-amount
              if    sih-e-vat = zero
                    move  zero to  le-vat
              else
                    move  1  to  le-vat.
*>
     move     2 to a.
*>
     if       sih-type = 1
              move  "Receipt"  to  l5-type
              move 1 to a
     else
              if    sih-type = 2
                    move  "Invoice"  to  l5-type
              else
                    move 3 to a
                    move  "Cr. Note" to  l5-type.
*>
     add      sih-c-vat sih-e-vat to total-cvat (a, 1).
*>
     move     sih-net  to  l5-goods.
     add      sih-vat  sih-c-vat  sih-e-vat  ws-deduct-vat giving  l5-vat.
     add      sih-net  sih-extra  sih-carriage  sih-discount ws-deduct-amt giving  l5-net.
     add      sih-vat  sih-c-vat  sih-e-vat  ws-deduct-vat
              sih-net  sih-extra  sih-carriage  sih-discount ws-deduct-amt giving  l5-gross.
*>
     add      sih-net  to  total-gds (a).
     add      sih-discount  sih-extra  to  total-dis (a).
     add      ws-deduct-amt to total-ded (a).
     add      sih-carriage  to  total-car (a).
     add      sih-vat  sih-c-vat  sih-e-vat  ws-deduct-vat to  total-vat (a).
     add      sih-net  sih-extra  sih-carriage  sih-discount ws-deduct-amt to  total-net (a).
     add      sih-vat  sih-c-vat  sih-e-vat  ws-deduct-vat
              sih-net  sih-extra  sih-carriage  sih-discount
              ws-deduct-amt to  total-grs (a).
*>
     if       line-cnt > Page-Lines - 2
              perform headings-1.
*>
     write    print-record from line-5 after 2.
     add      2 to line-cnt.
*>
     move     "Y"  to  first-time.
     move     zero to fs-Reply.
     perform  analysis-print  sih-lines times.
     perform  extra-analysis.
     go       to loop.
*>
 main-end.
*>*******
*>
     close    sales-file.
     close    invoice-file.
*>
     if       line-cnt < Page-Lines - 16
              move spaces to print-record
              write print-record after 3
     else
              perform  main12
     end-if
     write    print-record from line-7 after 2.
     move     spaces to print-record.
     write    print-record after 1.
     move     zero to a.
     perform  3 times
              add   1 to a
              move  total-gds (a) to  l6-goods
              move  total-dis (a) to  l6-disc
              move  total-car (a) to  l6-carr
              move  total-net (a) to  l6-net
              move  total-vat (a) to  l6-vat
              move  total-grs (a) to  l6-gross
              move  total-ded (a) to  l6-ded
              move  ws-lit (a)    to  l6-lit
              write print-record from line-6 after 1
     end-perform
*>
     if       sales-missing                                                   *> Should never happen but ...
              move "Warning Record/s Missing In Sales File" to print-record
              write print-record after 2.
*>
     write    print-record from line-9 after 2.
     move     spaces to print-record.
     write    print-record after 1.
     move     zero to i.		*> moved from within the perform above
     perform  3 times
              add   1 to i
              move  i to l8-vat-code
              move  vat-rate (i) to l8-vat-rate
              move  total-cvat (1, i) to l8-amount1
              move  total-cvat (2, i) to l8-amount2
              move  total-cvat (3, i) to l8-amount3
              write print-record from line-8 after 1
     end-perform
     if       Vat-Rate (4) not = zero		*> test if local tax in use & print if so
         or   Vat-Rate (5) not = zero		*> Not used in the UK (so far)
              perform  2 times
                       add   1 to i
                       move  i to l8-vat-code
                       move  vat-rate (i) to l8-vat-rate
                       move  total-cvat (1, i) to l8-amount1
                       move  total-cvat (2, i) to l8-amount2
                       move  total-cvat (3, i) to l8-amount3
                       write print-record from line-8 after 1
              end-perform
     end-if
     close    print-file.
     call     "SYSTEM" using Print-Report.
*>
 menu-call.
*>********
*>
     exit     program.
*>
 headings-1 section.
*>*****************
*>
 main12.
*>
     add      1  to  j.
     move     j  to  l3-page.
*>
     move     usera  to  l3-user.
     if       j not = 1
              write print-record from line-1 after page
     else
              write print-record from line-1 after 1.
     write    print-record from line-2 after 1.
*>
 cont-hds.
*>
     write    print-record from line-4 after 2.
     move     spaces  to  print-record.
     write    print-record after 1.
     move     5 to line-cnt.
*>
 analysis-print          section.
*>==============================
*>
     if       fs-reply = 99			*> Just in case
              go to Main-Exit.
     read     invoice-file  next record at end
              move 99 to fs-Reply		*> Just in case
              go to Main-Exit.
*>
     move     invoice-record  to  invoice-line (1).
*>
     move     sil-product (1)  to  test-product.
     if       il-comment
              go to  main-exit.
*>
     if       sih-type = 3			*> credit notes
              multiply -1 by sil-net (1)
              multiply -1 by sil-vat (1).
*>
     move     sil-pa (1)  to la-code.
     move     sil-net (1) to la-amount.
     move     sil-vat-code (1) to la-vat k.
     if       k > zero
              add sil-vat (1) to total-cvat (a, k).
*>
     if       first-time = "Y"
              move  "Analysis" to la-a
              move  "Value"    to la-b
              move  "Vat Code" to la-c
              move  "N"        to first-time
     else
              move  spaces     to la-a  la-b  la-c.
*>
     write    print-record from line-a after 1.
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform headings-1.
*>
 main-exit.   exit section.
*>********    ****
*>
 extra-analysis          section.
*>==============================
*>
     if       line-cnt > Page-Lines - 4
              perform headings-1.
*>
     if       lb-a  not equal  spaces
              write  print-record  from  line-b after 1
              add 1 to line-cnt
              move  spaces  to  lb-a.
*>
     if       lc-a  not equal  spaces
              write  print-record  from  line-c after 1
              add 1 to line-cnt
              move  spaces  to  lc-a.
*>
     if       ld-a  not equal  spaces
              write  print-record  from  line-d after 1
              add 1 to line-cnt
              move  spaces  to  ld-a.
*>
     if       le-a  not equal  spaces
              write  print-record  from  line-e after 1
              add 1 to line-cnt
              move  spaces  to  le-a.
*>
 main-exit.   exit section.
*>********    ****
*>
 zz050-Validate-Date        section.
*>*********************************
*>
*>  Converts USA/Intl to UK date format for processing.
*>****************************************************
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
