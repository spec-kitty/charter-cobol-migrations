       >>source free
*>*****************************************************
*>                                                    *
*>           Default  Accounts  Maintenance           *
*>                                                    *
*>*****************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         gl020.
*>**
*>    Author.             V.B.Coen FBCS
*>                        Converted To Cis December 84,
*>                        Converted to Open Cobol January 09
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Default Accounts set up, amend and display.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Module       maps01.
*>**
*>    Error messages used.
*>                        GL010
*>                        GL100
*>**
*>    Changes:
*> 27/01/09 vbc - Migration to Open Cobol.
*> 18/12/11 vbc - .02 Support for Page-Lines instead of fixed number.
*>                    Add support for printing for lpr
*>                    Support for dates other than UK & clean up msgs
*>                    Error msgs to GLnnn,
*>                    Support for path+filenames.
*>**
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
 copy "seledger.cob".
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdledger.cob".
*>
 working-storage section.
*>----------------------
*>
 77  prog-name           pic x(15)  value "GL020 (3.00.02)".
*>
 copy "wsfnctn.cob".
*>
 01  ws-amount-screen-display.
     03  ws-poundsd      pic 9(4).
     03  ws-period       pic x     value ".".
     03  ws-penced       pic v99.
 01  ws-amount-screen-accept redefines ws-amount-screen-display.
     03  ws-pound        pic 9(4).
     03  filler          pic x.
     03  ws-pence        pic v99.
*>
 01  ws-amount-work.
     03  amt-wk-pds      pic 9(4).
     03  amt-wk-pence    pic v99.
 01  ws-amount-ok redefines ws-amount-work.
     03  amt-ok          pic  9(4)v99.
*>
 01  work-fields.
     03  menu-reply      pic 9.
     03  ws-reply        pic x.
     03  a               pic 99.
     03  w               pic 99.
     03  y               pic 99.
     03  ws-acs          pic 9(4).99.
     03  ws-codes        pic xx.
     03  ws-vat          pic x.
     03  ws-env-lines    pic 999       value zero.
     03  ws-lines        binary-char unsigned value zero.
     03  ws-23-lines     binary-char unsigned value zero.
     03  ws-22-lines     binary-char unsigned value zero.
     03  ws-21-lines     binary-char unsigned value zero.
     03  ws-20-lines     binary-char unsigned value zero.
*>     03  ws-eval-msg     pic x(25)       value spaces.
*>
 01  accept-terminator-array   pic 9(4).
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
 copy "wsmaps03.cob".
 01  error-code          pic 999.
*>
01  Error-Messages.
*> System Wide
    03  GL010           pic x(16) value "GL010 Hit Return".
*> Module specific
    03  GL100           pic x(34) value "GL100 Chart of Accounts not set up".

*>
 copy "wsmaps01.cob".
*>
 linkage section.
*>---------------
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsdflt.cob".
 copy "wsnames.cob".
*>
 01  to-day          pic x(10).
*>
 procedure division using ws-calling-data system-record default-record to-day file-defs.
*>*************************************************************************************
*>
 init01       section.
*>*******************
*>
*>  Not use as only need 17 data lines but usable in other modules
*>
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
*> Force Esc, PgUp, PgDown, PrtSC to be detected
*>
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Default File Utilities" at 0129  with foreground-color 2.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
     display  usera at 0301 with foreground-color 2.
*>
     open     input ledger-file.
*>
     if       fs-reply not = zero
              display GL100    at 2301 with foreground-color 4
              display GL010    at 2401 with foreground-color 2
              accept ws-reply at 2420  with foreground-color 2
              go to main01-exit.
*>
     display  "Select the required function by number    [ ]" at 0501  with foreground-color 2.
     display  "(1)  Set-Up Default Accounts" at 0806             with foreground-color 2.
     display  "(2)  Amend  Default Accounts" at 1006             with foreground-color 2.
     display  "(3)  Display The Defaults" at 1206                with foreground-color 2.
     display  "(9)  Return To System Menu" at 2006               with foreground-color 2.
     accept   menu-reply  at 0544 with foreground-color 6 auto.
     if       menu-reply = 1
              perform  set-up.
     if       menu-reply = 2
              perform  amend.
     if       menu-reply = 3
              perform  show.
     if       menu-reply = 9
              go to main01-exit.
     go       to init01.
*>
 accept-money.
*>-----------
*>
     move     amt-wk-pds to ws-pound.
     move     amt-wk-pence to ws-pence.
     display  ws-amount-screen-display at curs2  with foreground-color 3.
     accept   ws-amount-screen-accept at curs2   with update foreground-color 3.
     move     ws-pound to amt-wk-pds.
     move     ws-pence to amt-wk-pence.
*>
 main01-exit.
     exit     program.
*>
 set-up       section.
*>-------------------
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
     display  "Default Accounts Set-Up" at 0129 with foreground-color 2.
     display  usera at 0301 with foreground-color 2.
*>
 main-loop.
*>--------
     display  "Add To Existing Defaults (Y/N) ? - [ ]" at 0501 with foreground-color 2.
     display  "N.B. (1) If first time set-up for this client answer no (N)"
                                      at 0701 with foreground-color 2.
     display  "(2) Answering no (N)"  at 0806  with foreground-color 2.
     display  "destroys" at 0827 with foreground-color 4 background-color 7 highlight.
     display  "the existing defaults" at 0836  with foreground-color 2.
     accept   ws-reply  at 0537 with foreground-color 4.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "N"
              perform  file-init.
     if       ws-reply not = "Y"
                   and not = "N"
              go to  main-loop.
     display  " " at 0501 with erase eol.
     display  " " at 0601 with erase eol.
     display  " " at 0701 with erase eol.
     display  " " at 0801 with erase eol.
     perform  input-headings.
*>
 get-input.
*>--------
*>
     display  w at curs with foreground-color 2.
     add      3  curs giving curs2.
     move     def-acs (w) to amt-ok.
     perform  accept-money.
     move     amt-ok to def-acs (w).
*>
     if       cob-crt-status = cob-scr-esc
       if     w < 30
              move 41  to  cole
              move 30  to  w
              move 20  to  lin
              go to get-input.
*>
     if       cob-crt-status = cob-scr-esc
       if     w < 31
         and  auto-vat
              move 41  to  cole
              move 31  to  w
              move 21  to  lin
              go to get-input
       else
              go to main-end.
*>
     if       def-acs (w) = zero
       and    w < 30
              move 41  to  cole
              move 30  to  w
              move 20  to  lin
              go to get-input.
*>
     if       def-acs (w) = zero
       and    auto-vat
              move 41  to  cole
              move 31  to  w
              move 21  to  lin
              go to get-input.
*>
*> get code description.
*>
     perform  get-description.
*>
     if       we-error = 255
              go to get-input.
*>
     add      12  curs giving curs2.
     display  ledger-name at curs2 with foreground-color 3.
     add      20 to col2.
     display  "[  ] " at curs2 with foreground-color 2.
     add      1 to col2.
     move     def-codes (w) to ws-codes.
     display  ws-codes at curs2 with foreground-color 3.
*>
     if       w < 30
              accept ws-codes  at curs2  with foreground-color 3 update
              move function upper-case (ws-codes) to ws-codes
     else
      if      w = 30
              move "OB" to ws-codes
      else
       if     w = 31
              move "VI" to ws-codes
       else
              move "VO" to ws-codes.
*>
     display  ws-codes at curs2 with foreground-color 2.
*>
     if       cob-crt-status not = cob-scr-esc
              next sentence
     else
       if     w < 30
              move 41 to cole
              move 30 to w
              move 20 to lin
              go to get-input.
*>
     if       cob-crt-status not = cob-scr-esc
              next sentence
     else
       if     auto-vat and w < 31
              move 41 to cole
              move 31 to w
              move 21 to lin
              go to get-input
       else
              go to main-end.
*>
     move     ws-codes to def-codes (w).
*>
 vat-check.
*>--------
*>
     add      38    curs giving curs2.
     move     def-vat (w) to ws-vat.
     display  ws-vat at curs2 with foreground-color 3.

     if       w < 30
              accept ws-vat at curs2 with foreground-color 3 update
              move function upper-case (ws-vat) to ws-vat
     else
              move "N" to ws-vat
              display ws-vat at curs2 with foreground-color 3.
*>
     if       cob-crt-status not = cob-scr-esc
              next sentence
     else
       if     auto-vat and w < 31
              move 41 to cole
              move 31 to w
              move 21 to lin
              go to get-input
       else
              go to main-end.
*>
     move     ws-vat to def-vat (w).
     if       ws-vat  = "I" or "N" or "O"
              next sentence
     else
              go to vat-check.
     add      1  to  w.
     if       w  >  32
              go to main-end.
     if       w  =  17
              move 41  to  cole
              move 6   to  lin.
     add      1  to  lin.
     go       to get-input.
*>
 main-end.
*>-------
*>
     perform  amend.
*>
 main-exit.   exit section.
*>--------    ----
*>
 amend        section.
*>-------------------
*>
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "Default Accounts Amendment" at 0127 with foreground-color 2.
     display  to-day at 0171 with foreground-color 2.
     display  usera at 0301 with foreground-color 2.
     perform  input-headings.
*>
 get-input.
*>--------
     move     zero to y.
     display  "Enter Number To Alter (Return to exit)  :- [  ]" at 2401 with foreground-color 2.
     accept   y  at 2445 with foreground-color 6 update.
     if       y = zero
              go to end-input.
     if       y  <  1  or  >  32
              go to get-input.
     move     y  to  w.
     if       y  >  16
              subtract 16  from  y
              move     41  to  cole
      else
              move     1   to  cole.
     move     zero  to  lin.
     add      y  6  to  lin
     display  w at curs with foreground-color 2.
     add      3    curs giving curs2.
     move     def-acs (w) to amt-ok.
     perform  accept-money.
     move     amt-ok to def-acs (w).
*>
*> get code description.
*>
     perform  get-description.
*>
     if       we-error = 255
              go to  get-input.
     add      12    curs giving curs2.
     display  ledger-name at curs2 with foreground-color 3.
     add      20 to col2.
     display  "[  ] " at curs2 with foreground-color 2.
     add      1 to col2.
     move     def-codes (w) to ws-codes.
     accept   ws-codes  at curs2 with update foreground-color 3.
     move     ws-codes to def-codes (w).
     add      33    curs giving curs2.
     display  ws-codes at curs2 with foreground-color 3.
*>
 vat-check.
*>--------
*>
     add      38    curs giving curs2.
     move     def-vat (w) to ws-vat.
     accept   ws-vat   at curs2 with update foreground-color 3.
     if       ws-vat  = "I" or "N" or "O"
              next sentence
     else
              go to vat-check.
     move     ws-vat to def-vat (w).
     go       to get-input.
*>
 end-input.
*>--------
*>
     close    ledger-file.
*>
 main-exit.   exit section.
*>--------    ----
*>
 show         section.
*>-------------------
*>
     display  " " at 0101  with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "default accounts display" at 0126   with foreground-color 2.
     display  to-day at 0171 with foreground-color 2.
     display  usera at 0301 with foreground-color 2.
*>
     perform  input-headings.
     display  "End of listing. Hit return for Menu." at 2301 with foreground-color 2.
     accept   ws-reply  at 2379 with foreground-color 6.
     close    ledger-file.
*>
 main-exit.   exit section.
*>--------    ----
*>
 file-init    section.
*>-------------------
*>
     move     "P" to encode.
     display  "Enter Password  - [    ]" at 0551  with foreground-color 2.
     accept   pass-word of maps01-ws at 0570      with foreground-color 6.
     display  "****" at 0570 with foreground-color 2.
     call     "maps01" using maps01-ws.
     if       pass-word of maps01-ws not =
              pass-word of system-record
              move "Z"  to  ws-reply
              go to main-exit.
     initialize default-record.
     cancel   "maps01".
*>
 main-exit.
*>--------
*>
     exit     section.
*>
 input-headings section.
*>---------------------
*>
     display  "A/C Nos" at 0504 with foreground-color 2.
     display  "Code Vat" at 0533 with foreground-color 2.
     display  "A/C Nos" at 0544 with foreground-color 2.
     display  "Code Vat" at 0573 with foreground-color 2.
     move     7  to  lin.
     move     1  to  w  cole.
*>
 input-loop.
*>---------
*>
     display  w at curs with foreground-color 2.
     add      2    curs giving curs2.
     display  "[       ]" at curs2 with foreground-color 2.
     add      30 to col2.
     display  "[  ] [ ]" at curs2 with foreground-color 2.
     add      1  to  w.
     if       w  >  32
              go to end-loop.
     if       w  =  17
              move 6  to  lin
              move 41 to  cole.
     add      1  to  lin.
     go       to input-loop.
*>
 end-loop.
*>-------
*>
*> Now input existing defaults
*>
     move     1  to  w  cole.
     move     7  to  lin.
*>
 display-existing.
*>---------------
*>
     add      3    curs giving curs2.
     move     def-acs (w) to ws-acs.
     display  ws-acs  at curs2 with foreground-color 3.
     if       def-acs (w) = zero
              go to jump-1.
*>
*> get code description.
*>
     perform  get-description.
     if       we-error = 255
              go to jump-1.
     add      12  curs giving curs2.
     display  ledger-name at curs2 with foreground-color 3.
     add      20 to col2.
     display  "[  ] " at curs2 with foreground-color 2.
*>
 jump-1.
*>-----
*>
     add      33    curs giving curs2.
     move     def-codes (w) to ws-codes.
     display  ws-codes  at curs2 with foreground-color 3.
     add      5 to col2.
     move     def-vat (w) to ws-vat.
     display  ws-vat  at curs2 with foreground-color 3.
     add      1  to  w.
     if       w  >  32
              go to display-existing-end.
     if       w  =  17
              move 41  to  cole
              move 6   to  lin.
     add      1  to  lin.
     go       to display-existing.
*>
 display-existing-end.
*>-------------------
*>
     move     1  to  w  cole.
     move     7  to  lin.
*>
 main-exit.   exit section.
*>--------    ----
*>
 get-description section.
*>----------------------
*>
     multiply def-acs (w)  by  100  giving  ledger-nos.
     move     "00"         to  ledger-pc.
     move     zero to we-error.
*>
     read     ledger-file  record  invalid key
              move  255  to  we-error.
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
