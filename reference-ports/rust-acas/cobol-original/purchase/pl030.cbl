       >>source free
*>***********************************************
*>                                              *
*>         Invoice   Maintenance                *
*>            SL920 is similar                  *
*>***********************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl030.
*>**
*>    Author.             V B Coen FBCS, For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Invoice Maintenance.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps04.
*>                        Maps99.
*>**
*>    Error messages used.
*>                        PL006
*>                        PL180
*>                        PL184
*>                        PL186
*>                        PL187
*>                        PL188
*>                        PL189
*>                        PL190
*>**
*>  Changes.
*> 07/01/85 Vbc - Fix Bug Clear Screen In Cr-Notes.
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00
*> 12/12/11 vbc - .01 Error msgs to SLnnn.Support for dates other than UK
*>                    Support for path+filenames.
*>                    Updated version to 3.01.nn, added support for IS delivery file
*>                    tie up with sl920
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
*>
 input-output            section.
*>------------------------------
*>
 file-control.
*>-----------
*>
 copy "selanal.cob".
 copy "selpl.cob".
 copy "selpinv.cob".
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdanal.cob".
 copy "fdpl.cob".
 copy "fdpinv.cob".
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "PL030 (3.01.01)".
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
 01  ws-discount redefines ws-discount-work pic 99v99.
*>
 copy "wspinv.cob".
*>
 01  ws-data.
     03  test-product.
         05  filler      pic x.
             88  il-comment              value "/".
         05  filler      pic x(11).
     03  menu-reply      pic 9.
     03  ws-reply        pic x.
     03  z               pic 99.
     03  c-check         pic 9.
         88  c-exists                    value  1.
     03  address-line.
         05  add-line1   pic x(15).
         05  add-line2   pic x(21).
     03  ws-named        pic x           value space.
     03  ws-dash         pic x(80)       value all "-".
     03  display-8       pic z(5)9.99.
     03  display-9       pic z(6)9.99.
     03  vat-code        pic 9.
     03  i               pic 99.
     03  j               pic 99.
     03  k               pic 99.
     03  m               pic 99.
     03  escape-code     pic x.
     03  new-screen      pic 9(8).
     03  altypes         pic x(45) value
     "Receipt <<<    Account <<<    Credit Note <<<".
     03  filler redefines altypes.
         05  d-types     pic x(15) occurs 3.
     03  ws-vat-rate     pic 99v99.
     03  ws-pa           pic xx.
     03  ws-product      pic x(12).
     03  ws-description  pic x(24).
     03  ws-qty          pic 9(5).
     03  ws-net          pic 9(7)v99.
     03  ws-vat          pic 9(7)v99.
     03  ws-unit         pic 9(6)v99.
     03  ws-cr           pic 9(8).
     03  ws-dayes        pic 99.
*>
     03  ws-env-lines    pic 999       value zero.
     03  ws-lines        binary-char unsigned value zero.
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
*>     03  PL003          pic x(28) value "PL003 Hit Return To Continue".
     03  PL006          pic x(43) value "PL006 Note Details & Hit Return to continue".

*> Module specific
     03  PL180          pic x(34) value "PL180 Err on Invoice file write : ".
     03  PL184          pic x(62) value "PL184 You Can Only Credit Invoices. Not Receipts, Credit Notes".
     03  PL186          pic x(36) value "PL186 Err on Invoice file rewrite : ".
     03  PL187          pic x(27) value "PL187 Invoice Not Found!!!!".
     03  PL188          pic x(48) value "PL188 Invoice Already Passed To Purchase Ledger!".
     03  PL189          pic x(54) value "PL189 Invoice To Credit Does Not Exist On Invoice File".
     03  PL190          pic x(65) value "PL190 You Can Only Credit An Invoice With The Same Account Number".
*>
 01  error-code          pic 999.
*>
 01  delete-test.
     03  delete-field    pic xx.
     03  filler          pic x(10).
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
     accept   ws-env-lines   from lines.
     if       ws-env-lines < 24
              move  24 to ws-env-lines ws-lines
     else
              move  ws-env-lines   to ws-lines
     end-if
     subtract 1 from ws-lines giving ws-23-lines.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
*>
     perform  program-start.
*>
 main.
*>***
*>
     initialize Pinvoice-lines.
     perform  invoice-details
*>
     if       cob-crt-status = cob-scr-esc
       or     z not = zero
       or     escape-code = "Q"
              go to  main-exit.
*>
     move     16  to  lin.
     perform  erase-screen.
*>
 data-input.
*>*********
*>
     move     zero to   ih-p-c ih-net ih-vat.
*>
     move     zero to  i.
     perform  inv-level-1
     if       cob-crt-status = cob-scr-esc
              go to main.
*>
     if       i not = 1
              perform end-totals.
*>
 more-data.
*>
     display "Amend further invoices? (Y/N)  [Y]" at 1629 with foreground-color 2.
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
 main-exit.
*>********
*>
     go       to menu-exit  of  program-start.
*>
*>****************************************************************
*>               P R O C E D U R E S                             *
*>****************************************************************
*>
 running-totals section.
*>=====================
*>
     move     zero  to  ih-net
                        ih-vat.
*>
     perform  varying k from 1 by 1 until k > i
              if  il-type (k) not = "D"
                  add il-net (k)  to  ih-net
                  add il-vat (k) to  ih-vat
     end-perform
     move     ih-net  to  display-9.
     display  display-9 at 1237 with foreground-color 3.
*>
     move     ih-vat  to  display-9.
     display  display-9 at 1255 with foreground-color 3.
*>
     add      ih-net  ih-vat  giving  display-9.
*>
     display  display-9 at 1268 with foreground-color 3.
*>
 main-exit.   exit section.
*>********    ****
*>
 write-details section.
*>====================
*>
     add      1  to  j.
     move     ih-invoice  to  il-invoice (j).
     move     j  to  il-line (j).
     move     ih-type to il-type (j).
     move     invoice-line (j)  to  invoice-record.
*>
     rewrite  invoice-record invalid key
              write invoice-record.
*>
     if       fs-reply not = zero
              perform Eval-Status
              display pl180         at 2001 with erase eol foreground-color 4
              display fs-reply      at 2036 with foreground-color 3
              display exception-msg at 2039 with foreground-color 3
              display invoice-key   at 2064 with foreground-color 3
              display pl006         at 2101 with foreground-color 3
              accept  ws-reply at 2130
              display " " at 2001 with erase eol
              display " " at 2101 with erase eol.
*>
 main-exit.   exit section.
*>********    ****
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
     perform  ih-lines times
              add  1 to j
              move ih-invoice to invoice-nos
              move j to item-nos
              read invoice-file
              end-read
              move invoice-record to invoice-line (j)
     end-perform.
*>
 main-exit.   exit section.
*>********    ****
*>
 maps99       section.
*>===================
*>
     call     "maps99"  using  error-code ws-calling-data.
*>
 main-exit.   exit section.
*>********    ****
*>
 comm-routines section.
*>********************
*>
 accept-money6c.
*>-------------
*>
     move     amt-wk-pence6 to ws-pence6.
     move     amt-wk-pds6 to ws-pound6.
     display  ws-amount-screen-display6 at curs with foreground-color 3.
     accept   ws-amount-screen-accept6 at curs  with foreground-color 3 update.
     move     ws-pound6 to amt-wk-pds6.
     move     ws-pence6 to amt-wk-pence6.
*>
 accept-money7c.
*>-------------
*>
     move     amt-wk-pence7 to ws-pence7.
     move     amt-wk-pds7 to ws-pound7.
     display  ws-amount-screen-display7 at curs with foreground-color 3.
     accept   ws-amount-screen-accept7 at curs  with foreground-color 3 update.
     move     ws-pound7 to amt-wk-pds7.
     move     ws-pence7 to amt-wk-pence7.
*>
 comm-exit.   exit section.
*>--------    ----
*>
 inv-level-1  section.
*>====================
*>
     display  ws-dash at 1101 with foreground-color 2.
     display  "Level 1" at 1201 with foreground-color 2.
     display  "Line - " at 1216 with foreground-color 2.
     display  "<          >" at 1236 with foreground-color 2.
     display  "<          >" at 1254 with foreground-color 2.
     display  "<          >" at 1267 with foreground-color 2.
     display  "Code" at 1406 with foreground-color 2.
     display  "<---Net----> Vat   Vat Amount  Gross Amount" at 1436 with foreground-color 2.
*>
 loop.
*>***
*>
     perform  display-outline-1 varying lin from 16 by 1 until lin > ws-23-lines.
*>
     subtract 16 from ws-23-lines giving m.
     subtract m  from  i.
     move     1 to j.
     display  i at 1223 with foreground-color 3.
*>
     perform  get-data-1.
     if       cob-crt-status = cob-scr-esc
              go to main-exit.
*>
     if       new-screen = 1
              go to loop.
*>
     if       il-description (i) not = spaces
        and   i not = 40
        and   escape-code not = "Q"
              go to  loop.
*>
 main-exit.   exit section.
*>********    ****
*>
 get-data-1   section.
*>===================
*>
     add      j  15  giving  lin.
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
     move     il-pa (i) to ws-pa.
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
                    subtract  8  from  i
                    go to  get-data-1.
*>
     move     ws-pa to delete-test.
     if       delete-field = "**"
              perform clear-down-line
              subtract 1 from i
              perform display-outline-1
              go to get-code.
*>
     move     ws-pa to il-pa (i) pa-group.
     move     "P" to pa-system.
     move     11 to cole.
     read     analysis-file  record  invalid key
              display "P.A. Code Does Not Exist!" at curs with foreground-color 4
              go to  get-code.
*>
     display  pa-desc at curs with foreground-color 3.
     move     pa-desc  to  il-description (i).
*>
 get-net.
*>******
*>
     move     37 to cole.
     move     il-net (i) to amt-ok7.
     perform  accept-money7c.
     if       amt-ok7 = zero
              go to get-code.
     move     amt-ok7 to il-net (i) ws-net.
*>
 get-vat-code.
*>***********
*>
     move     50 to cole.
     move     il-vat-code (i) to vat-code.
     display  vat-code at curs with foreground-color 3.
     accept   vat-code at curs with foreground-color 3 update.
*>
     if       vat-code  >  3     *> last two are for non-UK sales tax
              go to  get-vat-code.
*>
     move     vat-code  to  il-vat-code (i).
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
     move     amt-ok6 to il-vat (i) ws-vat.
*>
     add      ws-vat ws-net giving  display-9.
     move     68 to cole.
     display  display-9 at curs with foreground-color 3.
*>
     perform  running-totals.
*>
     add      1 to j.
     add      1  to  i.
     go to    get-data-1.
*>
 clear-down-line.
*>**************
*>
     perform  varying z from i by 1 until z > 39
              move invoice-line (z + 1) to invoice-line (z)
              move z to il-line (z)
     end-perform
*>
     move     zero to z.
     if       i not > ih-lines
              move ih-invoice to invoice-nos
              move ih-lines  to  item-nos
              delete invoice-file record
              subtract 1 from ih-lines.
*>
 main-exit.   exit section.
*>
 erase-screen section.
*>===================
*>
     move     1 to cole.
     display  " " at curs with erase eos.
*>
 main-exit.   exit section.
*>********    ****
*>
 end-totals   section.
*>===================
*>
     perform  total-screen.
*>
     move     15  to  lin.
     perform  erase-screen.
*>
     display  "*********************" at 1660  with foreground-color 2.
     display  "*" at 1760 with foreground-color 2.
     display  "*" at 1780 with foreground-color 2.
     display  "*" at 1860 with foreground-color 2.
     display  "*" at 1880 with foreground-color 2.
     display  "*" at 1960 with foreground-color 2.
     display  "*" at 1980 with foreground-color 2.
     display  "*" at 1760 with foreground-color 2.
     display  "*" at 1780 with foreground-color 2.
     display  "*********************" at 2060  with foreground-color 2.
*>
     display  "Invoice ok to store" at 1761  with foreground-color 2.
     display  "(Y/N) ? [Y]" at 1968 with foreground-color 2.
*>
*>
 confirmation.
*>***********
*>
     move     "Y"  to   ws-reply.
     accept   ws-reply at 1977 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "N"
              go to  end-totals.
*>
     if       ws-reply not = "Y"
              go to  confirmation.
*>
     move     "P"  to  ih-status.
     subtract 1  from  i.
     move     i    to  ih-lines.
*>
     move     invoice-header  to  invoice-record.
     rewrite  invoice-record.
     if       fs-reply not = zero
              perform Eval-Status
              display pl186         at 2001 with erase eol foreground-color 4
              display fs-reply      at 2036 with foreground-color 3
              display exception-msg at 2039 with foreground-color 3
              display invoice-key   at 2064 with foreground-color 3
              display pl006         at 2101 with foreground-color 3
              accept  ws-reply at 2130
              display " " at 2001 with erase eol
              display " " at 2101 with erase eol.
*>
     move     zero to  j.
     perform  write-details  i  times.
     move     11  to  lin.
     move     1 to p-flag-i.
     perform  erase-screen.
*>
 main-exit.   exit section.
*>********    *****
*>
 total-screen section.
*>===================
*>
     move     1 to cole.
     move     11 to lin.
     display  " " at curs with erase eos.
     display  ws-dash at 1101 with foreground-color 2.
*>
     display  "Level 1" at 1201 with foreground-color 2.
     display  "<---Net---->   <---Vat--->" at 1325  with foreground-color 2.
     display  "<---Gross-->     Days" at 1354       with foreground-color 2.
     display  "Sub-Totals" at 1504 with foreground-color 2.
     display  "{          }   {         }" at 1525  with foreground-color 2.
     display  "{          }     [  ]" at 1554       with foreground-color 2.
*>
     display  "Prompt Payment Disc" at 1704         with foreground-color 2.
     display  "[          ]" at 1725 with foreground-color 2.
     display  "{          }     [  ]" at 1754       with foreground-color 2.
*>
     display  "Shipping & Handling" at 1904         with foreground-color 2.
     display  "[          ]   [         ]" at 1925  with foreground-color 2.
     display  "{          }" at 1954 with foreground-color 2.
*>
     display  "------------   -----------" at 2225  with foreground-color 2.
     display  "------------" at 2254 with foreground-color 2.
*>
     display  "Itemised Totals" at 2304 with foreground-color 2.
     display  "{          }   {         }" at 2325  with foreground-color 2.
     display  "{          }" at 2354 with foreground-color 2.
*>
     move     ih-net  to  display-9.
     display  display-9 at 1526 with foreground-color 3.
*>
     move     ih-vat  to  display-8.
     display  display-8 at 1541 with foreground-color 3.
*>
     add      ih-net  ih-vat  giving  display-9.
     display  display-9 at 1555 with foreground-color 3.
*>
 get-days.
*>*******
*>
     move     ih-days to ws-dayes.
     display  ws-dayes at 1572 with foreground-color 3.
     if       ih-type not = 2
              move zero to ih-days
              go to get-carriage.
*>
     accept   ws-dayes at 1572 with foreground-color 3 update.
     move     ws-dayes to ih-days.
*>
 get-extra.
*>********
*>
     move     1726 to curs.
     move     ih-deduct-amt to amt-ok7.
     perform  accept-money7c.
     if       amt-ok7 not < 1000
              go to get-extra.
     move     amt-ok7 to ih-deduct-amt display-9.
*>
     if       ih-deduct-amt equal  zero
              move zero to ih-deduct-vat ih-deduct-days
              go to get-carriage.
*>
     display  display-9 at 1755 with foreground-color 3.
     move     ih-deduct-days to ws-days.
     display  ws-days at 1772 with foreground-color 3.
     accept   ws-days at 1772 with foreground-color 3 update.
     move     ws-days to ih-deduct-days.
*>
 get-carriage.
*>***********
*>
     move     1926 to curs.
     move     ih-carriage to amt-ok7.
     perform  accept-money7c.
     move     amt-ok7 to ih-carriage.
     compute  amt-ok6 rounded  = ih-carriage * vat-rate-1 / 100.
*>
*> Note that vat-rate-1 must be standard rate for p & p
*>
 get-carriage-vat.
*>***************
*>
     move     1941 to curs.
     perform  accept-money6c.
     move     amt-ok6 to ih-c-vat.
     add      ih-carriage  ih-c-vat  giving  display-9.
     display  display-9 at 1955 with foreground-color 3.
*>
     add      ih-net ih-carriage giving  display-9.
     display  display-9 at 2326 with foreground-color 3.
*>
     add      ih-vat ih-c-vat giving  display-8.
     display  display-8 at 2341 with foreground-color 3.
*>
     add      ih-net ih-carriage ih-vat ih-c-vat giving display-9.
     display  display-9 at 2355 with foreground-color 3.
     display  "ok  [ ]" at 2374 with foreground-color 2.
     accept   ws-reply at 2379 with foreground-color 6.
     move     function upper-case (ws-reply) to ws-reply.
*>
 main-exit.   exit section.
*>********    ****
*>
 invoice-details section.
*>======================
*>
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "Invoice Data Amend" at 0133  with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
     display  "****************************************" at 0441 with foreground-color 2.
     display  "*Date [  /  /    ]*A/C Nos    [       ]*" at 0541 with foreground-color 2.
     display  "**                *Order   [          ]*" at 0641 with foreground-color 2.
     display  "*Folio  [        ]*Invoice [          ]*" at 0741 with foreground-color 2.
     display  "****************************************" at 0841 with foreground-color 2.
*>
 main-display-end.
*>
     display  "Type [ ]  <1> = Receipt; <2> = Account; <3> = Credit Note"
                                             at 1001 with foreground-color 2.
*>
 invoice-enter.
*>************
*>
     move     zero to ih-invoice.
     display  ih-invoice at 0750 with foreground-color 3.
     accept   ih-invoice at 0750 with foreground-color 3 update.
     if       ih-invoice = zero
           or cob-crt-status = cob-scr-esc
              move 1 to z
              go to main-exit.
*>
     move     zero to item-nos.
     move     ih-invoice  to  invoice-nos.
     read     invoice-file invalid key
              display PL187 at 1640 with foreground-color 2
              go to invoice-enter.
     move     invoice-record to invoice-header.
     display  " " at 1640 with erase eol.
*>
     if       applied
              display PL188 at 1601 with foreground-color 2 erase eol
              go to invoice-enter.
*>
     display  " " at 1601 with erase eol.
     move     ih-date to u-bin.
     perform  zz060-Convert-Date.   *> now have ws-date
     perform  read-details.
*>
 date-input.
*>*********
*>
     display  ws-date at 0548 with foreground-color 3.
     accept   ws-date at 0548 with foreground-color 3 update.
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
     move     u-bin  to  ih-date.
*>
 supplier-input.
*>*************
*>
     display  ih-supplier at 0572 with foreground-color 3.
     accept   ih-supplier at 0572 with foreground-color 3 update.
     move     function upper-case (ih-supplier) to ih-supplier.
*>
     if       cob-crt-status = cob-scr-esc
         or   ih-supplier = spaces
              move  "Q"  to  escape-code
              go to  main-exit.
*>
     move     1  to  c-check.
*>
     move     ih-supplier  to  purch-key.
*>
     read     purchase-file invalid key
              move  zero  to  c-check.
*>
     if       not  c-exists
              go to  supplier-input.
*>
     display  purch-name at 0301 with foreground-color 3.
*>
     move     1  to  z.
     unstring purch-address  delimited by  pl-delim into  address-line count z pointer  z.
     display  address-line at 0401 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring purch-address  delimited by  pl-delim into  address-line count z pointer  z.
     display  address-line at 0501 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring purch-address  delimited by  pl-delim into  address-line count z pointer  z.
     display  address-line at 0601 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring purch-address  delimited by  pl-delim into  address-line count z pointer  z.
     display  address-line at 0701 with foreground-color 3.
*>
     move     spaces  to  address-line.
     unstring purch-address    into  address-line   pointer  z.
     display  address-line at 0801 with foreground-color 3.
*>
     move     spaces  to  address-line.
*>
 order-input.
*>**********
*>
     display  ih-order at 0669 with foreground-color 3.
     accept   ih-order at 0669 with foreground-color 3 update.
*>
 ref-input.
*>********
*>
     display  ih-ref at 0769 with foreground-color 3.
     accept   ih-ref at 0769 with foreground-color 3 update.
*>
 type-input.
*>*********
*>
     display  ih-type at 1007 with foreground-color 3.
     accept   ih-type at 1007 with foreground-color 3 update.
*>
     if       ih-type = zero
              go to main-exit.
*>
     if       ih-type  >  3
              go to  type-input.
*>
     if       ih-type = 3
              perform  cr-note
              if  escape-code = "Q"
                  perform main-display-end
                  go to  type-input.
*>
     move     zero to z.
     go       to main-exit.
*>
 main-exit.   exit section.
*>********    ****
*>
 cr-note      section.
*>===================
*>
 main-display.
     display  " " at 1201 with erase eol
     display  " " at 1301 with erase eol.
     display  " " at 1401 with erase eol.
     display  " " at 1501 with erase eol.
     display  " " at 1601 with erase eol.
*>
 main-input.
*>*********
*>
     display  "Invoice to Credit - [        ]" at 1201  with foreground-color 2.
*>
     move     ih-cr to  ws-cr.
*>
     display  ws-cr at 1222 with foreground-color 3.
     accept   ws-cr at 1222 with foreground-color 3 update.
     move     ws-cr to ih-cr.
     if       ih-cr = zero
              move  "Z"  to  ws-named
              go to  no-inv-restart
     else
              move  " "  to  ws-named.
*>
     if       ih-cr = 99999999
              move "Q" to escape-code
              go to main-exit
     else
              move space to escape-code.
*>
     move     ih-cr  to  invoice-nos.
     move     zero   to  item-nos.
*>
     read     invoice-file  invalid key
              display PL189 at 1332 with foreground-color 2
              go to  check-inv-no-ok.
*>
     display  " " at 1301 with erase eol.
     if       invoice-type not = 2
              display PL184 at 1301 with foreground-color 2
              go to main-input.
     if       invoice-supplier not = purch-key
              display PL190 at 1301  with foreground-color 2
              go to main-input.
*>
 no-inv-restart.
*>*************
*>
     perform  main-display.
*>
 main-end.
*>*******
*>
     go       to main-exit.
*>
 check-inv-no-ok.
*>
     display  "Do you wish to use this invoice no.? {N}" AT 1401 with foreground-color 2.
     display  "..If so, you must ensure that it belongs to the " &
              "same Supplier and that it is a " AT 1501 with foreground-color 2.
     display  "INVOICE ie not a Receipt" AT 1601 with foreground-color 2.
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
 program-start section.
*>====================
*>
     display  " " at 0101 with erase eos.
     move     to-day to u-date ws-test-date.
     if       file-status (15)  not equal 1
              move 29  to  error-code
              perform  maps99
              move 15 to error-code
              perform  maps99.
*>
     open     input purchase-file analysis-file.
     open     i-o invoice-file.
*>
 menu-return.
*>**********
*>
     move     zero  to  menu-reply.
     go       to main-exit.
*>
 menu-exit.
*>********
*>
     move     zero to  pass-value.
     close    purchase-file analysis-file invoice-file.
*>
     exit     program.
*>
 main-exit.   exit section.
*>********    ****
*>
 display-outline-1       section.
*>==============================
*>
     add      1  to  i.
     move     1 to cole.
     display  " " at curs with erase eol.
     display  "(" at curs         with foreground-color 2.
     move     2 to cole.
     display  i at curs           with foreground-color 3.
     move     4 to cole.
     display  ") [  ]" at curs    with foreground-color 2.
     move     36 to cole.
     display  "[          ] [ ]   {         } (" at curs with foreground-color 2.
     move     78 to cole.
     display  ")" at curs         with foreground-color 2.
*>
 main-exit52a. exit section.
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
