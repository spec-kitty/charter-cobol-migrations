       >>source free
*>********************************************************
*>                                                       *
*>              Invoice  Maintenance (Amend)             *
*>                                                       *
*>********************************************************
*>
 identification          division.
*>===============================
*>
      program-id.         sl920.
*>**
*>    Author.             Cis Cobol Conversion By V B Coen, FBCS 17/12/83
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Invoice Maintenance.
*>                        ON CR CHECKS SL920 USES THE INVOICE FILE BUT SL910 USES OTM3 WHY? 25/05/13
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps04.
*>                        Maps99.
*>                        SL070. Analysis codes set up - Defaults only.
*>**
*>    Error messages used.
*>                        SL006
*>                        SL180
*>                        SL184
*>                        SL186
*>                        SL190
*>                        SL191
*>                        SL192
*>                        SL194
*>                        SL195
*>                        SL193
*>                        SL196
*>****
*>  Changes.
*> 04/03/83 Vbc - Changes To Fdinv.Cob And Cr-Notes.
*> 22/03/83 Vbc - Cr-Notes.
*> 30/03/83 Vbc - When Creating Invoices Check For Sl-Charges &
*>                Sales-Late (Late-Charges).
*> 30/04/83 Sjw - Accept Late Charges Only If Invoice Ws-Named On
*>                Cr. Notes.
*> 02/05/83 Vbc - #.
*> 17/12/83 Vbc - Cis Cobol Conversion.
*> 18/01/84 Vbc - Fix Bugs In Delete Line & Record Routines.
*> 01/03/84 Vbc - Support Sales-Unapplied In Invoice-Details.
*> 10/03/84 Vbc - Scrap  Accept Of sih-Deduct-Vat(=0).
*> 16/11/84 Vbc - Fix Abort Graphic Screen In Invoice-Details.
*> 07/01/85 Vbc - Fix Bug Clear Screen In Cr-Notes.
*> 03/03/09 vbc - .02 Migration to Open Cobol v3.00.00.
*> 18/03/09 vbc - ,03 Bug/Feature 30.1 & 3 Escape out at any level.
*> 19/03/09 vbc - .04 Feature 30.5 Allow receipts to be amended if not posted.
*> 26/11/11 vbc - .05 Error msgs to SLnnn.Support for dates other than UK
*> 08/12/11 vbc - .06 Support for path+filenames.
*> 09/12/11 vbc -     Updated version to 3.01.nn, added support for IS delivery file
*> 11/12/11 vbc - .07 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 24/05/13 vbc - .08 Add in support for direct link to Stock Control with Stock and Audit files
*>                    in inv-level-2. Changed stk code 12>13, desc 24>32 removing pa code
*>                    & consider add new display field OS for Out of Stock but on order
*>                    with delivery expected in 7 days or less.
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
*>
 input-output            section.
*>------------------------------
*>
 file-control.
*>-----------
*>
 copy "selanal.cob".
 copy "selsl.cob".
 copy "selinv.cob".
 copy "seldel.cob".
*>
 copy "selstock.cob".	     *> Stock link
 copy "selaud.cob".          *> Stock audit
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdanal.cob".
 copy "fdsl.cob".
 copy "fdinv.cob".
 copy "fddel.cob".
*>
 copy "fdstock.cob".          *> Stock link
 copy "fdaudit.cob".          *> Stock audit
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "SL920 (3.01.08)".
 77  exception-msg       pic x(25) value spaces.
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
*>
 01  ws-amount-screen-display6.
     03  ws-poundsd6     pic 9(6).
     03  ws-period6      pic x     value ".".
     03  ws-penced6      pic v99.
 01  ws-amount-screen-accept6 redefines ws-amount-screen-display6.
     03  ws-pound6       pic 9(6).
     03  filler          pic x.
     03  ws-pence6       pic v99.
*>
 01  ws-amount-work6.
     03  amt-wk-pds6     pic 9(6).
     03  amt-wk-pence6   pic v99.
 01  ws-amount-ok6 redefines ws-amount-work6.
     03  amt-ok6         pic 9(6)v99.
*>
 01  ws-amount-screen-display7.
     03  ws-poundsd7     pic 9(7).
     03  ws-period7      pic x     value ".".
     03  ws-penced7      pic v99.
 01  ws-amount-screen-accept7 redefines ws-amount-screen-display7.
     03  ws-pound7       pic 9(7).
     03  filler          pic x.
     03  ws-pence7       pic v99.
*>
 01  ws-amount-work7.
     03  amt-wk-pds7     pic 9(7).
     03  amt-wk-pence7   pic v99.
 01  ws-amount-ok7 redefines ws-amount-work7.
     03  amt-ok7         pic 9(7)v99.
*>
 01  ws-discount-display.
     03  ws-disca1       pic 99.
     03  ws-disca2       pic x        value ".".
     03  ws-disca3       pic v99.
 01  ws-discount-accept redefines ws-discount-display.
     03  ws-discb1       pic 99.
     03  filler          pic x.
     03  ws-discb3       pic v99.
 01  ws-discount-work.
     03  ws-disc-wka     pic 99.
     03  ws-disc-wkb     pic v99.
 01  ws-discount redefines ws-discount-work  pic 99v99.
*>
 copy "wsinv.cob".
 01  ws-data.
     03  test-product.
         05  filler      pic x.
             88  sil-comment           value "/".
         05  filler      pic x(12).
     03  menu-reply      pic 9.
     03  ws-reply        pic x.
     03  z               pic 99.
     03  c-check         pic 9.
         88  c-exists                value  1.
     03  ws-delinv       pic 9       value zero.
         88  del-exists              value 1.
     03  address-A       pic x(96).
     03  address-line.
         05 add-line1    pic x(15).
         05 add-line2    pic x(21).
     03  ws-named        pic x           value " ".
     03  ws-dash         pic x(80)       value all "-".
     03  work-1          pic 9(7)v99.
     03  work-n          pic 9(7)v99.
     03  work-d          pic 9(7)v99.
     03  display-8       pic z(5)9.99.
     03  display-9       pic z(6)9.99.
     03  vat-code        pic 9.
     03  i               pic 99.
     03  j               pic 99.
     03  k               pic 99.
     03  m               pic 99.
     03  escape-code     pic x.
     03  new-screen      pic 9(8).
     03  altypes         pic x(60) value "Receipt <<<    Account <<<    Credit Note <<<Pro-Forma <<<".
     03  filler redefines altypes.
         05 d-types      pic x(15) occurs 4.
     03  ws-vat-rate     pic 99v99.
     03  ws-pa           pic xx.
     03  ws-product      pic x(13).
     03  ws-Stock-Key                    value spaces.
         05  ws-Abrev-Stock   pic x(7).
         05  ws-Stock-No-Long pic x(6).
     03  ws-description  pic x(32).
     03  ws-qty          pic 9(5).
     03  ws-net          pic 9(7)v99.
     03  ws-vat          pic 9(7)v99.
     03  ws-unit         pic 9(6)v99.
     03  ws-cr           pic 9(8).
     03  ws-dayes        pic 99.
     03  ws-Show-Delivery pic 9.
*>
     03  ws-Old-Product  pic x(13).     *> These hold line items prior to changes
     03  ws-Old-Qty      pic 9(5).	*> and new are tested against them for any changes & if needed
*>                                         the CIT tables are updated.
     03  ws-Old-Desc     pic x(32).	*> NOT USED
*>
     03  ws-env-lines    pic 999       value zero.
     03  ws-lines        binary-char unsigned value zero.
     03  ws-accept-body  binary-char unsigned value 8.         *> set for 24 line screen (-1)
     03  ws-23-lines     binary-char unsigned value zero.
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
 01  Change-Item-Tables.			*> Initialised on 1st getting a invoice/receipt/Cr
     03  CIT-New-Product     pic 9.	*> 0 = no & 1 yes
     03  Tab-A               pic 99.
     03  Tab-D               pic 99.
     03  CIT-Additions       occurs 40.		*> items deleted from invoice (or quantity changed ??)
         05  CIT-A-Stock-Key pic x(13).
         05  CIT-A-Desc      pic x(32).
         05  CIT-A-Trans-Qty pic s9(6).		*> if negative then qty was incresed
     03  CIT-A               pic 99.		*> index for above table
*>
     03  CIT-Deletions       occurs 40.		*> items added to invoice
         05  CIT-D-Stock-Key pic x(13).
         05  CIT-D-Desc      pic x(32).
         05  CIT-D-Trans-Qty pic s9(6).
     03  CIT-D               pic 99.		*> index for above table
*>
 01  Error-Messages.
*> System Wide
*>     03  SL003          pic x(28) value "SL003 Hit Return To Continue".
     03  SL006          pic x(43) value "SL006 Note Details & Hit Return to continue".

*> Module specific
     03  SL180          pic x(34) value "SL180 Err on Invoice file write : ".
     03  SL184          pic x(75) value "SL184 You Can Only Credit Invoices. Not Receipts, Credit Notes Or Proformas".
     03  SL186          pic x(30) value "SL186 P.A. Code Does Not Exist".
     03  SL190          pic x(36) value "SL190 Error on Writing to Audit File".
     03  SL191          pic x(33) value "SL191 Error on Stock file Rewrite".
     03  SL192          pic x(36) value "SL192 Err on Invoice file rewrite : ".
     03  SL193          pic x(54) value "SL193 Invoice To Credit Does Not Exist On Invoice File".
     03  SL194          pic x(27) value "SL194 Invoice Not Found!!!!".
     03  SL195          pic x(53) value "SL195 Invoice Details Already Passed To Sales Ledger!".
     03  SL196          pic x(65) value "SL196 You Can Only Credit An Invoice With The Same Account Number".
*>
 01  error-code          pic 999.
*>
 01  delete-test.
     03  delete-field    pic xx.
     03  filler          pic x(11).
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
*>*************
*>
     accept   ws-env-lines   from lines.
     if       ws-env-lines < 24
              move  24 to ws-env-lines ws-lines
     else
              move  ws-env-lines   to ws-lines
     end-if
     subtract 1 from ws-lines giving ws-23-lines.
     subtract 15 from ws-23-Lines giving ws-Accept-Body.	*> gives no. of invoice item lines
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     perform  zz070-Convert-Date.   *> ws-date now local disp date
*>
*>  Open files and check & setup if we have any deleted invoices
*>
     perform  program-start.
*>
 main.
*>***
*>
     initialize sInvoice-Bodies
                Change-Item-Tables.
     perform  invoice-details.
*>
     if       cob-crt-status = cob-scr-esc
       or     z not = zero
       or     escape-code = "Q"
              go to  menu-exit.
*>
     move     16  to  lin.
     perform  erase-screen.
*>
 data-input.
*>*********
*>
     move     zero to   sih-p-c sih-net sih-vat.
*>
     move     zero to  i.
*>
     if       i-level-1
              perform  inv-level-1
     else
              perform  inv-level-2.
     if       cob-crt-status = cob-scr-esc
              go to main.
*>
     if       i not = 1
              perform end-totals.
*>
 more-data.
*>
     display "Amend Further Invoices? (Y/N)  [Y]" at 1629 with foreground-color 2.
*>
     move     "Y"  to   ws-reply.
     accept   ws-reply at 1661 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     display  " " at 1601 with erase eol.
*>
     if       ws-reply = "Y"
              go to main.
     if       ws-reply not = "N"
              go to more-data.
*>
 menu-exit.			*> Moved from program-start, silly place to have it
*>********
*>
     move     zero to  pass-value.
     close    sales-file
              delivery-file.
     close    analysis-file
              invoice-file.
     if       SL-Stock-Link = "Y"
              close Stock-File
                    Stock-Audit.
*>
     exit     program.
*>
*>****************************************************************
*>                  P R O C E D U R E S                          *
*>****************************************************************
*>
 running-totals          section.
*>==============================
*>
     move     zero  to  sih-net
                        sih-vat.
*>
     perform  varying k from 1 by 1 until k > i
              if  sil-type (k) not = "D"
                  add sil-net (k)  to  sih-net
                  add sil-vat (k) to  sih-vat
     end-perform
*>
     move     sih-net  to  display-9.
     if       i-level-1
              display display-9 at 1237 with foreground-color 3.
*>
     move     sih-vat  to  display-9.
     if       i-level-1
              display display-9 at 1255 with foreground-color 3.
*>
     add      sih-net  sih-vat  giving  display-9.
*>
     if       i-level-1
              display display-9 at 1268 with foreground-color 3
     else
              display display-9 at 1270 with foreground-color 3.
*>
 main-exit.   exit section.
*>********    ****
*>
 write-details           section.
*>==============================
*>
     add      1  to  j.
     move     sih-invoice       to sil-invoice (j).
     move     j                 to sil-line (j).
     move     sih-letter        to sil-letter (j).
     move     sih-type          to sil-type (j).
     move     invoice-line (j)  to invoice-record.
*>
     rewrite  invoice-record invalid key		*> could be extra item
              write invoice-record.
*>
     if       fs-reply not = zero
              perform Eval-Status
              display sl180         at line ws-23-lines col 1 with erase eol foreground-color 4
              display fs-reply      at line ws-23-lines col 36 with foreground-color 3
              display exception-msg at line ws-23-lines col 39 with foreground-color 3
              display invoice-key   at line ws-23-lines col 64 with foreground-color 3
              display sl006         at line ws-lines col 01 with foreground-color 3
              accept  ws-reply      at line ws-lines col 30
              display " "           at line ws-23-lines col 1 with erase eos.
*>
 main-exit.   exit section.
*>********    ****
*>
 Update-Stock-and-Audit section.	*> This is NOT the same as in SL910 as
*>=============================		    it uses the CIT-A/D tables after writing out the updated invoice
*>
*> normal for Receipts(1) and Invoices (2) but reverse process for Credit Notes (3)
*>
     if       SL-Stock-Link not = "Y"		*> Only process if linked to Stock Control
              go to Update-Stock-Exit.
     if       CIT-A = zero			*> If both tables are empty, then exit
       and    CIT-D = zero
              go to Update-Stock-Exit.
*>
     initialize Stock-Audit-Record.
     perform  varying Tab-A from 1 by 1 until Tab-A > CIT-A
              move 3                       to Audit-Type
              move Sih-Invoice             to Audit-Invoice-PO
              move ws-Date                 to Audit-Process-Date
              move CIT-A-Stock-Key (Tab-A) to Audit-Stock-Key
                                              ws-Stock-Key
              move CIT-A-Desc (Tab-A)      to Audit-Desc
              if   CIT-A-Trans-Qty (Tab-A) > zero	*> Sale has decreased
                   move CIT-A-Trans-Qty (Tab-A) to Audit-Transaction-Qty
                   move 1                  to Audit-Reverse-Transaction
              else
               if  CIT-A-Trans-Qty (Tab-A) < zero	*> sale has increased
                   multiply CIT-A-Trans-Qty (Tab-A) by -1 giving
                                             Audit-Transaction-Qty
               end-if
              end-if
              if   Sil-Type (j) = 3	*> for Cr's, switch the reverse flag
                if Audit-Reverse-Transaction = zero
                   move 1      to Audit-Reverse-Transaction
                   move 5      to Audit-Type
                   move Sih-cr to Audit-Cr-for-Invoice
                else
                   move zero to Audit-Reverse-Transaction
                end-if
              end-if
              move Stk-Audit-No           to Audit-No
*>
*> Now get the stock record
*>
              if   ws-Stock-No-Long = spaces
                   move ws-Abrev-Stock to Stock-Abrev-Key
                   read Stock-File record key Stock-Abrev-Key invalid key
                        move zero to Stock-Cost
                        move spaces to Stock-Key
                   end-read
              else
                   move ws-Stock-Key to Stock-Key
                   read Stock-File key Stock-Key invalid key
                        move zero to Stock-Cost
                        move spaces to Stock-Key
                   end-read
              end-if
              if   fs-reply not = zero
                   perform Eval-Status
                   display "Stock Read : " at line ws-23-lines col 1 with erase eol foreground-color 4
                   display fs-reply        at line ws-23-lines col 16 with foreground-color 3
                   display exception-msg   at line ws-23-lines col 19 with foreground-color 3
                   display Stock-key       at 2064 with foreground-color 3
                   display sl006           at line ws-lines col 01 with foreground-color 3
                   accept  ws-reply        at line ws-lines col 30
                   display " "             at line ws-23-lines col 1 with erase eos
              end-if
*>
*> If we have great, but if not Stock-Cost is zero which helps it show up in proof reports
*>
              if   Stock-Key not = spaces		*> we have a stock rec.
                   if    Sil-Type (j) not = 3	*> Its not a Credit note
                    if   CIT-A-Trans-Qty (Tab-A) > zero	*> Sale has decreased
                         add CIT-A-Trans-Qty (Tab-A) to Stock-Held
                         compute  Audit-Stock-Value-Change = Audit-Transaction-Qty * Stock-Cost
                    else
                     if  CIT-A-Trans-Qty (Tab-A) < zero	*> sale has increased
                         subtract CIT-A-Trans-Qty (Tab-A) from Stock-Held
                         compute  Audit-Stock-Value-Change = Audit-Transaction-Qty * Stock-Cost * -1
                     end-if
                    end-if
                   end-if
                   if    Sil-Type (j) = 3		*> It is a Credit note
                    if   CIT-A-Trans-Qty (Tab-A) < zero	*> Sale has Increased
                         add CIT-A-Trans-Qty (Tab-A) to Stock-Held
                         compute  Audit-Stock-Value-Change = Audit-Transaction-Qty * Stock-Cost
                    else
                     if  CIT-A-Trans-Qty (Tab-A) > zero	*> sale has Decreased
                         subtract CIT-A-Trans-Qty (Tab-A) from Stock-Held
                         compute  Audit-Stock-Value-Change = Audit-Transaction-Qty * Stock-Cost * -1
                    end-if
                    end-if
                   end-if
*>
                   if       Stock-Held < zero		*> Should NOT happen as testing in data entry but if a Cr?
                            multiply -1 by Stock-Held
                            add Stock-Held to Stock-Pre-Sales
                            move zero to Stock-Held
                   end-if
                   if       Stock-Held > zero
                            multiply Stock-Held by Stock-Cost giving Stock-Value
                   else
                            move zero to Stock-Value
                   end-if
                   rewrite  Stock-Record invalid key
                            display SL191    at line ws-23-lines col 1 with foreground-color 4 highlight erase eol
                            display fs-reply at line ws-23-lines col 38 with foreground-color 2 highlight
                            display SL006    at line ws-lines col 1
                            accept ws-reply  at line ws-lines col 45
                   end-rewrite
                   if       fs-reply not = zero
                            perform Eval-Status
                            display "Stock Rewrite : " at line ws-23-lines col 1 with erase eol foreground-color 4
                            display fs-reply           at line ws-23-lines col 16 with foreground-color 3
                            display exception-msg      at line ws-23-lines col 19 with foreground-color 3
                            display Stock-key          at 2064 with foreground-color 3
                            display sl006              at line ws-lines col 01 with foreground-color 3
                            accept  ws-reply           at line ws-lines col 30
                            display " "                at line ws-23-lines col 1 with erase eos
                   end-if
              end-if
*>
              if   Stk-Audit-Used = 1
                   move zero to Stk-Activity-Rep-Run		*> Need to run audit report
                   write Stock-Audit-Record
                   if      fs-reply not = zero
                           perform Eval-Status
                           display SL190         at line ws-23-lines col 1 with foreground-color 4 highlight erase eol
                           display fs-reply      at line ws-23-lines col 38 with foreground-color 2 highlight
                           display exception-msg at line ws-23-lines col 41 with foreground-color 3
                           display SL006         at line ws-lines col 1
                           accept ws-reply       at line ws-lines col 45
                   end-if
              end-if
     end-perform.
*>
*> Now we have processed Table CIT-A we have to do it all again for CIT-D
*>  and No, it is too complex to try and do it all in one (higher risk of bugs)
*>
     perform  varying Tab-D from 1 by 1 until Tab-D > CIT-D
              move 3                       to Audit-Type
              move Sih-Invoice             to Audit-Invoice-PO
              move ws-Date                 to Audit-Process-Date
              move CIT-D-Stock-Key (Tab-D) to Audit-Stock-Key
                                              ws-Stock-Key
              move CIT-D-Desc (Tab-D)      to Audit-Desc
              if   CIT-D-Trans-Qty (Tab-D) > zero		*> Sale has increased
                   move CIT-D-Trans-Qty (Tab-D) to Audit-Transaction-Qty
              end-if
              if   Sil-Type (j) = 3	*> for Cr's, switch the reverse flag
                if Audit-Reverse-Transaction = zero
                   move 1 to Audit-Reverse-Transaction
                   move 5      to Audit-Type
                   move Sih-cr to Audit-Cr-for-Invoice
                else
                   move zero to Audit-Reverse-Transaction
                end-if
              end-if
              move Stk-Audit-No           to Audit-No
*>
*> Now get the stock record
*>
              if   ws-Stock-No-Long = spaces
                   move ws-Abrev-Stock to Stock-Abrev-Key
                   read Stock-File record key Stock-Abrev-Key invalid key
                        move zero to Stock-Cost
                        move spaces to Stock-Key
                   end-read
              else
                   move ws-Stock-Key to Stock-Key
                   read Stock-File key Stock-Key invalid key
                        move zero to Stock-Cost
                        move spaces to Stock-Key
                   end-read
              end-if
              if   fs-reply not = zero
                   perform Eval-Status
                   display "Stock Read : " at line ws-23-lines col 1 with erase eol foreground-color 4
                   display fs-reply        at line ws-23-lines col 16 with foreground-color 3
                   display exception-msg   at line ws-23-lines col 19 with foreground-color 3
                   display Stock-key       at 2064 with foreground-color 3
                   display sl006           at line ws-lines col 01 with foreground-color 3
                   accept  ws-reply        at line ws-lines col 30
                   display " "             at line ws-23-lines col 1 with erase eos
              end-if
*>
*> If we have great, but if not Stock-Cost is zero which helps it show up in proof reports
*>
              if   Stock-Key not = spaces		*> we have a stock rec.
                   if    Sil-Type (j) not = 3	*> Its not a Credit note
                         add CIT-D-Trans-Qty (Tab-D) to Stock-Held
                         compute  Audit-Stock-Value-Change = Audit-Transaction-Qty * Stock-Cost
                   end-if		*> CIT-D is NEW items so not on CR's.
                   if    Sil-Type (j) = 3		*> It is a Credit note
                         subtract CIT-D-Trans-Qty (Tab-D) from Stock-Held
                         compute  Audit-Stock-Value-Change = Audit-Transaction-Qty * Stock-Cost * -1
                   end-if
*>
                   if       Stock-Held < zero		*> Should NOT happen as testing in data entry but if a Cr?
                            multiply -1 by Stock-Held
                            add Stock-Held to Stock-Pre-Sales
                            move zero to Stock-Held
                   end-if
                   if       Stock-Held > zero
                            multiply Stock-Held by Stock-Cost giving Stock-Value
                   else
                            move zero to Stock-Value
                   end-if
                   rewrite  Stock-Record invalid key
                            display SL191    at line ws-23-lines col 1 with foreground-color 4 highlight erase eol
                            display fs-reply at line ws-23-lines col 38 with foreground-color 2 highlight
                            display SL006    at line ws-lines col 1
                            accept ws-reply  at line ws-lines col 45
                   end-rewrite
                   if       fs-reply not = zero
                            perform Eval-Status
                            display "Stock Rewrite : " at line ws-23-lines col 1 with erase eol foreground-color 4
                            display fs-reply           at line ws-23-lines col 16 with foreground-color 3
                            display exception-msg      at line ws-23-lines col 19 with foreground-color 3
                            display Stock-key          at 2064 with foreground-color 3
                            display sl006              at line ws-lines col 01 with foreground-color 3
                            accept  ws-reply           at line ws-lines col 30
                            display " "                at line ws-23-lines col 1 with erase eos
                   end-if
              end-if
*>
              if   Stk-Audit-Used = 1
                   move zero to Stk-Activity-Rep-Run		*> Need to run audit report
                   write Stock-Audit-Record
                   if      fs-reply not = zero
                           perform Eval-Status
                           display SL190         at line ws-23-lines col 1 with foreground-color 4 highlight erase eol
                           display fs-reply      at line ws-23-lines col 38 with foreground-color 2 highlight
                           display exception-msg at line ws-23-lines col 41 with foreground-color 3
                           display SL006         at line ws-lines col 1
                           accept ws-reply       at line ws-lines col 45
                   end-if
              end-if
     end-perform.
*>
 Update-Stock-Exit.
     exit     section.
*>
 Eval-Status        section.
*>=========================
*>
     move     spaces to exception-msg.
 copy "FileStat-Msgs.cpy"  replacing STATUS by fs-reply
                                     msg    by exception-msg.
*>
 main-exit.   exit section.
*>
 read-details  section.
*>====================
*>
     move     zero to j.
     perform  sih-lines times
              add  1 to j
              move sih-invoice to invoice-nos
              move j to item-nos
              move sih-letter to invoice-let
              read invoice-file
              end-read
              move invoice-record to invoice-line (j)
     end-perform.
*>
 main-exit.   exit section.
*>********    ****
*>
 net-compute             section.
*>==============================
*>
     multiply work-n  by  work-d  giving  work-1.
     divide   work-1  by  100     giving  work-1.
*>
 main-exit.   exit section.
*>********    ****
*>
 comm-routines section.
*>********************
*>
 accept-money6a.
*>-------------
*>
     move     zero to ws-poundsd6 ws-penced6 amt-ok6.
*>
 accept-money6b.
*>-------------
*>
     display  ws-amount-screen-display6 at curs  with foreground-color 3.
     accept   ws-amount-screen-accept6  at curs   with foreground-color 3 update.
     move     ws-pound6 to amt-wk-pds6.
     move     ws-pence6 to amt-wk-pence6.
*>
 accept-money6c.
*>-------------
*>
     move     amt-wk-pence6 to ws-pence6.
     move     amt-wk-pds6 to ws-pound6.
     display  ws-amount-screen-display6 at curs  with foreground-color 3.
     accept   ws-amount-screen-accept6  at curs   with foreground-color 3 update.
     move     ws-pound6 to amt-wk-pds6.
     move     ws-pence6 to amt-wk-pence6.
*>
 accept-money7a.
*>-------------
*>
     move     zero to ws-poundsd7 ws-penced7 amt-ok7.
*>
 accept-money7b.
*>-------------
*>
     display  ws-amount-screen-display7 at curs with foreground-color 3.
     accept   ws-amount-screen-accept7  at curs  with foreground-color 3 update.
     move     ws-pound7 to amt-wk-pds7.
     move     ws-pence7 to amt-wk-pence7.
*>
 accept-money7c.
*>-------------
*>
     move     amt-wk-pence7 to ws-pence7.
     move     amt-wk-pds7 to ws-pound7.
     display  ws-amount-screen-display7 at curs with foreground-color 3.
     accept   ws-amount-screen-accept7  at curs  with foreground-color 3 update.
     move     ws-pound7 to amt-wk-pds7.
     move     ws-pence7 to amt-wk-pence7.
*>
 comm-exit.   exit.
*>--------    ----
*>
 inv-level-1  section.		*> No one should be using this consider scrapping and forcing invoicer =2 etc
*>===================
*>
     display  ws-dash        at 1101 with foreground-color 2.
     display  "Level 1"      at 1201 with foreground-color 2.
     display  "Line - "      at 1216 with foreground-color 2.
     display  "<          >" at 1236 with foreground-color 2.
     display  "<          >" at 1254 with foreground-color 2.
     display  "<          >" at 1267 with foreground-color 2.
     display  "Code"         at 1405 with foreground-color 2.
     display  "<---Net---->  Vat   Vat Amount  Gross Amount" at 1436 with foreground-color 2.
*>
 loop.
*>***
*>
     perform  display-outline-1 varying lin from 16 by 1 until lin not < ws-23-lines.
*>
*>     subtract 16 from ws-23-lines giving m.   *> 24 line screen
     subtract ws-Accept-Body from  i.		*> was m from i
     move     1 to j.
     display  i at 1223 with foreground-color 2.
     move     zero to cob-crt-status.   *> from sl910
     perform  get-data-1.
     if       cob-crt-status = cob-scr-esc
              go to main-exit.
*>
     if       new-screen = 1
              go to loop.
*>
     if       sil-description (i) not = spaces
        and   i not = 40
*>       and  escape-code not = "Q"
              go to  loop.
*>
 main-exit.   exit section.
*>********    ****
*>
 get-data-1  section.     *> No one should be using this consider scrapping and forcing invoicer =2 etc
*>==================
*>
     add      j  15  giving  lin.
     if       lin  > ws-23-lines
              subtract 1 from i
              move 1 to new-screen
              go to  main-exit.
*>
     move     zero to new-screen.
*>
 get-code.
*>*******
*>
     move     sil-pa (i) to ws-pa.
     move     7 to cole.
     display  ws-pa at curs with foreground-color 3.
     accept   ws-pa at curs with foreground-color 3 update.
*>
     if       ws-pa = spaces
              go to  main-exit.
     if       cob-crt-status = cob-scr-esc
              go to main-exit.
*>
     if       ws-pa = "<<"
         and  i = 1
              go to get-code.
*>
     if       ws-pa = "<<"
              subtract  1  from  lin
              if    lin  >  15
                    subtract  1  from  i
                    subtract 1 from j
                    go to  get-code
              else
                    subtract ws-Accept-Body from  i          *> Was 8 Need to follow logic, can we use ws-Accept-Body ??
                    go to get-data-1.
*>
     move     ws-pa to delete-test.
     if       delete-field = "**"
              perform clear-down-line
              subtract 1 from i
              perform display-outline-1
              go to get-code.
*>
     move     ws-pa to sil-pa (i) pa-group.
     move     "S" to pa-system.
     move     11 to cole.
     read     analysis-file  record  invalid key
              display SL186 at line ws-23-lines col 1 with foreground-color 4 highlight beep
              go to  get-code.
     display  " " at line ws-23-lines col 1 with erase eol.
*>
     display  pa-desc at curs with foreground-color 3.
     move     pa-desc  to  sil-description (i).
*>
 get-net.
*>******
*>
     move     37 to cole.
     move     sil-net (i) to amt-ok7.
     perform  accept-money7c.
     if       amt-ok7 = zero
              go to get-code.
     move     amt-ok7 to sil-net (i) ws-net.
*>
 get-vat-code.
*>***********
*>
     move     50 to cole.
     move     sil-vat-code (i) to vat-code.
     display  vat-code at curs with foreground-color 3.
     accept   vat-code at curs with foreground-color 3 update.
*>
     if       vat-code  >  3     *> last two are for non-UK sales tax
              go to  get-vat-code.
*>
     move     vat-code  to  sil-vat-code (i).
     if       vat-code = zero
              move  zero  to  amt-ok6
     else
              move vat-rate (vat-code) to ws-vat-rate
              compute amt-ok6 rounded = (ws-net * ws-vat-rate) / 100.
*>
 get-vat-rate.
*>***********
*>
     move     56 to cole.
     perform  accept-money6c.
     move     amt-ok6 to sil-vat (i) ws-vat.
*>
     add      ws-vat ws-net giving  display-9.
     move     68 to cole.
     display  display-9 at curs with foreground-color 3.
*>
     perform  running-totals.
*>
     add      1 to j.
     add      1  to  i.
     go       to get-data-1.
*>
 main-exit.   exit section.
*>********    ****
*>
 inv-level-2             section.
*>==============================
*>
     display  ws-dash                 at 1101 with foreground-color 2.
     if       SL-Stock-Link not = "Y"
              display  "Level 2"      at 1201 with foreground-color 2
     else
              display  "Stock Linked" at 1201 with foreground-color 2.
     display  "Line - "               at 1216 with foreground-color 2.
     display  "Net <          >"      at 1227 with foreground-color 2.
     display  "Vat <          >"      at 1244 with foreground-color 2.
     display  "Invoice <          >"  at 1261 with foreground-color 2.
     if       SL-Stock-Link = "N"		*> No stock then process PA code
              display  "Product    Code <---------Description-------->   Qty   Unit Price  Disc. Vat"
                                     at 1405 with foreground-color 2
     else
              display  "Product     <----------Description--------->    Qty   Unit Price  Disc. Vat"
                                     at 1405 with foreground-color 2.
*>
 loop.
*>***
*>
     perform  display-outline-2 varying lin from 16 by 1 until lin not < ws-23-lines.
*>
*>     subtract 16 from ws-23-lines giving m.   *>  move 1 to i
     subtract ws-Accept-Body from i.		*>  was m
     move     1  to  j.
*>
     display  i at 1223 with foreground-color 2.
*>
     perform  get-data-2.
     if       cob-crt-status = cob-scr-esc
              go to main-exit.
*>
     if       new-screen = 1
              go to  loop.
*>
     if       ws-product not = spaces
        and   i not = 40			*> max no. of items per invoice
*>       and   escape-code not = "Q"
              go to loop.
*>
 main-exit.   exit section.
*>********    ****
*>
 get-data-2              section.
*>==============================
*>
*>**********************************************************************
*>  This section will accept invoice line data if SC (stock control)   *
*>  is NOT linked in param file. If it is linked, will only request:   *
*>  Stock code or if entered chars = 7 or less, Abrev code so can      *
*>  search same if using F3 to find 1st then using F2 for next record. *
*>  in place of the return key.                                        *
*>  Also will allow search on description using F6 in stock code entry *
*>  and then will accept a description using F5 to search 1st and for  *
*>  next records.   CHANGE TO SUIT CODE                                *
*>**********************************************************************
*>
     add      j  15  giving  lin.
     if       lin  > ws-23-lines - 1
              subtract  1  from  i
              move  1  to  new-screen
              go to  main-exit.
*>
     move     zero  to  new-screen.
*>
 get-product.
*>**********
*>
     move     2 to cole.
     move     sil-product (i) to ws-product.
     display  ws-product at curs with foreground-color 3.
     accept   ws-product at curs with foreground-color 3 update.
*>
     if       ws-product = spaces
              go to main-exit.
     if       cob-crt-status = cob-scr-esc
              go to main-exit.
*>
     move     function upper-case (ws-product) to ws-product.
     move     ws-product to test-product.
     add      1 to CIT-A.			*> items deleted from an invoice or qty changed
*>
     if       ws-product = sil-Product (i)		*> No Change
      if      SL-Stock-Link = "N"			*> so forget table
              subtract 1 from CIT-A
              go to Get-Code
      else						*> SAME Stock Item
              move  zero to CIT-New-Product
              move ws-product          to CIT-A-Stock-Key (CIT-A)
              move sil-Description (i) to CIT-A-Desc (CIT-A)
              move sil-Qty (i)         to CIT-A-Trans-Qty (CIT-A)
              go to Get-Qty				*> Desc does not change against product
      end-if
     end-if
*>
     if       sil-comment
              move ws-product to sil-product (i)
              move zero to sil-net (i) sil-qty (i) sil-vat (i)
              go to  get-desc.
*>
     if       ws-product = "<<          "
              subtract  1  from  lin
              go to get-prod-test.
*>
*> If here we have a change of product but only interested for Audit if stock linked
*>
     if       SL-Stock-Link = "Y"			*> Save original item details in deleted table
              move     sil-Product (i)     to CIT-A-Stock-Key (CIT-A)
              move     sil-Description (i) to CIT-A-Desc (CIT-A)
              move     sil-Qty (i)         to CIT-A-Trans-Qty (CIT-A)
*>                                                         Thats the original, now for the new
              add      1 to CIT-D
              move     1 to CIT-New-Product
              move     ws-Product to CIT-D-Stock-Key (CIT-D)  *> still need qty & desc
     end-if
     move     ws-product to sil-product (i).     *> NOW NEED TO GET Stock item from the Stock file etc <<<<<<<<<<<
     if       ws-Product (1:2) = "**"		*> deleted line
              subtract 1 from CIT-D
              move zero to CIT-New-Product
              go to Get-Code.			*> to process a deleted line
     if       SL-Stock-Link = "N"
              go to get-code.
*>
*>>>>>> now process stock file etc <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*>
     move     17 to cole.                *> 4 Desc.
*>
*> Search nearest Abrev key and read next ..
*>  When this is tested we can wrap this and next together with a F3 test then a if F2 or F3 test
*>
     if       cob-crt-status = cob-scr-F3                *> search Abrev then read next & thereafter F2 until wanted
              move ws-Abrev-Stock to Stock-Abrev-Key
              start Stock-File key not < Stock-Abrev-key invalid key
                    move "Not Found" to Stock-Desc
                    display Stock-Desc at curs with foreground-color 4
                    go to get-product
              end-start
              read  Stock-File next record at end
                    move "End of File" to Stock-Desc
                    display Stock-Desc at curs with foreground-color 4
                    go to get-product
              end-read
              move Stock-Abrev-Key to sil-product (i)    *> have we the right one?
              display Stock-Desc at curs with foreground-color 3
              go to Get-Product
     end-if
*>
     if       cob-crt-status = cob-scr-F2                *> read next record
              read  Stock-File next record at end
                    move "End of File" to Stock-Desc
                    display Stock-Desc at curs with foreground-color 4
                    go to get-product
              end-read
              move Stock-Abrev-Key to sil-product (i)    *> have we the right one?
              display Stock-Desc at curs with foreground-color 3
              go to Get-Product
     end-if
*>
*> Search on Desc. but has dup keys so disp. Abrev. code & F5 for next on description
*>  When this is tested we can wrap this and next together with a F6 test then a if F5 or F6 test
*>
     if       cob-crt-status = cob-scr-F6
              move    sil-description (i) to ws-description
              accept  ws-description at curs with foreground-color 3 update
              move ws-Description to Stock-Desc
              start Stock-File key not < Stock-Desc invalid key
                    move "Not Found" to Stock-Desc
                    display Stock-Desc at curs with foreground-color 4
                    go to Get-Product
              end-start
              read  Stock-File next record at end
                    move "End of File" to Stock-Desc
                    display Stock-Desc at curs with foreground-color 4
                    go to Get-Product
              end-read
              move Stock-Abrev-Key to sil-product (i)    *> Got the right one? Show desc, stock held & retail price
                                      ws-Product
              display Stock-Desc at curs with foreground-color 3 highlight
              move Stock-Held to ws-Qty
              display ws-Qty at line lin col 53 with foreground-color 3 highlight
              accept ws-reply at 2410            *> TESTING ONLY
              move Stock-Retail to amt-ok7
              move amt-wk-pds7   to ws-pound7
              move amt-wk-pence7 to ws-pence7
              display ws-amount-screen-display7 at line lin col 60 with foreground-color 3 highlight
              go to Get-Product
     end-if
*>
     if       cob-crt-status = cob-scr-F5                 *> Read next on Desc.
              read  Stock-File next record at end
                    move "End of File" to Stock-Desc
                    display Stock-Desc at curs with foreground-color 4
                    go to get-product
              end-read
              move Stock-Abrev-Key to sil-product (i)    *> Got the right one? Show desc, stock held & retail price
                                      ws-Product
              display Stock-Desc at curs with foreground-color 3 highlight
              move Stock-Held to ws-Qty
              display ws-Qty at line lin col 53 with foreground-color 3 highlight
              move Stock-Retail to amt-ok7
              move amt-wk-pds7   to ws-pound7
              move amt-wk-pence7 to ws-pence7
              display ws-amount-screen-display7 at line lin col 60 with foreground-color 3 highlight
              go to Get-Product
     end-if
*>
*> So, no special function just search for entered key
*>
     if       ws-Stock-No-Long = spaces
              move ws-Abrev-Stock to Stock-Abrev-Key
              read Stock-File record key Stock-Abrev-Key invalid key
                   move "Not on File" to Stock-Desc
                   display Stock-Desc at curs with foreground-color 4
                   go to get-product
              end-read
     else
              move ws-Stock-Key to Stock-Key
              read Stock-File key Stock-Key invalid key
                   move "Not on File" to Stock-Desc
                   display Stock-Desc at curs with foreground-color 4
                   go to get-product
              end-read
     end-if
     perform  Test-For-Read-Stock.
*>
 Process-Stock-Record.
*>
*>  Have the required Stock record so get and show the desc
*>
     move     17 to cole.        *> Desc.
     move     Stock-sa-Group to ws-pa pa-group sil-pa (i).
     display  Stock-Desc   at curs with foreground-color 3.
     move     Stock-Desc    to ws-description
                               sil-description (i)
                               CIT-D-Desc (CIT-D).
     move     Stock-Retail  to amt-ok7.
     move     Stock-Retail  to ws-Unit.
     move     amt-wk-pds7   to ws-pound7.
     move     amt-wk-pence7 to ws-pence7.
     display  ws-amount-screen-display7 at line lin col 60 with foreground-color 3.
     move     Stock-Held to ws-qty.
     go       to Get-Qty.          *> Bypass manual input code as comes from stock record
*>
 get-prod-test.
*>************
*>
     if       i = 1
              add 1 to lin
              go to get-product.
*>
     if       lin  >  15
              subtract  1  from  i
              subtract  1  from  j
              go to  get-product
      else
              subtract ws-Accept-Body from i           *> instead of 8 can we use ws-Accept-Body ??
              go to get-data-2.
*>
 clear-down-line.
*>**************
*>
     perform  varying z from i by 1 until z > 39
              move invoice-line (z + 1) to invoice-line (z)
              move z to sil-line (z)
     end-perform
*>
     move     zero to z.
     if       i not > sih-lines			*> Check that the deleted line is not the last item
              move sih-invoice to invoice-nos
              move sih-letter  to invoice-let
              move sih-lines  to  item-nos
              delete invoice-file record	*> delete the last item (that was)
              subtract 1 from sih-lines.
*>
 get-code.
*>*******
*>
     move     sil-product (i) to delete-test.
     if       delete-field = "**"
              perform clear-down-line
              subtract 1 from i
              perform display-outline-2
              go to get-product.
*>
     move     sil-pa (i) to ws-pa.
     move     17 to cole.
     display  ws-pa at curs with foreground-color 3.
     accept   ws-pa at curs with foreground-color 3 update.
*>
     if       ws-pa = spaces
              go to  get-product.
     move     "S" to pa-system.
     move     ws-pa to pa-group sil-pa (i).
     move     21 to cole.                       *> disp error in desc.
     read     analysis-file  record  invalid key
              display SL186 at curs with foreground-color 4
              go to  get-code.
*>
 get-desc.
*>*******
*>
     if       SL-Stock-Link = "Y"
              move 17 to cole
     else
              move 21 to cole.
     move     sil-description (i) to ws-description.
     display  ws-description at curs with foreground-color 3.
     accept   ws-description at curs with foreground-color 3 update.
*>
     if       ws-description = space
              move "B" to escape-code
     else
              move space to escape-code.
     if       escape-code = "B"
         and  sil-comment
              go to get-product.
     if       escape-code = "B"
              go to  get-code.
*>
     move     ws-description to sil-description (i).
     if       sil-comment
              go to  jump-totals.
*>
 get-qty.
*>******
*>
     move     sil-qty (i) to ws-qty.
     move     53 to cole.
     display  ws-qty at curs with foreground-color 3.
     accept   ws-qty at curs with foreground-color 3 update.
*>
     if       ws-qty = zero
      and     SL-Stock-Link = "Y"
              go to Recomp-Net. 		*> deleting this transaction so zero qty
     if       ws-qty = zero
              go to get-desc.
     if       SL-Stock-Link = "Y"         	*> make sure not selling more stock than held
       and    ws-qty > Stock-Held
              move Stock-Held to ws-Qty
              go to Get-Qty.
*>
     if       SL-Stock-Link = "Y"		*> bypass accept unit price
       and    CIT-New-Product = 1
              move ws-Qty              to CIT-D-Trans-Qty (CIT-D)
              go to Recomp-Net.
     if       SL-Stock-Link = "Y"		*> bypass accept unit price
       and    CIT-New-Product = zero
       and    ws-Qty = Sil-Qty (i)
              initialize CIT-Additions (CIT-A)	*> No change so clear the table entry
              subtract 1 from CIT-A		*> as only possible changes discount & vat does not effect stock
              go to Recomp-Net.
     if       SL-Stock-Link = "Y"		*> bypass accept unit price
       and    CIT-New-Product = zero
       and    ws-Qty not = Sil-Qty (i)		*> We have a change in qty
              subtract ws-Qty from Sil-Qty (i) giving CIT-A-Trans-Qty (CIT-A)
*>              if  CIT-A-Trans-Qty > zero	*> selling less to return unused/sold as reverse trans
     end-if.    *> Any thing else needed ???????

*>
 get-unit.
*>*******
*>
     move     60 to cole.
     move     sil-unit (i) to amt-ok6.
     perform  accept-money6c.
     if       amt-ok6 = zero
              go to get-qty.
     move     amt-ok6 to ws-unit.
*>
 recomp-net.
*>
     multiply ws-qty by  ws-unit giving  ws-net on size error
              display  "SizEr" at curs with blink foreground-color 4.
              go to get-qty.
*>
*>
     move     ws-net to  display-9 sil-net (i).
     move     ws-qty to sil-qty (i).
     move     ws-unit to sil-unit (i).
     display  display-9 at 1232 with foreground-color 3.
*>
 get-disc.
*>*******
*>
     move     sil-discount (i) to  ws-discount.
     move     72 to cole.
     move     ws-disc-wka to ws-disca1.
     move     ws-disc-wkb to ws-disca3.
     display  ws-discount-display at curs with foreground-color 3.
     accept   ws-discount-accept  at curs with foreground-color 3 update.
     move     ws-discb1 to ws-disc-wka.
     move     ws-discb3 to ws-disc-wkb.
*>
     move     ws-discount to  work-d sil-discount (i).
     move     ws-net to  work-n.
*>
     perform  net-compute.
*>
     subtract work-1  from  ws-net.
*>
     move     ws-net to sil-net (i) display-9.
     display  display-9 at 1232 with foreground-color 3.
*>
 get-vat-code.
*>***********
*>
     move     79 to cole.
     move     sil-vat-code (i) to vat-code.
     display  vat-code at curs with foreground-color 3.
     accept   vat-code at curs with foreground-color 3 update.
*>
     if       vat-code  >  3	    *> using 1st three as last 2 are Sales tax, Not used in the UK.
              go to  get-vat-code.  *> so change test for 'not = 4 or 5' instead of '> 3'
*>
     move     vat-code  to  sil-vat-code (i).
*>
     if       vat-code = zero
              move  zero  to  ws-vat
     else
              move vat-rate (vat-code) to ws-vat-rate
              compute  ws-vat rounded = (ws-net * ws-vat-rate) / 100.
*>
     move     ws-vat to  display-9 sil-vat (i).
     display  display-9 at 1249 with foreground-color 3.
*>
     perform  running-totals.
*>
 jump-totals.
*>
     add      1  to  j.
     add      1  to  i.
     go       to get-data-2.
*>
 Test-For-Read-Stock.			*> NOT YET USED
     if       fs-reply not = zero
              perform Eval-Status
              display "Read Stock Error : " at line ws-23-lines col 1 with foreground-color 4 highlight erase eol
              display fs-reply at line ws-23-lines col 20 with foreground-color 2 highlight
              display exception-msg at line ws-23-lines col 24 with foreground-color 3
              display SL006 at line ws-lines col 1
              accept ws-reply at line ws-lines col 45
     end-if.
*>
 main-exit.   exit section.
*>********    ****
*>
 erase-screen            section.
*>==============================
*>
     move     1 to cole.
     display  " " at curs with erase eos.
*>
 main-exit.   exit section.
*>********    ****
*>
 end-totals              section.
*>==============================
*>
     perform  total-screen.
*>
     move     15  to  lin.
     perform  erase-screen.
*>
     display  "*********************" at 1660  with foreground-color 2
     display  "*" at 1760 with foreground-color 2
     display  "*" at 1760 with foreground-color 2
     display  "*" at 1860 with foreground-color 2
     display  "*" at 1880 with foreground-color 2
     display  "*" at 1960 with foreground-color 2
     display  "*" at 1980 with foreground-color 2
     display  "*********************" at 2060 with foreground-color 2
*>
     display  "Invoice Ok To Store?" at 1761 with foreground-color 2.
     display  "(Y/N)  [Y]" at 1967 with foreground-color 2.
*>
 confirmation.
*>***********
*>
     move     "Y"  to   ws-reply.
     accept   ws-reply at 1975 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "N"
              go to end-totals.
*>
     if       ws-reply not = "Y"
              go to  confirmation.
*>
     move     "P"  to  sih-status.
     move     space to sih-status-P.
     subtract 1  from  i.
     move     i    to  sih-lines.
*>
     move     sinvoice-header  to  invoice-record.
     rewrite  invoice-record.
     if       fs-reply not = zero
              perform Eval-Status
              display sl192         at line ws-23-lines col  1 with erase eol foreground-color 4
              display fs-reply      at line ws-23-lines col 36 with foreground-color 3
              display exception-msg at line ws-23-lines col 39 with foreground-color 3
              display invoice-key   at line ws-23-lines col 64 with foreground-color 3
              display sl006         at line ws-lines    col  1 with foreground-color 3
              accept  ws-reply      at line ws-lines    col 30
              display " "           at line ws-23-lines col  1 with erase eos
     end-if
*>
     move     zero to  j.
     perform  write-details  i  times.
     perform  Update-Stock-And-Audit.
     move     1 to s-flag-i.
     move     11  to  lin.
     perform  erase-screen.
*>
 main-exit.   exit section.
*>********    *****
*>
 total-screen            section.
*>==============================
*>
     move     1 to cole.
     move     11 to lin.
     display  " " at curs with erase eos.
     display  ws-dash at 1101 with foreground-color 2.
*>
     if       i-level-1
              move  1  to  menu-reply
     else
              move  2  to  menu-reply.
*>
     display  "Level "   at 1201 with foreground-color 2.
     display  menu-reply at 1207 with foreground-color 2.
     display  "<---Net---->   <---Vat--->" at 1225 with foreground-color 2.
     display  "<---Gross-->     Days"      at 1254 with foreground-color 2.
     display  "Sub-Totals"                 at 1404 with foreground-color 2.
     display  "{          }   {         }" at 1425 with foreground-color 2.
     display  "{          }     [  ]"      at 1454 with foreground-color 2.
*>
     display  extra-desc                   at 1504 with foreground-color 2.
     display  "[          ]   [         ]" at 1525 with foreground-color 2.
     display  "{          }"               at 1554 with foreground-color 2.
*>
     display  "Shipping & Handling"        at 1604 with foreground-color 2.
     display  "[          ]   [         ]" at 1625 with foreground-color 2.
     display  "{          }"               at 1654 with foreground-color 2.
*>
     display  "Late Charge"                at 1704 with foreground-color 2.
     display  "[          ]              " at 1725 with foreground-color 2.
     display  "{          }     [  ]"      at 1754 with foreground-color 2.
*>
     display  "------------   -----------" at 1825 with foreground-color 2.
     display  "------------"               at 1854 with foreground-color 2.
*>
     display  "Itemised Totals"            at 1904 with foreground-color 2.
     display  "{          }   {         }" at 1925 with foreground-color 2.
     display  "{          }"               at 1954 with foreground-color 2.
*>
     move     sih-net  to  display-9.
     display  display-9 at 1426 with foreground-color 3.
*>
     move     sih-vat  to  display-8.
     display  display-8 at 1441 with foreground-color 3.
*>
     add      sih-net  sih-vat  giving  display-9.
     display  display-9 at 1455 with foreground-color 3.
*>
 get-days.
*>*******
*>
     move     sih-days to ws-dayes.
     display  ws-dayes at 1472 with foreground-color 3.
     if       sih-type not = 2
*>              move zero to sih-days		*> its a proforma so leave it & unchanged
              go to get-extra.
*>
     accept   ws-dayes at 1472 with foreground-color 3 update.
     move     ws-dayes to sih-days.
*>
 get-extra.
*>********
*>
     if       extra-type = space
              move zero to sih-extra sih-e-vat
              go to get-carriage.
*>
     if       extra-rate not = zero
              compute  sih-extra = (sih-net * extra-rate) / 100
     else
              move  zero  to  sih-extra.
*>
     move     1526 to curs.
     move     sih-extra to amt-ok7.
     perform  accept-money7c.
     move     amt-ok7 to sih-extra.
*>
 get-extra-vat.
*>************
*>
     if       sih-extra = zero
              move  zero to  sih-e-vat
              go to get-carriage.
*>
     compute  amt-ok6 = sih-extra  *  vat-rate-1  /  100.
*>
     move     1541 to curs.
     perform  accept-money6c.
     move     amt-ok6 to sih-e-vat.
*>
     add      sih-extra  sih-e-vat  giving  display-9.
     display  display-9 at 1555 with foreground-color 3.
*>
     if       discount
         and  sih-extra not = zero
              multiply -1 by sih-extra
              multiply -1 by sih-e-vat.
*>
 get-carriage.
*>***********
*>
     move     1626 to curs.
     move     sih-carriage to amt-ok7.
     perform  accept-money7c.
     move     amt-ok7 to sih-carriage.
     compute  amt-ok6 rounded = sih-carriage * vat-rate-1 / 100.
*>
*> Note That Vat-Rate-1 Must Be Standard Rate For P & P
*>
 get-carriage-vat.
*>***************
*>
     move     1641 to curs.
     perform  accept-money6c.
     move     amt-ok6 to sih-c-vat.
     add      sih-carriage  sih-c-vat  giving  display-9.
     display  display-9 at 1655 with foreground-color 3.
*>
 get-deduct-amt.
*>*************
*>
     if       (sih-type not = 2  and not = 3)		*> Invoices, Credit Notes
          or  not late-charges
          or  ws-named = "Z"
              move  zero  to  sih-deduct-amt  sih-deduct-vat  sih-deduct-days
              go to  main-exit.
*>
     compute  amt-ok7 =  sih-net  /  10.
*>
     if       amt-ok7 <  4
              move  4  to  amt-ok7.
*>
     move     1726 to curs.
     perform  accept-money7c.
     move     amt-ok7 to sih-deduct-amt.
*>
 get-deduct-vat.
*>*************
*>
     move     zero to sih-deduct-vat.
*>
     add      sih-net  sih-extra  sih-carriage  sih-deduct-amt  giving  display-9.
     display  display-9 at 1926 with foreground-color 3.
*>
     add      sih-vat  sih-e-vat  sih-c-vat  sih-deduct-vat   giving  display-8.
     display  display-8 at 1941 with foreground-color 3.
*>
     add      sih-net  sih-extra  sih-carriage  sih-deduct-amt
              sih-vat  sih-e-vat  sih-c-vat  sih-deduct-vat    giving  display-9.
     display  display-9 at 1955 with foreground-color 3.
*>
 get-deduct-days.
*>**************
*>
     move     sih-days  to  ws-dayes.
     display  ws-dayes at 1772 with foreground-color 3.
     accept   ws-dayes at 1772 with foreground-color 3 update.
     move     ws-dayes to sih-deduct-days.
*>
 main-exit.   exit section.
*>********    ****
*>
 invoice-details section.
*>======================
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Invoicing Data Amend" at 0132 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
     display  "****************************************" at 0441 with foreground-color 2.
     display  "*Date   [  /  /    ]*                  *" at 0541 with foreground-color 2.
     display  "*A/C Nos   [       ]*Ref   [          ]*" at 0641 with foreground-color 2.
     display  "*Invoice [         ]*Order [          ]*" at 0741 with foreground-color 2.
     display  "****************************************" at 0841 with foreground-color 2.
     display  "F8 = Only Show delivery details on 'A/C nos' entry" at 0911 with foreground-color 2.
     display  "Type [ ]  <1> = Receipt; <2> = Account; <3> = Credit Note; <4> = Pro-Forma"
                                                         at 1001 with foreground-color 2.
*>
 invoice-enter.
*>************
*>
     move     zero to sih-invoice.
     display  sih-invoice at 0751 with foreground-color 3.
     if       sl-own-nos not = "Y"
              display "] " at 0759 with foreground-color 2.
     accept   sih-invoice at 0751 with foreground-color 3 update.
     if       sih-invoice = zero
           or cob-crt-status = cob-scr-esc
              move 1 to z
              go to main-exit.
*>
     move     space to invoice-let sih-letter.
     move     zero to item-nos.
     move     sih-invoice  to  invoice-nos.
     if       sl-own-nos = "Y"
              accept sih-letter at 0759  with foreground-color 6 update
              move   sih-letter to invoice-let.
     read     invoice-file invalid key
              display SL194 at 1640 with foreground-color 4
              go to invoice-enter.
     move     invoice-record to sinvoice-header.
     display  " " at 1640 with erase eol.
*>
     if       sih-status = "z"
              display SL195 at 1601 with foreground-color 4 erase eol
              go to invoice-enter.
*>
     display  " " at 1601 with erase eol.
     move     sih-date to u-bin.
     perform  zz060-Convert-Date.   *> now have ws-date
     perform  read-details.
*>
 date-input.
*>*********
*>
     display  ws-date at 0550 with foreground-color 3.
     accept   ws-date at 0550 with foreground-color 3 update.
     if       cob-crt-status = cob-scr-esc
         or   ws-date = spaces
              move 1 to z
              go to  main-exit.
*>
     move     ws-date to ws-test-date.
     perform  zz050-Validate-Date.
     if       u-bin = zero
              go to  date-input.
*>
     move     u-bin  to sih-date.
*>
 customer-input.
*>*************
*>
     display  sih-customer at 0653 with foreground-color 3.
     accept   sih-customer at 0653 with foreground-color 3 update.
     move     function upper-case (sih-customer) to sih-customer.
*>
     if       cob-crt-status = cob-scr-esc
         or   sih-customer = spaces
              move  "Q"  to  escape-code
              go to  main-exit.
     if       Cob-Crt-Status = Cob-Scr-F8
              move "Y" to ws-Show-Delivery
     else
              move "N" to ws-Show-Delivery
     end-if
*>
     move     1  to  c-check.
*>
     move     sih-customer  to  sales-key.
*>
     read     sales-file  record  invalid key
              move  zero  to  c-check.
*>
     if       not  c-exists
              go to  customer-input.
*>
     if       delivery-tag = zero	*> Only show delivery details if F8 pressed instead of
       or     ws-Show-Delivery = "N"	*> accept on cust no. input
              go to  customer-setup.
*>
     move     "D"       to Deliv-Key-Type.
     move     Sales-Key to Deliv-Sales-Key.
     read     delivery-file  invalid
              move  zero  to  delivery-tag
              go to  customer-setup.
*>
     move     deliv-address to address-A.
*>
     go       to customer-display.
*>
 customer-setup.
*>*************
*>
     move     sales-address  to  address-A.
*>
 customer-display.
*>****************
*>
     if       delivery-tag = zero
              display sales-name at 0301 with foreground-color 3
     else
              display deliv-name at 0301 with foreground-color 3.
*>
     move     1  to  z.
     unstring address-A  delimited  by  sl-delim into  address-line count z pointer  z.
     display  address-line at 0401 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address-A  delimited  by  sl-delim into  address-line count z pointer  z.
     display  address-line at 0501 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address-A  delimited  by  sl-delim into  address-line count z pointer  z.
     display  address-line at 0601 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address-A  delimited  by  sl-delim into  address-line count z pointer  z.
     display  address-line at 0701 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address-A into  address-line  pointer  z.
     display  address-line at 0801 with foreground-color 3.
*>
     move     spaces  to  address-line.
*>
 ref-input.
*>********
*>
     display  sih-ref at 0669 with foreground-color 3.
     accept   sih-ref at 0669 with foreground-color 3 update.
*>
 order-input.
*>**********
*>
     display  sih-order at 0769 with foreground-color 3.
     accept   sih-order at 0769 with foreground-color 3 update.
*>
 type-input.
*>*********
*>
     display  sih-type at 1007 with foreground-color 3.
     accept   sih-type at 1007 with foreground-color 3 update.
*>
     if       sih-type = zero
              go to main-exit.
*>
     if       sih-type  >  4
              go to  type-input.
*>
     if       sih-type = 3
              perform  cr-note
              if  escape-code = "Q"
                  go to  type-input.
*>
     move     zero to z.
*>
*>     if       sih-type = 1  or  >  2
*> Allow receipts to be amended
*>
     if       sih-type  >  2
              go to  main-exit.
*>
     move     zero  to  we-error.
*>
     subtract sales-unapplied from sales-current.
*>
     if       sales-current  >  zero
              subtract sales-last-inv from run-date giving  work-1
              if work-1  >  sales-credit
              display "Overdue Balance <<<" at 1648 with foreground-color 2 highlight
              move  999  to  we-error.
*>
     if       sales-current  >  sales-limit
              display "Balance Exceeds Credit Limit <<<" at 1725 with foreground-color 2 highlight
              move  998  to  we-error.
*>
     if       sales-credit not > zero
          or  sales-limit  not > zero
              display "No Longer an Account Customer <<<" at 1825 with foreground-color 2 highlight
              move  997  to  we-error.
*>
     if       we-error = zero
              go to  main-exit.
*>
     display  ">>> Warning! " at 1635 with foreground-color 2 highlight.
     display  "**********************" at 1958 with foreground-color 2
     display  "*" at 2058 with foreground-color 2
     display  "*" at 2158 with foreground-color 2
     display  "*" at 2079 with foreground-color 2
     display  "*" at 2179 with foreground-color 2
     display  "**********************" at 2258 with foreground-color 2
*>
     display  "None Zero To Abort" at 2060 with foreground-color 2.
     display  "Return To Continue" at 2160 with foreground-color 2.
*>
     move     zero to z.
     accept   z at 2280 with foreground-color 3 update.
     if       cob-crt-status = cob-scr-esc
              move 1 to z   cob-crt-status.
     go       to main-exit.
*>
 main-exit.   exit section.
*>********    ****
*>
 cr-note             section.
*>==========================
*>
     display  " " at 1001 with erase eol.
     display  " " at 1101 with erase eol.
     display  " " at 1201 with erase eol.
     display  " " at 1301 with erase eol.
     display  " " at 1401 with erase eol.
*>
 main-input.
*>*********
*>
     display  "Invoice To Credit - [         ]" at 1001 with foreground-color 2.
*>
     if       sl-own-nos not = "Y"
              display "] " at 1030 with foreground-color 2.
     move     sih-cr to  ws-cr.
*>
     display  ws-cr at 1022 with foreground-color 3.
     accept   ws-cr at 1022 with foreground-color 3 update.
     move     ws-cr to sih-cr.
     if       sih-cr = zero
              move  "Z"  to  ws-named
              go to  no-inv-restart
     else
              move  " "  to  ws-named.
*>
     if       sih-cr = 99999999
              move "Q" to escape-code
              go to main-exit
     else
              move space to escape-code.
*>
     move     sih-cr  to  invoice-nos.
     move     zero   to  item-nos.
     move     space to  invoice-let.
     if       sl-own-nos = "Y"
              accept invoice-let at 1030 with foreground-color 3 update.
*>
*>  Why is this the Invoice file and not the open-item-3 file as in
*>  sl910 ???????? maybe because we are amending one created on inv file in sl910
*>  and that is looking for a open inv BUT STILL NEEDS LOOKING AT
*>
     read     invoice-file  invalid key
              display SL193 at 1132 with foreground-color 4
              go to  check-inv-no-ok.
*>
     display  " " at 1101 with erase eol.
     if       invoice-type not = 2
              display SL184  at 1101 with foreground-color 4
              go to main-input.
     if       invoice-customer not = sales-key
              display SL196  at 1101 with foreground-color 4
              go to main-input.
*>
 no-inv-restart.
*>*************
*>
     display  " " at 1101 with erase eol.
     display  " " at 1201 with erase eol.
     display  " " at 1301 with erase eol.
     display  " " at 1401 with erase eol.
*>
 main-end.
*>*******
*>
     go       to main-exit.
*>
 check-inv-no-ok.
*>
     display  "Do You Wish To Use This Invoice No.? {N}" at 1201 with foreground-color 2.
     display  "..If So, You must ensure that it Belongs to the same Customer and that it is a "
                                                         at 1301 with foreground-color 2.
     display  "Invoice ie, not a Receipt"                at 1401  with foreground-color 2.
     move     "N" to ws-reply.
     accept   ws-reply at 1239 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "Y"
              go to no-inv-restart.
     if       ws-reply = "N"
              go to cr-note.
     go       to check-inv-no-ok.
*>
 main-exit.   exit section.
*>********    ****
*>
 program-start section.
*>====================
*>
     display  " " at 0101 with erase eos.
     move     to-day to u-date ws-test-date.
     if       file-status (15) not = 1
              move 1 to ws-Process-Func ws-Sub-Function
              call "sl070" using ws-calling-data
                                 system-record
                                 to-day
                                 file-defs
              end-call
              if    File-Status (15) not = 1       *> Only if the call failed for some unknown reason
                    move 29  to  error-code
                    perform  maps99
                    move 15 to error-code
                    perform  maps99
              end-if
     end-if
*>
     open     input sales-file delivery-file analysis-file.
     open     i-o invoice-file.
*>
*> if linked open Stock & Audit file
*>
     if       SL-Stock-Link = "Y"
       if     file-status (11) not = 1
              open output stock-file           *> OC doesnt create in i-o - possible bug
              close       stock-file
              open i-o  stock-file   *> Thats ok we just won't find any items!!   (sharing all        )
              move 1 to file-status (11)                *> as stock could be in use to create items
       else
              open i-o  stock-file   *> we could be updating records   (sharing read only  )
       end-if
       if     Stk-Audit-Used = 1
         if   File-Status (10) not = 1
              open output  Stock-Audit  *> this could be shared but this is safer as we will write (sharing no other)
              move 1 to File-Status (10)
         else
              open extend  Stock-Audit  *> (sharing no other)
         end-if
       end-if
     end-if.
*>
 menu-return.
*>**********
*>
     move     zero  to  menu-reply.
*>
 main-exit.   exit section.
*>********    ****
*>
 display-outline-1       section.
*>==============================
*>
     add      1  to  i.
     move     1 to cole.
     display  "(" at curs with erase eol foreground-color 2.
     move     2 to cole.
     display  i at curs with foreground-color 2.
     move     4 to cole.
     display  ") [  ]" at curs with foreground-color 2.
     move     36 to cole.
     display  "[          ] [ ]   {         } (" at curs with foreground-color 2.
     move     78 to cole.
     display  ")" at curs with foreground-color 2.
*>
 main-exit52a. exit section.
*>***********  ************
*>
 display-outline-2       section.
*>===============================
*>
     add      1  to  i.
     move     1 to cole.
     if       SL-Stock-Link = "N"		*> No stock then process PA code
              display "[             ][  ][" at curs with foreground-color 2 erase eol
              move    51 to cole
              display   "][     ][          ][     ][ ]" at curs  with foreground-color 2
     else				*> ignore PA
              display "[             ][" at curs with foreground-color 2 erase eol
              move    49 to cole
              display "]  [     ][          ][     ][ ]" at curs  with foreground-color 2
     end-if.
*>
 main-exit52b.     exit section.
*>=============================
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
 maps99                  section.
*>==============================
*>
     call     "maps99"  using  error-code ws-calling-data.
*>
 main-exit.   exit.
*>********    ****
*>
