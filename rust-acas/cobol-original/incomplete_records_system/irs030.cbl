       >>source free
*>*****************************************************************
*>                                                                *
*>                Transaction  Posting  Program                   *
*>                                                                *
*>*****************************************************************
 identification          division.
*>================================
*>
 program-id.            irs030.
*>
*> author.              Cobol conversion by Vincent B Coen, MBCS
*>                      for Applewood Computers.
*>
*>Security.             Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*> remarks.             Posting program
*>
*> version.             see prog-name in ws.
*> calls.               irsub1 nl       file handler.
*>                      irsub2 system   file handler.
*>                      irsub3 accounts default.
*>                      irsub4 posting  file handler.
*> changes.
*>
*>  11/7/83 vbc - Check response on correct account?,fix date vet
*>                to vet for zero day month,year < 70 & improve
*>                loop in accept post date routine.
*> 13/07/83 vbc - Clear save-sequ if updating post file.
*> 26/07/83 vbc - Rewrite date vet routines.
*> 07/12/83 vbc - Tidyup display.
*> 28/05/84 vbc - Hilite display heads.
*> 12/04/85 vbc - Check if posting to vat account direct.
*> 26/09/89 vbc - Mods for cobol/2.
*> 09/10/89 vbc - Recalc net amount if vat code = m & vat changed.
*> 28/12/89 vbc - Test for deflt a/c same as input a/c.
*> 22/01/09 vbc - Migration to Open Cobol as version 3.
*> 21/02/09 vbc - Added support for env's LINES and COLUMNS as needed.
*> 24/02/09 vbc - Added change of default within postings at accept for
*>                post-date via test for F3 added from full version.
*> 07/04/09 vbc - .12 Added posting file from S.L. and P.L. as input to IRS.
*> 14/03/10 vbc - .13-5 Cleanup multi field displays to comply with standards.
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
 environment division.
*>====================
*>
 copy  "envdiv.cob".
 input-output section.
 file-control.
*>
 copy "selpost-irs.cob".
*>
 data division.
*>=============
*>
 file section.
 copy "fdpost-irs.cob".
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(16) value "irs030 (3.01.15)".
*>
 01  filler.
     03  a               binary-char     value zero.
     03  b               binary-char     value zero.
     03  c               binary-char     value zero.
     03  d               binary-char     value zero.
     03  e               binary-char     value zero.
     03  ws-env-lines    pic 999         value zero.
     03  ws-lines        binary-char unsigned value zero.
     03  ws-20-lines     binary-char unsigned value zero.
     03  ws-21-lines     binary-char unsigned value zero.
     03  ws-22-lines     binary-char unsigned value zero.
     03  ws-23-lines     binary-char unsigned value zero.
*>************************************************************
*>     demo-flag set to 1 for generation of DEMO version     *
*>===========================================================*
     03  demo-flag       pic 9           value zero.
         88 demo                         value 1.
*>===========================================================*
*>    above demo flag set to 1 for demo version              *
*>************************************************************
     03  rev-flag        pic 9           value zero.
     03  menu-reply      pic 9.
     03  ws-reply        pic x.
     03  fs-reply        pic 99.
     03  ws-pass         pic x(4).
     03  w               pic 99.
     03  y               pic 99.
     03  ws-type         pic xx.
     03  ws-type2        pic xx.
     03  ws-default      pic s9(7)v99    value zero.
     03  ws-vat          pic s9(7)v99    value zero.
     03  ws-batch        pic s9(7)v99    value zero.
     03  ws-def-ac       pic s9(7)v99    value zero.
     03  input-account   pic s9(5).
     03  ws-vat-code     pic x.
*>
     03  post-true       pic z(4)9.
     03  save-post       pic 9(5).
     03  save-key        pic 9(5).
     03  save-lin        pic 99.
     03  net-display     pic z(6)9.99-.
     03  vat-display     pic z(6)9.99-.
     03  display-amount  pic z(6)9.99-.
     03  display-account pic zzzz9.
     03  ws-type-display pic xx.
     03  hold-post       pic 9(5).
     03  ws-acs          pic 9(5).
     03  ws-codes        pic xx.
     03  ws-vax          pic x.
     03  vat-flag        pic 9          value zero.
     03  vat-flag-2      pic 9          value zero.
*>
     03  curs            pic 9(4).
     03  filler redefines curs.
         05  lin         pic 99.
         05  cole        pic 99.
     03  curs2           pic 9(4).
     03  filler redefines curs2.
         05  lin2        pic 99.
         05  col2        pic 99.
     03  ws-spaces       pic x(80)    value spaces.
     03  ws-def-name     pic x(24).
     03  ws-vat-ac       pic x(20).
     03  display-legend  pic x(16).
*>
     03  post-record-cnt pic 9(5)     value zero.
*>
 copy "wsfnctn.cob".
 copy "wsnl.cob".
 copy "wsdflt.cob".
 copy "wspost.cob".
 01  date-fields.
     03  q                 pic 9.
*>
     03  days-in-month     pic x(24)  value "312831303130313130313031".
     03  filler  redefines  days-in-month.
       05  days            pic 99     occurs 12.
*>
     03  ws-work1          pic 9(5)   comp-3.
     03  ws-work2          pic 9(5)   comp-3.
     03  display-bin       pic zzzz9.
*>
 01  maps03-ws.
     03  u-date          pic x(8).
     03  filler  redefines  u-date.
       05  u-days        pic 99.
       05  filler        pic x.
       05  u-month       pic 99.
       05  filler        pic x.
       05  u-year        pic 99.
     03  u-bin           pic 9(5)     comp.
*>
 01  ws-amount-screen-display.
     03  ws-poundsd      pic 9(7).
     03  ws-period       pic x     value ".".
     03  ws-penced       pic v99.
     03  ws-signd        pic x.
 01  ws-amount-screen-accept redefines ws-amount-screen-display.
     03  ws-pound        pic 9(7).
     03  filler          pic x.
     03  ws-pence        pic v99.
     03  ws-sign         pic x.
*>
 01  ws-amount-work.
     03  amt-wk-pds      pic s9(7).
     03  amt-wk-pence    pic v99.
 01  ws-amount-ok redefines ws-amount-work.
     03  amt-ok          pic s9(7)v99.
*>
 01  ws-num-dstring.
     03  ws-nstrg        pic 9(9).
 01  ws-dstrg.
     03  ws-dstrg-9      pic 99.
*>
 01  All-My-Constants    pic 9(4).
     copy "screenio.cpy".
*>
*>  Working Storage for NL Default rec 31
*>
 01  nl31-record.
     03  nl31-key.
         05  nl31-owning   pic 9(5).
         05  nl31-sub-nominal pic 9(5).
     03  nl31-type         pic a.
     03  nl31-data.
         05  nl31-name     pic x(24).
         05  nl31-dr       pic 9(8)v99   comp.
         05  nl31-cr       pic 9(8)v99   comp.
         05  nl31-dr-last  pic 9(8)v99   comp  occurs  4.
         05  nl31-cr-last  pic 9(8)v99   comp  occurs  4.
         05  nl31-ac       pic a.
*>
*>  Working Storage for NL Default rec 32
*>
 01  nl32-record.
     03  nl32-key.
       05  nl32-owning     pic 9(5).
       05  nl32-sub-nominal pic 9(5).
     03  nl32-type         pic a.
     03  nl32-data.
       05  nl32-name       pic x(24).
       05  nl32-dr         pic 9(8)v99   comp.
       05  nl32-cr         pic 9(8)v99   comp.
       05  nl32-dr-last    pic 9(8)v99   comp  occurs  4.
       05  nl32-cr-last    pic 9(8)v99   comp  occurs  4.
       05  nl32-ac         pic a.
*>
 linkage section.
*>---------------
*>
 copy "wssystem.cob".
*>
 Screen Section.
*>==============
*>
 01  heading-screen.
   02                                       background-color 0 foreground-color 6.
     03  pic x(16)      from  prog-name         line  1 col  1 foreground-color 2.
     03             value "Transaction Posting"         col 31 foreground-color 1
                                                               background-color 7.
     03  pic x(8)       from  run-date                  col 73 foreground-color 2.
     03             value "Default -"           line  2 col  1 foreground-color 2.
     03  pic z9         from  w                         col 11 foreground-color 3.
     03             value "Run is - "                   col 14 foreground-color 2.
     03  pic xx         from  ws-type-display           col 23 foreground-color 3.
     03  pic x(20)      from  ws-def-name               col 50 foreground-color 3.
     03  pic z(6)9.99-  from  ws-default                col 70 foreground-color 3.
     03             value "Client "             line  3 col  1 foreground-color 2.
     03  pic x(24)      from  client                    col  8 foreground-color 3.
     03             value "End Date "                   col 32 foreground-color 2.
     03  pic x(8)       from  end-date                  col 41 foreground-color 3.
     03  pic x(20)      from  ws-vat-ac                 col 50 foreground-color 3.
     03  pic z(6)9.99-  from  ws-vat                    col 70 foreground-color 3.
     03             value "Batch Total"         line  4 col 50 foreground-color 2.
     03  pic z(6)9.99-  from  ws-batch                  col 70 foreground-color 3.
*>
 01  Display-Screen-1                          background-color cob-color-black
                                               foreground-color cob-color-green.
     03  pic x(16)      from  prog-name         line 1 col  1  blank screen.
     03        value "Default Accounts Display" line 1 col 27
                                               foreground-color cob-color-white
                                               background-color cob-color-blue
                                                      reverse-video.
     03  pic x(8)       from run-date           line 1 col 73.
*> setup this is to display the defaults
 01  Setup-Amend-Screen-3                      background-color cob-color-black
                                               foreground-color cob-color-green.
     03             value "Client -"            line  3 col  1.
     03  pic x(24)      from client             line  3 col 10
                                               foreground-color cob-color-cyan.
     03             value "Start date -"        line  3 col 39.
     03  pic x(8)       from start-date         line  3 col 52
                                               foreground-color cob-color-cyan.
     03             value "End date -"          line  3 col 62.
     03  pic x(8)       from end-date           line  3 col 73
                                               foreground-color cob-color-cyan.
     03             value "A/C Nos"             line  5 col  4.
     03             value "Description"         line  5 col 14.
     03             value "Code VAT   A/C Nos"  line  5 col 33.
     03             value "Description"         line  5 col 54.
     03             value "Code VAT"            line  5 col 73.
     03             value " "  erase eol        line  6 col 1.
     03  occurs 16
                    value "01 [00000]                      [AB] [C]" &
                          "17 [00000]                      [DE] [F"
                                                line plus 1 col 1.
*> after display need to update cc1&2 with 1 - 16 & cc41&42 with 17 - 32
*>  cc4/44 = a/c-nos , vat 38/78, 33/73 code
*> ] cc80
*>
 procedure division using system-record.
*>=====================================
*>
 init-main section.
*>*****************
*>
*> first get date & user information..
*>
     perform  initialise-main.
     if       a > zero                   *> found errors in vat a/cs
              go to main-exit.
     go       to main-loop.
 call-irsub3.
     call     "irsub3" using default-record file-access.
 call-irsub4.
     call     "irsub4" using posting-record file-access.
 call-irsub1.
     call     "irsub1" using nl-record file-access.
*>
 main-loop.
*>---------
*>     display  " " at 0101 with erase eos.
     move     zero to w.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Transaction Posting"                       at 0131 with foreground-color 1 background-color 7.
     display  "Enter Run Option     -    [  ]"            at 0501 with foreground-color 2.
     display  "(<99>    Display Existing Defaults)"       at 0532 with foreground-color 2.
     display  "(<88>    Add to Existing Postings)"        at 0632 with foreground-color 2.
     display  "(<77>    Clear Existing Postings)"         at 0732 with foreground-color 2.
     display  "(<66>    Add PL or SL Postings from file)" at 0832 with foreground-color 2.
     display  "(<Return> to exit to System Menu)"         at 1032 with foreground-color 2.
*>
     accept   w at 0528 with foreground-color 3 update.
*>
 main-loop-clear.
*>
*> close A/C file
*>
     if       w = zero
              move  2  to  file-function
              perform call-irsub1
              go to main-exit.
*>
     if       w = 99
              perform  show-default.
     if       w = 77
              perform  file-init
              if   ws-reply = "Z"
                   go to main-loop
              else
                   move  zero  to  next-post save-sequ
                   go to  get-default.
     if       w = 66
              move zero to save-sequ
              perform Ledger-Postings-Add.
     if       w not = 88
              go to  main-loop.
*>
 get-default.
*>
     display  "Enter Default Number -    [  ]" at line ws-lines col 1 with foreground-color 2
                                                       erase eol.
 get-default-1.
     accept   w  at line ws-lines col 28 with foreground-color 3.
     if       w  <  1  or  >  32
              go to  get-default.
*>
*> get Default A/C
*>
     move     def-acs (w)  to  nl-owning.
     move     zero  to  nl-sub-nominal.
     move     4  to  file-function.
     call     "irsub1"  using  nl-record  file-access.
*>
     if       we-error = 2
              display "That Account now deleted!!!  Re-enter!" at line ws-lines col 34 with
                                                            erase eol foreground-color 2
              go to get-default-1.
*>
     if       w > 30
          or  nl-owning = def-acs (31) or def-acs (32)
              move 1    to vat-flag
     else
              move zero to vat-flag.
*>
     display  nl-name at line ws-lines col 01 with erase eol foreground-color 2.
     if       def-vat (w) = "N"
              display "(No VAT)    " at line ws-lines col 26 with foreground-color 2
     else
      if      def-vat (w) = "O"
              display "(Output VAT - Sales)" at line ws-lines col 26 with foreground-color 2
      else
              display "(Input VAT - Purchases) " at line ws-lines col 26 with foreground-color 2.
*>
     move     nl-name  to  ws-def-name.
*>
 chk-ans.
*>
     display  "Correct Account (Y/N)....[ ]" at line ws-lines col 51 with foreground-color 2.
     accept   ws-reply  at line ws-lines col 77 with foreground-color 3.
     if       ws-reply = "N" or = "n"
              go to get-default.
     if       ws-reply not = "Y" and not = "y"
              go to chk-ans.
*>
 get-char.
*>
     display  "Enter Run Characteristic [  ]" at line ws-lines col 01 with erase eol
                                                                      foreground-color 2.
     display  "('DR' or 'CR') DR if entered a/c, is debited (TO)" at line ws-lines col 31
                                                                 with foreground-color 2.
     accept   ws-type2  at line ws-lines col 27 with foreground-color 3.
     move     function upper-case (ws-type2) to ws-type.
     if       ws-type not = "DR" and not = "CR"
              go to  get-char.
     display  " " at line ws-lines col 01 with erase eol.
*>
*> now reverse posting type
*>
     move     ws-type to ws-type-display.
*>
     if       ws-type = "DR"
              move "CR" to ws-type
     else
              move "DR" to ws-type.
*>
*> now set-up totals including VAT
*>
     subtract nl-cr from nl-dr giving ws-default.
*>
     if       def-vat (w) equal "N"
              move spaces to ws-vat-ac
              move zero  to ws-vat vat-ac-def
              go to set-up.
     if       def-vat (w) equal "O"
              move 32 to y
     else
              move 31 to y.
*>
*> set-up for VAT
*>
     move     def-acs (y) to nl-owning.
     move     y to vat-ac-def.
     move     zero to nl-sub-nominal.
     move     4 to file-function.
     call     "irsub1" using nl-record file-access.
*>
*> now error can't occur as tested in initialization
*>
 get-new-vat-done.
     if       we-error = 2
              display "VAT Account not present, Fix it!,returning to main menu. " &
                 "Now hit return" at line ws-lines col 01
                                                  with foreground-color cob-color-red erase eol
              accept ws-reply at line ws-lines col 74
              display " " at line ws-lines col 01 with erase eol
              go to  main-exit.
*>
     subtract nl-dr  from  nl-cr  giving  ws-vat.
     move     nl-name  to  ws-vat-ac.
*>
 set-up.
*>------
*>
     move     1  to  file-function.
     move     2  to  access-type.
     call     "irsub4"  using  posting-record  file-access.
*>
     move     zero  to  ws-batch save-sequ.
 set-up-1.
     display  space at 0101 with erase eos.
 set-up-2.
     perform  heading-screenp.
*>
     display  "--Date--  Account"                    at 0501 with foreground-color 2.
     display  "----Narrative----     Net       VAT"  at 0543 with foreground-color 2.
     move     6  to  lin.
     move     run-date  to  post-date.
*>
     move     next-post  to  post-key.
     move     def-codes (w)  to  post-code.
     move     spaces  to  post-legend.
*>
 input-loop.
*>----------
*>
     display  "Date      - [        ]"      at line ws-21-lines col 01 with foreground-color 2.
     display  "Account                 -[     ]" at line ws-21-lines col 41 with foreground-color 2.
     display  "Narrative - ["               at line ws-22-lines col 01 with foreground-color 2.
     display  "]"                           at line ws-22-lines col 46 with foreground-color 2.
     add      1  post-key  giving  post-true.
*>
*>    The code below is for the demo version, if DEMO-FLAG set to 1
*>      but as this version is now Open Source the flag is zero
*> WARNING:: SET to 0 for use in normal system. <<<<<<<<<<<<
*>
     if       demo   and   post-true > 50
              display space
              display "Sorry only 50 postings allowed on DEMO system" at 1220
              display "Hit return to go to Menu" AT 1426
              accept ws-reply at 1453
              perform end-batch thru batch-close
              move zero to w
              go to main-loop-clear.
*>
     display  "{Posting number :- "     at line ws-22-lines col 51 with foreground-color 2.
     display  post-true                 at line ws-22-lines col 70 with foreground-color 3.
     display  "}"                       at line ws-22-lines col 75 with foreground-color 2.
     display  "Amount    - [           ]" at line ws-23-lines col 1 with foreground-color 2.
     display  "VAT Code (P/M or space) - [ ]" at line ws-23-lines col 41 with foreground-color 2.
*>
     move     zeros to post-amount.
*>     move     zeros to input-account. *> so we can use the one previously input (date & desc. as well)
     display  post-date at line ws-21-lines col 14 with foreground-color 3.
*>
 date-inp.
*>
     accept   post-date  at line ws-21-lines col 14 with foreground-color 3 update.
     if       cob-crt-status = cob-scr-f3
              perform  end-batch thru batch-close
              perform  get-default thru set-up
              perform  set-up-2
              move  next-post  to  post-key
              move  def-codes (w)  to  post-code
              go to date-inp
     end-if
     if       post-date = spaces
              go to end-batch.
     perform  date-validate.
     if       u-bin = zero
              go to  date-inp.
     move     1 to cole.
     display  post-date at curs with foreground-color 3.
*>
 account-input.
*>
     accept   input-account at line ws-21-lines col 67 with foreground-color 3 update.
     move     input-account to  display-account.
     if       input-account = zero
              go to  end-batch.
     if       input-account < zero
              go to  account-input.
     if       Input-account = Def-acs (w)
              display "Posting & Default a/c must not be the same"
                                   at line ws-lines col 01 with foreground-color 2
              go to account-input
     else
              display ws-spaces at line ws-lines col 01.
*>  2401
     move     11 to cole.
     display  display-account at curs with foreground-color 3.
*>
     move     input-account to nl-owning.
     move     zero to nl-sub-nominal.
     move     4 to file-function.
     call     "irsub1" using nl-record file-access.
*>
     if       we-error = 2
              display "That account does not exist. Re-enter"
                                 at line ws-lines col 01 with foreground-color 2
              go to  account-input
     else
              display  ws-spaces at line ws-lines col 01.
     if       input-account = def-acs (31) or def-acs (32)
          or  vat-flag = 1
              move 1  to vat-flag-2
     else
              move zero to vat-flag-2.
*>
     display  "Amount    - [           ]" at line ws-23-lines col 01 with foreground-color 2.
     display  "VAT Code (P/M or space) - [ ]" at line ws-23-lines col 41 with foreground-color 2.
*>
     move     18 to cole.
     display  nl-name at curs with foreground-color 3.
     display  post-legend at line ws-22-lines col 14 with foreground-color 3.
     accept   post-legend at line ws-22-lines col 14 with foreground-color 3 update.
     move     post-legend  to  display-legend.
     move     43 to cole.
     display  display-legend at curs with foreground-color 3.
*>
     move     ws-23-lines to lin2
     move     14 to col2.
     move     zero to amt-ok.
     if       vat-flag-2 = zero
              perform accept-money.
     move     amt-ok to post-amount.
     move     post-amount to display-amount.
     move     61 to cole.
     display  display-amount at curs with foreground-color 3.
*>
     if       def-vat (w) equal "N"
              move zero to vat-amount  ws-vat
              go to input-tidy.
*>
 vat-input.
*>
     move     space to ws-vat-code.
     if       vat-flag-2 = 1
              move zero to vat-amount
              go to vat-input-skip.
*>
     accept   ws-vat-code  at line ws-23-lines col 68 with foreground-color 3.
     if       ws-vat-code = "P"  OR  "p"
              move  "P"  to  ws-vat-code
              perform  net
     else
      if      ws-vat-code = "M"  OR  "m"
              move  "M"  to  ws-vat-code
              perform  gross
      else
       if     ws-vat-code = space
              move zero to vat-amount
       else
              go to vat-input.
*>
 vat-input-skip.
*>
     move     post-amount  to  net-display.
     move     vat-amount   to  vat-display.
     move     61 to cole.
     display  net-display at curs with foreground-color 3.
     move     71 to cole.
     display  vat-display at curs with foreground-color 3.
*>
     move     vat-amount to amt-ok.
     move     curs to curs2.
     perform  accept-money2.
     if       vat-amount not = amt-ok
        and   ws-vat-code = "M"
              Add Vat-amount to Post-amount
              Subtract Amt-ok from Post-amount
              move post-amount to net-display
              move 61 to cole
              display net-display at curs with foreground-color 3.
     move     amt-ok to vat-amount.
     if       vat-amount < zero
              multiply vat-amount by -1 giving  vat-amount.
*>
     if       post-amount = zero  and
              vat-amount  = zero
              go to  input-loop.
*>
 input-tidy.
*>----------
     if       ws-type = "CR" and post-amount > zero
              go to credit-tidy.
     if       ws-type = "DR" and post-amount < zero
              go to credit-tidy.
*>
*> processing for dr run
*>
     if       post-amount < zero
              move 1 to rev-flag
              multiply post-amount by -1 giving post-amount.
     move     def-acs (w) to post-dr.
     move     input-account to post-cr.
     if       rev-flag = 1
              subtract post-amount vat-amount from ws-batch.
     if       rev-flag not = 1
              add      post-amount vat-amount to ws-batch.
     move     "CR" to post-vat-side.
     add      post-amount vat-amount to ws-default.
     add      vat-amount             to ws-vat.
     add      post-amount            to nl-cr.
*>
*> now for traps
*>
     if       input-account = def-acs (w)
              subtract post-amount from ws-default.
*>
     if       def-vat (w) = "N"
              go to input-end.
*>
     if       input-account = def-acs (y)
              add  post-amount  to  ws-vat.
*>
     go       to input-end.
*>
 accept-money.
*>------------
*>
*>     move     zero to ws-poundsd amt-ok ws-penced.
     move     spaces to ws-amount-screen-accept.
*>     move     space to ws-sign.
     display  ws-amount-screen-display at curs2 with foreground-color 3.
     accept   ws-amount-screen-accept at curs2 with foreground-color 3.
     perform  justify-accept-money.
     if       c > 1 or d > 1
*>     if       ws-pound not numeric
*>           or ws-pence not numeric
              display "Amount not numeric. Re-Enter" at line ws-lines col 01 with foreground-color 4
              go to accept-money
     else
              display "                            " at line ws-lines col 01
     end-if .
*>     move     ws-pound to amt-wk-pds.
*>     move     ws-pence to amt-wk-pence.
*>     if       ws-sign = "-"
*>              multiply -1 by amt-ok.
*>
 accept-money2.
*>------------
*>
     if       amt-ok negative
              move "-" to ws-sign else
              move space to ws-sign.
     move     amt-wk-pence to ws-pence.
     move     "." to ws-period.
     move     amt-wk-pds to ws-pound.
     accept   ws-amount-screen-accept at curs2 with foreground-color 3 update.
     perform  justify-accept-money.
     if       c > 1 or d > 1
              display "Amount not numeric. Re-Enter" at line ws-lines col 01 with foreground-color 4
              go to accept-money2
     else
              display "                            " at line ws-lines col 01
     end-if.
*>     move     ws-pound to amt-wk-pds.
*>     move     ws-pence to amt-wk-pence.
*>     if       ws-sign = "-"
*>              multiply -1 by amt-ok.
*>
 justify-accept-money.
*>*******************
*>
*> because OC has no numeric editing or justification on accept
*>      as of v1.1 beta on 16/02/09
*> input field 9(7).99- output 9(9)
     move     zero to amt-ok c d.   *> c = neg flag,d = dec. flag,e = dig before '.'
     move     zero to ws-dstrg-9 ws-nstrg
     move     10 to b.      *> for num string 9 chars, if changed must also do below
     perform  varying a from 11 by -1 until a < 1
              if    ws-amount-screen-accept (a:1) = "-"
                and c = 1
                    move 2 to c                        *> set negative flag - twice
                    exit perform                       *> we have an error
              end-if
              if    ws-amount-screen-accept (a:1) = "."
                and d = 1
                    move 2 to d                        *> set decimal flag - twice
                    exit perform                       *> we have an error
              end-if
              if    ws-amount-screen-accept (a:1) = "-"
                    move 1 to c                        *> set negative flag
                    exit perform cycle
              end-if
              if    ws-amount-screen-accept (a:1) = "."
                    move 1 to d                        *> set decimal flag
                    subtract b from 10 giving e    *> = 0, 1 or 2 dec. digits
                    exit perform cycle
              end-if
*>
*> thats the allowed non numerics done
*>    below may need to test for 0 thru 9 instead
              if    ws-amount-screen-accept (a:1) not numeric
                and b not = 10                  *> must be same as start value
                    move 3 to c                 *> if we have number already we can't
                    exit perform                *> NOT have more
              end-if
              if    ws-amount-screen-accept (a:1) numeric
                    subtract 1 from b               *> 1st char is (10)
                    move ws-amount-screen-accept (a:1) to ws-num-dstring (b:1)
                    exit perform cycle
              end-if
     end-perform
     if       c < 2 and d < 2         *> these are errors
       if     e = 2
              divide ws-nstrg by 100 giving amt-ok
       else
        if    e = 1
              divide ws-nstrg by 10  giving amt-ok
        else
              move ws-nstrg to amt-ok
        end-if
       end-if
       if     c = 1
              multiply -1 by amt-ok
       end-if
     end-if .
*>
 credit-tidy.
*>-----------
*>
*> processing for CR run
*>
     move     def-acs (w)  to  post-cr.
     move     input-account to  post-dr.
*>
     if       post-amount < zero
              move 1 to rev-flag
              multiply post-amount by -1 giving post-amount.
     if       rev-flag = 1
              subtract post-amount vat-amount from ws-batch.
     if       rev-flag not = 1
              add      post-amount vat-amount to   ws-batch.
     move     "DR"  to post-vat-side.
     subtract post-amount vat-amount from ws-default.
     subtract vat-amount             from ws-vat.
     add      post-amount to nl-dr.
*>
*> now for traps
*>
     if       input-account = def-acs (w)
              add   post-amount  to  ws-default.
*>
     if       def-vat (w) = "N"
              go to  input-end.
*>
     if       input-account = def-acs (y)
              add  post-amount  to  ws-vat.
*>
 input-end.
*>---------
*>
     perform  heading-screenp.
*>
*> now write-out updated account
*>
     move     7  to  file-function.
     call     "irsub1"  using  nl-record  file-access.
*>
*> now write-out posting record
*>
 input-end-1.
*>
     if       rev-flag = 1
              multiply  post-amount  by  -1 giving  post-amount.
     if       rev-flag = 1
              multiply  vat-amount  by  -1 giving  vat-amount.
*>
     move     post-amount  to  net-display.
     move     vat-amount   to  vat-display.
     move     61 to cole.
     display  net-display at curs with foreground-color 3.
     move     71 to cole.
     display  vat-display at curs with foreground-color 3.
*>
     add      1  to  post-key.
     add      1  to  lin.
     if       rev-flag = 1
              multiply post-amount by -1 giving  post-amount.
     if       rev-flag = 1
              multiply vat-amount by -1 giving  vat-amount.
*>
     if       rev-flag = 1
              move  zero  to  rev-flag.
*>
     move     5  to  file-function.
     call     "irsub4"  using  posting-record  file-access.
*>
     if       lin  <  ws-20-lines  *> 20
              go to  input-loop.
     move     6  to  lin.
*>
 clear-screen.
*>
     move     1 to cole.
     display  ws-spaces at curs.
     add      1  to  lin.
     if       lin  <  ws-20-lines  *> 20
              go to  clear-screen.
*>
     display  post-date       at 0601 with foreground-color 3.
     display  display-account at 0611 with foreground-color 3.
     display  nl-name         at 0618 with foreground-color 3.
     display  display-legend  at 0643 with foreground-color 3.
     display  net-display     at 0661 with foreground-color 3.
     display  vat-display     at 0671 with foreground-color 3.
*>
     move     7  to  lin.
     go       to input-loop.
*>
 end-batch.
*>---------
*>
*> now output totals including vat
*>
     move     def-acs (w)  to  nl-owning.
     move     zero         to  nl-sub-nominal.
     move     4            to  file-function.
     call     "irsub1"  using  nl-record  file-access.
*>
     if       ws-default < zero
              multiply  ws-default by -1 giving ws-default
              move ws-default to nl-cr
              move zero to nl-dr
     else
              move ws-default to nl-dr
              move zero to nl-cr.
*>
     move     7 to file-function.
     call     "irsub1" using nl-record file-access.
*>
     if       def-vat (w)  equal "N"
              go to   batch-close.
*>
*> output for vat
*>
     move     def-acs (y)  to  nl-owning.
     move     zero  to  nl-sub-nominal.
     move     4  to  file-function.
     call     "irsub1"  using  nl-record  file-access.
*>
     if       ws-type = "DR"  and  ws-vat  >  zero
              move  ws-vat  to  nl-cr
              move  zero    to  nl-dr.
     if       ws-type = "DR"  and  ws-vat  <  .01
              move  ws-vat  to  nl-dr
              move  zero    to  nl-cr.
*>
     if       ws-type = "CR"  and  ws-vat  >  zero
              move  ws-vat  to  nl-cr
              move  zero    to  nl-dr.
     if       ws-type = "CR"  and  ws-vat  <  .01
              move  ws-vat  to  nl-dr
              move  zero    to  nl-cr.
*>
     move     7  to  file-function.
     call     "irsub1"  using  nl-record  file-access.
*>
 batch-close.
*>-----------
*>
*> now close files
*>
     move     2  to  file-function.
     call     "irsub4"  using  posting-record  file-access.
     move     post-key  to  next-post.
     move     5  to  file-function.
     call     "irsub2"  using  system-record  file-access.
*>
 batch-close-return.
*>
     go to    main-loop.
*>
 heading-screenp.
*>
     display  heading-screen at 0101.
*>
 main-exit.
     exit     program.
*>
*>-------------------------------------------------
*>            second level procedures
*>-------------------------------------------------
*>
*>  all below looks good. vbc 22/1/09
*>
 input-headings section.
*>----------------------
*>
     move     1  to  w  cole.
     move     7  to  lin.
*>
 display-existing.
*>----------------
*>
     display  w at curs with foreground-color cob-color-green.
     add      4 curs giving curs2.
     move     def-acs (w) to ws-acs.
     display  ws-acs at curs2 with foreground-color cob-color-cyan.
     move     ws-acs to  nl-owning.
     move     zero  to  nl-sub-nominal.
     if       ws-acs not = zero
              move 4 to file-function
              call "irsub1" using nl-record file-access
              add  10 curs giving curs2
              display nl-name (1:22) at curs2 with foreground-color cob-color-cyan
     end-if
*>
*>  get code description
*>
     add      33 curs giving curs2.
     move     def-codes (w) to ws-codes.
     display  ws-codes at curs2 with foreground-color cob-color-cyan.
     add      5  to col2.
     move     def-vat (w) to ws-vax.
     display  ws-vax at curs2 with foreground-color cob-color-cyan.
     add      1 to col2.
     display  "]" at curs2 with foreground-color cob-color-green.
     add      1 to w.
     if       w > 32
              go to  display-existing-end.
     if       w = 17
              move 41 to cole
              move 6  to lin.
     add      1  to lin.
     go to    display-existing.
*>
 display-existing-end.
*>--------------------
*>
     move     1 to w  cole.
     move     7 to lin.
*>
 main-exit.   exit.
*>********    ****
*>
*>
 date-validate section.
*>---------------------
*>
*>************************************************
*>                                               *
*>            date vet section.                  *
*>            =================                  *
*>                                               *
*>    format of date must be as follows:-        *
*>                                               *
*>       ddxmmxyy                                *
*>                                               *
*>    where x can only be one of the following:- *
*>                                               *
*>        / , . -                                *
*>                                               *
*>     and  dd = 1 thru [days in month]          *
*>          mm = 1 thru 12                       *
*>                                               *
*>************************************************
*>
     move     zero to u-bin q.
     move     post-date to u-date.
     inspect  u-date replacing all "." by "/".
     inspect  u-date replacing all "," by "/".
     inspect  u-date replacing all "-" by "/".
     inspect  u-date tallying q for all "/".
*>
     if       q not = 2 or
              u-days  not numeric or
              u-month not numeric or
              u-year  not numeric or
              u-days  < 01 or > 31 or
              u-month < 01 or > 12
              go to main-exit.
*>
     if       u-days > 29 and
              u-month = 2
              go to main-exit.
*>
     if       u-days > days (u-month) and
              u-month not = 2
              go to main-exit.
*>
     divide   u-year by 4 giving ws-work1.
     multiply ws-work1 by 4 giving ws-work2.
*>
     if       u-month = 2 and
              u-days > 28 and
              u-year not = ws-work2
              go to main-exit.
*>
     move     u-date to post-date.
*>
*>********************************************
*>                                           *
*>       date validation & conversion        *
*>       ============================        *
*>                                           *
*>                                           *
*>  requires  date input in u-date           *
*>  & returns  date as binary days since     *
*>    01/01/70  in  u-bin                    *
*>  date errors returned as u-bin equal zero *
*>                                           *
*>********************************************
*>
*>
     move     1     to  ws-work1.
     move     zero  to  ws-work2
                        u-bin.
*>
     if       u-year not = zero
              compute u-bin  = u-year * 365.
*>
     if       u-bin <   zero
              move  zero  to  u-bin
              go to  pack-end.
*>
 pack-loop-1.
*>
     if       u-year  >  ws-work2
              add  1  to  u-bin
              add  4  to  ws-work2
              go to  pack-loop-1.
*>
     if       u-year =  ws-work2
       and    u-month  >  2
              add  1  to  u-bin.
*>
 pack-loop-2.

     if       u-month  >  12
              move  zero  to  u-bin
              go to pack-end.
     if       u-month  >  ws-work1
              add  days (ws-work1)  to  u-bin
              add  1  to  ws-work1
              go to pack-loop-2.
*>
     if       u-days  not  >  days (ws-work1)
              add  u-days  to  u-bin
              go to  pack-end.
     if       u-days  = 29
        and   u-month = 2
        and   u-year  = ws-work2
              add  u-days  to   u-bin
     else
              move  zero  to u-bin.
 main-exit.
*>
 pack-end.    exit.
*>********    ****
*>
 initialise-main    section.
*>**************************
     display  space at 0101 with erase eos.
     accept   ws-env-lines   from lines.
     if       ws-env-lines < 24
              move  24 to ws-env-lines ws-lines
     else
              move  ws-env-lines   to ws-lines
     end-if
     subtract 1 from ws-lines giving ws-23-lines.
     subtract 2 from ws-lines giving ws-22-lines.
     subtract 3 from ws-lines giving ws-21-lines.
     subtract 4 from ws-lines giving ws-20-lines.
*>
*> test if the 2 vat accounts exist. if not, a non 0
*>
     move     system-files to file-names.
     move     3  to  file-function.
     perform  call-irsub3.                 *> get default record
*>
*> open A/C file
*>
     move     1  to  file-function.
     move     2  to  access-type.
     perform  call-irsub1.
     move     zero to a.
*>
*> make sure vat a/c exist
*>
     perform  varying y from 31 by 1 until y > 32
              move  def-acs (y) to nl-owning
              move  zero to nl-sub-nominal
              move  4 to file-function
              call  "irsub1" using nl-record file-access
              if   we-error = 2
                   display "VAT Account/s not present, Fix it. Now hit return"
                          at line ws-lines col 01 with foreground-color cob-color-red erase eol
                   accept ws-reply at line ws-lines col 77
                   display " " at line ws-lines col 01 with erase eol
                   add 1 to a
              end-if
     end-perform
     if       a > zero
              display " " at 0101 with erase eos
              display "You will need to fix the VAT account problems before posting"
                                                     at 1201 with erase eos foreground-color 4
              display "So hit return to get back to main menu" at 1401 with foreground-color 4
              accept ws-reply at 1440
     end-if.
*>
 initialise-main-exit.
     exit.
*>
 show-default section.
*>--------------------
*>
     display  Display-Screen-1.
     display  Setup-Amend-Screen-3.
     perform  input-headings.
     display  ws-spaces at line ws-23-lines col 01 with erase eos.
     display  "End of listing. Hit return for Menu." at line ws-lines col 01
                                              with foreground-color cob-color-white.
     move     space to ws-reply.
     accept   ws-reply  at line ws-lines col 79.  *>   2479
*>
 main51-exit.
     exit.
*>
 file-init section.
*>-----------------
*>
     move     spaces to ws-reply.
     display  " Make sure that you have backed up your data" at 0301 with foreground-color 4
                            highlight.
     display  " " at 0401 with erase eol.
     display  "Enter Pass-word - [****]" AT 0432 with foreground-color 2.
     accept   ws-pass  at 0451 with secure.
     if       ws-pass not = pass-word
              move "Z"  to  ws-reply
              go to  main52-exit.
*>
     move     1  to  file-function.
     move     3  to  access-type.
     perform  call-irsub4.
     move     2  to  file-function.
     perform  call-irsub4.
*>
 main52-exit.
     exit.
*>
 net section.
*>----------
*>
*> calculate vat from net
*>
     compute  vat-amount rounded =  post-amount *  vat  /  100.
*>
 main-exita.
     exit.
*>
 gross section.
*>------------
*>
*> calculate vat from gross
*>
     compute  vat-amount rounded = post-amount - (post-amount / ( (vat + 100) / 100)).
     subtract vat-amount from post-amount.
*>
 main-exitb.
     exit.
*>
 Ledger-Postings-Add section.
*>--------------------------
*>
*>  open input file, get vat a/cs for both Sales and Purchases and hold records
*>   some code bits from irs080
*>
     open     input irs-post-file.
     if       fs-reply not = zero
              display "No Ledger posting file found. Process Aborted" at 2301
                                    with foreground-color 2
              go to main99-exit.
*>
*>   get default record
*>
     move     3  to  file-function.
     perform  call-irsub3.
*>
*>   Open I-O Nominal-Ledger.
*>
     move     1  to  file-function.
     move     2  to  access-type.
     perform  call-irsub1.
*>
     move     def-acs (31) to nl-owning.
     move     zero         to nl-sub-nominal.
     move     4            to file-function.
     perform  call-irsub1.
     if       we-error not = zero
              display "IRSUB1-31 returns " at 2301 with foreground-color 4 highlight
              display we-error at 2319 with foreground-color 4 highlight
              accept we-error at 2340
              go to main99-exit.
     move     nl-record to nl31-record.
*>
     move     def-acs (32) to nl-owning.
     move     zero         to nl-sub-nominal.
     move     4            to file-function.
     perform  call-irsub1.
     if       we-error not = zero
              display "IRSUB1-32 returns " at 2301 with foreground-color 4 highlight
              display we-error at 2319 with foreground-color 4 highlight
              accept we-error at 2340
              go to main99-exit.
     move     nl-record to nl32-record.
*>
*>   open    i-o post-file.
*>
     display  "Updating Nominal Ledger" at 2401 with foreground-color 2.
     move     1  to  file-function.
     move     2  to  access-type.
     perform  call-irsub4.
*>
 input-loop.
     read     irs-post-file at end
              go to eoj.
     add      1 to post-record-cnt.
*>
*> processing for dr
*>
     move     irs-post-dr  to  nl-owning.
     move     zero     to  nl-sub-nominal.
     move     4        to  file-function.
     perform  call-irsub1.
     if       we-error = 2
              display "Invalid key 1 = " at 2301 with foreground-color 4 highlight
              display irs-post-dr at 2317 with foreground-color 4 highlight
              accept we-error at 2340
              go to input-loop.
     add      irs-post-amount  to  nl-dr.
     if       irs-post-vat-side = "CR"
              add  irs-vat-amount  to  nl-dr.
*>
*>  rewrite
*>
     move     7  to  file-function.
     perform  call-irsub1.
*>
*> processing for CR
*>
     move     irs-post-cr  to  nl-owning.
     move     zero     to  nl-sub-nominal.
     move     4        to  file-function.
     perform  call-irsub1.
     if       we-error = 2
              display "Invalid key 2 = " at 2301 with foreground-color 4 highlight
              display irs-post-cr at 2317 with foreground-color 4 highlight
              accept we-error at 2340
              go to input-loop.
     add      irs-post-amount  to  nl-cr.
     if       irs-post-vat-side = "DR"
              add  irs-vat-amount  to  nl-cr.
*>
     move     7  to  file-function.
     perform  call-irsub1.
*>
*> Now add to IRS post file
*>
     move     irs-post-code   to post-code.
     move     irs-post-date   to post-date.
     move     irs-post-cr     to post-cr.
     move     irs-post-dr     to post-dr.
     move     irs-post-amount to post-amount.
     move     irs-post-legend to post-legend.
     move     irs-vat-ac-def  to vat-ac-def.
     move     irs-post-vat-side to post-vat-side.
     move     irs-vat-amount  to vat-amount.
     move     next-post to post-key.
     add      1 to next-post.
*>
     move     5  to  file-function.
     perform  call-irsub4.
     if       we-error not = zero
              display "Error writing to Posting File" at 2301 with foreground-color 2
              accept we-error at 2330
              go to eoj.
*>
*> processing for VAT
*>
     if       irs-vat-ac-def = zero
              go to  input-loop.
*>
     if       irs-vat-ac-def = 31
         and  irs-post-vat-side = "CR"
              add  irs-vat-amount  to  nl31-cr
     else
       if     irs-vat-ac-def = 31
         and  irs-post-vat-side = "DR"
              add  irs-vat-amount  to  nl31-dr
       else
        if    irs-vat-ac-def = 32
          and irs-post-vat-side = "CR"
              add  irs-vat-amount  to  nl32-cr
        else
         if   irs-vat-ac-def = 32
          and irs-post-vat-side = "DR"
              add  irs-vat-amount  to  nl32-dr.
     go       to input-loop.
*>
 eoj.
*>
     move     7  to  file-function.
     move     nl31-record to nl-record.
     perform  call-irsub1.
*>
     move     nl32-record to nl-record.
     perform  call-irsub1.
*>
     move     2  to  file-function.
     perform  call-irsub4
     perform  call-irsub1.
     move     5  to  file-function.
     call     "irsub2"  using  system-record  file-access.
     close    irs-post-file.
     display   " " at 1201 with erase eol.
     display  "Processing Complete on " post-record-cnt " records".
eoj-q1.
     display  "Can I clear the Ledgers Posting file? [Y]" at 1401 with erase eol.
     accept   ws-reply at 1440 with foreground-color 6.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply not = "Y" and not = "N"
              go to eoj-q1.
     if       ws-reply = "Y"
              open output irs-post-file
              close irs-post-file.
     display  "Note counts and any messages" at 1401 with erase eol.
     accept   ws-reply at 1430.
*>
 main99-exit.
     exit     section.
