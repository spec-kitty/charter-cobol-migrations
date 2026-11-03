       >>source free
*>*********************************************************************
*>                                                                    *
*>  P O S T I N G    D E F A U L T S   F I L E    U T I L I T I E S   *
*>                                                                    *
*>   This module uses the Report Writer function in Gnu COBOL v2.1    *
*>        the one without RW is called irs020-non-rw.cbl              *
*>*********************************************************************
*>
 identification division.
 program-id.            irs020.
*>author.               Cobol Conversion by Vincent Bryan Coen. MBCS
*>                      for Applewood Computers.
*>
*>Security.             Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*>  remarks.            Postings Default File Utilities Program
*>
*>  version.            See PROG-NAME in ws.
*>
*>  calls               irsub1
*>                      irsub3
*>                      irsub5
*>
*>changes.
*> 28/06/83 vbc - Allow final a/c 2 b displayed before change.
*> 11/07/83 vbc - Get default 30 on setup,force code.
*> 11/07/83 vbc - Check if coa exists if not exit.
*> 25/07/83 vbc - Fix print routine,set ans to 0 1st.
*> 15/09/83 vbc - Clean up print layout.
*> 28/05/84 vbc - Hilite disp heads.
*> 14/04/85 vbc - Exclude finals & reduce print to 79 chars.
*> 26/09/89 vbc - Mods for cobol/2 change print to 80 chars.
*> 21/01/09 vbc - Migration to Open Cobol as version 3.
*> 21/02/09 vbc - Cosmetics in the displays for setup and amend
*> 21/09/10 vbc - Added print spool.
*>                .10 Fix for portrait printing
*> 16/12/13 vbc - .11 Rewritten for GNU Cobol Report Writer functions in V2.1.
*>                     LATEST version without rw is called irs020-non-rw but 
*>                          check version number (just in case).
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
 copy  "envdiv.cob".
*>
 input-output section.
 file-control.
*>
     select  print-file     assign  "prt-1"
                            organization line sequential.
*>
 data division.
 file section.
*>
 fd  print-file
     report Default-File-Report.
*>
 working-storage section.
 01  prog-name           pic x(16)    value "irs020 (3.01.11)".
 copy "print-spool-command-p.cob".
*>
 01  filler.
     03  menu-reply      pic 9.
     03  ws-reply        pic x.
     03  input-type      pic x.
         88  sub-input        value  "Y".
*>     03  counter         pic 99.
     03  ws-pass         pic x(4).
     03  w               pic 99.
     03  y               pic 99.
*>     03  count2          pic 9.
*>
     03  curs            pic 9(4).
     03  filler redefines curs.
         05  lin         pic 99.
         05  cole        pic 99.
     03  curs2           pic 9(4).
     03  filler redefines curs2.
         05  lin2        pic 99.
         05  col2        pic 99.
*>
     03  ws-acs          pic 9(5).
     03  ws-codes        pic xx.
     03  ws-codes2       pic xx.
     03  ws-vat          pic x.
     03  ws-vat2         pic x.
     03  p-code          pic xx.
     03  p-vat           pic x.
*>
 copy  "wsnl.cob".
 copy  "wsfnctn.cob".
 copy  "wsdflt.cob".
*>
*>                  finals not in use at present
 copy  "wsfinal.cob".
*>
 01  All-My-Constants      pic 9(4).
     copy "screenio.cpy".
*>
*>         finals not in use at present
*>copy "wsirs020.cob".
*>
 linkage section.
 copy  "wssystem.cob".
*>
 report section.
*>**************
*>
 rd  Default-File-Report
     page limit is 38
     heading 1
     first detail 7
     last  detail 38.
*>
 01  Report-Head-Group type page heading.
     03  line 1.
         05  col  1      pic x(24)     source Suser.
         05  col 30      pic x(25)    value "Incomplete Records System".
         05  col 72      pic x(8)      source Run-Date.
     03  line + 2.
         05  col  1      pic x(24)     source Client.
         05  col 34      pic x(16)    value "Posting Defaults".
     03  line + 2.
         05  col 14      pic x(64)    value "A/C Nos".
         05  col 26      pic x(23)    value "------Description------".
         05  col 53      pic x(8)     value "Code VAT".
*>
 01  Default-Detail type detail.
     03  line + 1.
         05  col 11      pic z9        source w.
         05  col 15      pic zzzz9     source def-acs (w)  blank when zero.
         05  col 26      pic x(25)     source nl-name.
         05  col 54      pic xx        source p-code.
         05  col 61      pic x         source p-vat.
*>
 screen section.
*>--------------
 01  menu-screen-1             background-color cob-color-black
                               foreground-color cob-color-green.
     03  pic x(16) from prog-name          line 1 col 1   blank screen.
     03  value "Default File Utilities"    line 1 col 29
                               foreground-color cob-color-white
                               background-color cob-color-blue
                                        reverse-video.
     03  pic x(8) from run-date            line 1 col 73.
     03  value "Client -"                  line 3 col 1.
     03  pic x(29) from client             line 3 col 10
                               foreground-color cob-color-cyan.
     03  value "Start date -"              line 3 col 39.
     03  pic x(8) from start-date          line 3 col 52
                               foreground-color cob-color-cyan.
     03  value "End date -"                line 3 col 62.
     03  pic x(8) from end-date            line 3 col 73
                               foreground-color cob-color-cyan.
     03  value "Select the required function by number    ["
                                           line 5 col 1.
     03  pic x using menu-reply  auto      line 5 col 44
                               foreground-color cob-color-yellow.
     03  value "]"                         line 5 col 45.
     03  value "(1)  Set-Up Default Accounts" line  8 col 6.
     03  value "(2)  Amend  Default Accounts" line 10 col 6.
     03  value "(3)  Display the Defaults"    line 12 col 6.
     03  value "(4)  Print   the Defaults"    line 14 col 6.
     03  value "(5)  Set-Up Final Accounts"   line 17 col 6.
     03  value "(9)  Return to System Menu"   line 20 col 6.
     03  value "F1 to F5 = options 1 to 5;  Return to Accept " &
             "data;   Escape to quit"               line 23 col 1
                       highlight foreground-color cob-color-white.
*>
 01  Setup-Screen-1            background-color cob-color-black
                               foreground-color cob-color-green.
     03  pic x(16) from prog-name          line 1 col 1   blank screen.
     03  value "Default Accounts Setup"    line 1 col 29
                               foreground-color cob-color-white
                               background-color cob-color-blue
                                reverse-video.
     03  pic x(8) from run-date            line 1 col 73.
*>
 01  Setup-Screen-2Q.
     03  value "Client -"                  line 3 col  1.
     03  pic x(24) from client             line 3 col 10 foreground-color cob-color-cyan.
     03  value "Start date -"              line 3 col 39.
     03  pic x(8) from start-date          line 3 col 52 foreground-color cob-color-cyan.
     03  value "End date -"                line 3 col 62.
     03  pic x(8) from end-date            line 3 col 73 foreground-color cob-color-cyan.
     03  value "Add to Existing Defaults (Y/N) ? - ["
                                           line 5 col 1.
     03  pic x to ws-reply  auto           line 5 col 37 foreground-color cob-color-yellow.
     03  value "]"                         line 5 col 38.
     03  value "N.B. (1) If first time setup for this client an" &
               "swer no (N)"               line 7 col  1 background-color cob-color-red
                                                         foreground-color cob-color-white.
     03  value "(2) Answering no (N)"      line 8 col  6 background-color cob-color-red
                                                         foreground-color cob-color-white.
     03  value "destroys"                  line 8 col 27 foreground-color cob-color-white
                                                         background-color cob-color-red
                                                                blink reverse-video.
     03  value "the existing defaults"     line 8 col 36 background-color cob-color-red
                                                         foreground-color cob-color-white.
     03  value "Escape to quit;    Return to Accept data"
                                           line 23 col 1 highlight foreground-color cob-color-white.
*>
 01  Amend-Screen-1                                      background-color cob-color-black
                                                         foreground-color cob-color-green.
     03  pic x(16) from prog-name          line 1 col  1  blank screen.
     03  value "Default Accounts Amendments" line 1 col 28 foreground-color cob-color-white
                                                           background-color cob-color-blue
                                                                reverse-video.
     03  pic x(8) from run-date            line 1 col 73.
*> setup
 01  Setup-Amend-Screen-3                                 background-color cob-color-black
                                                          foreground-color cob-color-green.
     03  value "Client -"                  line  3 col  1.
     03  pic x(24) from client             line  3 col 10 foreground-color cob-color-cyan.
     03  value "Start date -"              line  3 col 39.
     03  pic x(8) from start-date          line  3 col 52 foreground-color cob-color-cyan.
     03  value "End date -"                line  3 col 62.
     03  pic x(8) from end-date            line  3 col 73 foreground-color cob-color-cyan.
     03  value "A/C Nos"                   line  5 col  4.
     03  value "Description"               line  5 col 14.
     03  value "Code VAT   A/C Nos"        line  5 col 33.
     03  value "Description"               line  5 col 54.
     03  value "Code VAT"                  line  5 col 73.
     03  value " "  erase eol              line  6 col 1.
     03  occurs 16
      value "01 [00000]                      [AB] [C]" &
            "17 [00000]                      [DE] [F"
                                           line plus 1 col 1.
*> after display need to update cc1&2 with 1 - 16 & cc41&42 with 17 - 32
*>  cc4/44 = a/c-nos , vat 38/78, 33/73 code
*>
 01  Display-Screen-1                                     background-color cob-color-black
                                                          foreground-color cob-color-green.
     03  pic x(16) from prog-name          line  1 col  1      blank screen.
     03  value "Default Accounts Display"  line  1 col 27 foreground-color cob-color-white
                                                          background-color cob-color-blue
                                                                reverse-video.
     03  pic x(8) from run-date            line  1 col 73.
*>
 01  Finished-Account-Setup-Screen-1                      background-color cob-color-black
                                                          foreground-color cob-color-green.
     03  value "Client "                   line  1 col  1         blank screen.
     03  pic x(24) from client             line  1 col  8 foreground-color cob-color-cyan.
     03  value "Finished Accounts Setup"   line  1 col 34 foreground-color cob-color-white
                                                          background-color cob-color-blue
                                                                 reverse-video.
     03  pic x(8) from run-date            line  1 col 73.
     03  value "Trading and Profit & Loss Account              " &
               "   Balance Sheet"          line  3 col  4.
     03  value "--------Heading---------  Sign          -------" &
               "-Heading---------  Sign"   line  4 col 10.
     03  value "Income Accounts"           line  5 col  1.
     03  value "Fixed     Assets"          line  5 col 41.
     03  value "<A>   ["                   line  6 col  3.
     03  pic x(24) using ar1-1             line  6 col 10 foreground-color 3.
     03  value "] ["                       line  6 col 34.
     03  pic x     using ar2-1             line  6 col 37 foreground-color 3.
     03  value "]    <O>   ["              line  6 col 38.
     03  pic x(24) using ar1-15            line  6 col 50 foreground-color 3.
     03  value "] ["                       line  6 col 74.
     03  pic x     using ar2-15            line  6 col 77 foreground-color 3.
     03  value "]"                         line  6 col 78.
     03  value "<B>   ["                   line  7 col  3.
     03  pic x(24) using ar1-2             line  7 col 10 foreground-color 3.
     03  value "] ["                       line  7 col 34.
     03  pic x     using ar2-2             line  7 col 37 foreground-color 3.
     03  value "]    <P>   ["              line  7 col 38.
     03  pic x(24) using ar1-16            line  7 col 50 foreground-color 3.
     03  value "] ["                       line  7 col 74.
     03  pic x     using ar2-16            line  7 col 77 foreground-color 3.
     03  value "]"                         line  7 col 78.
     03  value "<C>   ["                   line  8 col  3.
     03  pic x(24) using ar1-3             line  8 col 10 foreground-color 3.
     03  value "] ["                       line  8 col 34.
     03  pic x     using ar2-3             line  8 col 37 foreground-color 3.
     03  value "]    <Q>   ["              line  8 col 38.
     03  pic x(24) using ar1-17            line  8 col 50 foreground-color 3.
     03  value "] ["                       line  8 col 74.
     03  pic x     using ar2-17            line  8 col 77 foreground-color 3.
     03  value "]"                         line  8 col 78.
     03  value "<D>   ["                   line  9 col  3.
     03  pic x(24) using ar1-4             line  9 col 10 foreground-color 3.
     03  value "] ["                       line  9 col 34.
     03  pic x     using ar2-4             line  9 col 37 foreground-color 3.
     03  value "]"                         line  9 col 38.
     03  value "Direct Cost Accounts"      line 10 col  1.
     03  value "Current Assets"            line 10 col 41.
     03  value "<E>   ["                   line 11 col  3.
     03  pic x(24) using ar1-5             line 11 col 10 foreground-color 3.
     03  value "] ["                       line 11 col 34.
     03  pic x     using ar2-5             line 11 col 37 foreground-color 3.
     03  value "]    <R>   ["              line 11 col 38.
     03  pic x(24) using ar1-18            line 11 col 50 foreground-color 3.
     03  value "] ["                       line 11 col 74.
     03  pic x     using ar2-18            line 11 col 77 foreground-color 3.
     03  value "]"                         line 11 col 78.
     03  value "<F>   ["                   line 12 col  3.
     03  pic x(24) using ar1-6             line 12 col 10 foreground-color 3.
     03  value "] ["                       line 12 col 34.
     03  pic x     using ar2-6             line 12 col 37 foreground-color 3.
     03  value "]    <S>   ["              line 12 col 38.
     03  pic x(24) using ar1-19            line 12 col 50 foreground-color 3.
     03  value "] ["                       line 12 col 74.
     03  pic x     using ar2-19            line 12 col 77 foreground-color 3.
     03  value "]"                         line 12 col 78.
     03  value "<G>   ["                   line 13 col  3.
     03  pic x(24) using ar1-7             line 13 col 10 foreground-color 3.
     03  value "] ["                       line 13 col 34.
     03  pic x     using ar2-7             line 13 col 37 foreground-color 3.
     03  value "]    <T>   ["              line 13 col 38.
     03  pic x(24) using ar1-20            line 13 col 50 foreground-color 3.
     03  value "] ["                       line 13 col 74.
     03  pic x     using ar2-20            line 13 col 77 foreground-color 3.
     03  value "]"                         line 13 col 78.
     03  value "<H>   ["                   line 14 col  3.
     03  pic x(24) using ar1-8             line 14 col 10 foreground-color 3.
     03  value "] ["                       line 14 col 34.
     03  pic x     using ar2-8             line 14 col 37 foreground-color 3.
     03  value "]"                         line 14 col 38.
     03  value "Sundry Income Accounts"    line 15 col  1.
     03  value "Current Liabilities"       line 15 col 41.
     03  value "<I>   ["                   line 16 col  3.
     03  pic x(24) using ar1-9             line 16 col 10 foreground-color 3.
     03  value "] ["                       line 16 col 34.
     03  pic x     using ar2-9             line 16 col 37 foreground-color 3.
     03  value "]    <U>   ["              line 16 col 38.
     03  pic x(24) using ar1-21            line 16 col 50 foreground-color 3.
     03  value "] ["                       line 16 col 74.
     03  pic x     using ar2-21            line 16 col 77 foreground-color 3.
     03  value "]"                         line 16 col 78.
     03  value "<J>   ["                   line 17 col  3.
     03  pic x(24) using ar1-10            line 17 col 10 foreground-color 3.
     03  value "] ["                       line 17 col 34.
     03  pic x     using ar2-10            line 17 col 37 foreground-color 3.
     03  value "]    <V>   ["              line 17 col 38.
     03  pic x(24) using ar1-22            line 17 col 50 foreground-color 3.
     03  value "] ["                       line 17 col 74.
     03  pic x     using ar2-22            line 17 col 77 foreground-color 3.
     03  value "]"                         line 17 col 78.
     03  value "Indirect Cost Accounts"    line 18 col  1.
     03  value "Capital Accounts"          line 18 col 41.
     03  value "<K>   ["                   line 19 col  3.
     03  pic x(24) using ar1-11            line 19 col 10 foreground-color 3.
     03  value "] ["                       line 19 col 34.
     03  pic x     using ar2-11            line 19 col 37 foreground-color 3.
     03  value "]    <W>   ["              line 19 col 38.
     03  pic x(24) using ar1-23            line 19 col 50 foreground-color 3.
     03  value "] ["                       line 19 col 74.
     03  pic x     using ar2-23            line 19 col 77 foreground-color 3.
     03  value "]"                         line 19 col 78.
     03  value "<L>   ["                   line 20 col  3.
     03  pic x(24) using ar1-12            line 20 col 10 foreground-color 3.
     03  value "] ["                       line 20 col 34.
     03  pic x     using ar2-12            line 20 col 37 foreground-color 3.
     03  value "]    <X>   ["              line 20 col 38.
     03  pic x(24) using ar1-24            line 20 col 50 foreground-color 3.
     03  value "] ["                       line 20 col 74.
     03  pic x     using ar2-24            line 20 col 77 foreground-color 3.
     03  value "]"                         line 20 col 78.
     03  value "<M>   ["                   line 21 col  3.
     03  pic x(24) using ar1-13            line 21 col 10 foreground-color 3.
     03  value "] ["                       line 21 col 34.
     03  pic x     using ar2-13            line 21 col 37 foreground-color 3.
     03  value "]    <Y>   ["              line 21 col 38.
     03  pic x(24) using ar1-25            line 21 col 50 foreground-color 3.
     03  value "] ["                       line 21 col 74.
     03  pic x     using ar2-25            line 21 col 77 foreground-color 3.
     03  value "]"                         line 21 col 78.
     03  value "<N>   ["                   line 22 col  3.
     03  pic x(24) using ar1-14            line 22 col 10 foreground-color 3.
     03  value "] ["                       line 22 col 34.
     03  pic x     using ar2-14            line 22 col 37 foreground-color 3.
     03  value "]    <Z>   ["              line 22 col 38.
     03  pic x(24) using ar1-26            line 22 col 50 foreground-color 3.
     03  value "] ["                       line 22 col 74.
     03  pic x     using ar2-26            line 22 col 77 foreground-color 3.
     03  value "]"                         line 22 col 78.
     03  value "P & L Appropriation Account ["  line 23 col  1.
     03  pic 9(5) using PL-Approp-AC       line 23 col 30 foreground-color 3.
     03  value "]"                         line 23 col 35.
*>
 procedure division using system-record.
*>*************************************
*>
 init01  section.
*>--------------
*>
*> first get Date & User Information
*>
     move     system-files to file-names.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name to PSN.
*>
 main-loop.
*>----------
*>
     move     zero to menu-reply.
     display  menu-screen-1.
     accept   menu-screen-1.
     if       menu-reply = 1 or Cob-Crt-Status = Cob-Scr-F1
              perform Set-Up
     else
      if      menu-reply = 2 or Cob-Crt-Status = Cob-Scr-F2
              perform Amend
      else
       if     menu-reply = 3 or Cob-Crt-Status = Cob-Scr-F3
              perform Show
       else
        if    menu-reply = 4 or Cob-Crt-Status = Cob-Scr-F4
              perform Listing
        else
         if   menu-reply = 5 or Cob-Crt-Status = Cob-Scr-F5
              perform Set-Up-Finished
         else
         if   menu-reply = 9 or Cob-Crt-Status = Cob-Scr-Esc
*>             move 5  to  file-function
*>             call "irsub5"  using  final-record  file-access
              go to main01-exit.
     go       to main-loop.
*>
 main01-exit.
     exit     program.
*>
 set-up section.
*>-------------
*>
     display  Setup-Screen-1.
     accept   Setup-Screen-2Q.
*>
 main-loop.
*>---------
     if       Cob-Crt-Status = Cob-Scr-Esc
              go to main-exit.
     if       function upper-case (ws-reply) = "N"
              perform  file-init.
     if       function upper-case (ws-reply) not = "Y" and not = "N"
              go to set-up.
*>
     display  Setup-Screen-1.
     display  Setup-Amend-Screen-3.
     perform  varying w from 1 by 1 until w > 16
              add w 16 giving y
              move 1 to cole
              add 6 w giving lin
              display w at curs with foreground-color 2
              move 41 to cole
              display y at curs with foreground-color 2
     end-perform
     perform  Input-Headings.
*>
 get-input.
*>----------
*>
     display  w at curs with foreground-color 2.
     add      4  curs giving curs2.
     move     def-acs (w) to ws-acs.
     accept   ws-acs at curs2 with update foreground-color cob-color-cyan.
     move     ws-acs to def-acs (w).
     if       def-acs (w)  =  zero
              move 41  to  cole
              move 30  to  w
              move 20  to  lin
              go to get-input.
     move     def-acs (w)  to  nl-owning.
     move     zero  to  nl-sub-nominal.
*>
*> get code description.
*>
     move     4  to  file-function.
     call     "irsub1"  using  nl-record  file-access.
     if       we-error  =  2
              go to get-input.
     add      10  curs giving curs2.
     display  nl-name at curs2  with foreground-color cob-color-cyan.
     add      22 to col2.
     display  "[  ]"  at curs2 with foreground-color 2.
     add      1 to col2.
     move     def-codes (w) to ws-codes.
*>
     if       w < 30
              accept ws-codes  at curs2 with update foreground-color 3
     else
      if      w = 30
              move "OB" to ws-codes
      else
       if     w = 31
              move "VI" to ws-codes
       else
              move "VO" to ws-codes.
*>
     move     function upper-case (ws-codes) to def-codes (w).
     add      32    curs giving curs2.
     add      1 to col2.
     display  ws-codes at curs2  with foreground-color cob-color-cyan.
     add      2 to col2.
*>
 vat-check.
*>----------
*>
     add      38    curs giving curs2.
     move     def-vat (w) to ws-vat2.
     if       w < 30
              accept ws-vat2 at curs2 with foreground-color 3
     else
              move "N" to ws-vat2
              display ws-vat2 at curs2 with foreground-color 3
     end-if
     move     function upper-case (ws-vat2) to ws-vat.
     move     ws-vat to def-vat (w).
     if       ws-vat not = "I" and not = "N" and not = "O"
              go to vat-check.
*>
     add      1  to  w.
     if       w  >  32
              go to end-input.
     if       w  =  17
              move 41  to  cole
              move 6   to  lin.
     add      1  to  lin.
     go       to get-input.
*>
 end-input.
*>----------
*>
*> now close A/c file & write out defaults.
*>
     move     2  to  file-function.
     call     "irsub1"  using  nl-record   file-access.
     move     5  to  file-function.
     call     "irsub3"  using  default-record  file-access.
     perform  amend.
*>
 main-exit.
     exit.
*>
 amend section.
*>-------------
*>
     display  Amend-Screen-1.
     display  Setup-Amend-Screen-3.
     perform  varying w from 1 by 1 until w > 16
              add w 16 giving y
              move 1 to cole
              add 6 w giving lin
              display w at curs with foreground-color 2
              move 41 to cole
              display y at curs with foreground-color 2
     end-perform
     perform  Input-Headings.
*>
 get-input.
*>----------
     move     zero to y.
     display  "Give Default to amend - [  ]  (Use 00 to quit)" at 2420 with foreground-color 2.
     accept   y at 2445 with update foreground-color cob-color-yellow.
     if       y = zero
              go to end-input.
     if       y < 1 or > 32
              go to get-input.
     move     y to w.
     if       y > 16
              subtract 16 from y
              move 41 to cole
     else
              move 1 to cole
     end-if
     move     zero to lin.
     add      y 6 to lin.
     display  w at curs       with foreground-color 2.
     add      4 curs giving curs2.
     move     def-acs (w) to ws-acs.
     accept   ws-acs at curs2 with update foreground-color cob-color-cyan.
     move     ws-acs to def-acs (w).
     if       ws-acs = zero
              go to end-input.
     move     ws-acs to nl-owning.
     move     zero to nl-sub-nominal.
*>
*> get code description.
*>
     move     4 to file-function.
     call     "irsub1" using nl-record file-access.
     if       we-error = 2
              go to get-input.
     add      10 curs giving curs2.
     display  nl-name at curs2 with foreground-color cob-color-cyan.
     add      22 to col2.
     display  "[  ]"  at curs2 with foreground-color 2.
     add      1 to col2.
     move     def-codes (w) to ws-codes.
     accept   ws-codes2 at curs2   with update foreground-color cob-color-cyan.
     move     function upper-case (ws-codes2) to ws-codes.
     move     ws-codes to def-codes (w).
     add      32 curs giving curs2.
     display  "[" at curs2 with foreground-color 2.
     add      1 to col2.
     display  ws-codes at curs2 with foreground-color cob-color-cyan.
     add      2 to col2.         *> this looks wrong should only be 1
     display  "]" at curs2 with foreground-color 2.
*>
 vat-check.
*>----------
*>
     add      38 curs giving curs2.
     move     def-vat (w) to ws-vat2.
     accept   ws-vat2 at curs2 with update foreground-color cob-color-cyan.
     move     function upper-case (ws-vat2) to ws-vat.
     move     ws-vat to def-vat (w).
     if       ws-vat not = "I" and not = "N" and not = "O"
              go to vat-check.
     go       to get-input.
*>
 end-input.
*>--------
*>
*>  Close A/c file & write out defaults.
*>
     move     2 to file-function.
     call     "irsub1" using nl-record file-access.
     move     5 to file-function.
     call     "irsub3" using default-record file-access.
*>
 main-exit.
     exit.
*>
 Set-Up-Finished section.
*>----------------------
*>
*>   Final Accts not used on Open Source version but we can set then up
*> Now get record, if 1st time get an initialised record so no errors.
*>
     move     3  to  file-function.
     call     "irsub5" using final-record file-access.
*>
     if       we-error not = zero
              display "Failure to on Final File -" at 2301 with foreground-color 4 erase eol
              display we-error at 2330 with foreground-color 4 highlight
              display "Hit return to go back to menu" at 2401 with foreground-color 2 erase eol
              accept  menu-reply at 2432
              go to Set-Up-Finished-Exit
     end-if
     move     1  to  file-function access-type.      *> open input Nominal
     call     "irsub1" using nl-record file-access.
*>
 Setup-Fin-Retry.
     if       PL-App-Created not = "1"
              move zeros to PL-App-Created PL-Approp-AC
     end-if
     accept   Finished-Account-Setup-Screen-1.
     if       PL-Approp-AC not = zero
              move "1" to PL-App-Created
              move  PL-Approp-AC to nl-owning
              move  zero to nl-sub-nominal
              move  4 to file-function
              call  "irsub1" using nl-record file-access end-call
              if    we-error = 2
                    display "Account not found. Try again!" at 2401 with foreground-color 4
                    display "Hit return to continue" at 2431 with foreground-color 2
                    accept ws-reply at 2455
                    go to setup-fin-retry
              end-if
     end-if
*>
*> open, write out & close file
*>
     move     5 to file-function.
     call     "irsub5" using final-record file-access.    *> write and close default
     move     2 to file-function.                         *> close Nominal
     call     "irsub1" using nl-record file-access.
*>
 Set-Up-Finished-Exit.
     exit     section.
*>
 Show section.
*>------------
*>
     display  Display-Screen-1.
     display  Setup-Amend-Screen-3.
     perform  Input-Headings.
     display  " " at 2301 with erase eol.
     display  "End of listing. Hit return for Menu." AT 2401
                                             with foreground-color cob-color-white.
     move     space to ws-reply.
     accept   ws-reply  at 2479.
*>
*> now close A/Cs File
*>
     move     2 to file-function.
     call     "irsub1" using nl-record file-access.
*>
 main-exit.
     exit.
*>
 listing section.
*>---------------
*>
     display  " " at 0101 with erase eos.
*>
*> Open printer & Accounts files
*>
     open     output  print-file.
     initiate Default-File-Report.
     move     1  to  file-function  access-type.
     call     "irsub1"  using  nl-record  file-access.
*>
*>  get record
*>
     move     3  to  file-function.
     call     "irsub3"  using  default-record  file-access.
*>
*> Now print 'em
*>
     perform  varying w from 1 by 1 until w > 32
              move  def-acs (w)  to  nl-owning
              move  zero  to  nl-sub-nominal
              if    nl-owning  =  zero
                    move spaces to  nl-name
                                    p-vat
                                    p-code
              else
                    move 4  to  file-function   *>  get code description
                    call "irsub1" using nl-record file-access
                    move def-codes (w) to p-code
                    move def-vat (w)   to p-vat
              end-if
              generate Default-Detail
     end-perform
*>
*> Done so close files and spool report
*>
     move     2  to  file-function.        *>  close a/cs file
     call     "irsub1"  using nl-record file-access.
     terminate Default-File-Report.
     close    print-file.
     call     "SYSTEM" using Print-Report.
*>
 list-exit.
     exit.
*>
 file-init section.
*>-----------------
*>
     display  "Enter pass-word - [    ]" at 0551 with foreground-color 2.
     accept   ws-pass at 0570 with update secure.
     if       ws-pass not = pass-word
              move "Z" to ws-reply
              go to main-exit.
     move     zero to default-record.
     move     5 to file-function.
     call     "irsub3" using  default-record   file-access.
*>
 main-exit.
     exit.
*>
*>        Finals but not supplied on free copy
*>
*>copy "pirs020.cob".
*>
 Input-Headings section.
*>---------------------
*>
*> open a/c files
*>
     move     1  to  file-function   access-type.
     call     "irsub1"  using  nl-record   file-access.
*>
     if       we-error not = zero
              display "You must Setup Chart of Accounts first (" &
                      "Selection no. 2)" at 2301
              display "Hit return for return to Main Menu" at 2401
                                                 with foreground-color cob-color-white
              move space to ws-reply
              accept ws-reply at 2443
              go to main01-exit in init01.
*>
*> now input existing defaults
*>
     move     1 to w  cole.   *> curs
     move     7 to lin.
*>
     move     3  to  file-function.
     call     "irsub3"  using  default-record   file-access.
*>
 display-existing.
*>-----------------
*>
     display  w at curs with foreground-color cob-color-green.
     add      4  curs giving curs2.
     move     def-acs (w) to ws-acs.
     display  ws-acs at curs2      with foreground-color cob-color-cyan.
     move     ws-acs to nl-owning.
     move     zero  to  nl-sub-nominal.
     if       ws-acs not = zero
              move 4 to file-function
              call "irsub1" using nl-record file-access
              add  10 curs giving curs2
              display nl-name (1:22) at curs2 with foreground-color cob-color-cyan
     end-if
*>*> get code description
     add      33  curs giving curs2.
     move     def-codes (w) to ws-codes.
     display  ws-codes  at curs2     with foreground-color cob-color-cyan.
     add      5 to col2.
     move     def-vat (w) to ws-vat.
     display  ws-vat  at curs2       with foreground-color cob-color-cyan.
     add      1 to col2.
     display  "]" at curs2           with foreground-color cob-color-green.
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
*>---------------------
*>
     move     1  to  w  cole.
     move     7  to  lin.
*>
 main-exit.
     exit.
