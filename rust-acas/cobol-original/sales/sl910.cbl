       >>source free
*>***************************************************
*>                                                  *
*>               Invoice  Data  Entry               *
*>                                                  *
*>***************************************************
*>
 identification          division.
*>===============================
*>
      program-id.         sl910.
*>**
*>    Author.             Cis Cobol Conversion By V B Coen, FBCS 12/11/83
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Sharing Files.      Stock       is shared read with read locked & unlocked
*>                        Stock-Audit is locked (share no)
*>    Remarks.            Invoice Data Entry & Maintenance.
*>                        OTM3 is used to check status of invoices when issuing CR.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps04.
*>                        Maps99.
*>                        SL070. Analysis codes set up - Defaults only.
*>                        Sl930. Invoice print
*>                        Sl960. New customer create
*>**
*>    Error messages used.
*>                        SL003
*>                        SL006
*>                        SL180
*>                        SL181
*>                        SL182
*>                        SL183
*>                        SL184
*>                        SL185
*>                        SL186
*>                        SL187  *> Stock file not found
*>                        SL188  *> Stock audit file not found
*>                        SL189  *> Stock not created
*>                        SL190. *> writing error to Stock Audit file
*>                        SL191. *> Rewrite error on Stock record
*>****
*>  Changes.
*> 04/03/83 Vbc - Changes To Fdinv.Cob And Cr-Notes.
*> 22/03/83 Vbc - Cr-Notes.
*> 30/03/83 Vbc - When Creating Invoices Check For Sl-Charges &
*>                Sales-Late (Late-Charges).
*> 30/04/83 Sjw - Accept Late Charges Only If Invoice Ws-Named On
*>                Cr. Notes.
*> 02/05/83 Vbc - #.
*> 13/10/83 Vbc - Use Deleted Invoice Nos If Available.
*> 17/11/83 Vbc - Cis Cobol Conversion.
*> 24/02/84 Vbc - Clear Ws-Named Before Usage.
*> 01/03/84 Vbc - Support Of Sales-Unapplied In Invoice-Details.
*> 10/03/84 Vbc - Support Of sih-Day-Book-Flag.
*> 12/05/84 Vbc - Support Of Graphics,If Cn Check Openitm File.
*> 16/11/84 Vbc - Fix Abort Graphics Screen In Invoice-Details.
*> 07/01/85 Vbc - Fix Bug Clear Screen In Cr-Notes.
*> 03/03/09 vbc - .04 Migration to Open Cobol v3.00.00.
*> 16/03/09 vbc - .05 Bug/Feature 30.1 & 3 escape out at any level.
*> 04/04/09 vbc - .06 Support for F1 (or NEW) on customer no. to create new
*>                account. Sales & Purchase ledger both match function.
*>                Changed usage of deleted folio nos. by
*>                deleting record after re-use, matches PL020.
*> 26/11/11 vbc - .07 Error msgs to SLnnn.Support for dates other than UK
*> 08/12/11 vbc - .08 Support for path+filenames.
*> 09/12/11 vbc -     Updated version to 3.01.nn
*> 11/12/11 vbc - .09 Changed usage of Stk-Date-Form to global Date-Form making former redundent.
*> 17/04/13 vbc       Note change regarding Invoicer setting = 2 did not reflect sl910 ?
*>                    Clear display for F1 key after accepting a valid cust no.
*> 15/05/13 vbc - .10 Add in support for direct link to Stock Control with Stock and Audit files
*>                    in inv-level-2. Changed stk code 12>13, desc 24>32 removing pa code
*>                    and consider add new display field OS for Out of Stock but on order
*>                    with delivery expected in 7 days or less
*>		      MORE?????
*>                    [all this also in sl920 and need to look at 930 - 960 for any needed changes]
*> 22/05/13 vbc - .11 Bug fixes from 09/10.
*>                .12 Ditto, missing stock-value computation.
*> 24/05/13 vbc - .13 Changed coding to use ws-accept-body instead of '8' for larger screens than 24 lines.
*>                    Added Invoice to Audit record.
*>                    NEED TO CHECK CREDIT NOTE PROCESSING FOR REQUIREMENT FOR AUDIT FILE & STOCK FILE PROCESSING!!
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
*>------------
 copy "selanal.cob".
 copy "selsl.cob".
 copy "selinv.cob".
 copy "seldel.cob".
 copy "seloi3.cob".
 copy "seldnos.cob".
*>
 copy "selstock.cob".	     *> Stock link
 copy "selaud.cob".          *> Stock audit
*>
 data                    division.
*>===============================
*>
 file section.
*>------------
*>
 copy "fdanal.cob".
 copy "fdsl.cob".
 copy "fdinv.cob".
 copy "fddel.cob".
 copy "fdoi3.cob".
 copy "wsoi.cob".
 copy "fddnos.cob".
*>
 copy "fdstock.cob".          *> Stock link
 copy "fdaudit.cob".          *> Stock audit
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "SL910 (3.01.13)".
 77  Exception-Msg       pic x(25) value spaces.
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
*>
 01  ws-data.
     03  test-product.
         05  filler      pic x.
             88  sil-comment              value "/".
         05  filler      pic x(12).
     03  menu-reply      pic 9.
     03  ws-reply        pic x.
     03  z               pic 99.
     03  c-check         pic 9.
         88  c-exists                    value  1.
     03  ws-delinv       pic 9           value zero.
         88  del-exists                  value 1.
     03  Address-A       pic x(96).
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
     03  ws-unit         pic 9(7)v99.
     03  ws-cr           pic 9(8).
     03  ws-dayes        pic 99.
     03  ws-Show-Delivery pic 9.
*>
     03  ws-env-lines    pic 999         value zero.
     03  ws-lines        binary-char unsigned value zero.
     03  ws-accept-body  binary-char unsigned value 8.         *> set for 24 line screen (-1) but Not yet in use
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
 01  Error-Messages.
*> System Wide
     03  SL003          pic x(28) value "SL003 Hit Return To Continue".
     03  SL006          pic x(43) value "SL006 Note Details & Hit Return to continue".

*> Module specific
     03  SL180          pic x(34) value "SL180 Err on Invoice file write : ".
     03  SL181          pic x(56) value "SL181 Invoice To Credit Does Not Exist On Open Item File".
     03  SL182          pic x(31) value "SL182 Invoice To Credit Is Paid".
     03  SL183          pic x(42) value "SL183 Invoice To Credit Has Query Flag Set".
     03  SL184          pic x(75) value "SL184 You Can Only Credit Invoices. Not Receipts, Credit Notes Or Proformas".
     03  SL185          pic x(56) value "SL185 Credit of Prompt Pay/Late Charge will be Automatic".
     03  SL186          pic x(30) value "SL186 P.A. Code Does Not Exist".
     03  SL187          pic x(26) value "SL187 Stock File not found".
     03  SL188          pic x(26) value "SL188 Audit File not found".
     03  SL189          pic x(42) value "SL189 Stock File not created yet, creating".
     03  SL190          pic x(36) value "SL190 Error on Writing to Audit File".
     03  SL191          pic x(33) value "SL191 Error on Stock file Rewrite".
*>
 01  error-code          pic 999.
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
     perform  Program-Start.
     if       sl-own-nos = "Y"
              move zero to ws-delinv.
*>
 main.
     initialize sinvoice-header.
     perform  invoice-details.
*>
     if       z not = zero
       or     escape-code = "Q"
              go to  menu-exit.
*>
     move     16  to  lin.
     move     1 to cole.
     display  " " at curs with erase eos.
*>
 data-input.
*>*********
*>
     initialize SInvoice-Bodies.
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
     display "Enter Further Invoices? (Y/N) [Y] " at line ws-lines col 29 with foreground-color 3.
     move     zero to cob-crt-status.
     move     "Y" to ws-reply.
     accept   ws-reply at line ws-lines col 60  with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     display  " " at line ws-lines col 01 with erase eol.
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
     close    del-inv-nos-file
              sales-file
              delivery-file.
     close    analysis-file
              invoice-file
              open-item-file-3.
     if       SL-Stock-Link = "Y"
              close Stock-File
                    Stock-Audit.
*>
     exit     program.
*>
*>
*>****************************************************************
*>                 P R O C E D U R E S                           *
*>****************************************************************
*>
 running-totals          section.
*>==============================
*>
     move     zero  to  sih-net
                        sih-vat.
*>
     perform  varying k from 1 by 1 until k  >  i
              add sil-net (k) to sih-net
              add sil-vat (k) to sih-vat
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
     move     sih-invoice  to sil-invoice (j).
     move     j            to sil-line (j).
     move     sih-letter   to sil-letter (j).
     move     sih-type     to sil-type (j).
     move     invoice-line (j)  to  invoice-record.
     write    invoice-record.
     if       fs-reply not = zero
              perform Eval-Status
              display sl180         at line ws-23-lines col 1 with erase eol foreground-color 4
              display fs-reply      at line ws-23-lines col 36 with foreground-color 3
              display exception-msg at line ws-23-lines col 39 with foreground-color 3
              display invoice-key   at line ws-23-lines col 64 with foreground-color 3
              display sl006         at line ws-lines col 01 with foreground-color 3
              accept  ws-reply at line ws-lines col 30
              display " " at line ws-23-lines col 1 with erase eos.
*>
     perform  Update-Stock-n-Audit.
*>
 main-exit.   exit section.
*>********    ****
*>
 Update-Stock-n-Audit section.
*>===========================
*>
*> normal for Receipts(1) and Invoices (2) but reverse process for Credit Notes (3)
*>
     if       SL-Stock-Link not = "Y"		*> Only process if linked to Stock Control
              go to Update-Stock-Exit.
*>
     initialize Stock-Audit-Record.
     move     3                   to Audit-Type.
     move     Sih-Invoice         to Audit-Invoice-PO.
     move     ws-Date             to Audit-Process-Date.
     move     Sil-Product (j)     to Audit-Stock-Key
                                     ws-Stock-Key.
     move     Sil-Description (j) to Audit-Desc.
     move     sil-qty (j)         to Audit-Transaction-Qty.
     move     zero                to Audit-Unit-Cost.
     if       Sil-Type (j) = 3
              move 5      to Audit-Type
              move 1      to Audit-Reverse-Transaction
              move Sih-cr to Audit-Cr-for-Invoice
     else
              move zero to Audit-Reverse-Transaction
     end-if
     move     Stk-Audit-No        to Audit-No.
*>
*> Get the stock record
*>
     if       ws-Stock-No-Long = spaces
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
     if       fs-reply not = zero
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
     if       Stock-Key not = spaces		*> we have a stock rec.
              if       Sil-Type (j) = 1 or = 2
                       compute  Audit-Stock-Value-Change = Audit-Transaction-Qty * Stock-Cost * -1
                       subtract Audit-Transaction-Qty from Stock-Held
              else
               if      Sil-Type (j) = 3		*> Credit note
               compute  Audit-Stock-Value-Change = Audit-Transaction-Qty * Stock-Cost
                       add Audit-Transaction-Qty to Stock-Held
               end-if
              end-if
              if       Stock-Held < zero		*> Should NOT happen as testing in data entry
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
     if       Stk-Audit-Used = 1
              move zero to Stk-Activity-Rep-Run		*> Need to run audit report
              write Stock-Audit-Record
              if       fs-reply not = zero
                       perform Eval-Status
                       display SL190         at line ws-23-lines col 1 with foreground-color 4 highlight erase eol
                       display fs-reply      at line ws-23-lines col 38 with foreground-color 2 highlight
                       display exception-msg at line ws-23-lines col 41 with foreground-color 3
                       display SL006         at line ws-lines col 1
                       accept ws-reply       at line ws-lines col 45
              end-if
     end-if.
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
*>************************
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
     move     amt-wk-pds6   to ws-pound6.
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
     display  ws-amount-screen-display7 at curs  with foreground-color 3.
     accept   ws-amount-screen-accept7  at curs   with foreground-color 3 update.
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
 comm-exit.   exit section.
*>--------    ----
*>
 inv-level-1  section.		*> No one should be using this consider scrapping and forcing invoicer =2 etc
*>===================
*>
     display  ws-dash        at 1101 with foreground-color 2.
     display  "Level 1"      at 1201 with foreground-color 2.
     display  "Line - "      at 1216 with foreground-color 2.
     display  "[          ]" at 1236 with foreground-color 2.
     display  "[          ]" at 1254 with foreground-color 2.
     display  "[          ]" at 1267 with foreground-color 2.
     display  "Code"         at 1405 with foreground-color 2.
     display  "<---Net---->  Vat   Vat Amount  Gross Amount" at 1436 with foreground-color 2.
*>
 loop.
*>***
*>
     perform  varying lin from 16 by 1 until lin not < ws-23-lines
              add      1  to  i
              move     1 to cole
              display  "(" at curs with erase eol foreground-color 2
              move     2 to cole
              display  i at curs with foreground-color 2
              move     4 to cole
              display  ") [  ]" at curs with foreground-color 2
              move     36 to cole
              display  "[          ] [ ]   {         } (" at curs with foreground-color 2
              move     78 to cole
              display  ")" at curs       with foreground-color 2
     end-perform
*>
*> i = no. lines on screen for items, then less 7 (24 line screen)
*>      why this way ,  no idea as against move 1 to i ?????
*>
*>     subtract 16 from ws-23-lines giving m.       *> or move 1 to i
     subtract ws-Accept-Body  from  i.             *> was m from i
     move     1 to j.
     display  i at 1223 with foreground-color 3.
     move     zero to cob-crt-status.
     perform  get-data-1.
     if       cob-crt-status = cob-scr-esc
              go to main-exit.
*>
     if       new-screen = 1
              go to loop.
*>
     if       sil-description (i) not = spaces
       and    i not = 40
              go to  loop.
*>
 main-exit.   exit section.
*>********    ****
*>
 get-data-1   section.		*> No one should be using this consider scrapping and forcing invoicer =2 etc
*>===================
*>
     add      j  15  giving  lin.
*>
     if       lin  >  ws-23-lines
              subtract 1 from i
              move 1 to new-screen
              go to  main-exit.
*>
     move     zero to new-screen.
*>
 get-code.
*>*******
*>
     if       i  >  1
       and    sil-pa (i) = spaces
              move  sil-pa (i - 1)  to  sil-pa (i).
*>
     move     sil-pa (i) to ws-pa.
     move     7 to cole.
     display  ws-pa at curs with foreground-color 3.
     accept   ws-pa at curs with foreground-color 3 update.
     move     ws-pa to sil-pa (i) pa-group.
     move     spaces  to  sil-description (i).
*>
     if       ws-pa = spaces
              go to  main-exit.
     if       cob-crt-status = cob-scr-esc
              go to main-exit.
*>
     if       ws-pa = "<<"
        and   i = 1
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
                    go to  get-data-1.
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
     perform  accept-money7a thru accept-money7b.
     if       amt-ok7 = zero
              go to get-code.
     move     amt-ok7 to sil-net (i) ws-net.
*>
 get-vat-code.
*>***********
*>
*>  Only using 1st three as last 2 are for local sales tax (not in UK)
*>
     move     50 to cole.
     accept   vat-code at curs with foreground-color 3 update.
*>
     if       vat-code  >  3
              go to  get-vat-code.
*>
     move     vat-code  to  sil-vat-code (i).
     if       vat-code = zero
              move  zero  to  amt-ok6
       else
              move vat-rate (vat-code) to ws-vat-rate
              compute amt-ok6 rounded =  (ws-net * ws-vat-rate) / 100.
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
     display  ws-dash at 1101 with foreground-color 2.
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
     perform  varying lin from 16 by 1 until lin not < ws-23-lines
              add     1  to  i
              move    1 to cole
              if      SL-Stock-Link = "N"		*> No stock then process PA code
                      display "[             ][  ][" at curs with foreground-color 2 erase eol
                      move    51 to cole
                      display   "][     ][          ][     ][ ]" at curs  with foreground-color 2
              else				*> ignore PA
                      display "[             ][" at curs with foreground-color 2 erase eol
                      move    49 to cole
                      display "]  [     ][          ][     ][ ]" at curs  with foreground-color 2
              end-if
     end-perform
*>
*> this is what the item capture displays look like & 1st is for non-linked stock Control:
*>
*>    Product    Code <---------Description-------->   Qty   Unit Price  Disc. Vat
*>[      12 >13 ][2 ][        24 >30                ][  5  ][  9>10    ][  5  ][1]
*> If STOCK LINKED:
*>    Product     <----------Description--------->    Qty   Unit Price  Disc. Vat
*>[      12 >13 ][        24 >32                  ]  [  5  ][  9>10    ][  5  ][1]
*>
*>     subtract 16 from ws-23-lines giving m.  *> or move 1 to i = pos. in line item table
     subtract ws-Accept-Body from i.                    *> m = ws-accept-body
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
       and    i not = 40			*> max no. of items per invoice
              go to  loop.
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
     if       lin  >  ws-23-lines - 1
              subtract  1  from  i
              move  1  to  new-screen
              go to  main-exit.
*>
     move     zero  to  new-screen.
*>
 get-product.
*>**********
*>
     if       i  >  1
       and    sil-product (i) = spaces
              move  sil-product (i - 1)  to  sil-product (i).  *> display prev entered code for new line
*>                                                                to save typing
     display  i at 1223 with foreground-color 2.             *> disp line # on summary line
     move     2 to cole.
     move     sil-product (i) to ws-product.
     display  ws-product at curs with foreground-color 3.
     accept   ws-product at curs with foreground-color 3 update.
*>
     move     spaces  to  sil-description (i).
*>
*> process description accept & search via start / read next if F6 detected
*>
     if       cob-crt-status = cob-scr-F6
              go to Bypass-Product-Space-Tests.
*>
     if       ws-product = spaces
              go to main-exit.
     if       cob-crt-status = cob-scr-esc
              go to main-exit.
*>
 Bypass-Product-Space-Tests.
     move     function upper-case (ws-product) to ws-product.
     move     ws-product to sil-product (i)
                            test-product
                            ws-Stock-Key.
*>
     if       sil-comment
              move zero to ws-net ws-unit ws-qty
              go to  get-desc.
*>
     if       ws-product = "<<           "
              subtract  1  from  lin
              go to get-prod-test.
*>
     if       SL-Stock-Link not = "Y"    *> continue with old code to accept all data
              go to get-code.
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
*>     if       Stock-Desc not = "Not on File"
*>              display ws-pa        at line lin col 17 with foreground-color 3
     move     17 to cole.        *> Desc.
     move     Stock-sa-Group to ws-pa pa-group sil-pa (i).
     display  Stock-Desc   at curs with foreground-color 3.
     move     Stock-Desc    to ws-description sil-description (i).
     move     Stock-Retail  to amt-ok7.
     move     Stock-Retail  to ws-Unit.
     move     amt-wk-pds7   to ws-pound7.
     move     amt-wk-pence7 to ws-pence7.
     display  ws-amount-screen-display7 at line lin col 60 with foreground-color 3.
     move     Stock-Held to ws-qty.
     go       to Get-Qty.          *> Bypass manual input code as comes from stock record
*>
 get-prod-test.           *> THESE TESTS LOOK WRONG IF SCREEN LONGER THAN 24 LINES <<<<<<<<<<<<<
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
              go to  get-data-2.
*>
 get-code.
*>*******
*>
     if       i  >  1
       and    sil-pa (i) = spaces
              move  sil-pa (i - 1)  to  sil-pa (i).
*>
     move     sil-pa (i) to ws-pa.
     move     17 to cole.
     display  ws-pa at curs with foreground-color 3.
     accept   ws-pa at curs with foreground-color 3 update.
*>
     move     spaces  to  sil-description (i).
*>
     if       ws-pa = spaces
              go to  get-product.
*>
     move     ws-pa to pa-group sil-pa (i).
     move     "S" to pa-system.
     move     21 to cole.                         *> disp error in desc.
     read     analysis-file  record  invalid key
              display SL186 at curs  with foreground-color 4
              go to  get-code.
*>
 get-desc.
*>*******
*>
     if       i  >  1
         and  sil-description (i) = spaces
         and  not  sil-comment
              move  sil-description (i - 1) to  sil-description (i).
*>
     if       SL-Stock-Link = "Y"
              move 17 to cole
     else
              move 21 to cole.
     move     sil-description (i) to ws-description.
     display  ws-description at curs with foreground-color 3.
     accept   ws-description at curs with foreground-color 3 update.
*>
     move     ws-description to sil-description (i).
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
     if       sil-comment
              go to  jump-totals.
*>
 get-qty.
*>******
*>
     if       SL-Stock-Link = "N"		*> if it is shown current stock
              move     zero to ws-qty.
     move     53 to cole.
     display  ws-qty at curs with foreground-color 3.
     accept   ws-qty at curs with foreground-color 3 update.
*>
     if       ws-qty = zero
              go to get-desc.
     if       SL-Stock-Link = "Y"         *> make sure not selling more stock than held
       and    ws-qty > Stock-Held
              move Stock-Held to ws-Qty
              go to Get-Qty.
*>
     if       SL-Stock-Link = "Y"    *> bypass accept unit price
              go to Recomp-Net.
*>
 get-unit.
*>*******
*>
     move     60 to cole.
     perform  accept-money7a thru accept-money7b.
     if       amt-ok7 = zero
              go to get-qty.
     move     amt-ok7 to ws-unit.
*>
 Recomp-Net.
     multiply ws-qty by  ws-unit giving  ws-net on size error
              display  "SizEr" at curs with blink foreground-color 4
              go to get-qty.
*>
     move     ws-net to  display-9 sil-net (i).
     move     ws-qty to sil-qty (i).
     move     ws-unit to sil-unit (i).
     display  display-9 at 1232 with foreground-color 3.
*>
 get-disc.
     move     Sales-Discount  to  ws-discount.
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
     multiply work-n by work-d giving work-1
     divide   work-1 by 100    giving work-1
*>
     subtract work-1  from  ws-net.
*>
     move     ws-net to sil-net (i) display-9.
     display  display-9 at 1232 with foreground-color 3.
*>
 Get-Vat-Code.
*>***********
*>
     move     79 to cole.
     display  vat-code at curs with foreground-color 3.
     accept   vat-code at curs with foreground-color 3 update.
*>
     if       vat-code  >  3          *> using 1st three as last 2 are Sales tax, Not used in the UK.
              go to  Get-Vat-Code.    *> so change test for 'not = 4 or 5' instead of '> 3'
*>
     move     vat-code  to  sil-vat-code (i).
*>
     if       vat-code = zero
              move  zero  to  ws-vat
       else
              move vat-rate (vat-code) to ws-vat-rate
              compute  ws-vat rounded =  (ws-net * ws-vat-rate) / 100.
*>
     move     ws-vat to  display-9 sil-vat (i).
     display  display-9 at 1249 with foreground-color 3.
*>
     perform  Running-Totals.
*>
 jump-totals.
     add      1  to  j.
     add      1  to  i.
     go to    get-data-2.
*>
 Test-For-Read-Stock.
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
 end-totals              section.
*>==============================
*>
     move     zero to cob-crt-status.
     perform  total-screen.
     if       cob-crt-status = cob-scr-esc
              go to main-exit.
*>
     move     15  to  lin.
     move     1 to cole.
     display  " " at curs with erase eos.
*>
     display  "*********************" at 1660  with foreground-color 2
     display  "*" at 1760 with foreground-color 2
     display  "*" at 1780 with foreground-color 2
     display  "*" at 1860 with foreground-color 2
     display  "*" at 1880 with foreground-color 2
     display  "*" at 1960 with foreground-color 2
     display  "*" at 1980 with foreground-color 2
     display  "*********************" at 2060 with foreground-color 2.
*>
     display  "Invoice Ok to" at 1761 with foreground-color 2.
     if       pass-value = 2
              display "Store" at 1775 with foreground-color 2
     else
              display "Print" at 1775 with foreground-color 2.
     display  "(Y/N) ? [Y]" at 1968 with foreground-color 2.
*>
 confirmation.
*>***********
*>
     move     "Y"  to   ws-reply.
     accept   ws-reply at 1977 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       cob-crt-status = cob-scr-esc
              go to main-exit.
*>
     if       ws-reply = "N"
              go to  end-totals.
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
     write    invoice-record.
     if       fs-reply not = zero
              perform Eval-Status
              display sl180         at line ws-23-lines col  1 with erase eol foreground-color 4
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
*>
     if       first-sl-inv = zero
       and    pass-value not = 3
              move  sih-invoice to  first-sl-inv.
*>
     if       not del-exists
              add 1  to  next-invoice
     else
*>              move  zeros to del-inv-nos
              delete  del-inv-nos-file record.
*>
     if       pass-value = 3
              go to et-print.
*>
     move     1 to s-flag-i.
     move     11  to  lin.
     move     1 to cole.
     display  " " at curs with erase eos.
     go       to main-exit.
*>
 et-print.
*>*******
*>
     close    sales-file delivery-file open-item-file-3.
     close    analysis-file invoice-file del-inv-nos-file.
     if       SL-Stock-Link = "Y"
              close Stock-File Stock-Audit
     end-if
     call     "sl930" using ws-calling-data system-record to-day file-defs.
     exit     program.
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
     move     zero to sih-days sih-carriage.
     if       sih-type = 2
              move sales-credit  to  sih-days
     else if  sih-type = 4
              move pf-retention to sih-days.
     move     sih-days to ws-dayes.
     if       sih-type not = 2
              display ws-dayes at 1472 with foreground-color 3
              go to get-extra.
*>
     display  ws-dayes at 1472 with foreground-color 3.
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
     perform  accept-money7a thru accept-money7b.
     move     amt-ok7 to sih-carriage.
     compute  amt-ok6 rounded = sih-carriage * vat-rate-1 / 100.
*>
*> note that vat-rate-1 must be standard rate for p & p
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
     if       ws-named = "A"
        and   oi-net = sih-net
        and   oi-vat = sih-vat
        and   oi-carriage = sih-carriage
              move "Z" to ws-named.
*>
     if       (sih-type not = 2  and not = 3)		*> Invoices, Credit Notes
          or  not late-charges
          or  ws-named = "Z"
              move zero to sih-deduct-amt sih-deduct-vat sih-deduct-days
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
     move     zeros to sih-deduct-vat.
*>
     add      sih-net  sih-extra  sih-carriage  sih-deduct-amt giving  display-9.
     display  display-9 at 1926 with foreground-color 3.
*>
     add      sih-vat  sih-e-vat  sih-c-vat  sih-deduct-vat giving  display-8.
     display  display-8 at 1941 with foreground-color 3.
*>
     add      sih-net  sih-extra  sih-carriage  sih-deduct-amt
              sih-vat  sih-e-vat  sih-c-vat  sih-deduct-vat   giving  display-9.
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
     display  "Invoicing Data Entry" at 0132           with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
     display  "****************************************" at 0441 with foreground-color 2.
     display  "*Date  [  /  /    ]*                   *" at 0541 with foreground-color 2.
     display  "*A/C Nos  [       ]*Ref    [          ]*" at 0641 with foreground-color 2.
     display  "*Invoice [        ]*Order  [          ]*" at 0741 with foreground-color 2.
     display  "****************************************" at 0841 with foreground-color 2.
     display  "F1 = Setup new Customer; F8 = Only Show delivery details" at 0911 with foreground-color 2.
     display  "Type [ ]  <1> = Receipt; <2> = Account; <3> = Credit Note; <4> = Pro-Forma"
                                                         at 1001  with foreground-color 2.
*>
 date-input.
*>*********
*>
     display  ws-date at 0549 with foreground-color 3.
     accept   ws-date at 0549 with foreground-color 3 update.
*>
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
     move     ws-test-date to ws-date.  *> still need orig. disp date as ws-date now UK
     move     u-bin  to  sih-date.
*>
 customer-input.
*>*************
*>
     move     spaces  to  sih-customer.
     move     zero to cob-crt-status.
     accept   sih-customer at 0652 with foreground-color 3 update.
     move     function upper-case (sih-customer) to sih-customer.
*>
     if       Cob-Crt-Status = Cob-Scr-F8
              move "Y" to ws-Show-Delivery
     else
              move "N" to ws-Show-Delivery
     end-if
     if       sih-customer not = "CREATE9"		*> Feature for 1 user, should not be needed now!!
              go to customer-test.
     display  "Creating Invoice File                    " at 2301  with foreground-color 2.
     close    invoice-file.
     open     output invoice-file.
     close    invoice-file.
     move     1 to file-status (16).
     open     i-o invoice-file.
*>
 customer-test.
*>************
*>
     if       sih-customer = "NEW"
         or   Cob-Crt-Status = Cob-Scr-F1
              go to new-customer.
*>
     if       sih-customer = spaces
              move  "Q"  to  escape-code
              go to  main-exit.
*>
     move     1  to  c-check.
     move     sih-customer  to  sales-key.
*>
     read     sales-file  record  invalid key
              move  zero  to  c-check.
*>
     if       not  c-exists
              display  "No such Customer" at 0401 with foreground-color 3
              go to  customer-input.
*>
     display  "                       " at 0911.  *> Clear F1 comment
*>
     if       sl-own-nos = "Y"
              go to get-inv.
*>
     if       del-exists
              perform get-a-deleted-invoice
     else
              move next-invoice  to  sih-invoice.
*>
     display  sih-invoice at 0751 with foreground-color 3.
     move     space to sih-letter.
     go       to jump-1.
*>
 get-inv.
*>******
*>
     accept   sih-invoice at 0751 with foreground-color 3 update.
     if       cob-crt-status = cob-scr-esc
              go to customer-input.
     move     space to sih-letter.
*>
 try-again.
     move     zero to sih-test.
     move     sih-invoice  to  invoice-nos.
     move     sih-letter   to  invoice-let.
     move     sih-test     to  item-nos.
     read     invoice-file invalid key
              go to jump-1.
     display  "Confirm Duplicate - [ ]" at 0701  with foreground-color 2.
     accept   ws-reply at 0722 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply not = "Y"
              go to  get-inv.
     if       sih-letter = " "			*> Come on, 4 dups really is 3 too many
              move "A"  to  sih-letter
     else
      if      sih-letter = "A"
              move  "B"  to  sih-letter
      else
       if     sih-letter = "B"
              move  "C"  to  sih-letter.
     go       to try-again.
*>
 jump-1.
*>*****
*>
     if       delivery-tag = zero	*> Only show delivery details if F8 pressed instead of
       or     ws-Show-Delivery = "N"	*> accept on cust no. input
              go to customer-setup.
*>
     move     "D"       to Deliv-Key-Type.
     move     Sales-Key to Deliv-Sales-Key.
     read     delivery-file  invalid key
              move  zero  to  delivery-tag
              go to  customer-setup.
*>
     move     deliv-address to address-a.
     go       to customer-display.
*>
 customer-setup.
*>*************
*>
     move     sales-address  to  address-a.
*>
 customer-display.
*>***************
*>
     if       delivery-tag = zero
              display sales-name at 0301 with foreground-color 3
     else
              display deliv-name at 0301 with foreground-color 3.
*>
     move     1  to  z.
     unstring address-a  delimited  by  sl-delim   into  address-line  count z  pointer  z.
     display  address-line at 0401 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address-a  delimited  by  sl-delim   into  address-line  count z  pointer  z.
     display  address-line at 0501 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address-a  delimited  by  sl-delim   into  address-line  count z  pointer  z.
     display  address-line at 0601 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address-a  delimited  by  sl-delim   into  address-line  count z  pointer  z.
     display  address-line at 0701 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring address-a  into  address-line   pointer  z.
     display  address-line at 0801 with foreground-color 3.
*>
     move     spaces  to  address-line.
*>
 ref-input.
*>********
*>
     move     spaces to sih-ref sih-order.
     accept   sih-ref at 0669 with foreground-color 3 update.
*>
 order-input.
*>**********
*>
     accept   sih-order at 0769 with foreground-color 3 update.
*>
 type-input.
*>*********
*>
     move     zero to sih-type.
     accept   sih-type at 1007 with foreground-color 3 update.
     move     space to ws-named.
     if       sih-type = zero
              go to invoice-details.
*>
     if       sih-type  >  4
              go to  type-input.
     move     d-types (sih-type) to add-line1.
     display  " " at 1001 with erase eol.
     display  ">>> " at 1031 with foreground-color 2.
     display  add-line1 at 1035 with foreground-color 2.
*>
     move     zero to sih-cr.
     if       sih-type = 3
              perform  cr-note
              if    escape-code = "Q"
                    go to  invoice-details.
*>
     move     zero to z.
*>
     if       sih-type = 1  or  >  2
              go to  main-exit.
*>
     move     zero  to  we-error.
*>
     subtract sales-unapplied from sales-current.
*>
     if       sales-current  >  zero
              subtract sales-last-inv from run-date giving  work-1
              if work-1  >  sales-credit
              display "Overdue Balance <<<" at 1648   with foreground-color 2 highlight
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
     display  ">>> Warning! " at 1635 with foreground-color 2  highlight.
     display  "**********************" at 1958  with foreground-color 2.
     display  "*" at 2058 with foreground-color 2.
     display  "*" at 2158 with foreground-color 2.
     display  "*" at 2079 with foreground-color 2.
     display  "*" at 2179 with foreground-color 2.
     display  "**********************" at 2258  with foreground-color 2.
*>
     display  "None Zero To Abort" at 2060 with foreground-color 2.
     display  "Return To Continue" at 2160 with foreground-color 2.
     move     zero to z.
     accept   z at 2280 with foreground-color 6 update.
     if       cob-crt-status = cob-scr-esc
              move 1 to z   cob-crt-status.
     go       to main-exit.
*>
 new-customer.
*>***********
*>
     close    sales-file invoice-file del-inv-nos-file.
     close    delivery-file analysis-file open-item-file-3.
     if       SL-Stock-Link = "Y"
              close Stock-File.
     if       Stk-Audit-Used = 1
              close Stock-Audit.
     call     "sl960" using ws-calling-data system-record to-day.
     perform  program-start.
     go       to invoice-details.
*>
 main-exit.   exit section.
*>********    ****
*>
 get-a-deleted-invoice section.
*>============================
*>
     if       not del-exists
              go to l70ad-terminate.
 l70ab-read.
*>---------
*>
     read     del-inv-nos-file at end
              go to l70ac-close.
     if       del-inv-nos = zero
              go to l70ab-read.
     move     del-inv-nos to sih-invoice.
     display  "Using Deleted Invoice Numbers" at 0345  with foreground-color 2 blink.
     go       to l70ae-exit.
*>
 l70ac-close.
*>==========
*>
     close    del-inv-nos-file.
     open     output del-inv-nos-file.
     display  "                             " at 0345.
*>
 l70ad-terminate.
*>==============
*>
     move     next-invoice to sih-invoice.
     move     zero to ws-delinv.
*>
 l70ae-exit.
     exit     section.
*>
 cr-note             section.
*>==========================
*>
 main.
     display  " " at 1201 with erase eol.
     display  " " at 1301 with erase eol.
     display  " " at 1401 with erase eol.
     display  " " at 1501 with erase eol.
     display  " " at 1601 with erase eol.
*>
 main-input.
*>**********
*>
     display  "Invoice To Credit - [" at 1201  with foreground-color 2.
     display  "] " at 1230 with foreground-color 2.
*>
     move     zero  to  ws-cr.
*>
     accept   ws-cr at 1222 with foreground-color 3 update.
     if       cob-crt-status = cob-scr-esc
              move "Q" to escape-code
              go to main-exit.
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
     move     sih-cr  to  oi3-invoice.
     move     sih-customer to oi3-customer.
*>
     read     open-item-file-3 invalid key		*> Error cant find the invoice
              display SL181   at line ws-23-lines col 01 with foreground-color 2 highlight
              go to  check-inv-no-ok.
*>
     display  " " at line ws-23-lines col 01 with erase eol.
     if       oi-type not = 2		*> Error can only credit invoices
              display SL184  at line ws-23-lines col 01 with foreground-color 2 highlight
              go to main-input.
*>
     if       s-closed			*> Error invoice is Paid
              display SL182  at 1301  with foreground-color 2 highlight
              go to main-input
     else
              display " " at line ws-23-lines col 01 with erase eol.
*>
     if       oi-hold-flag = "Q"	*> Warning Invoice has query flag set but we can continue
              display SL183  at line ws-23-lines col 01  with foreground-color 2 highlight.
*>
     move     oi-date to u-bin.
     add      1 oi-deduct-days to u-bin.
     if       u-bin > sih-date
              move "A" to ws-named.
*>
     add      oi-deduct-vat to oi-deduct-amt.
     add      oi-extra oi-carriage oi-deduct-amt oi-net
              oi-vat oi-c-vat oi-e-vat to oi-discount.
     subtract oi-paid from oi-discount.
*>
     display  "Amount O/S on Invoice is " at 1401   with foreground-color 2.
     move     oi-discount to display-9.
     display  display-9 at 1426 with foreground-color 3.
     move     oi-deduct-amt to display-8.
     display  "of which" at 1437 with foreground-color 2.
     display  display-8 at 1446 with foreground-color 3.
     display  "is Late Charges" at 1456 with foreground-color 2.
     if       ws-named = "A"
              display SL185 at 1510 with foreground-color 2.
     display  SL006  at 1626.
     accept   ws-reply  at 1661.
*>
 no-inv-restart.
*>*************
*>
     perform  main.
     go       to main-exit.
*>
 check-inv-no-ok.
*>
     display  "Do you wish to use this Invoice No.? {N}" at 1401 with foreground-color 2.
     display  "..If so, you must ensure that it belonged to the same customer and that it is a "
                                                         at 1501 with foreground-color 2.
     display  "Invoice ie, not a receipt"                at 1601 with foreground-color 2.
     move     "N" to ws-reply.
     accept   ws-reply at 1439 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "Y"
              go to no-inv-restart.
     if       ws-reply = "N"
              go to main.
     go       to check-inv-no-ok.
*>
 main-exit.   exit section.
*>********    ****
*>
 Program-Start section.
*>====================
*>
     display  " " at 0101 with erase eos.
     move     to-day to u-date.          *> in UK date form
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
*>
     if       file-status (16) not = 1
              open  output  invoice-file
              close invoice-file
              move  1  to  file-status (16).
*>
     if       file-status (19) not = 1
              open output open-item-file-3
              close open-item-file-3
              move 1 to file-status (19).
*>
     move     zero  to  menu-reply.
     open     i-o invoice-file.
     open     input open-item-file-3.
*>
     open     input del-inv-nos-file.
     if       fs-reply not = zero
              move zero to ws-delinv    *> REMOVED GOTO
*>
*>   therefore deleted invoices exist (maybe)
*>
     else
         close    del-inv-nos-file
         open     i-o del-inv-nos-file
         move     1 to ws-delinv
     end-if
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
 main-exit.   exit section.
*>********    ****
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
 maps99       section.
*>===================
*>
     call     "maps99"  using  error-code ws-calling-data.
*>
 main-exit.   exit section.
*>********    ****
*>
