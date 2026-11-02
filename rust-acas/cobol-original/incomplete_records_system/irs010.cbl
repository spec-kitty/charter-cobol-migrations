       >>source free
*>*****************************************************************
*>                                                                *
*> A C C O U N T   F I L E    U T I L I T I E S    P R O G R A M  *
*>                                                                *
*>*****************************************************************
*>
 identification division.
 program-id.            irs010.
*>author.               Cobol Conversion By Vincent B Coen, MBCS 13/10/82
*>                      for Applewood Computers.
*>
*>Security.             Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*>remarks.              Accounts File Utilities Program
*>
*>  calls               irsub1
*>
*> changes.
*> 16/09/83 vbc - fix error on amend not clear input type.
*> 28/05/84 vbc - hilite display heads.
*> 14/04/85 vbc - change print to 79 chars.
*> 26/09/89 vbc - mods for cobol/2 & change printline to 80 chars.
*> 28/09/89 vbc - force lower case to upper.
*> 18/01/09 vbc - Migration to Open Cobol as version 3
*> 20/02/09 vbc - Added support for env's LINES and COLUMNS as needed.
*> 21/09/10 vbc - Added print spool.
*>                .05 fix for portrait printing
*> 21/11/11 vbc - .06 Added firsttime-flag proc to clear down prebuild CoA
*>                    prior to 1st usage and pre postings.
*> 29/04/13 vbc - .07 Added facility to export and import CoA as a template
*>                    in .txt format and export only as a cvf (common delimiter
*>                    form eg, chars,chars,chars,chars. Normal is text (.txt).
*> 03/05/13 vbc - .08 Clear bug on importing CoA from text file when processing
*>                    sub nominals
*> 04/05/13 vbc - .09 Tidy up displays for export/import of CoA
*>                .10 Change ws-amend-lines to ws-accept-lines in amend.
*> 05/05/13 vbc - .11 Changed opening sequence for CoA import to that for setup.
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
     select  print-file     assign       "prt-1"
                            organization line sequential.
*>
     select  Saved-CoA      assign       Archive-Name
                            organization line sequential
                            status       fs-reply.
*>
 data division.
 file section.
*>
 fd  print-file.
*>
 01  print-record        pic x(80).
*>
 fd  Saved-CoA.
 01  Export-CoA-Text.
     03  ECoA-Data-Type  pic x.
     03  ECoA-Owning     pic 9(5).
     03  ECoA-Sub        pic 9(5).
     03  ECoA-nl-Type    pic x.
         88 ECoA-nl-sub-ac               value "S".
         88 ECoA-nl-owner                value "O".
     03  ECoA-nl-Name    pic x(24).
     03  ECoA-nl-AC      pic x.
*>
 01  Saved-CoA-Comma.
     03  ECoA-Data-TypeB pic x.
     03  Saved-CoA-Data  pic x(43).
*>
 working-storage section.
 77  prog-name           pic x(16)  value "irs010 (3.01.11)".
 copy "print-spool-command-p.cob".
 77  fs-reply            pic xx.
 77  menu-reply          pic x      value space.
 01  work-fields.
     03  ws-reply        pic x.
     03  ws-reply2       pic x.
     03  ws-Export-Format pic x     value "T".
     03  input-type      pic x.
         88  sub-input        value "y" "Y".
     03  input-type2     pic x.
         88  sub-input2       value "y" "Y".
     03  counter         pic 9(4).
     03  ws-pass         pic x(4).
     03  nl-ac2          pic a.
     03  save-owning     pic 9(5).
     03  count2          pic 9.
     03  curs            pic 9(4).
     03  filler redefines curs.
         05 lin          pic 99.
         05 cole         pic 99.
     03  curs2           pic 9(4).
     03  filler redefines curs2.
         05 lin2         pic 99.
         05 col2         pic 99.
     03  prt-file        pic x(11).
     03  Archive-Name    PIC X(32)     VALUE "coa-archived.txt".
     03  line-cnt        pic 99   comp value 99.
     03  ws-spaces                     value  spaces.
         05  ws-spaces78 pic x(78).
         05  filler      pic xx.
     03  p-owning        pic zzzzz blank when zero.
     03  p-sub           pic zzzzz blank when zero.
     03  ws-env-columns  pic 999       value zero.
     03  ws-env-lines    pic 999       value zero.
     03  ws-lines        binary-char unsigned value zero.
     03  ws-columns      binary-char unsigned value zero.
     03  ws-show-lines   binary-char unsigned value zero.
*>     03  ws-amend-lines  binary-char unsigned value zero.
     03  ws-setup-lines  binary-char unsigned value zero.
     03  ws-accept-lines binary-char unsigned value zero.
*>
 01  Cbl-File-Details.
     03  Cbl-File-Size       pic x(8)  comp-x  value zero.
     03  Cbl-File-Date.
         05  Cbl-File-Day    pic x     comp-x  value zero.
         05  Cbl-File-Mth    pic x     comp-x  value zero.
         05  Cbl-File-Year   pic xx    comp-x  value zero.
     03  Cbl-File-time.
         05  Cbl-File-Hour   pic x     comp-x  value zero.
         05  Cbl-File-Min    pic x     comp-x  value zero.
         05  Cbl-File-Sec    pic x     comp-x  value zero.
         05  Cbl-File-Hund   pic x     comp-x  value zero.
*>
 copy "wsfnctn.cob".
 copy "wsnl.cob".
*>
 01  print-lines.
     03  line-1.
         05  p-user        pic x(24).
         05  filler        pic x(4)    value spaces.
         05  l1-a          pic x(26)   value "Incomplete Records System".
         05  filler        pic x(18)   value spaces.
         05  p-date        pic x(8).
     03  line-3.
         05  p-client      pic x(24).
         05  filler        pic x(7)    value spaces.
         05  l3-a          pic x(18)   value "Accounts Directory".
         05  filler        pic x(22)   value spaces.
         05  l3-b          pic x(6)    value "Page -".
         05  p-page        pic zz9.
     03  line-4.
         05  filler        pic x(11)   value spaces.
         05  l4-a          pic x(56)   value
         "  Main A/C       Sub-Account     ------Description------".
         05  l4-b          pic x(12)   value "    A/C Type".
     03  line-6.
         05  filler        pic x(14)   value spaces.
         05  p6-owning     pic zzzz9   blank when zero.
         05  filler        pic x(12)   value spaces.
         05  p6-sub        pic zzzz9   blank when zero.
         05  filler        pic x(8)    value spaces.
         05  p-description pic x(24).
         05  filler        pic x(7)    value spaces.
         05  p-ac          pic x.
*>
 01  All-My-Constants      pic 9(4).
     copy "screenio.cpy".
*>
 linkage section.
*>---------------
*>
 copy "wssystem.cob".
*>
 screen section.
*>--------------
 01  menu-screen-1                                      background-color cob-color-black
                                                        foreground-color cob-color-green.
     03  pic x(16) from prog-name          line 1 col  1    blank screen.
     03  value "Accounts File Utilities"   line 1 col 29 foreground-color cob-color-white
                                                         background-color cob-color-blue
                                                            reverse-video.
     03  pic x(8) from run-date            line 1 col 73.
     03  value "Client -"                  line 3 col  1.
     03  pic x(24) from client             line 3 col 10 foreground-color cob-color-cyan.
     03  value "Start date -"              line 3 col 39.
     03  pic x(8) from start-date          line 3 col 52 foreground-color cob-color-cyan.
     03  value "End date -"                line 3 col 62.
     03  pic x(8) from end-date            line 3 col 73 foreground-color cob-color-cyan.
     03  value "Select the required function by number    ["
                                           line 5 col  1.
     03  pic x using menu-reply  auto      line 5 col 44 foreground-color cob-color-yellow.
     03  value "]"                         line 5 col 45.
     03  value "(1)  Set-Up Chart of Accounts" line  8 col 6.
     03  value "(2)  Amend  Chart of Accounts" line 10 col 6.
     03  value "(3)  Display the Chart"    line 12 col 6.
     03  value "(4)  Print   the Chart"    line 14 col 6.
     03  value "(5)  Export  the Chart"    line 15 col 6.
     03  value "(6)  Import  the Chart"    line 16 col 6.
     03  value "(9)  Return to System Menu" line 18 col 6.
     03  value "F1 to F4 = options 1 to 4;  Return to Accept " &
             "data;   Escape to quit"      line 23 col 1 foreground-color cob-color-white
                                                               highlight.
*>
 01  Amend-Screen-1                                      background-color cob-color-black
                                                         foreground-color cob-color-green.
     03  pic x(16) from prog-name          line 1 col  1   blank screen.
     03  value "Chart of Accounts Amendments" line 1 col 28 foreground-color cob-color-white
                                                            background-color cob-color-blue
                                                                  reverse-video.
     03  pic x(8)  from run-date           line 1 col 73.
*>
 01  Setup-Screen-1                                      background-color cob-color-black
                                                         foreground-color cob-color-green.
     03  pic x(16) from prog-name          line 1 col  1          blank screen.
     03  value "Chart of Accounts Setup"   line 1 col 30 foreground-color cob-color-white
                                                         background-color cob-color-blue
                                                                  reverse-video.
     03  pic x(8) from run-date            line 1 col 73.
*>
 01  Setup-Screen-2Q.
     03  value "Client -"                  line  3 col  1.
     03  pic x(24) from client             line  3 col 10 foreground-color cob-color-cyan.
     03  value "Start date -"              line  3 col 39.
     03  pic x(8) from start-date          line  3 col 52 foreground-color cob-color-cyan.
     03  value "End date -"                line  3 col 62.
     03  pic x(8) from end-date            line  3 col 73 foreground-color cob-color-cyan.
     03  value "Add to Existing Chart (Y/N) ? - [" line 5 col 1.
     03  pic x to menu-reply  auto         line  5 col 34 foreground-color cob-color-yellow.
     03  value "]"                         line  5 col 35.
     03  value "N.B. (1) If first time setup for this client answer no (N)"
                                           line  7 col  1 background-color cob-color-red
                                                          foreground-color cob-color-white.
     03  value "(2) Answering no (N)"      line  8 col  6 background-color cob-color-red
                                                          foreground-color cob-color-white.
     03  value "destroys"                  line  8 col 27 foreground-color cob-color-white
                                                          background-color cob-color-red
                                                                reverse-video.
     03  value "the existing chart"        line  8 col 36 background-color cob-color-red
                                                          foreground-color cob-color-white.
     03  value "Escape to quit;    Return to Accept data"
                                           line 23 col  1  foreground-color cob-color-white
                                                                highlight.
*>
 01  Setup-Amend-Screen-3                                 background-color cob-color-black
                                                          foreground-color cob-color-green.
     03  value "Client -"                  line  3 col  1.
     03  pic x(24) from client             line  3 col 10 foreground-color cob-color-cyan.
     03  value "Start date -"              line  3 col 39.
     03  pic x(8) from start-date          line  3 col 52 foreground-color cob-color-cyan.
     03  value "End date -"                line  3 col 62.
     03  pic x(8) from end-date            line  3 col 73 foreground-color cob-color-cyan.
     03  value "Main A/C      Sub-Nominal       Sub-Account     " &
         "  Description          A/C Type" line  4 col  2 highlight.
     03  value " "  erase eol              line  5 col  1.
     03  occurs 16
         value "[     ]           [ ]             [     ]" &
         "   [                        ]   [ ]" line plus 1 col 2.
*>
 01  Display-Screen-1                                     background-color cob-color-black
                                                          foreground-color cob-color-green.
     03  pic x(24) from suser              line  1 col 1  blank screen.
     03  value "Incomplete Records System" line  1 col 28 foreground-color cob-color-white
                                                          background-color cob-color-blue
                                                                reverse-video.
     03  pic x(8) from run-date            line  1 col 73.
     03  value "Client -"                  line  3 col 1.
     03  pic x(24) from client             line  3 col 10 foreground-color cob-color-cyan.
     03  value "Accounts Directory"        line  3 col 32.
     03  value "Page"                      line  3 col 73.
     03  pic zz9 from counter              line  3 col 78 foreground-color cob-color-cyan.
     03  value "  Main       Sub             Description         " &
               "     Type "                line  5 col 11 background-color cob-color-blue
                                                          foreground-color cob-color-white.
*>
 procedure division using system-record.
*>**************************************
*>
 inita  section.
*>
*>   first get Date & User Information..
*>
     move     system-files to file-names.
*>
     accept   ws-env-lines   from lines.
     accept   ws-env-columns from columns.
     if       ws-env-columns < 80
              move 80 to ws-env-columns ws-columns
     else
              move  ws-env-columns to ws-columns
     end-if
     if       ws-env-lines < 24
              move  24 to ws-env-lines ws-lines
     else
              move  ws-env-lines   to ws-lines
     end-if.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name to PSN.
*>
 main01-loop.
*>-----------
*>
*> First check if this is first time setting up a/c's
*>  if so does accounts exist in which case a/cs are from
*> inported from sample data and if so, offer to clear down
*>  all values before any thing else happens
*>
     if       First-Time-Flag = zero
              perform zz000-clear-NL
              if   menu-reply = "0"
                   move 1 to First-Time-Flag.
*>
     move     "0" to menu-reply.
     display  Menu-Screen-1.
     accept   Menu-Screen-1.
*>
     if       menu-reply = 1  or Cob-Crt-Status = Cob-Scr-F1
              perform set-up
              go to main01-loop.
     if       menu-reply = 2  or Cob-Crt-Status = Cob-Scr-F2
              perform amend
              go to main01-loop.
     if       menu-reply = 3  or Cob-Crt-Status = Cob-Scr-F3
              perform show
              go to main01-loop.
     if       menu-reply = 4  or Cob-Crt-Status = Cob-Scr-F4
              perform listing
              go to main01-loop.
     if       menu-reply = 5  or Cob-Crt-Status = Cob-Scr-F5
              perform ea-Export-CoA
              go to main01-loop.
     if       menu-reply = 6  or Cob-Crt-Status = Cob-Scr-F6
              perform fa-Import-CoA
              go to main01-loop.
     if       menu-reply = 9  or Cob-Crt-Status = Cob-Scr-Esc
              go to main01-exit.
     go       to main01-loop.
*>
 main01-exit.
     exit     program.
*>
 set-up section.
*>--------------
*>
 main02.
*>-----
*>
     display  Setup-Screen-1.
     accept   Setup-Screen-2Q.
     subtract 1 from ws-lines giving ws-accept-lines.
*>
     if       Cob-Crt-Status = Cob-Scr-Esc
              go to main02-exit.
     if       function upper-case (menu-reply) = "N"
              perform  file-init.
     if       function upper-case (menu-reply) = "Y" OR "N"
              move 2 to access-type
     else
              go to main02.
*>
*> Open the Nominal Ledger
*>
     move     1  to  file-function.
     call     "irsub1"  using  nl-record file-access.
*>
     display  setup-screen-1.
     display  Setup-Amend-Screen-3.
     perform  setup-display.
     move     6  to  lin.
*>
*> screen refresh after using last data accept on screen might be screwed
*>   if so, perf setup-display    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
 input02-loop.
*>-----------
     move     1 to cole.
     display  " [     ]           [ ]             [     ]   [      " &
     "                  ]   [ ]" at curs with foreground-color cob-color-green.
     if       sub-input
              go to input02-sub.
     move     zero  to  nl-owning nl-sub-nominal.
     move     3  to  cole.
     accept   nl-owning at curs with update foreground-color cob-color-yellow.
     if       nl-owning = zero
              go to main02-end.
     if       access-type = 3           *> file opened as output so key check bypassed
              go to jump02-1.
*>
*> check that key is unique
*>
     move     4  to  file-function.    *> read indexed
     call     "irsub1"  using  nl-record  file-access.
     if       we-error = 2             *> record not found
              display  ws-spaces78 at line ws-lines col 01
              go to jump02-1.
*>
*> Record already exists
*>
     move     47 to cole.
     display  nl-name at curs with foreground-color cob-color-yellow.
     move     curs to curs2.
     add      1 to lin2.
     move     1 to col2.
     display  "Record already exists re-enter!" at line ws-lines col 01 with blink reverse-video.
*> 2401
     go       to input02-loop.
*>
 jump02-1.
*>-------
*>
     move     21 to cole.
     accept   input-type2 at curs with update foreground-color cob-color-yellow.
     move     function upper-case (input-type2) to input-type.
     if       input-type not = "N" and not = "Y"
              go to jump02-1.
     move     47 to cole.
     move     spaces to nl-name.
     accept   nl-name at curs with update foreground-color cob-color-yellow.
*>
 jump02-1-1.
*>---------
     move     76 to cole.
     accept   nl-ac2 at curs with update foreground-color cob-color-yellow.
     move     function upper-case (nl-ac2) to nl-ac.
     if       nl-ac < "A" OR > "Z"
              go to jump02-1-1.
*>
*>  Output the record.
*>
     move     "O" to nl-type.
     move      1 to First-Time-Flag.
     go       to main02-output.
*>
 input02-sub.
*>----------
     move     zero to nl-sub-nominal.
     move     37 to cole.
     accept   nl-sub-nominal at curs with update foreground-color cob-color-yellow.
     if       nl-sub-nominal = zero
              move "N" to input-type
              subtract 1 from  lin
              go to main02-return.
*>
*> check that key is unique
*>
     move     4 to file-function.
     call     "irsub1"  using  nl-record  file-access.
     if       we-error = 2
              display ws-spaces78 at line ws-lines col 01
              go to jump02-2.
*>
*> Record already exists
*>
     display  nl-name at curs.
     display  "Record already exists re-enter!   Key is - "
                   at line ws-lines col 01 with blink reverse-video.
     display  nl-key at line ws-lines col 45 with foreground-color 3.
*> 2445
     go       to input02-sub.
*>
 jump02-2.
*>-------
     move     47 to cole.
     move     spaces to nl-name.
     accept   nl-name at curs with update foreground-color cob-color-yellow.
     move     "S" to nl-type.
*>
 main02-output.
*>------------
     move     zero  to  nl-dr           nl-cr
                        nl-dr-last (1)  nl-dr-last (2)
                        nl-dr-last (3)  nl-dr-last (4)
                        nl-cr-last (1)  nl-cr-last (2)
                        nl-cr-last (3)  nl-cr-last (4).
*>
     move     5 to file-function.  *> write
     call     "irsub1"  using  nl-record  file-access.
*>
 main02-return.
*>------------
*>
     add      1 to lin.
     move     1 to cole.
     display  ws-spaces  at curs.
     if       lin  <  ws-accept-lines
              go to input02-loop.
     move     6  to  lin.
*>
 return02-loop.
*>------------
     move     1 to cole.
     display  ws-spaces  at curs.
     add      1  to  lin.
     if       lin  <  ws-accept-lines
              go to return02-loop.
     move     6  to  lin.
     go       to input02-loop.
*>
 main02-end.
*>---------
*>
*> close nominal ledger
*>
     move     2 to file-function.
     call     "irsub1"  using  nl-record  file-access.
*>
 main02-exit.
     exit     section.
*>
 amend section.
*>-------------
*>
 main03.
*>
     display  Amend-screen-1.
     display  Setup-Amend-Screen-3.
     subtract 1 from ws-lines giving ws-accept-lines.
 setup-display.
*>     subtract 3 from ws-lines giving ws-amend-lines.
     move     2 to cole
*>
*> display extra lines if above 24 line display (if lines = 24 this won't run)
*>
     perform  varying lin from 22 by 1 until lin > ws-accept-lines
              display "[     ]           [ ]             [     ]" &
                      "   [                        ]   [ ]" at curs
                                                with foreground-color cob-color-green
     end-perform.
*>
 main03-loop.
*>----------
*>
*> now open the nominal ledger
*>
     move     2  to  access-type.
     move     1  to  file-function.
     call     "irsub1"  using  nl-record  file-access.
*>
 input03-headings.
*>---------------
*>
     move     6  to  lin.
*>
 input03-loop.
*>-----------
*>
     move     spaces to input-type.
     move     1 to cole.
     move     zero  to  nl-owning  nl-sub-nominal.
     move     3 to cole.
     accept   nl-owning  at curs with update foreground-color cob-color-yellow.
     if       nl-owning = zero
              go to main03-end.
*>
*> check key.
*>
     move     4  to  file-function.
     call     "irsub1"  using  nl-record  file-access.
     if       we-error = 2
              go to input03-loop.
*>
*> if here record does exist
*>
     move     47 to cole.
     display  nl-name at curs with foreground-color cob-color-yellow.
*>
 jump03-1.
*>-------
     move     21 to cole.
     accept   input-type2 at curs with update foreground-color cob-color-yellow.
     move     function upper-case (input-type2) to input-type.
     if       input-type = "D"
              perform delete-record
              go to input03-loop.
     if       input-type = "N"
              go to jump03-1-0.
     if       input-type = "Y"
              go to input03-sub
     else
              go to jump03-1.
*>
 jump03-1-0.
*>---------
     move     47 to cole.
     accept   nl-name at curs with update foreground-color cob-color-yellow.
*>
 jump03-1-1.
*>---------
     move     76 to cole.
     accept   nl-ac2  at curs with update foreground-color cob-color-yellow.
     move     function upper-case (nl-ac2) to nl-ac.
*>
     if       nl-ac < "A" or > "Z"
              go to jump03-1-1.
*>
*> now output the record.
*>
     move     "O"  to  nl-type  input-type.
     go       to main03-output.
*>
 input03-sub.
*>----------
     move     zero  to  nl-sub-nominal.
     move     37 to cole.
     accept   nl-sub-nominal at curs with update foreground-color cob-color-yellow.
     if       nl-sub-nominal = zero
              move "N"  to  input-type
              subtract 1  from  lin
              go to main03-return.
*>
*> check that key is unique
*>
     move     4  to  file-function.
     call     "irsub1"  using  nl-record  file-access.
     if       we-error = 2
              go to jump03-2.
*>
*> if here record already exists
*>
     move     47 to cole.
     display  nl-name at curs with foreground-color cob-color-yellow.
     move     "O"  to  input-type.
     move     "O"  to  nl-type.
     accept   nl-name at curs with update foreground-color cob-color-yellow.
*>
 jump03-1-s.
*>---------
     move     76 to cole.
     accept   nl-ac2 at curs with update foreground-color cob-color-yellow.
     move     function upper-case (nl-ac2) to nl-ac.
     if       nl-ac < "A" or > "Z"
              go to jump03-1-s.
     go       to  main03-output.
*>
 jump03-2.
*>-------
     move     47 to cole.
     accept   nl-name at curs with update foreground-color cob-color-yellow.
     move     "S" to nl-type input-type.
     move     zero to nl-dr           nl-cr
                      nl-dr-last (1)  nl-dr-last (2)
                      nl-dr-last (3)  nl-dr-last (4)
                      nl-cr-last (1)  nl-cr-last (2)
                      nl-cr-last (3)  nl-cr-last (4).
*>
 main03-output.
*>------------
*>
     if       input-type = "S"
              move 5  to  file-function
     else
              move 7  to  file-function.
     call     "irsub1"  using  nl-record  file-access.
*>
 main03-return.
*>------------
     move     1 to cole.
     add      1  to  lin.
*>    display  ws-spaces at curs.
     if       lin  <  ws-accept-lines   *> 23
              go to input03-loop.
     move     6  to  lin.
*>
     perform  main03.
     go       to input03-headings.
*>
 main03-end.
*>---------
*>
*> close nominal ledger
*>
     move     2  to  file-function.
     call     "irsub1"  using  nl-record   file-access.
*>
 main03-exit.
     exit     section.
*>
 show section.
*>------------
*>
     move     zero to counter.
     move     7 to lin.
     subtract 2 from ws-lines giving ws-accept-lines.
*>
*> now open nominal ledger
*>
     move     1  to  file-function  access-type.
     call     "irsub1"  using  nl-record  file-access.
     perform  main04-display.
     if       we-error = 1 *> no file
              go to main04-end.
*>
 main04-loop.
*>----------
*>
*> read next record
*>
     move     3  to  file-function.
     call     "irsub1"  using  nl-record  file-access.
     if       we-error = 3
              go to main04-end.
     move     nl-owning      to p-owning.
     move     nl-sub-nominal to p-sub.
     if       nl-sub-nominal  not equal zero
              move zero to p-owning.
     move     12 to cole.
     display  p-owning at curs with foreground-color cob-color-cyan.
     add      11 to cole.
     display  p-sub  at curs with foreground-color cob-color-cyan.
     add      13 to cole.
     display  nl-name at curs with foreground-color cob-color-cyan.
     add      30 to cole.
     display  nl-ac at curs with foreground-color cob-color-cyan.
     add      1  to  lin.
     if       lin  <  ws-accept-lines  *> 22
              go to main04-loop.
*>
*> end of screen routine
*>
     display  "Enter <N> for Next screen or <X> to Quit.......[ ]"
                      at line ws-lines col 18 with foreground-color cob-color-yellow.
     move     space to ws-reply2.
     accept   ws-reply2 at line ws-lines col 66 with auto foreground-color cob-color-yellow.
     move     function upper-case (ws-reply2) to ws-reply.
     if       ws-reply = "X"
              go to    main04-end2.
     display  " " at 0101 with erase eos.
     move     7 to  lin.
     perform  main04-display.
     go to    main04-loop.
*>
 main04-display.
*>--------------
*>
     add      1 to counter.
     display  Display-Screen-1.
*>
 main04-end.
*>---------
*>
     display  "End of display. Hit return for Menu." at line ws-lines col 18
                                 with erase eol foreground-color cob-color-yellow.
     move     space to ws-reply.
     accept   ws-reply at line ws-lines col 56 with foreground-color cob-color-yellow.
*>
 main04-end2.
*>-----------
*>
*> Close file
*>
     move     2 to file-function.
     call     "irsub1" using nl-record  file-access.
*>
 main04-exit.
     exit     section.
*>
 listing section.
*>---------------
*>
     display  space.
     move     run-date to p-date.
     move     client   to p-client.
     move     suser    to p-user.
*>
*> Open nominal ledger
*>
     move     zero to counter.
     move     1  to  file-function  access-type.
     call     "irsub1"  using  nl-record   file-access.
     open     output  print-file.
     move     85 to line-cnt.
*>
     perform  until we-error = 3           *> yep, its also checked lower
              move  3  to  file-function   *> read next record
              call "irsub1"  using nl-record file-access
              if   we-error = 3
                   exit perform
              end-if
              if   line-cnt > 80
                   add 1  to  counter
                   move  counter  to  p-page
                   if    counter not = 1
                         write print-record from line-1 after page
                   else
                         write print-record  from  line-1 after 1
                   end-if
                   write print-record  from  line-3 after 2
                   write print-record  from  line-4 after 2
                   move  spaces  to  print-record
                   write print-record after 1
                   move  6 to line-cnt
              end-if
              move  nl-owning      to p6-owning
              move  nl-sub-nominal to p6-sub
              if    nl-sub-nominal not = zero
                    move zero to  p6-owning
              end-if
              move  nl-name to  p-description
              move  nl-ac   to  p-ac
              write print-record from line-6 after 1
              add 1 to line-cnt
     end-perform
*>
*> Close file
*>
     move     2  to  file-function.
     call     "irsub1"  using  nl-record  file-access.
     close    print-file.
     call     "SYSTEM" using Print-Report.
*>
 list-exit.
     exit     section.
*>
 file-init section.
*>-----------------
*>
     display  "Enter Pass-word - [    ]" at 0551 with foreground-color 2.
     accept   ws-pass at 0570 with secure.
     if       ws-pass = pass-word
              move 1  to  file-function         *> Open output
              move 3  to  access-type
              call "irsub1"  using  nl-record file-access
              move  2 to file-function           *> Close file
              call  "irsub1" using nl-record file-access
     else
              move  "Z"  to  ws-reply
     end-if
     move     2 to access-type.              *> open i-o
*>
 main05-exit.
     exit     section.
*>
 delete-record section.
*>---------------------
*>
*> check key.
*>
     move     4  to  file-function.
     call     "irsub1"  using  nl-record  file-access.
     if       we-error = 2
              go to main06-exit.
     move     8 to file-function.
     call     "irsub1"  using  nl-record  file-access.
     move     nl-owning  to  save-owning.
     move     9 to file-function.
     move     6 to access-type.
     call     "irsub1"  using  nl-record  file-access.
*>
 loop06.
*>-----
*>
     if       nl-owning  not = save-owning
              go to main06-exit.
     move     8  to  file-function.
     call     "irsub1" using nl-record file-access.
     move     nl-owning to save-owning.
     if       nl-sub-nominal not = zero
              move nl-sub-nominal to nl-owning
              move zero  to  nl-sub-nominal
              call "irsub1" using nl-record file-access
              move save-owning  to nl-owning.
     move     2  to  file-function.
     call     "irsub1"  using  nl-record  file-access.
     move     1  to  file-function.
     move     2  to  access-type.
     call     "irsub1"  using  nl-record  file-access.
     move     9  to  file-function.
     move     6  to  access-type.
     move     zero  to  nl-sub-nominal.
     call     "irsub1"  using  nl-record  file-access.
     if       we-error = zero
              go to loop06.
*>
 main06-exit.
     exit     section.
*>
 ea-Export-CoA section.
*>--------------------
*>
 ea010-Warning-Notice.
     display  "This process will export a copy of the current CoA (Chart of Accounts)"
                                                                          at 0101 with foreground-color cob-color-yellow erase eos.
     display  "overwriting any copy of the file if it exists."            at 0221 with foreground-color cob-color-yellow.
     display  "Continue Y/N [ ]"                                          at 0401 with background-color cob-color-red
                                                                                       foreground-color cob-color-white.
*>
     accept   menu-reply at 0415.
     if       menu-reply = "N" or = "n"
              move "1" to menu-reply
              exit section
     end-if
*>
     display  "File name to be created [12345678901234567890123456789012]"
                                                                          at 0601 with foreground-color cob-color-yellow.
     accept   Archive-Name at 0626 with update.
     if       Archive-Name = spaces or Cob-Crt-Status = Cob-Scr-Esc
              display "Quiting to menu" at 1001 with erase eol
              exit section.
*>
     display  "Format: T(xt) or (C)omma delimited?  [T]" at 0801 with foreground-color cob-color-yellow.
     accept   ws-Export-Format  at 0839 with update.
     move     function upper-case (ws-Export-Format) to ws-Export-Format.
     if       ws-Export-Format not = "T" and not = "C"    *> space to quit
              exit section.
*>
 ea020-Open-Output.
     open     Output Saved-CoA.
     if       fs-reply not = zero
              display "Problem opening Export File, hit return to quit action" at 2301
              accept  ws-reply at 2360
              exit section
     end-if
*>
*> Open nominal ledger
*>
     move     zero to counter.
     move     1  to  file-function  access-type.
     call     "irsub1"  using  nl-record   file-access.
*>
     move     3 to file-function   *> read next record
     move     ws-Export-Format to ECoA-Data-Type.
     perform  until we-error = 3      *> initially on open, and checked lower down
              call "irsub1"  using nl-record file-access
              if   we-error = 3       *> eof
                   exit perform
              end-if
              if   nl-Sub-Nominal not = zero     *> Not really needed but just in case !!
                   move "S" to nl-Type
              end-if
              if   ws-Export-Format = "T"
                   move  nl-Owning      to ECoA-owning
                   move  nl-Sub-Nominal to ECoA-sub
                   move  nl-Name to  ECoA-nl-name
                   move  nl-ac   to  ECoA-nl-ac
                   move  nl-Type to  ECoA-nl-Type
                   write Export-CoA-Text
                   if  fs-reply not = zero
                       display "Problem writing to Export File, hit return to quit action" at 2301
                       accept  ws-reply at 2360
                       exit perform     *> at least close files and get totals
                   end-if
                   add 1 to counter
              else   *> = "C", comma delimited
                   string  nl-owning      delimited by size
                           ","            delimited by size
                           nl-sub-nominal delimited by size
                           ","            delimited by size
                         quote            delimited by size
                         nl-name          delimited by size
                         quote            delimited by size
                         ","              delimited by size
                         nl-ac            delimited by size
                         ","              delimited by size
                         nl-type          delimited by size
                         " "              delimited by size into Saved-CoA-Data
                   end-string
                   write Saved-CoA-Comma
                   if  fs-reply not = zero
                       display "Problem writing to Export File, hit return to quit action" at 2301
                       accept  ws-reply at 2360
                       exit perform     *> at least close files and get totals
                   end-if
                   add 1 to counter
              end-if
     end-perform
*>
*> Close file
*>
     display  "Total record count written out = "   at 2001.
     display  Counter                               at 2034.
     display  "Note count & hit return to continue" at 2201.
     accept   ws-reply                              at 2237.
*>
     move     2  to  file-function.
     call     "irsub1"  using  nl-record  file-access.
     close    Saved-CoA.
*>
 ea999-exit.
     exit     section.
*>
 fa-Import-CoA section.
*>--------------------
 fa010-Warning-Notice.
*>
*>**********************************************
*> Although allowed for, comma delimited files *
*> Should not be used for input, but just in   *
*> case !!!                                    *
*>**********************************************
*>
     display  "This process will import a CoA (Chart of Accounts) in TEXT format " at 0101 with foreground-color cob-color-yellow erase eos.
     display  "overwriting any existing IRS Chart of Accounts."    at 0201 with foreground-color cob-color-yellow.
     display  "This must only be done for a new set of accounts for a new client." at 0301 with foreground-color cob-color-yellow.
     display  "OTherwise, If you have not made a back up of it you should quit this process."
                                                                          at 0401 with foreground-color cob-color-yellow.
     display  "Warning: This is NON RECOVERABLE, so think about it"       at 0714 with foreground-color cob-color-red.
     display  "Before responding (Y)es ensure you have a back copy of the original file"
                                                                          at 0901 with foreground-color cob-color-yellow.
     display  "Otherwise respond (N)o and then exit the main menu to do so."
                                                                          at 1001 with foreground-color cob-color-yellow.
     display  "Continue Y/N [ ]"                                          at 1201 with background-color cob-color-red
                                                                                       foreground-color cob-color-white.
*>
     accept   menu-reply at 1215.
     if       menu-reply = "N" or = "n"
              move "1" to menu-reply
              exit section
     end-if
*>
     display  "File name to be Imported [12345678901234567890123456789012]" at 1501 with foreground-color cob-color-yellow.
     accept   Archive-Name at 1527 with foreground-color cob-color-yellow update.
     if       Archive-Name = spaces or Cob-Crt-Status = Cob-Scr-Esc
              display "Quiting to menu" at 1501 with erase eol
              exit section.
*>
 fa020-Open-Files.
     open     Input Saved-CoA.
     if       fs-reply not = zero
              display "Problem opening Import File, hit return to quit action" at 2301
              accept  ws-reply at 2360
              exit section
     end-if
*>
*> Open the Nominal Ledger
*>
     move     1  to  file-function         *> Open output
     move     3  to  access-type
     call     "irsub1"  using  nl-record file-access
     if       we-error = 1
              display "Problem opening Accounts for output, hit return to quit action" at 2301
              accept  ws-reply at 2365
              exit section
     end-if
     move     2 to file-function           *> Close file
     call     "irsub1" using nl-record file-access
     move     2 to access-type.              *> open i-o
     move     1 to File-Function.
     call     "irsub1"  using  nl-record file-access.
     if       we-error not = zero
              display "Problem opening Accounts for output, hit return to quit action" at 2301
              accept  ws-reply at 2365
              exit section
     end-if
     move     zero to Counter.
*>
*>  Set all amounts to zero, can't use initialize owing to presence of redefines
*>
     move     zero  to  nl-dr           nl-cr
                        nl-dr-last (1)  nl-dr-last (2)
                        nl-dr-last (3)  nl-dr-last (4)
                        nl-cr-last (1)  nl-cr-last (2)
                        nl-cr-last (3)  nl-cr-last (4).
*>
 fa030-Read-Input.
     read     Saved-CoA record at end
              go to fa040-End-Of-Input.
*>
*>  Output the record if record type = T (Text) and check them all in case user has manually modified them.
*>
     if       ECoA-Data-Type not = "T"
              display "Error: Can only import a Text file (.txt) as exported by this program"
                                                 at 2001 with blink highlight
              display "Hit return for menu" at 2101
              accept  ws-reply at 2122
              exit section
     end-if
     move     ECoA-Owning  to nl-owning.
     move     ECoA-Sub     to nl-sub-nominal.
     if       ECoA-Sub = zero                *> In case user has modified file
              move "O" to ECoA-nl-Type
     else
              move "S" to ECoA-nl-Type
     end-if
     move     ECoA-nl-Type to nl-type.
     move     ECoA-nl-Name to nl-name.
     move     ECoA-nl-AC   to nl-ac.
*>
     move     5  to  file-function. *> writing
     call     "irsub1"  using  nl-record  file-access.
     add      1  to Counter.
     go       to fa030-Read-Input.
*>
 fa040-End-Of-Input.
     display  "Total records created = " at 2001.
     display  Counter                    at 2026.
     display  "Note count & hit return to continue" at 2201.
     accept   ws-reply                   at 2237.
*>
     close    Saved-CoA.
     move     2 to file-function.                   *> close NL file
     call     "irsub1"  using  nl-record  file-access.
*>
 fa999-Exit.
     exit     section.
*>
zz000-clear-NL section.
*>--------------------
*>
zz010-main.
*>--------
     call     "CBL_CHECK_FILE_EXIST" using fn-1 Cbl-File-Details.
     if       Return-Code not = zero  *> file not found so not using a CoA from elsewhere for the 1st time
              move "0" to Menu-Reply
              exit section
     end-if
*>
*>    We now have the CoA but do we have any postings?
*>
     call     "CBL_CHECK_FILE_EXIST" using fn-4 Cbl-File-Details.
     if       Return-Code = zero    *> file found so flag is wrong so skip this process
              move "0" to Menu-Reply
              exit section
     end-if
*>
*>   We now have a CoA with NO posting file so we can clear, lets ask!
*>
     display  " " at 0101 with erase eos.
     display  "This appears to be the first time you are running IRS and there is a"
                                                                          at 0101 with foreground-color cob-color-yellow.
     display  "set of accounts (Nominal Ledger) present"                  at 0221 with foreground-color cob-color-yellow.
     display  "Can I clear down all amounts from these, so that you can start with a clean"
                                                                          at 0401 with foreground-color cob-color-yellow.
     display  "set of accounts"                                           at 0533 with foreground-color cob-color-yellow.
     display  "Warning: This is NON RECOVERABLE, so think about it"       at 0714 with foreground-color cob-color-red.
     display  "Before responding (Y)es ensure you have a back copy of the original file"
                                                                          at 0901 with foreground-color cob-color-yellow.
     display  "Otherwise respond (N)o and then exit the main menu to do so."
                                                                          at 1001 with foreground-color cob-color-yellow.
     display  "Continue Y/N [ ]"                                          at 1201 with background-color cob-color-red
                                                                                       foreground-color cob-color-white.
*>
     accept   menu-reply at 1215.
     if       menu-reply = "N" or = "n"
              move "1" to menu-reply
              exit section
     end-if
*>
     display  "Wait while I clear the Chart of Accounts down " at 1501 with foreground-color cob-color-yellow blink.
*>
     move     1 to file-function.
     move     2 to access-type.                          *> open for i-o
     call     "irsub1"  using  nl-record  file-access.
     if       we-error not = zero                        *> we have an error so close and quit
              move 2 to file-function                    *>  but as we tested for the file, this SHOULD NOT happen
              call     "irsub1"  using  nl-record  file-access
              end-call
              move "1" to menu-reply                     *>  ok, we are done
              exit section
     end-if.
*>
 zz020-Read-A-Record.
*>------------------
*>
     move     3 to file-function.                        *> read next
     call     "irsub1"  using  nl-record  file-access.
     if       we-error = 3                               *> EOF
              move 2 to file-function                    *> close
              call     "irsub1"  using  nl-record  file-access
              end-call
              move "0" to menu-reply                     *>  ok, we are done
              exit section
     end-if
*>                                                           clear all amounts
     move     zero  to  nl-dr           nl-cr
                        nl-dr-last (1)  nl-dr-last (2)
                        nl-dr-last (3)  nl-dr-last (4)
                        nl-cr-last (1)  nl-cr-last (2)
                        nl-cr-last (3)  nl-cr-last (4).
*>
     move     7 to file-function.                        *> rewrite (sub gives no error check)
     call     "irsub1"  using  nl-record  file-access.
     go       to zz020-Read-A-Record.
*>
zz030-Exit.
     exit     section.
