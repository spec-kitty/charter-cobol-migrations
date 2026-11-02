       >>source free
*>*********************************************
*>                                            *
*>            ACAS  System  Menu              *
*>            ==================              *
*>  This program will call each of the main   *
*>   elements in ACAS via a menu              *
*>    such as General, Stock, Sales, Purchase *
*>    but NOT irs until sorting out env vars  *
*>    ACAS_IRS, ACAS_LEDGERS                  *
*>*********************************************
*> IT is not expected to use this module to   *
*>  run ACAS as most users will just load the *
*>  needed sub-system as they tend to be used *
*>  by differing departments                  *
*>*********************************************
*> No RDBMS support used or needed! ?         *
*>                                            *
*>*********************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         ACAS.
*>**
*>    author.             V.B.Coen FBCS.
*>**
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    remarks.            ACAS System Menu.
*>**
*>    version.            See Prog-Name In Ws.
*>**
*>    Calls:              Maps01
*>                        Maps04
*>                        Sys002
*>                        General
*>                        Purchase
*>                        Sales
*>                        Stock
*> Not yet                IRS
*> NOT on opensource:     OE
*> NOT on opensource:     Payroll
*> NOT on opensource:     EPOS
*>**
*>    Changes.
*> WARNING: This program module is STILL under development so do not
*>          use at this time (October 2012).
*> 04/10/11 vbc - .00 ACAS control program/module for OC v1.1 & v2.
*>                    This element MUST be compiled with -x and all the
*>                    main system programs compiled with -m.
*> 18/11/11 vbc - .03 Added IRS to menu but marked out until sorting out
*>                    env variables eg, ACAS_IRS and ACAS_LEDGERS
*>                    by adding the path to ALL file names     <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*> 28/04/13 vbc - .04 changed call to sub-systems without 'using'.
*> 09/08/13 vbc - .05 wsnames using copybook version that support entire 
*>                    ACAS system but currently excluding IRS.
*>****
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of the Applewood Computers Accounting System
*> and is copyright (c) Vincent B Coen. 1976-2013 and later.
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
*>
*> SUPPORT Service:
*>=================
*> Support for this system is available:
*>     Free via email on an as time is available basis ONLY.
*>     Paid for [Normal] subscription, via email/phone as required by customer
*>          within normal office hours Monday through Friday 10:00 - 17:00.
*>     Paid for [W/E] subscription, via email/phone as required by customer 
*>          outside normal office hours and the weekend.
*>  Email to vbcoen@gmail.com for details of subscriptions or for support
*>  with subject 'ACAS Bug' for support or 'ACAS subscription' for paid service.
*>
*>*************************************************************************
*>
 environment             division.
*>===============================
*>
 copy  "envdiv.cob".
 input-output            section.
*>------------------------------
*>
 file-control.
*>-----------
*>
 copy "selsys.cob".
 data  division.
*>=============
*>
 file section.
*>-----------
*>
 copy "fdsys.cob".
 working-storage section.
*>----------------------
 77  prog-name           pic x(15)    value "ACAS (3.00.05)".
 77  z                   binary-char.
 77  OS-Delimiter        pic x        value "/".     *> Preset for Linux/unix etc
 77  ACAS_BIN            pic x(512)   value spaces.  *> added
 77  ACAS_IRS            pic x(500)   value spaces.
 77  ACAS_LEDGERS        pic x(500)   value spaces.
 77  Arg-Number          pic 9        value zero.
 77  ACAS_IRS-Count      binary-short value zero.
 77  ACAS_LEDGERS-Count  binary-short value zero.
*>========================================================
*>  in case file layout upgrade is needed.
*>   Using a file update program.
*>
 77  ws-Sys-Record-Ver-Prime          binary-char value 1.
 77  ws-Sys-Record-Ver-Secondary      binary-char value 1.
*>^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*>
*> Holds program parameter values from command line
 01  Arg-Vals                         value spaces.
     03  Arg-Value       pic x(525)  occurs 2.
 01  Arg-Test            pic x(525)   value spaces.
*>
 01  Cbl-File-Details.
     03  Cbl-File-Size     pic x(8)  comp-x  value zero.
     03  Cbl-File-Date.
         05  Cbl-File-Day  pic x     comp-x  value zero.
         05  Cbl-File-Mth  pic x     comp-x  value zero.
         05  Cbl-File-Year pic xx    comp-x  value zero.
     03  Cbl-File-time.
         05  Cbl-File-Hour pic x     comp-x  value zero.
         05  Cbl-File-Min  pic x     comp-x  value zero.
         05  Cbl-File-Sec  pic x     comp-x  value zero.
         05  Cbl-File-Hund pic x     comp-x  value zero.
*>
 01  ws-data.
     03  menu-reply      pic x          value "A".
     03  op-display      pic x(6).
*>
     03  letters-upper   pic x(26)      value "ABCDEFGHIJKLMNOPQRSTUVWXYZ".
     03  letters.
         05  a-entry     pic x          occurs 26 indexed by q.
*>
     03  ws-reply        pic x.
     03  a               pic 99         comp.
     03  option-list     pic x(60).
     03  wsmaps-ser.
         05  wsmaps-ser-xx pic xx.
         05  wsmaps-ser-nn pic 9(4).
*>
 copy "wstime.cob".
 copy "wsfnctn.cob".
 copy "wsmaps01.cob".
 copy "wsmaps03.cob".
 copy "wscall.cob".
 copy "wssys4.cob".
 copy "wsdflt.cob".
 copy "wsfinal.cob".
 copy "wsnames.cob".
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
     03  SY006           pic x(62) value "SY006 Program Arguments limited to two and you have specified ".
     03  SY007           pic x(35) value "SY007 Program arguments incorrect: ".
     03  SY008           pic x(31) value "SY008 Note message & Hit return".
     03  SY009           pic x(53) value "SY009 Environment variables not yet set up : ABORTING".
*> Module specific
*>
 01  error-code          pic 999        value zero.
 01  to-day              pic x(10).
*>
 procedure division.
*>=================
*>
 ACAS-Main.
*>
*> Force Esc, PgUp, PgDown, PrtSC to be detected
*>
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     function current-date to wse-date-block.
     perform  zz020-Get-Program-Args.
*>
 Open-System.
     open     i-o system-file.
     if       fs-reply not = zero
              close system-file
              perform mapser
              open i-o system-file.
*>
     move     1 to rrn.
     read     system-file record.
     close    system-file.   *>  Assuming that record still avail in FD.
*>
     if       scycle = zero
              go to call-system-setup.
*>
     move     run-date to u-bin.
     call     "maps04" using maps03-ws.
     move     u-date to to-day.
     perform  zz060-Convert-Date.
*>
 display-menu.
*>
     display  " " at 0101 with erase eos.
     move     to-day to u-date.
     move     "ACAS" to ws-caller.
     move     spaces to ws-called ws-del-link menu-reply.
     move     zeros to ws-term-code.
     display  maps-ser-xx at 2474 with foreground-color 3.
     move     maps-ser-nn to curs2.
     display  curs2 at 2476  with foreground-color 3.
     display  "Copyright (c) 1976-" at 2401 with foreground-color 3.
     display  wse-year at 2420 with foreground-color 3.
     display  " Applewood Computers" at 2424 with foreground-color 3.
     display  usera at 0101  with foreground-color 3.
*>
 Conv-date.
*>
*> Convert from UK to selected form
*>
     if       Date-USA
              move u-date to ws-date
              move ws-days to ws-swap
              move ws-month to ws-days
              move ws-swap to ws-month
              move ws-date to u-date
     end-if
     if       Date-Intl
              move "ccyy/mm/dd" to ws-date   *> swap Intl to UK form
              move u-date (7:4) to ws-Intl-Year
              move u-date (4:2) to ws-Intl-Month
              move u-date (1:2) to ws-Intl-Days
              move ws-date to u-date
     end-if.
*>
 conv-date-end.
     display  u-date at 0171 with foreground-color 3.
*>
 Display-Go.
*>
     display  prog-name at 0301 with foreground-color 2.
     display  "ACAS System Menu" at 0333 with foreground-color 2.
*>
     accept   wsb-time from time.
     if       wsb-time not = "00000000"
              move wsb-hh to wsd-hh
              move wsb-mm to wsd-mm
              move wsb-ss to wsd-ss
              display "at " at 0355 with foreground-color 2
              display wsd-time at 0358 with foreground-color 2.
*>
     accept   wsa-date from date.
     if       wsa-date not = "000000"
              move wsa-yy to u-year
              move wsa-mm to u-month
              move wsa-dd to u-days
              display "on " at 0367 with foreground-color 2
              perform conv-date
              display u-date at 0370 with foreground-color 2.
*>
     display  "Select one of the following by letter  :- [ ]" at 0601 with foreground-color 2.
*>
     display  "(A)  General Ledger"  at 1004 with foreground-color 2.
     display  "(B)  Sales Ledger"    at 1104 with foreground-color 2.
     display  "(C)  Purchase Ledger" at 1204 with foreground-color 2.
     display  "(D)  Stock Control"   at 1304 with foreground-color 2.
     display  "(E)  Order Entry"     at 1404 with foreground-color 2.
     display  "(F)  Payroll"         at 1504 with foreground-color 2.
     display  "(G)  Epos"            at 1604 with foreground-color 2.
*>     display  "(H)  Incomplete Records" at 1044 with foreground-color 2
*>
*>*******************************************************************
*>  Need to build in usage of ENV variables to select data
*>  before allowing a call to IRS but should put in place anyway
*>*******************************************************************
*>
     display  "(X)  Exit To system" At 1444 with foreground-color 2.
     display  "(Z)  System Setup" At 1644 with foreground-color 2.
*>
 accept-loop.
*>
     accept   menu-reply at 0644 with foreground-color 6 auto.
     move     function upper-case (menu-reply) to menu-reply.
*>
     if       menu-reply = "X"
              display " " at 0101 with erase eos
              go to pre-overrewrite.
*>
     move     zero to z.
     move     letters-upper to letters.
     set      q to 1
     search   a-entry
              when a-entry (q) = menu-reply
              set z to q.
     if       z = zero
              go to accept-loop.
*>
     go       to load-it.
*>
 call-system-setup.
*>****************
*>
     move     zero to ws-term-code.
*>     move     1 to rrn.
*>     rewrite  system-record.
*>     close    system-file.
     move     "sys002" to ws-called.
     call     ws-called using ws-calling-data file-defs.  *> and we only use file00.
     if       ws-term-code > 7
              stop run.
     go       to Open-System.
*>
 pre-overrewrite.
 overrewrite.
*>     move     1 to rrn.
*>     rewrite  system-record.
*>     close    system-file.
*>
 overclose.
     stop     run.
*>
 load-it.
*>******
*>
     move     space to menu-reply.
     go       to load01 load02 load03 load04 loadsr2 loadsr2 loadsr2
                 loadsr loaderror loaderror loaderror loaderror loaderror loaderror
*>                 load08 loaderror loaderror loaderror loaderror loaderror loaderror
                 loaderror loaderror loaderror loaderror loaderror loaderror loaderror
                 loaderror load23 loaderror loadsr call-system-setup
              depending on z.
*>
 loaderror.
*>--------
*>
     go       to display-menu.
*>
 load00.
*>-----
*>
     move     zero to ws-term-code.
     call     ws-called        *> using ws-calling-data system-record to-day.
     if       ws-term-code > 7
              go to overrewrite.
     cancel   ws-called.
*>
 load00-exit.
*>
     go       to display-menu.
*>
 load01.
*>-----
*>
     move     "general" to ws-called.
     go       to load00.
*>
 load02.
*>-----
*>
     move     "sales" to ws-called.
     go       to load00.
*>
 load03.
*>-----
*>
     move     "purchase" to ws-called.
     go       to load00.
*>
 load04.
*>-----
*>
     move     "stock" to ws-called.
     go       to load00.
*>
 load05.
*>-----
*>
     move     "OE" to ws-called.
     go       to load00.
*>
 load06.
*>-----
*>
     move     "payroll" to ws-called.
     go       to load00.
*>
 load07.
*>-----
*>
     move     "epos" to ws-called.
     go       to load00.
*>
 load08.
*>-----
*>
     move     "irs" to ws-called.
     go       to load00.
*>
 load23.
*>-----
*>
     go       to accept-loop.
*>
 loadsr.
*>-----
*>
     display  "Sorry, not yet available" at 2331 with foreground-color 2.
     go       to accept-loop.
*>
 loadsr2.
*>------
*>
     display  "Sorry, not available" at 2331 with foreground-color 2.
     go       to accept-loop.
*>
 main-exit.
     stop     run.
*>
 mapser section.
*>*************
*>
*> Encrypt/Decrypt coding and other security code removed for
*>    Open Source release
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "ACAS System Setup Routine - Level 1" at 0122 with foreground-color 2.
*>
*> Now Open System File for Output (overwriting existing contents)
*>
     open     output system-file.
     if       fs-reply not = zero
              display "Problem with opening system file. Hit return to quit"
                         at 1101 with foreground-color 4
              accept ws-reply at 1157
              stop run
     end-if
     initialize system-record.
     move     ws-Sys-Record-Ver-Prime      to System-Record-Version-Prime
     move     ws-Sys-Record-Ver-Secondary  to System-Record-Version-Secondary
     move     1 to date-form.                                                *> default UK format
*>
 Capture-Data.
     display  "Enter the Company Name :- [" at 1101 with foreground-color 2.
     display  "]" at 1160 with foreground-color 2.
*>
     accept   usera at 1128 with foreground-color 3 update.
*>
     display  "Please verify that name is correct (Y/N) :- [ ]"               at 1301 with foreground-color 2.
     move     "Y"  to  ws-reply.
     accept   ws-reply  at 1346 with foreground-color 6 update.
*>
     if       ws-reply not = "Y" and not = "y"
              go to Capture-Data
     end-if
     move     "N" to encode.
     move     usera to pass-name.
     call     "maps01" using maps01-ws.
     move     pass-name to user-code.
     move     "P" to encode.
     move     "pass" to pass-word of maps01-ws
                        pass-word of system-record.
     call     "maps01" using maps01-ws.
     move     pass-word of maps01-ws  to
              pass-word of system-record.
*>
     move     "N" to sl-own-nos.
     move     function current-date to wse-date-block.
     move     "00/00/0000" to u-date.
     move     wse-year  to u-year.
     move     wse-month to u-month.
     move     wse-days  to u-days.
     move     u-date    to to-day.
     move     zero      to u-bin.
     call     "maps04" using maps03-ws.
     move     u-bin  to run-date.
*>
     perform  level-setup.
*>
     move     1  to  op-system.
     move     1  to  sales-range.
     move     2  to  purchase-range.
     move     1  to  next-batch.
     move     1  to sl-dunning sl-charges.
     move     30 to sl-credit.
     move     2  to Invoicer.
     move     "\" to sl-delim.
*>
     move     1  to  rrn.
     write    system-record.
*>
     initialize default-record.
     move     2     to  rrn.
     write    system-record  from  default-record.  *> G/L Only
*>
     move     spaces  to  final-record.
     move     3       to  rrn.
     write    system-record  from  final-record.    *> G/L only
*>
     initialize system-record-4.
     move     4 to rrn.
     write    system-record from system-record-4.
*>
     close    system-file.
*>
 main-exit.
     exit section.
*>
 level-setup  section.
*>*******************
*>
     move     "mp9999" to wsmaps-ser.           *> Open Source version
     move     wsmaps-ser-xx to maps-ser-xx.
     move     wsmaps-ser-nn to maps-ser-nn.
*>
     display  "Using General  Ledger (Y/N) ? :- [ ]" at 1901 with foreground-color 2.
     display  "Using Purchase Ledger (Y/N) ? :- [ ]" at 2001 with foreground-color 2.
     display  "Using Sales    Ledger (Y/N) ? :- [ ]" at 2101 with foreground-color 2.
     display  "Using Invoicing       (Y/N) ? :- [ ]" at 1941 with foreground-color 2.
     display  "Using Stock Control   (Y/N) ? :- [ ]" at 2041 with foreground-color 2.
     display  "Using Order Entry     (Y/N) ? :- [ ]" at 2141 with foreground-color 2.
*>
     accept   ws-reply at 1935 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "Y"
              move  1  to  level-1    *> General
     else
              move zero to level-1
     end-if
     accept   ws-reply at 2035 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "Y"
              move  1  to  level-2    *> Purchase
     else
              move zero to level-2
     end-if
     accept   ws-reply at 2135 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "Y"
              move  1  to  level-3    *> Sales
     else
              move zero to level-3
     end-if
     accept   ws-reply at 1975 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "Y"
              move  1  to  full-invoicing      *> Invoicing
     else
              move zero to full-invoicing
     end-if
     accept   ws-reply at 2075 with foreground-color 6 update.
     if       ws-reply = "Y" or "y"
              move  1  to  Level-4    *> Stock Control
     else
              move zero to Level-4
     end-if
     accept   ws-reply at 2175 with foreground-color 6 update.
     if       ws-reply = "Y" or "y"
              move  1  to  Level-5     *> O/E
     else
              move zero to Level-5
     end-if
     display  "Please confirm (Y/N) :- [ ] " at 2301 with foreground-color 2.
*>  IRS here when sorted
     move     spaces  to  option-list.
     move     1  to  a.
*>
     if       G-L
              string "General " delimited by size into option-list with pointer a.
*>
     if       B-L  and  G-L
              string "/ " delimited by size into option-list  with pointer a.
*>
     if       B-L
              string "Purchase " delimited by size into option-list with pointer a.
*>
     if       S-L  and  G-L
        or    S-L  and  B-L
              string "/ " delimited by size into option-list with pointer a.
*>
     if       S-L
              string "Sales " delimited by size into option-list with pointer a.
*>
     if       S-L  and  full-invoicing = 1
              string  "/ Invoicing" delimited by size into option-list with  pointer  a.
*>
     if       Stock
              string "/ Stock " delimited by size into option-list pointer a.
*>
     if       O-E
              string "/ Order Entry" delimited by size into option-list pointer a.
*>
*>   if       IRS
*>             string "/ IRS" delimited by size into option-list   pointer a.
*>
*>  option-list now max 60 chars used
*>
     display  option-list at 2401 with foreground-color 2.
     accept   ws-reply at 2326 with foreground-color 6.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply not = "Y"
              go to level-setup.
*>
 main-exit.
     exit     section.
*>
 zz010-Get-Env-Set-Files section.
*>******************************
*>
     accept   ACAS_LEDGERS from Environment "ACAS_LEDGERS".
     accept   ACAS_IRS     from Environment "ACAS_IRS".
     accept   ACAS_BIN     from Environment "ACAS_BIN".
*>
     if       ACAS_IRS (1:1) = space
           or ACAS_LEDGERS (1:1) = spaces
           or ACAS_BIN (1:1) = spaces
              display SY009        at 0505 with erase eos highlight
              display SY008        at 1210 with           foreground-color 3 highlight
              accept ws-reply      at 1243
              stop run
     end-if
     if       ACAS_LEDGERS (1:1) = "/"   *> Its Linux/Unix
              move "/" to OS-Delimiter.
     if       ACAS_LEDGERS (1:1) = "\"   *> Its Windoz
              move "\" to OS-Delimiter.
*>
 zz010-GESF-Exit.
     exit     section.
*>
 zz020-Get-Program-Args      section.
*>**********************************
*>
     perform  zz010-Get-Env-Set-Files.          *> This must be set so get it 1st + need os-delimiter
*>
*> See if we have temporary overrides that have ben supplied whwn calling program
*>
     accept   Arg-Number from argument-number.
     if       Arg-Number = zero
              go to zz020-Set-the-Paths.
*>
     if       Arg-Number > 2
              display SY006        at 0101 with erase eos foreground-color 3
              display Arg-Number   at 0164 with           foreground-color 3
              display SY008        at 1210 with           foreground-color 3 highlight
              accept ws-reply      at 1243
              stop run.
*>
     move     zero to z.
     perform  Arg-Number times
              add      1 to z
              accept   Arg-Value (z) from argument-value
              move     Arg-Value (z) to Arg-Test
              if       Arg-Test (1:13) not = "ACAS_LEDGERS="
                 and   Arg-Test (1:9)  not = "ACAS_IRS="
                       display SY007   at 0101 with erase eos foreground-color 3
                       display SY008   at 1210 with           foreground-color 3 highlight
                       accept ws-reply at 1243
                       stop run
              end-if
              if       Arg-Test (1:13) = "ACAS_LEDGERS="
                       move Arg-Test (14:512) to ACAS_LEDGERS
              else
                 if    Arg-Test (1:9) = "ACAS_IRS="
                       move Arg-Test (10:512) to ACAS_IRS
                 end-if
              end-if
     end-perform
*>
*>  In case there are NO env. vars from zz010-Get-Env-Set-Files
*>
     if       ACAS_LEDGERS (1:1) = "/"   *> Its Linux/Unix
              move "/" to OS-Delimiter.
     if       ACAS_LEDGERS (1:1) = "\"   *> Its Windoz
              move "\" to OS-Delimiter.
*>
*>  Put absolute path with file names into the file-id areas over-writing filename.
*>    Note that count in perform is equal to number of files used in system & wsnames.cob held
*>       in File-Defs-Count (IRS file is elsewere
*>
 zz020-Set-the-Paths.
*>
     move     zero to z.
     perform  File-Defs-Count times
              add 1 to z
              move space to Arg-Test
              string ACAS_LEDGERS          delimited by space
                     OS-Delimiter          delimited by size
                     System-File-Names (z) delimited by space into Arg-Test
              end-string
              move     Arg-Test to System-File-Names (z)
     end-perform
     move     zero to z.
*>
 zz020-Exit.
     exit   section.
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
 maps04       section.
*>*******************
*>
     call     "maps04"  using  maps03-ws.
*>
 maps04-exit.
     exit     section.
*>
