       >>source free
*>*******************************************************
*>                                                      *
*>        Transaction  Maintenance  (Program 2)         *
*>                                                      *
*>*******************************************************
*>
 identification          division.
*>===============================
*>
*>**
      Program-Id.         gl051.
*>**
*>    Author.             V.B.Coen, FBCS,
*>                        Converted To Cis December 84,
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Batch/Posting Amendment/Reporting.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Modules Called.     maps04.
*>**
*>    Error messages used.
*>                        GL011
*>                        GL108
*>                        GL109
*>                        GL110
*>                        GL111
*>**
*>    Changes:
*> 29/01/09 vbc - Migration to Open Cobol.
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 07/09/10 vbc - .03 Mod lpr.
*> 19/12/11 vbc - .04 Support for dates other than UK & clean up msgs
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
*>------------
*>
 copy "seledger.cob".
 copy "selbatch.cob".
 copy "selpost.cob".
 copy "selprint.cob".
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdledger.cob".
 copy "fdbatch.cob".
 copy "fdpost.cob".
 copy "fdprint.cob".
 working-storage section.
*>----------------------
*>
 77  prog-name           pic x(15)    value "gl051 (3.00.04)".
 copy "print-spool-command.cob".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
*>
 01  accept-terminator-array pic 9(4).
         copy "screenio.cpy".
 01  filler.
     03  ws-menu             pic 9.
     03  display-batch       pic z(4)9.
     03  display-vat         pic z9.99.
     03  line-cnt            binary-char      value zero.
     03  page-nos            binary-char      value zero.
     03  batch-in            pic 9(5).
     03  a                   pic 99.
     03  v                   pic 9.
     03  y                   pic 99.
     03  z                   pic 99.
     03  first-time-flag     pic 9            value zero.
     03  save-batch          pic 9(5)   comp  value zero.
     03  trutht              pic 9.
         88  falset                           value zero.
         88  truet                            value 1.
     03  account-in          pic 9(4)v99.
     03  array-pc            pic 99.
     03  array-vat           pic x.
     03  ws-reply            pic x.
     03  display-amt         pic 9(8).99-.
     03  ws-vat-rate         pic 99v99  comp   value zero.
     03  vat-flag            pic 9             value zero.
     03  vat-flag-2          pic 9             value zero.
 01  ws-account-screen-display.
     03  ws-maind        pic 9(4).
     03  ws-period1      pic x     value ".".
     03  ws-subd         pic v99.
 01  ws-account-screen-accept redefines ws-account-screen-display.
     03  ws-main         pic 9(4).
     03  filler          pic x.
     03  ws-sub          pic v99.
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
*>    03  GL010           pic x(16) value "GL010 Hit Return".
     03  GL011          pic x(18) value "GL011 Invalid Date".
*> Module specific
    03  GL108           pic x(24) value "GL108 Invalid. Too early".
    03  GL109           pic x(26) value "GL109 Invalid. Too forward".
    03  GL110           pic x(24) value "GL110 No check on items.".
    03  GL111           pic x(18) value "GL111 Invalid code".
*>
 01  ws-account-work.
     03  acc-wk-main     pic 9(4).
     03  acc-wk-sub      pic v99.
 01  ws-account-ok redefines ws-account-work.
     03  acc-ok          pic 9(4)v99.
*>
 01  ws-amount-screen-display8s.
     03  ws-poundsd8s    pic 9(8).
     03  ws-period8s     pic x     value ".".
     03  ws-penced8s     pic v99.
 01  ws-amount-screen-accept8s redefines ws-amount-screen-display8s.
     03  ws-pound8s      pic 9(8).
     03  filler          pic x.
     03  ws-pence8s      pic v99.
*>
 01  ws-amount-work8s.
     03  amt-wk-pds8s    pic 9(8).
     03  amt-wk-pence8s  pic v99.
 01  ws-amount-ok8s redefines ws-amount-work8s.
     03  amt-ok8s        pic 9(8)v99.
*>
 01  ws-amount-screen-display9.
     03  ws-poundsd9     pic 9(9).
     03  ws-period9      pic x     value ".".
     03  ws-penced9      pic v99.
 01  ws-amount-screen-accept9 redefines ws-amount-screen-display9.
     03  ws-pound9       pic 9(9).
     03  filler          pic x.
     03  ws-pence9       pic v99.
*>
 01  ws-amount-work9.
     03  amt-wk-pds9     pic 9(9).
     03  amt-wk-pence9   pic v99.
 01  ws-amount-ok9 redefines ws-amount-work9.
     03  amt-ok9         pic 9(9)v99.
*>
 01  display-plus-31                value all "+".
     03  display-plus-27 pic x(27).
     03  display-plus-4  pic xxxx.
*>
 01  display-star-46     pic x(46)  value all "*".
 01  ws-spaces              value spaces.
     03  ws-space-29     pic x(29).
     03  ws-space-f      pic x(51).
*>
 01  line-1.
     03  l1-prog             pic x(14).
     03  filler              pic x(41)   value spaces.
     03  filler              pic x(24)   value "Transaction Proof Report".
     03  filler              pic x(45)   value spaces.
     03  filler              pic x(6)    value "Page  ".
     03  l1-page             pic z9.
*>
 01  line-3.
     03  l3-user             pic x(32).
     03  filler              pic x(90)   value spaces.
     03  l3-date             pic x(10).
*>
 01  line-4.
     03  filler              pic x(8)    value "Batch - ".
     03  l4-batch            pic z(4)9.
     03  filler              pic x(8)    value spaces.
     03  l4-desc             pic x(24).
     03  filler              pic x(20)   value "    Date Entered - ".
     03  l4-date             pic x(10).
*>
 01  line-5.
     03  filler              pic x(110)  value "Number  Code  ---Date--- --Debit--   --Credit-    Net" &
                                               " Amount    VAT Amount  VAT Account  VAT Side   ----------".
     03  filler              pic x(22)   value "--Narative------------".
*>
 01  line-6.
     03  filler              pic x(97)   value "------  ----              A/C  P/C    A/C  P/C    ---" &
                                               "-------    ----------    A/C  P/C   --------".
*>
 01  line-7         value spaces.
     03  l7-number           pic z(4)9b(4).
     03  l7-code             pic x(5).
     03  l7-date             pic x(12).
     03  l7-dr               pic zzz9.99b.
     03  l7-dr-pc            pic 99bb.
     03  l7-cr               pic zzz9.99b.
     03  l7-cr-pc            pic 99bb.
     03  l7-amount           pic z(8)9.99bb.
     03  l7-vat              pic z(8)9.99bb.
     03  l7-vat-ac           pic zzz9.99  blank when zero.
     03  l7-vat-pc           pic bz9bbbbbb blank when zero.
     03  l7-side             pic x(8).
     03  l7-legend           pic x(32).
*>
 01 line-error.
     03  filler              pic x(24)  value spaces.
     03  dr-error            pic x(12).
     03  cr-error            pic x(12).
*>
 01  line-8.
     03  filler              pic x(20)   value spaces.
     03  filler              pic x(45)   value "Batch              ----Net----    ----VAT----".
*>
 01  line-9.
     03  filler              pic x(20)   value spaces.
     03  filler              pic x(17)   value "Header".
     03  l9-amount           pic z(9)9.99bb.
     03  l9-vat              pic z(9)9.99bb.
*>
 01  line-10.
     03  filler              pic x(20)   value spaces.
     03  filler              pic x(17)   value "Actual".
     03  l10-amount          pic z(9)9.99bb.
     03  l10-vat             pic z(9)9.99bb.
*>
 01  line-11.
     03  filler              pic x(20)   value spaces.
     03  l11-status          pic x(30).
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
 gl051 section.
*>************
*>
 menu-input.
*>*********
*>
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name to PSN.
     perform  zz070-convert-date.
     move     ws-date to l3-date.
     move     usera to l3-user.
*>
     move     zero to z.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Batch Amendment / Reporting Functions" at 0123 with foreground-color 2.
     display  ws-date at 0171 with foreground-color 2.
     display  usera at 0301 with foreground-color 2.
     display  "Select one of the following by number :- [ ]" at 0801 with foreground-color 2.
     display  "(1)  Amend existing Batch" at 1001        with foreground-color 2.
     display  "(2)  Print Proof Reports - All Batches" at 1101 with foreground-color 2.
     display  "(3)  Print Proof Reports - One Batch" at 1201   with foreground-color 2.
     display  "(4)  Print all Transactions" at 1301  with foreground-color 2.
     display  "(9)  Exit to system menu" at 1601     with foreground-color 2.
     accept   ws-menu at 0843 with foreground-color 6.
*>
     if       ws-menu = 9
              go to  menu-exit.
     open     i-o  batch-file.
*>
     if       ws-menu = 1  or  3
              perform  get-batch
              if    batch-nos = zero
                     close  batch-file
                     go to  menu-input.
*>
     if       ws-menu = 1
              perform gl050c.
*>
     if       ws-menu = 3
              perform gl050d.
*>
     if       ws-menu = 2
              perform  proof-all.
*>
     if       ws-menu = 4
              move zero to save-batch
              move 1  to  batch-start
              move 99  to  z
              perform gl050d.
*>
     if       ws-menu not = 1
              move  u-bin  to  proofed.
*>
     rewrite  batch-record.
     close    batch-file.
     go       to menu-input.
*>
 menu-exit.
     exit     program.
*>
*>**********************************************
*>           P R O C E D U R E S               *
*>**********************************************
*>
 get-batch.
*>********
*>
     move     1 to  ledger.
*>
     display  "Enter Batch Number :- [     ]" at 1801 with foreground-color 2.
     accept   batch-nos at 1824 with foreground-color 6 update.
*>
     if       batch-nos = zero
              go to  end-get-batch.
*>
     read     batch-file  record  invalid key
              go to  get-batch.
*>
 end-get-batch.
     exit.
*>
 accept-money8s2.
*>--------------
*>
     move     amt-wk-pence8s to ws-pence8s.
     move     amt-wk-pds8s   to ws-pound8s.
     display  ws-amount-screen-display8s at curs2  with foreground-color 3.
     accept   ws-amount-screen-accept8s at curs2  with foreground-color 3 update.
     move     ws-pound8s to amt-wk-pds8s.
     move     ws-pence8s to amt-wk-pence8s.
*>
 accept-money9.
*>------------
*>
     move     amt-wk-pds9   to ws-pound9.
     move     amt-wk-pence9 to ws-pence9.
     display  ws-amount-screen-display9 at curs2 with foreground-color 3.
     accept   ws-amount-screen-accept9 at curs2  with foreground-color 3 update.
     move     ws-pound9 to amt-wk-pds9.
     move     ws-pence9 to amt-wk-pence9.
*>
 accept-account.
*>-------------
*>
     move     acc-wk-main to ws-main.
     move     acc-wk-sub  to ws-sub.
     display  ws-account-screen-display at curs2 with foreground-color 3.
     accept   ws-account-screen-accept at curs2 with foreground-color 3 update.
     move     ws-main  to acc-wk-main
     move     ws-sub   to acc-wk-sub.
*>
 proof-all               section.
*>------------------------------
*>
 loop.
*>***
*>
     read     batch-file  next record  at end
              go to  proof-end.
*>
     if       bcycle of batch-record not = scycle of system-record
              go to  loop.
*>
     if       not  waiting
              go to  loop.
*>
     perform  gl050d.
     rewrite  batch-record.
     go       to loop.
*>
 proof-end.   exit section.
*>
 gl050c section.
*>*************
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "General Ledger - Batch Amendment" at 0126 with foreground-color 2.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
*>
     perform  help-outline  through  h-o-data.
     perform  batch-amendment.
*>
     if       truet
              go to  main-exit.
*>
     open     input  ledger-file.
*>
 define-vat-rate.
*>**************
*>
     move     1  to  v.
     display  "VAT Rate :- [1]" at 0401 with foreground-color 2.
     accept   v at 0414 with foreground-color 3 update.
*>
     if       v  <  1  or  >  3
              go to  define-vat-rate.
*>
     move     vat-rate (v)  to  display-vat ws-vat-rate.
     display  display-vat at 0417 with foreground-color 2.
     display  "% ok (Y/N) :- [Y]" at 0422 with foreground-color 6.
*>
     move     "Y"  to  ws-reply.
     accept   ws-reply at 0437 with foreground-color 3.
*>
     if       ws-reply = "N"  or  "n"
              go to  define-vat-rate.
*>
     display  "Batch      - " at 0456 with foreground-color 2.
     display  display-batch at 0469 with foreground-color 2.
     display "/" at 0474 with foreground-color 2.
     display  "Default    - " at 0656 with foreground-color 2.
     display  bdefault at 0669 with foreground-color 2.
     display  "Contra A/C - " at 0856 with foreground-color 2.
     display  batch-def-ac at 0869 with foreground-color 2.
*>
     if       batch-def-pc not = zero
              display "/" at 0875 with foreground-color 2
              display batch-def-pc at 0876 with foreground-color 2.
*>
     display  "Vat A/C    - " at 1056 with foreground-color 2.
     display  batch-def-vat at 1069 with foreground-color 2.
     display  "Convention - " at 1256 with foreground-color 2.
     display  convention at 1269 with foreground-color 2.
*>
     open     i-o  posting-file.
*>
 loop.
*>***
*>
     display  "Date           [          ]"  at 0601  with foreground-color 2.
     display  "Account        [       ]"     at 0801     with foreground-color 2.
     if       profit-centres
              display "Profit Centre  [  ]"  at 1001  with foreground-color 2.
     if       branches
              display "Branch         [  ]"  at 1001  with foreground-color 2.
     display  "Amount         [           ]" at 1201 with foreground-color 2.
     if       auto-vat
              display "VAT Code       [ ]  {P or M or space}" at 1401 with foreground-color 2.
*>
     display  "VAT Amount     [           ]" at 1601 with foreground-color 2.
     display  "Narrative      ["             at 1801 with foreground-color 2.
     display  "]"                            at 1849 with foreground-color 2.
*>
*>    move     entered  to  u-bin.
*>    call     "maps04"  using  maps03-ws.
*>
 read-loop.
*>********
*>
     read     posting-file  next record  at end
              go to  main-exit.
*>
     if       batch not = batch-nos
              go to  read-loop.
*>
 accept-date.
*>-----------
*>
     display  post-date at 0617 with foreground-color 3.
     accept   post-date at 0617 with foreground-color 3 update.
*>
     if       cob-crt-status = cob-scr-esc
*> escape-code = "E"  or  "q"
              go to  main-exit.
*>
     move     post-date  to  ws-test-date.
     perform  zz050-Validate-Date.
     move     ws-test-date  to  post-date.
*>
     if       u-bin = zero
              move   zero  to  trutht
              display GL011 at 0636 with foreground-color 4
              go to accept-date.
*>
     display  ws-space-29 at 0626.
*>
     if       convention = "DR"
              divide post-dr by 100 giving acc-ok
              move  dr-pc    to  array-pc
     else
              divide post-cr by 100 giving acc-ok
              move  cr-pc    to  array-pc.
*>
 get-account.
*>----------
*>
     move     0817 to curs2.
     perform  accept-account.
     move     acc-ok to account-in.
*>
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
                        or = cob-scr-page_down or cob-scr-key-down
*> escape-code = "B"  or  "F"
       or     z not = zero
              go to  accept-date.
*>
     if       cob-crt-status = cob-scr-esc
*> escape-code = "E"  OR  "Q"
              go to  main-exit.
*>
     perform  get-description.
     if       we-error not = zero
              go to get-account.
*>
 accept-p-c.
*>---------
*>
     if       not  profit-centres
       and    not  branches
              go to  accept-amount.
*>
     display  array-pc at 1017 with foreground-color 3.
     accept   array-pc at 1017 with foreground-color 3 update.
*>
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
*> escape-code = "B"
              go to  get-account.
*>
     if       cob-crt-status = cob-scr-esc
*>escape-code = "E"  OR  "Q"
              go to  main-exit.
*>
 accept-amount.
*>------------
*>
     if       convention = "DR"
              multiply account-in by 100 giving post-dr
              move  array-pc    to  dr-pc
     else
              multiply account-in by 100 giving post-cr
              move  array-pc    to  cr-pc.
*>
     move     1217 to curs2.
     move     post-amount to amt-ok8s.
     perform  accept-money8s2.
     move     amt-ok8s to post-amount.
*>
*>
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
*>escape-code = "B"
       and    not profit-centres  and  not branches
              go to  get-account.
*>
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
*> escape-code = "B"
              go to  accept-p-c.
*>
     if       cob-crt-status = cob-scr-esc
*> escape-code = "E"  OR  "Q"
              go to  main-exit.
*>
 accept-vat.
*>---------
*>
     if       not auto-vat
              go to  vat-amount-input.
*>
     move     space  to  array-vat.
     display  array-vat at 1417 with foreground-color 3.
     accept   array-vat at 1417 with foreground-color 3 update.
     move     function upper-case (array-vat) to array-vat.
     display  "                  " at 1439.
*>
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
*> escape-code = "B"
              go to  accept-amount.
*>
     if       cob-crt-status = cob-scr-esc
*> escape-code = "E"  OR  "Q"
              go to  main-exit.
*>
     if       array-vat = "P"
              perform  net
              go to vat-amount-input.
*>
     if       array-vat = "M"
              perform  gross
              go to vat-amount-input.
*>
     if       array-vat = space
              move zero to vat-amount
              go to accept-narative.
*>
     display  GL111 at 1439 with foreground-color 2.
     go       to accept-vat.
*>
 vat-amount-input.
*>***************
*>
     move     1617 to curs2.
     move     vat-amount to amt-ok8s.
     perform  accept-money8s2.
*>
     if       amt-ok8s not = vat-amount
        and   post-amount not = zero
        and   array-vat = "M"
              add vat-amount to post-amount
              subtract amt-ok8s from post-amount.
*>
     move     amt-ok8s to vat-amount.
*>
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
*> escape-code = "B"
              go to  accept-vat.
*>
     if       cob-crt-status = cob-scr-esc
*> escape-code = "E"  OR  "Q"
              go to  main-exit.
*>
 accept-narative.
*>
*>  test for zeros in post & vat,if so kill record ???????
*>
     display  "                  " at 1439.
     display  post-legend at 1817 with foreground-color 3.
     accept   post-legend  at 1817 with foreground-color 3 update.
*>
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
*> escape-code = "B"
       and    auto-vat
              go to  accept-vat.
*>
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
*> escape-code = "B"
              go to  accept-amount.
*>
     if       cob-crt-status = cob-scr-esc
*> escape-code = "E"  OR  "Q"
              go to  main-exit.
*>
 loop-end.
*>*******
*>
     rewrite  posting-record.
     go       to loop.
*>
 help-outline.
*>===========
*>
     move     14  to  lin.
     move     54  to  cole.
     display  display-plus-27 at 1454.
     display  display-plus-27 at 2354.
*>
 h-o-loop2.
*>
     add      1  to  lin.
     move     54 to cole.
     display  "+" at curs with foreground-color 2.
     move     80 to cole.
     display  "+" at curs with foreground-color 2.
     if       lin  <  22
              go to  h-o-loop2.
*>
 h-o-data.
*>
     display  "Option :- [ ]" at 1656 with foreground-color 2.
     display  "B - Back-up one field" at 1856 with foreground-color 2.
     display  "E - End" at 1956 with foreground-color 2.
*>
 net.
*>==
*>
     compute  vat-amount rounded = post-amount * ws-vat-rate / 100.
*>
 gross.
*>====
*>
     compute  vat-amount rounded = post-amount - (post-amount / ((ws-vat-rate + 100) / 100)).
     subtract vat-amount  from  post-amount.
*>
 get-description.
*>--------------
*>
     move     zero  to  we-error.
     multiply account-in by 100 giving ledger-nos.
     move     array-pc    to  ledger-pc.
*>
     read     ledger-file  record  invalid key
              move  255  to  we-error.
*>
     if       we-error = zero
              display ledger-name at 0826 with foreground-color 3
     else
              move  0  to  trutht
              display "Invalid A/C number" at 0826 with foreground-color 2.
*>
 main-exit.
*>********
*>
     close    ledger-file posting-file.
*>
 end-routine. exit section.
*>**********  ****
*>
 batch-amendment             section.
*>----------------------------------
*>
     display  "Amend Batch Header ? (Y/N) :- [N]" at 0801 with foreground-color 2.
     move     "N" to ws-reply.
     accept   ws-reply at 0832 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "N"
              move   0  to  trutht
              display " " at 0801 with erase eol
              go to  main-exit.
*>
 batch-outline.
*>============
*>
     move     15  to  lin.
     display  display-star-46 at 1501.
     display  display-star-46 at 2301.
*>
 b-o-loop2.
*>
     add      1  to  lin.
     move     1 to cole.
     display  "*" at curs with foreground-color 2.
     move     46 to cole.
     display  "*" at curs with foreground-color 2.
     if       lin  <  23
              go to  b-o-loop2.
*>
 b-o-data.
*>
     display  "Batch Data" at 1618 with foreground-color 2.
     display  "Batch         :- {     }" at 1702  with foreground-color 2.
     move     batch-nos to  display-batch.
     display  display-batch at 1720 with foreground-color 2.
     display  "Cycle         :- [  ]" at 1802   with foreground-color 2.
     display  "Items         :- [  ]" at 1902   with foreground-color 2.
     display  "Gross Value   :- [            ]" at 2002  with foreground-color 2.
     display  "VAT Value     :- [            ]" at 2102 with foreground-color 2.
     display  "Description   :- [" at 2202 with foreground-color 2.
     display  "]" at 2244 with foreground-color 2.
*>
 cycle-in.
*>*******
*>
     display  bcycle of batch-record at 1820  with foreground-color 3.
     accept   bcycle of batch-record at 1820  with foreground-color 3 update.
*>
     if       cob-crt-status = cob-scr-esc
              move   0  to  trutht
              go to  main-exit.
*>
     if       bcycle of batch-record <  scycle of system-record
              display GL108 at 1824 with foreground-color 2
              go to cycle-in.
*>
     subtract scycle of system-record from bcycle of batch-record  giving  y.
*>
     if       y  >  1
              display GL109 at 1824  with foreground-color 2
              go to cycle-in.
     display  "                           " at 1824.
*>
 items-in.
*>*******
*>
     display  items at 1920 with foreground-color 3.
     accept   items at 1920 with foreground-color 3 update.
*>
     if       cob-crt-status = cob-scr-esc
              go to  cycle-in.
*>
     if       items = zero
              display GL110 at 1924 with foreground-color 2.
*>
 gross-in.
*>*******
*>
     move     2020 to curs2.
     move     input-gross to amt-ok9.
     perform  accept-money9.
     move     amt-ok9 to input-gross.
*>
     if       cob-crt-status = cob-scr-esc
              go to  items-in.
*>
 vat-in.
*>*****
*>
     if       not  auto-vat
              go to  desc-in.
*>
     move     2120 to curs2.
     move     input-vat to amt-ok9.
     perform  accept-money9.
     move     amt-ok9 to input-vat.
*>
     if       cob-crt-status = cob-scr-esc
              go to  gross-in.
*>
 desc-in.
*>******
*>
     display  description at 2220 with foreground-color 3.
     accept   description at 2220 with foreground-color 3 update.
*>
     if       cob-crt-status not = cob-scr-esc
              go to  detail-query.
     if       auto-vat
              go to  vat-in
     else
              go to  gross-in.
*>
 detail-query.
*>***********
*>
     display  "Amend Batch Details? (Y/N) :- [N]" at 0801 with foreground-color 2.
     move     "N" to ws-reply.
     accept   ws-reply  at 0832 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "N"
              move   1  to  trutht
     else
              move   0  to  trutht.
*>
     display  " " at 0801 with erase eol.
     move     1 to cole.
     move     15 to lin.
     display  " " at curs with erase eos.
     perform  help-outline  through  h-o-data.
     go to    main-exit.
*>
 main-exit.   exit section.
*>********    ****
*>
 gl050d section.
*>*************
*>
     move     prog-name to l1-prog.
     open     output  print-file.
     move     zero  to  page-nos.
     move     1     to  trutht.
     if       first-time-flag not = zero
              go to disp-head-skip.
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "General Ledger - Proof Report" at 0127  with foreground-color 2.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
     display  "Printing......please wait" at 1212 with foreground-color 2.
     if       ws-menu = 2
              move 1 to first-time-flag.
*>
 disp-head-skip.
*>
     open     input  posting-file ledger-file.
     move     zero  to  actual-gross actual-vat.
     perform  batch-print.
*>
 main-exit.
*>********
*>
     close    posting-file ledger-file print-file.
     call     "SYSTEM" using Print-Report.
*>
 end-routine. exit section.
*>
*>******************************************************
*>                     Procedures                      *
*>******************************************************
*>
 batch-print                 section.
*>**********************************
*>
     perform  headings.
     move     1 to ledger.
*>
 loop.
*>***
*>
     read     posting-file  next record  at end
              go to  end-batch.
*>
     if       batch = zero
              go to  loop.
*>
     if       z = 99
       and    save-batch not = batch
              move   batch  to  l4-batch save-batch batch-nos
              perform get-a-batch
              move  entered  to  u-bin
              perform zz060-Convert-Date
              move ws-date  to  l4-date
              move description to l4-desc
              write  print-record  from  line-4  after  2
              add 2 to line-cnt
     else
      if      z = 99
              then next sentence
      else
        if    batch not = batch-nos
              go to  loop.
*>
     move     post-number  to  l7-number.
     move     post-code in posting-record   to  l7-code.
     move     post-date    to  l7-date.
     divide   post-dr  by  100  giving  l7-dr.
     move     dr-pc        to  l7-dr-pc.
     divide   post-cr  by  100  giving  l7-cr.
     move     cr-pc        to  l7-cr-pc.
     move     post-amount  to  l7-amount.
     move     vat-amount   to  l7-vat.
     move     zero         to  l7-vat-ac  l7-vat-pc
     move     spaces       to  l7-side.
*>
     divide   vat-ac of posting-record by 100 giving l7-vat-ac.
     move     vat-pc  to  l7-vat-pc.
*>
     if       vat-ac of posting-record not equal  zero
              move    post-vat-side  to  l7-side.
*>
     move     post-legend  to  l7-legend.
*>
     write    print-record  from  line-7 after 1.
     add      1 to line-cnt.
     perform  get-description.
*>
     if       cr-error not = spaces
       or     dr-error not = spaces
              write print-record from line-error after 1
              add 1 to line-cnt.
     if       line-cnt > Page-Lines - 6
              perform  headings.
*>
     add      post-amount  to  actual-gross.
     add      vat-amount   to  actual-vat.
     go       to loop.
*>
 get-a-batch.
*>**********
*>
     read     batch-file invalid key
              move 99999 to batch-nos.
*>
 headings.
*>*******
*>
     add      1          to  page-nos.
     move     page-nos   to  l1-page.
     move     batch-nos  to  l4-batch.
     move     description  to  l4-desc.
     move     entered  to  u-bin.
     perform  zz060-Convert-Date.
     move     ws-date  to  l4-date.
*>
     write    print-record  from  line-1 after 1.
     write    print-record  from  line-3 after 1.
     move     6 to line-cnt.
     if       z not = 99
              write  print-record  from  line-4 after 2
              add 2 to line-cnt.
     write    print-record  from  line-5 after 2.
     write    print-record  from  line-6 after 1.
     move     spaces  to  print-record.
     write    print-record after 1.
*>
 end-batch.
*>********
*>
     if       z = 99
              go to  main-exit.
     if       not truet
              move  0  to  batch-status
              go to  main-exit.
*>
     subtract input-vat  from  input-gross  giving  l9-amount.
     move     input-vat    to  l9-vat.
     move     actual-gross to  l10-amount.
     move     actual-vat   to  l10-vat.
     add      actual-vat   to  actual-gross.
*>
     if       line-cnt > Page-Lines - 12
              perform headings.
     write    print-record  from  line-8 after 3.
     write    print-record  from  line-9 after 2.
     write    print-record  from  line-10 after 2.
*>
     if       input-gross = actual-gross
       and    input-vat   = actual-vat
              move  1  to  batch-status
     else
              move  0  to  batch-status.
*>
     move     "*********************"  to  l11-status.
     write    print-record  from  line-11 after 3.
*>
     if       batch-status = 1
              move  "* Batch Verified Ok *"  to  l11-status
     else
              move  "*  Batch In ERROR   *"  to  l11-status.
*>
     write    print-record  from  line-11 after 1.
     move     "*********************"  to  l11-status.
     write    print-record  from  line-11 after 1.
     go       to main-exit.
*>
 get-description.
*>
     move     zero         to  we-error.
     move     post-dr      to  ledger-nos.
     move     dr-pc        to  ledger-pc.
*>
     read     ledger-file  invalid key
              move  1  to  we-error.
*>
     if       we-error = zero
              move  spaces  to  dr-error
     else
              move  "^^^^^^^^^^"  to  dr-error
              move  0  to  trutht.
*>
     move     zero         to  we-error.
     move     post-cr      to  ledger-nos.
     move     cr-pc        to  ledger-pc.
*>
     read     ledger-file  invalid key
              move  1  to  we-error.
*>
     if       we-error = zero
              move  spaces  to  cr-error
     else
              move  "^^^^^^^^^^"  to  cr-error
              move  0  to  trutht.
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
     perform  maps03.
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
     perform  maps03.
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
 maps03       section.
*>*******************
*>
     call     "maps04"  using  maps03-ws.
*>
 maps04-exit.
     exit     section.
*>
