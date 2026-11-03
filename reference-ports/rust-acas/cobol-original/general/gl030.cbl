       >>source free
*>*************************************************************
*>                                                            *
*>              Chart  Of  Accounts  Maintenance              *
*>                                                            *
*>*************************************************************
*>
 identification          division.
*>================================
*>
*>**
      Program-Id.         gl030.
*>**
*>    Author.             V.B.Coen, FBCS
*>                        Converted For Cis December 84,
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Chart of Accounts maintainence.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called modules.     maps04.
*>                        GL030A    (Internal)
*>                        GL030B    (Internal)
*>                        GL030C    (Internal)
*>                        GL030E    (Internal)
*>                        GL030F    (Internal)
*>                        GL030G    (Internal)
*>**
*>    Error messages used.
*>                        GL101
*>                        GL102
*>                        GL103
*>                        GL104
*>                        GL105
*>                        GL106
*>**
*> Changes:
*> 29/01/09 vbc - Migration to Open Cobol.
*> 02/03/09 vbc - Added support for env's LINES and COLUMNS as needed.
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 07/09/10 vbc - .03 Mod lpr.
*> 18/12/11 vbc - .04 Support for dates other than UK & clean up msgs
*>                    Error msgs to GLnnn,
*>                    Support for path+filenames.
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of the Applewood Computers Accounting System
*> and is copyright (c) Vincent B Coen. 1976 - 2012 and later.
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
 copy "selprint.cob".
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdledger.cob".
 copy "fdprint.cob".
*>
 working-storage section.
*>----------------------
*>
 77  prog-name           pic x(15)       value "GL030 (3.00.04)".
 copy "print-spool-command.cob".
 77  gate-sw             pic 9           value 1.
     88  doclear                         value 1.
     88  askclear                        value 2.
*>
 copy "wsmaps03.cob".
 copy "wspc.cob".
 copy "wsfnctn.cob".
 01  work-fields.
     03  ws-reply        pic x.
     03  ws-menu         pic 9.
     03  ws-codes        pic x.
     03  ws-num          pic 9.
     03  line-cnt        binary-char     value zero.
     03  page-nos        binary-char     value zero.
     03  seek            pic x.
     03  a               pic 9.
     03  i               pic 9.
     03  xx              pic 99.
     03  y               pic 999.
     03  z               pic 99.
     03  est             pic 99.
     03  ws-ledger-desc  pic x(7).
     03  ws-place        pic x(13).
*>
     03  ws-env-columns  pic 999       value zero.
     03  ws-env-lines    pic 999       value zero.
     03  ws-lines        binary-char unsigned value zero.
     03  ws-columns      binary-char unsigned value zero.
     03  ws-22-lines     binary-char unsigned value zero.
     03  ws-23-lines     binary-char unsigned value zero.
*>
     03  ws-show-lines   binary-char unsigned value zero.
     03  ws-amend-lines  binary-char unsigned value zero.
     03  ws-setup-lines  binary-char unsigned value zero.
     03  ws-accept-lines binary-char unsigned value zero.

 01  accept-terminator-array pic 9(4)   value zero.
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
*>    03  GL010           pic x(16) value "GL010 Hit Return".
*> Module specific
    03  GL101           pic x(44) value "GL101 A code for Establishment must be input".
    03  GL102           pic x(46) value "GL102 Error! Ledger Code must be not less 1000".
    03  GL103           pic x(30) value "GL103 No Ledger File to update".
    03  GL104           pic x(46) value "GL104 Rewrite ERR 030-01. hit return to finish".
    03  GL105           pic x(55) value "GL105 Deletion Request Denied! Current Balance Not Zero".
    03  GL106           pic x(32) value "GL106 Ledger File Does Not Exist".
*>
 01  ledger-codes.
     03  name-test.
         05  first-char  pic x.
         05  filler      pic x(23).
     03  ledger-test     pic 9(5).
     03  ledger-check.
         05  ledger-first-four.
             07  ledger-first  pic 9.
             07  filler        pic 999.
         05  ledger-sub  pic 99.
     03  filler  redefines  ledger-check.
         05  filler      pic 9.
         05  header-1    pic 999.
         05  filler      pic 99.
     03  filler  redefines  ledger-check.
         05  filler      pic 99.
         05  header-2    pic 99.
         05  filler      pic 99.
     03  filler  redefines  ledger-check.
         05  filler      pic 999.
         05  header-3    pic 9.
         05  filler      pic 99.
     03  pc-code.
         05  pc-code1    pic x.
         05  pc-code2    pic x.
     03  numeric-key.
         05  filler      pic x(4)          value "0000".
         05  n-code      pic 9(6).
         05  n-pc        pic 99.
     03  truth           pic 9.
         88  a-true                        value  1.
         88  a-false                       value  0.
*>
     03  save-n          pic 9(4).
     03  save-s          pic 99.
     03  save-h-1        pic 999.
     03  save-h-2        pic 99.
     03  save-h-3        pic 9.
     03  a-test          pic x.
     03  save-type       pic 9.
     03  save-place      pic x.
     03  save-code       pic xx.
     03  save-lin        pic 99.
     03  save-ledger     pic 9(6).
*>
     03  types.
         05  filler      pic x(7)      value "Header ".
         05  filler      pic x(7)      value "Detail ".
         05  filler      pic x(7)      value "Sales  ".
         05  filler      pic x(7)      value "Purch. ".
         05  filler      pic x(7)      value "Special".
     03  filler  redefines  types.
         05  ledger-desc pic x(7)       occurs  5.
*>
     03  account-placement.
       05  filler        pic x(13)     value "Direct Income".
       05  filler        pic x(13)     value "Direct Costs ".
       05  filler        pic x(13)     value "Sundry Income".
       05  filler        pic x(13)     value "Indirect Cost".
       05  filler        pic x(13)     value "Fixed Assets ".
       05  filler        pic x(13)     value "Current Asset".
       05  filler        pic x(13)     value "Current Liab.".
       05  filler        pic x(13)     value "Capital A/Cs ".
     03  filler  redefines  account-placement.
       05  place         pic x(13)      occurs  8.
*>
 01  print-lines.
     03  line-1.
       05  l1-prog         pic x(14).
       05  filler          pic x(28)     value spaces.
       05  filler          pic x(17)     value "Chart of Accounts".
       05  filler          pic x(31)     value spaces.
       05  l1-date         pic x(10).
*>
     03  line-3.
       05  l3-user         pic x(32).
       05  filler          pic x(60)     value spaces.
       05  filler          pic x(6)      value "Page -".
       05  l3-page         pic z9.
*>
     03  line-4.
       05  filler          pic x(24)     value "----------Name----------".
       05  filler          pic x(36)     value "---Level---   Header       Detail   ".
       05  l4-filler-1     pic x(4)      value spaces.
       05  l4-filler-2     pic x(17)     value spaces.
       05  filler          pic x(19)     value "--Placement--".
*>
     03  line-5.
       05  l5-name         pic x(24).
       05  l5-level-filler pic x(10).
       05  filler  redefines  l5-level-filler.
         07  l5-level      pic 9          occurs 10.
       05  filler          pic x(3)       value spaces.
       05  l5-header       pic zzz9.99    blank when zero.
       05  filler          pic x(7)       value spaces.
       05  l5-detail       pic zzz9.99    blank when zero.
       05  filler          pic x(6)       value spaces.
       05  l5-pc           pic b(5)z9     blank when zero.
       05  filler          pic x(10)      value spaces.
       05  l5-placement    pic x(13).
       05  filler          pic x(6)       value spaces.
*>
     03  line-6.
       05  filler          pic x(36)     value "---Level---   Header       Detail   ".
       05  l6-filler-1     pic x(4)      value spaces.
       05  l6-filler-2     pic x(17)     value spaces.
       05  filler          pic x(43)     value "--Placement--      ----------Name----------".
*>
     03  line-7.
       05  l7-level-filler pic x(10).
       05  filler  redefines  l7-level-filler.
         07  l7-level      pic x          occurs 10.
       05  filler          pic x(3)       value spaces.
       05  l7-header       pic zzz9.99    blank when zero.
       05  filler          pic x(7)       value spaces.
       05  l7-detail       pic zzz9.99    blank when zero.
       05  filler          pic x(6)       value spaces.
       05  l7-pc           pic b(5)z9     blank when zero.
       05  filler          pic x(10)      value spaces.
       05  l7-placement    pic x(13).
       05  filler          pic x(6)       value spaces.
       05  l7-name         pic x(24).
*>
     03  line-11.
       05  l11-prog        pic x(14).
       05  filler          pic x(30)     value spaces.
       05  filler          pic x(14)     value "Profit Centres".
       05  filler          pic x(33)     value spaces.
       05  l11-date        pic x(10).
*>
     03  line-13.
       05  l13-user        pic x(32).
       05  filler          pic x(60)     value spaces.
       05  filler          pic x(6)      value "Page -".
       05  l13-page        pic z9.
*>
     03  line-14.
       05  filler          pic x(36)     value "Number        Name".
*>
     03  line-15.
       05  l15-nos         pic z9.
       05  filler          pic x(10)     value spaces.
       05  l15-name        pic x(32).
*>
 01  dummy-record          pic x(128).
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
 01  to-day                pic x(10).
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 init01 section.
*>*************
*>
*> Force Esc, PgUp, PgDown, PrtSC to be detected
*>
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name to PSN.
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
     end-if
     subtract 1 from ws-lines giving ws-23-lines.
     subtract 2 from ws-lines giving ws-22-lines.
*>
 menu-input.
*>*********
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Chart Of Account Utilities" at 0128 with foreground-color 2.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
     display  usera at 0301 with foreground-color 3.
*>
     display  "Select one of the following by number :- [ ]" at 0801 with foreground-color 2.
*>
     move     10 to  lin.
     move     1  to  a.
*>
     if       profit-centres
              perform displaya
              display "Set-up or Amend Profit Centres" at curs with foreground-color 2
              add  1  to  lin
              add  1  to  a.
*>
     if       branches
              perform displaya
              display "Set-up or Amend Branch Codes" at curs with foreground-color 2
              add  1  to  lin
              add  1  to  a.
*>
     perform  displaya.
     display  "Add New Accounts" at curs with foreground-color 2.
     add      1  to  lin.
     add      1  to  a.
*>
     perform  displaya.
     display  "Amend/Delete Existing Accounts" at curs with foreground-color 2.
     add      1  to  lin.
     add      1  to  a.
*>
     if       index-2
              perform displaya
              display "Print Alphabetic List" at curs with foreground-color 2
              add 1  to  lin
              add 1  to  a.
*>
     perform  displaya.
     display  "Display Chart of Accounts" at curs with foreground-color 2.
     add      1  to  lin.
     add      1  to  a.
*>
     perform  displaya.
     display  "Print Chart of Accounts" at curs  with foreground-color 2.
     add      1  to  lin.
     add      1  to  a.
*>
     if       profit-centres
              perform displaya
              display "Print Report on Profit Centres" at curs with foreground-color 2.
*>
     if       branches
              perform displaya
              display "Print Report on Branch Codes" at curs with foreground-color 2.
*>
     add      3  to  lin
     add      1  to  a.
*>
     move     a to z.
     move     9 to a.
     perform  displaya.
     move     z to a.
     display  "Exit to system menu" at curs with foreground-color 2.
*>
     accept   ws-menu at 0843  with foreground-color 6.
*>
     if       ws-menu = 9
              go to  menu-exit.
*>
     if       p-c = space
              add  1  to  ws-menu.
*>
     if       ws-menu = 1
              perform gl030a
              go to menu-input.
     if       ws-menu = 2
              perform gl030b
              go to menu-input.
     if       ws-menu = 3
              perform gl030c
              go to menu-input.
     if       not  index-2
              add  1  to  ws-menu.
     if       ws-menu = 4
              perform gl030e
              go to menu-input.
     if       ws-menu = 5  or  6
              perform gl030f
              go to menu-input.
*>
     if       ws-menu = 7
              perform gl030g.
*>
     go       to menu-input.
*>
 menu-exit.
*>********
*>
     exit     program.
*>
 displaya.
*>
     move     1 to cole.
     display  "(" at curs with foreground-color 2.
     move     2 to cole.
     display  a at curs with foreground-color 2.
     move     3 to cole.
     display  ")" at curs with foreground-color 2.
     move     6 to cole.
*>
 gl030a section.
*>*************
*>
 main.
*>---
*>
     open     input    ledger-file.
     if       fs-reply not = zero
              open  output  ledger-file
              move low-values to ledger-name
              move  999999 to  ledger-nos
              move  99     to  ledger-pc
              move zeros to ledger-type ledger-place ledger-level
                   ledger-balance ledger-last ledger-q1 ledger-q2
                   ledger-q3 ledger-q4
              write ledger-record.
*>
 main-continue.
*>
     close    ledger-file.
     open     i-o ledger-file.
*>
     move     999999 to  ledger-nos.
     move     zero   to  ledger-pc.
*>
     read     ledger-file  record invalid  key
              move     255  to  we-error.
*>
     if       we-error = 255
              move  spaces  to  p-c-branches
     else
              move  ledger-record  to  p-c-branches.
*>
     move     999999  to  pc-ledg.
     move     zero    to  pc-pc est.
*>
     set      pc  to  1.
     search   p-b-codes
              when p-b-codes (pc) = "E"  set est to pc.
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
*>
     if       profit-centres
              display "Set-Up for Profit Centres" at 0127 with foreground-color 2
      else
              display "Set-Up for Branches" at 0130 with foreground-color 2.
*>
 est-input.
*>********
*>
     display  "Establishment Code :- [  ]" at 0401  with foreground-color 2.
     display  est at 0424 with foreground-color 2.
     accept   est at 0424 with foreground-color 3 update.
*>
     if       est = zero
              display GL101 at 0501 with foreground-color 2
              go to est-input.
*>
     move     "E" to p-b-codes (est).
     display  " " at 0501 with erase eol.
*>
 re-input.
*>*******
*>
     move     7  to  lin.
     move     1  to  cole y.
*>
 loop.
*>***
*>
     move     curs to curs2.
     display  y at curs2 with foreground-color 2.
     add      3 to col2.
     display  ". [" at curs2 with foreground-color 2.
     add      3 to col2.
     move     p-b-codes (y) to ws-codes.
     display  ws-codes at curs2 with foreground-color 3.
     add      1 to col2.
     display  "]" at curs2 with foreground-color 2.
     add      1  to  lin.
     add      1  to  y
     if       lin  <  ws-23-lines  and  y  <  100
              go to  loop.
     if       y  <  100
              move  7  to  lin
              add  11  to  cole
              go to  loop.
*>
     move     7  to  lin  cole.
     move     1  to  y.
*>
     display  "Enter <Y> to select the code. Space to de-select" &
              " the code.<Q> to finish" at line ws-23-lines col 1  with foreground-color 2.
*>
 loop-2.
*>
     if       p-b-codes (y) = "E"
              go to  loop-2-return.
*>
 p-c-b-accept.
*>
     move     p-b-codes (y) to ws-codes.
     accept   ws-codes at curs with foreground-color 3 update.
     move     function upper-case (ws-codes) to ws-codes.
     move     ws-codes to p-b-codes (y).
     if       ws-codes = "Q"
              move  space  to  p-b-codes (y)
              go to  p-c-b-end.
     if       p-b-codes (y) = space or = "Y"
              next sentence
       else
              go to  p-c-b-accept.
*>
 loop-2-return.
*>
     add      1  to  lin.
     add      1  to  y
     if       lin  <  ws-23-lines and  y  <  100
              go to  loop-2.
     if       y  <  100
              move  7  to  lin
              add  11  to cole
              go to  loop-2.
*>
 p-c-b-end.
*>
     display  " " at line ws-23-lines col 01 with erase eol.
     display  "Details OK to file ? (Y/N) :- [Y]" at line ws-23-lines col 01 with foreground-color 2.
     move     "Y"  to  ws-reply.
     accept   ws-reply at line ws-23-lines col 32 with foreground-color 6 update.
*>
     if       ws-reply = "N" or "n"
              go to  re-input.
*>
     move     spaces  to  ledger-record.
     string   p-c-branches  delimited  by size
              into  ledger-record.
*>
     if       we-error = 255
              perform   write-ledger
     else
              perform   rewrite-ledger.
*>
     move     zero  to  we-error.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
*>
     if       profit-centres
              display "Name the Profit Centres" at 0128 with foreground-color 2
     else
              display "Name the Branches" at 0131 with foreground-color 2.
*>
     move     4  to  lin.
     move     1  to  y.
     move     zero to ledger-pc  ledger-type ledger-balance
                      ledger-last ledger-q1 ledger-q2 ledger-q3
                      ledger-q4.
*>
     move     space  to  ledger-place.
*>
 loop-3.
*>*****
*>
     if       p-b-codes (y)  = space
              go to  loop-3-return.
*>
     move     y  to  z.
     move     999999 to  ledger-nos.
     move     z      to  ledger-pc.
*>
     read     ledger-file  record  invalid key
              move  255  to  we-error.
*>
     if       we-error = 255
              move  spaces  to  ledger-name.
*>
 loop-3-back.
*>**********
*>
     move     1 to cole.
     display  "Code - " at curs with foreground-color 2.
     move     8 to cole.
     display  y at curs with foreground-color 2.
     move     11 to cole.
     display  " Name :- [" at curs with foreground-color 2.
     move     45 to cole.
     display  "]" at curs with foreground-color 2.
     move     21 to cole.
     display  ledger-name at curs with foreground-color 2.
     accept   ledger-name at curs with foreground-color 3 update.
*>
     if       ledger-name = "QUIT" OR = "quit"
        or    cob-crt-status = cob-scr-esc
              go to  loop-3-end.
*>
     if       we-error = 255
              and  ledger-name = space
              go to  loop-3-back.
*>
     if       we-error = 255
              perform   write-ledger
     else
              perform   rewrite-ledger.
*>
     move     zero  to  we-error.
     add      1  to  lin.
*>
 loop-3-return.
*>
     add      1  to  y.
     if       y  >  99
              go to  loop-3-end.
*>
     if       lin  <  ws-22-lines
              go to  loop-3.
*>
     move     4  to  lin.
     move     1 to cole.
*>
 loop-3-clear.
*>
     display  " " at curs with erase eol.
     add      1  to  lin.
     if       lin  <  ws-22-lines
              go to  loop-3-clear.
*>
     move     4  to  lin.
     go       to loop-3.
*>
 write-ledger.
*>***********
*>
     write    ledger-record.
*>
 rewrite-ledger.
*>*************
*>
     rewrite  ledger-record.
*>
 loop-3-end.
*>
     close    ledger-file.
*>
 main-exit.   exit section.
*>********    ****
*>
 gl030b section.
*>*************
*>
     open     input ledger-file.
     if       fs-reply not = zero
              perform main in gl030a.
     close    ledger-file.
     open     i-o ledger-file.
*>
     if       not  profit-centres
          and not  branches
              go to  by-pass-pc.
*>
     move     999999 to  ledger-nos.
     move     zero   to  ledger-pc.
*>
     read     ledger-file  record invalid  key
              move     255  to  we-error.
*>
     if       we-error = 255
              move  spaces  to  p-c-branches
     else
              move  ledger-record  to  p-c-branches.
*>
     move     999999  to  pc-ledg.
     move     zero    to  pc-pc est.
*>
     set      pc  to  1.
     search   p-b-codes when  p-b-codes (pc)  =  "E"  set   est  to  pc.
*>
 by-pass-pc.
*>*********
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  to-day at 0171 with foreground-color 2.
*>
 get-input.
     display  "Chart of Accounts Set-Up" at 0129  with foreground-color 2.
     display  "Ledger    Sub" at 0401 with foreground-color 2.
*>
     if       profit-centres
              display "P/C" at 0417 with foreground-color 2.
     if       branches
              display "Branch" at 0415 with foreground-color 2.
     display  "-----------Name-----------  Type  Placement  Level" at 0423 with foreground-color 2.
     move     6  to  lin.
*>
 loop.
*>---
*>
     move     1 to cole.
     display  "[    ]   [  ]" at curs with foreground-color 2.
*>
     if       profit-centres  or  branches
              move 16 to cole
              display "[  ]" at curs with foreground-color 2.
*>
     move     23 to cole.
     display  "[" at curs with foreground-color 2.
     move     48 to cole.
     display  "]  [ ]      [ ]      [ ]" at curs with foreground-color 2.
*>
     move     zero  to  ledger-n ledger-s.
*>
 accept-ledger.
*>************
*>
     move     2 to cole.
     accept   ledger-n at curs with foreground-color 3 update.
     if       ledger-n = zero
              go to  main-end.
*>
     move     curs to curs2.
     add      1 to lin2.
     move     1 to col2.
     if       ledger-n  <  1000
              display GL102 at curs2  with foreground-color 2
              go to  accept-ledger.
*>
     display  " " at curs2 with erase eol.
*>
     move     11 to cole.
     accept   ledger-s at curs with foreground-color 3 update.
*>
     move     ledger-nos  to  ledger-check.
     if       ledger-first = sales-range
        or    purchase-range
              display "Invalid start number!" at curs2 with foreground-color 2
              go to  accept-ledger.
*>
     if       ledger-first-four = "9999"
              display "<9999>  Is reserved!" at curs2 with foreground-color 2
              go to  accept-ledger.
*>
 accept-pc.
*>********
*>
     if       not profit-centres and not branches
              move  zero  to  ledger-pc
              go to  accept-name.
*>
     move     spaces  to  pc-code.
     move     17 to cole.
     accept   pc-code at curs with foreground-color 2 update.
     perform  pc-code-check thru pc-code-check-exit.
*>
     if       a-false
              move 17 to col2
              display "Invalid! Code must be numeric or <n*>." at curs2 with foreground-color 2
              go to  accept-pc.
*>
 accept-name.
*>**********
*>
     move     24 to cole.
     move     spaces to ledger-name.
     accept   ledger-name at curs with foreground-color 3 update.
*>
 accept-type.
*>**********
*>
     if       ledger-sub  not = zero
              go to  accept-end.
*>
     move     52 to cole.
     move     zero to ledger-type.
     display  "0" at curs with foreground-color 2.
     accept   ledger-type at curs with foreground-color 3 update.
*>
     if       ledger-type  not = zero  and  1  and  9
              move 52 to col2
              display "Invalid type!" at curs2 with foreground-color 2
              go to  accept-type.
*>
 accept-placement.
*>***************
*>
     move     61 to cole.
     display  " " at curs.
*>
     if       ledger-type  not = zero
              go to  accept-end.
*>
     move     space to ws-reply.
*>     accept   ledger-place at curs with foreground-color 3 update.
     accept   ws-reply at curs with foreground-color 3 update.
     move     function upper-case (ws-reply) to ledger-place
     if       ledger-place  <  "A"  or  >  "Z"
              move 61 to col2
              display "Invalid Placement!." at curs2 with foreground-color 2
              go to  accept-placement.
*>
     if       revenue-only  and  ledger-place >  "N"
       and    pc-code  not = "00"
              move 61 to col2
              display "Profit centres/branches only valid for Revenue Accounts!"
                                            at curs2 with foreground-color 2
              go to  accept-ledger.
*>
 accept-header.
*>************
*>
     move     zero  to  ledger-level.
*>
     move     70 to cole col2.
     display  " " at curs.
     accept   ledger-level at curs with foreground-color 3 update.
*>
     if       ledger-level  <  1  or  >  4
              display "Invalid!" at curs2 with foreground-color 2
              go to  accept-header.
*>
 accept-end.
*>*********
*>
     move     zero  to  ledger-balance  ledger-last
                        ledger-q1       ledger-q2
                        ledger-q3       ledger-q4.
*>
     if       ledger-s  not = zero
              move  ledger-s  to  save-s
              perform  detail-check
       else
              perform  header-check.
*>
     move     52 to cole.
     display  ledger-type at curs with foreground-color 2.
     move     70 to cole.
     display  ledger-level at curs with foreground-color 2.
*>
     if       a-true
              go to  accept-ledger
       else
              go to  loop-end.
*>
 detail-check.
*>***********
*>
     move     zero  to  ledger-sub.
     move     "D"  to  a-test.
*>
     perform  ledger-read.
*>
     move     space to  a-test.
     move     save-s  to  ledger-sub  ledger-s.
*>
     if       a-false
              move 1 to col2
              display "INVALID! Header Missing" at curs2 with foreground-color 2
              move  1  to  truth
       else
              perform  ledger-read.
*>
     if       ledger-type  not = 9
              move  1  to  ledger-type.
*>
     move     zero  to  ledger-level.
*>
 header-check.
*>***********
*>
     if       header-1 = 0
              perform   ledger-read
              move      1  to  ledger-level.
*>
     if       header-1  not = 0
       and    header-2 = 0
              move      2  to  ledger-level
              move      header-1  to  save-h-1
              move      zero      to  header-1
              perform   ledger-read
              move      save-h-1  to  header-1
              if        a-true
                        perform  ledger-read
                 else
                        move 1 to col2
                        display "INVALID! Header Missing" at curs2 with foreground-color 2
                        move  1  to  truth.
*>
     if       header-2  not = 0
       and    header-3 = 0
              move      3  to  ledger-level
              move      header-2  to  save-h-2
              move      zero      to  header-2
              perform   ledger-read
              move      save-h-2  to  header-2
              if        a-true
                        perform  ledger-read
                   else
                        move 1 to col2
                        display "INVALID! Header Missing" at curs2 with foreground-color 2
                        move  1  to  truth.
*>
     if       header-3  not = 0
              move      4  to  ledger-level
              move      header-3  to  save-h-3
              move      zero      to  header-3
              perform   ledger-read
              move      save-h-3  to  header-3
              if        a-true
                        perform  ledger-read
               else
                        move 1 to col2
                        display "INVALID! Header Missing" at curs2 with foreground-color 2
                        move  1  to  truth.
*>
 loop-end.
*>*******
*>
     if       pc-code2 = "*"
              go to  multi-add.
*>
     move     pc-code  to  y.
     perform  ledger-write.
     go       to addition-end.
*>
 multi-add.
*>
     move     zero  to  ledger-pc  y.
*>
     if       pc-code1 = "*"
              move  1  to  y
              perform  loop-add  99  times
              go to  addition-end.
*>
     move     pc-code1  to  y.
     multiply y  by  10  giving  y.
*>
     if       y  >  0
              perform  loop-add  10  times
       else
              add  1  to  y
              perform  loop-add  9   times.
*>
     go       to addition-end.
*>
 loop-add.
*>*******
*>
     if       p-b-codes (y) = "E"  or  "Y"
              perform  ledger-write.
*>
     add      1  to  y.
*>
 addition-end.
*>-----------
*>
     move     zero  to  y.
     perform  ledger-write.
*>
     add      1 to  lin.
     move     1 to cole.
     display  " " at curs with erase eol.
     display  " " at line ws-23-lines col 01 with erase eol.
*>
     if       lin  <  ws-22-lines
              go to  loop.
*>
     move     6  to  lin.
     move     1 to cole.
*>
 screen-clear.
*>
     display  " " at curs with erase eol.
     add      1  to  lin.
*>
     if       lin  <  ws-22-lines
              go to  screen-clear
      else
              move  6  to  lin
              go to  loop.
*>
 main-end.
*>-------
*>
     close    ledger-file.
*>
 main-exit.   exit section.
*>********    ****
*>
 ledger-read.
*>**********
*>
*> Set status false initialy. If record exists set to true.
*>
     move     zero  to  truth.
     move     ledger-check  to  ledger-nos.
     move     ledger-nos  to  n-code.
*>
     if       pc-code2 = "*"
              move     "00"  to  n-pc
              move     "00"  to  ledger-pc
     else
              move     pc-code     to  n-pc  ledger-pc.

     move     ledger-record  to  dummy-record.
     move     zero  to  we-error.
*>
     read     ledger-file  record  invalid
              move  255  to  we-error.
     if       we-error  not = 255
              move  1  to  truth.
*>
     if       a-test = "D"
              move  ledger-place to  save-place
              if    ledger-type  numeric
                    move  ledger-type  to  save-type
              else
                    move  zero  to  save-type.
*>
     move     dummy-record  to  ledger-record.
*>
     if       a-test = "D"
              move  save-type  to  ledger-type
              move  save-place to  ledger-place.
*>
 ledger-write.
*>***********
*>
     move     ledger-nos  to  n-code.
     move     y to  n-pc  ledger-pc.
*>
     write    ledger-record.
*>
 pc-code-check.
*>************
*>
     move     1  to  truth.
*>
     if       pc-code = spaces
              move  "00"  to  pc-code.
     if       pc-code = "**"
              go to  pc-code-check-exit.
*>
     if       pc-code  not <  "00"  and  not >  "99"
              go to  pc-code-check-exit.
*>
     if       pc-code2  not = "*"
              move   zero  to  truth
              go to  pc-code-check-exit.
*>
     if       pc-code1  not <  "0"  and  not >  "9"
              go to  pc-code-main-check
     else
              move   zero  to  truth
              go to  pc-code-check-exit.
*>
 pc-code-main-check.
*>*****************
*>
     if       pc-code2  not = "*"
              move   pc-code  to  z
              if     p-b-codes (z) = "E"  or  "Y"
                     go to  pc-code-check-exit
                else
                     move   zero  to  truth
                     go to  pc-code-check-exit.
*>
     move     pc-code1  to  z.
     multiply z  by  10  giving  z.
     move     zero  to  truth.
*>
     if       z  >  0
              perform aloop  10  times
       else
              add  1  to  z
              perform aloop  9   times.
*>
     go       to pc-code-check-exit.
*>
 aloop.
*>****
*>
     if       p-b-codes (z) = "E"  or  "Y"
              move  1  to  truth.
*>
     add      1  to  z.
*>
 pc-code-check-exit.
              exit.
*>
 gl030c section.
*>*************
*>
     open     input ledger-file.
     if       fs-reply not = zero
              display space
              display GL103 at 0901 with foreground-color 2
              go to main-exit.
     close    ledger-file.
     open     i-o ledger-file.
*>
     if       not  profit-centres
       and    not  branches
              go to  by-pass-pc.
*>
     move     999999  to  ledger-nos.
     move     zero    to  ledger-pc.
*>
     read     ledger-file  invalid key
              move  255  to  we-error.
*>
     if       we-error = 255
              move  spaces  to  p-c-branches
       else
              move  ledger-record  to  p-c-branches.
*>
 by-pass-pc.
*>*********
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
*>
 get-input.
*>
     display  "Chart Of Accounts Update" at 0129 with foreground-color 2.
     display  "Ledger    Sub" at 0401 with foreground-color 2.
     if       profit-centres
              display "P/C" at 0417 with foreground-color 2.
     if       branches
              display "Branch" at 0415 with foreground-color 2.
     display  "-----------Name-----------  Type  Placement  Level" at 0423 with foreground-color 2.
     move     6  to  lin.
*>
 loop.
*>---
*>
     move     1 to cole.
     display  "[    ]" at curs with foreground-color 2.
     move     11 to cole.
     display  "[  ]" at curs with foreground-color 2.
*>
     if       profit-centres  or  branches
              move 16 to cole
              display "[  ]" at curs with foreground-color 2.
*>
     move     23 to cole.
     display  "[" at curs with foreground-color 2.
     move     48 to cole.
     display  "]  [ ]      [ ]      [ ]" at curs with foreground-color 2.
*>
 accept-ledger.
*>************
*>
     move     zeros to ledger-nos.
     move     2 to cole.
     accept   ledger-n at curs with foreground-color 3 update.
*>
     if       ledger-n = zero
              go to  main-end.
*>
     move     12 to cole.
     accept   ledger-s at curs with foreground-color 3 update.
*>
 accept-pc.
*>********
*>
     move     lin to lin2.
     if       profit-centres  or  branches
              next  sentence
       else
              move  zero  to  pc-code
              go to  a-test-key.
*>
     move     17 to cole.
     accept   pc-code at curs with foreground-color 3 update.
*>
     perform  pc-code-check thru pc-code-check-exit.
*>
     add      1 to lin2.
     move     17 to col2.
     if       a-false
              display "Invalid! Code must be numeric or <n*>" at curs2 with foreground-color 2
              go to  accept-pc.
*>
 a-test-key.
*>*********
*>
     move     1 to col2.
     display  " " at curs2 with erase eol.
*>
     move     zero        to  we-error.
*>
     if       pc-code2 = "*"
              move  "A"  to  a-test
              move  pc-code  to  save-code
              move  "00"  to  pc-code.
     move     pc-code     to  ledger-pc.
*>
     read     ledger-file  record  invalid key
              move  255  to  we-error.
*>
     if       we-error = 255
              move 1 to col2
              display ledger-nos at curs2 with foreground-color 2
              move 7 to col2
              display "/" at curs2 with foreground-color 2
              move 8 to col2
              display ledger-pc at curs2 with foreground-color 2
              move 11 to col2
              display "Does not exist!" at curs2 with foreground-color 2
              go to  accept-ledger.
     if       a-test = "A"
              move  save-code  to  pc-code
              move  " "  to  a-test.
*>
     move     24 to col2 cole.
     display  "Enter <+> only to Delete" at curs2 with foreground-color 2.
     display  ledger-name at curs with foreground-color 2.
     accept   ledger-name at curs with foreground-color 3 update.
*>
     move     ledger-name  to  name-test.
     if       first-char = "+"
              perform  deletion
              go to    addition-end-2.
*>
 accept-type.

     move     1 to col2.
     display  " " at curs2 with erase eol.
     move     52 to cole col2.
     display  ledger-type at curs with foreground-color 2.
     accept   ledger-type at curs with foreground-color 3 update.
*>
     if       ledger-type = zero  or  1  or  9
              next  sentence
      else
              display "Invalid type!" at curs2 with foreground-color 2
              go to  accept-type.
*>
 accept-placement.
*>
     if       ledger-type not = zero
              go to accept-end.
*>
     move     61 to cole col2.
*>     display  ledger-place at curs with foreground-color 2.
     accept   ledger-place at curs with foreground-color 3 update.
     move     function upper-case (ledger-place) to ledger-place.
     if       ledger-place  <  "A"  or  >  "Z"
              display "Invalid Placement!" at curs2 with foreground-color 2
              go to  accept-placement.
*>
*> this msg may wrap and be in wrong place which is a bug
*>
     if       revenue-only  and  ledger-place >  "N"
              and  ledger-pc  not = zero
              display "Profit centres/branches only valid for Revenue Accounts!"
                                                        at curs2 with foreground-color 2
              go to  accept-ledger.
*>
 accept-header.
*>
     move     70 to cole col2.
     display  ledger-level at curs with foreground-color 2.
     accept   ledger-level at curs with foreground-color 3 update.
     if       ledger-level  <  1  or  >  4
              display "Invalid!" at curs2 with foreground-color 2
              go to  accept-header.
*>
 accept-end.
*>
 loop-end.
*>*******
*>
     if       pc-code2 = "*"
              go to  multi-add.
*>
     move     pc-code  to  y.
     perform  ledger-rewrite.
     go       to addition-end.
*>
 multi-add.
*>
     move     zero  to  ledger-pc  y.
*>
     if       pc-code1 = "*"
              move  1  to  y
              perform  loop-add  99  times
              go to  addition-end.
*>
     move     pc-code1  to  y.
     multiply y  by  10  giving  y.
*>
     if       y  >  0
              perform  loop-add  10  times
       else
              add  1  to  y
              perform  loop-add  9   times.
*>
     go       to addition-end.
*>
 loop-add.
*>*******
*>
     if       p-b-codes (y) = "E"  or  "Y"
              perform  ledger-rewrite.
*>
     add      1  to  y.
*>
 addition-end.
*>-----------
*>
     move     zero  to  y.
     perform  ledger-rewrite.
*>
 addition-end-2.
*>
     add      1  to  lin.
     move     1 to cole.
     display  " " at curs with erase eol.
*>
     if       lin  <  ws-22-lines
              go to  loop.
*>
     move     6  to  lin.
*>
 screen-clear.
*>
     display  " " at curs with erase eol.
     add      1  to  lin.
*>
     if       lin  <  ws-22-lines
              go to screen-clear
      else
              go to  loop.
*>
 main-end.
*>-------
*>
     close    ledger-file.
*>
 main-exit.   exit section.
*>********    ****
*>
 deletion                section.
*>------------------------------
*>
 loop-end.
*>*******
*>
     if       pc-code2 = "*"
              go to  multi-add.
*>
     move     pc-code  to  y.
     perform  ledger-delete.
     go       to addition-end.
*>
 multi-add.
*>
     move     zero  to  ledger-pc  y.
*>
     if       pc-code1 = "*"
              move  1  to  y
              perform  loop-add  99  times
              go to  addition-end.
*>
     move     pc-code1  to  y.
     multiply y  by  10  giving  y.
*>
     if       y  >  0
              perform  loop-add  10  times
       else
              add  1  to  y
              perform  loop-add  9   times.
     go       to addition-end.
*>
 loop-add.
*>*******
*>
     if       p-b-codes (y) = "E"  or  "Y"
              perform  ledger-delete.
     add      1  to  y.
*>
 addition-end.
*>-----------
*>
     move     zero  to  y.
     perform  ledger-delete.
     move     1  to  truth.
*>
 main-exit.   exit section.
*>********    ****
*>
 ledger-rewrite          section.
*>------------------------------
*>
     move     ledger-nos  to  n-code.
     move     y           to  n-pc  ledger-pc.
*>
     rewrite  ledger-record.
     if       fs-reply not = zero
              display GL104   at line ws-23-lines col 01 with foreground-color 4
              accept ws-reply at line ws-23-lines col 48 with foreground-color 2
              write ledger-record.
*>
 main-exit.   exit section.
*>********    ****
*>
*>
 ledger-delete           section.
*>------------------------------
*>
     move     ledger-nos  to  n-code.
     move     y           to  n-pc  ledger-pc.
*>
     if       ledger-balance  not = zero
              move  zero  to  truth
              move ws-lines to col2
              display "Deletion Request Denied! Current Balance Not Zero" at curs2 with foreground-color 2
              go to  main-exit.
*>
     delete   ledger-file  record.
*>
 main-exit.   exit section.
*>********    ****
*>
 gl030e section.
*>*************
*>
     move     prog-name to l1-prog.
     open     input  ledger-file.
     if       fs-reply not = zero
              display GL105 at line ws-lines col 01 with foreground-color 2
              go to main-exit.
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
     display  "Chart Of Accounts Alphabetic Print" at 0123 with foreground-color 2.
*>
     move     zero  to  truth.
     open     output  print-file.
*>
     if       profit-centres
              move  "Profit Centre    "  to  l4-filler-2
     else
      if      branches
              move  "   Branch       " to  l4-filler-2
      else
              move  spaces  to  l4-filler-2.
*>
     move     ws-date  to  l1-date.
     move     zero    to  page-nos.
     move     usera   to  l3-user.
     perform  page-heading.
     move     low-values to ledger-name.
     read     ledger-file key ledger-name invalid key
              move 255 to we-error.
*>
 p-loop.
*>*****
*>
     read     ledger-file next record at end
              go to  end-report.
*>
     if       ledger-n = 9999
              go to  p-loop.
*>
     move     spaces  to  l5-level-filler l5-placement l5-name.
     move     zero    to  l5-header l5-detail l5-pc z.
*>
     if       ledger-level = zero
              go to  detail-jump.
*>
     move     ledger-level  to  z.
     multiply z  by  2  giving  i.
     add      1  to  i.
     move     ledger-level  to  l5-level (i).
     move     ledger-nos    to  n-code.
     divide   n-code  by  100   giving  l5-header.
*>
 detail-jump.
*>
     if       ledger-level = zero
              move    ledger-nos  to  n-code
              divide  n-code      by  100  giving  l5-detail.
*>
     perform  compute-placement.
     move     place (z)    to  l5-placement.
     move     ledger-pc     to  l5-pc.
     move     ledger-name  to  l5-name.
*>
     write    print-record  from  line-5 after 1.
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform  page-heading.
*>
     go       to p-loop.
*>
 display-file-error.  *> NOT USED
*>-----------------
*>    if           s1 not = 0
*>                 move s1 to s1-displ
*>                 move low-values to s1
*>                 move stat-bin to s2-displ
*>                 display disply-stat at 2460.
*>
 page-heading.
*>***********
*>
     add      1  to  page-nos.
     move     page-nos  to  l3-page.
*>
     if       page-nos not = 1
              write print-record  from  line-1 after page
     else
              write print-record  from  line-1 after 1.
     write    print-record  from  line-3 after 1.
     write    print-record  from  line-4 after 2  lines.
*>
     move     spaces  to  print-record.
     write    print-record after 1.
     move     5 to line-cnt.
*>
 end-report.
*>*********
*>
     close    print-file.
     call     "SYSTEM" using Print-Report.
*>
 main-end.
*>*******
*>
     close    ledger-file.
*>
 main-exit.   exit section.
*>********    ****
*>
 compute-placement section.
*>------------------------
*>
     if       ledger-place  less  "E"
              move  1  to  z
     else
      if      ledger-place  less  "I"
              move  2  to  z
      else
       if     ledger-place  less  "K"
              move  3  to  z
       else
        if    ledger-place  less  "O"
              move  4  to  z
        else
         if   ledger-place  less  "R"
              move  5  to  z
         else
          if  ledger-place  less  "U"
              move  6  to  z
          else
           if ledger-place  less  "W"
              move  7  to  z
           else
              move  8  to  z.
*>
 main-exit.   exit section.
*>********    ****
*>
 gl030f section.
*>*************
*>
     move     prog-name to l1-prog.
     open     input  ledger-file.
     if       fs-reply not = zero
              display " " at 0101 with erase eos
              display GL106 at 0901 with foreground-color 2
              go to main-exit.
*>
 d-head-1.
*>*******
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
     display  "Chart Of Accounts Display" at 0127 with foreground-color 2.
*>
 d-head-end.
*>
     move     zero  to  truth.
*>
 main-target.
*>**********
*>
     if       ws-menu = 6
              display "Print Out" at 0145 with foreground-color 2
              go to  print-out.
*>
     move     3  to  lin.
     perform  gl030f-screen-clear.
*>
     move     zero  to  ledger-n  ledger-s.
*>
     display  "Enter the start Account - [      ]" at 0401 with foreground-color 2.
     if       profit-centres  or  branches
              display "/  ]" at 0434 with foreground-color 2.
*>
     display  " " at line ws-23-lines col 01 with erase eol.
     display  "Press <Esc> key to exit" at line ws-23-lines col 01 with foreground-color 2.
*>
     display  ledger-nos at 0428 with foreground-color 2.
     accept   ledger-nos at 0428 with foreground-color 3 update.
*>
     if       cob-crt-status = cob-scr-esc
              move  "Q"  to  seek
              move  0  to  truth
              go to  main-end.
*>
     move     zero  to  ledger-pc.
*>
     if       profit-centres  or  branches
              display ledger-pc at 0435 with foreground-color 2
              accept ledger-pc at 0435  with foreground-color 3 update.
*>
     move     ledger-nos  to  save-ledger.
     move     ledger-nos  to  n-code.
     move     ledger-pc   to  n-pc.
     move     4   to  lin.
     move     1   to  truth.
*>
*>     alter    gate  to  do-clear
     move     1 to gate-sw.
*>
     perform  display-chart.
*>
     start    ledger-file key not < ledger-key invalid key
              move  255  to  we-error.
*>
     if       we-error = zero
              read  ledger-file   next record  at end
                     move 255 to we-error.
*>
     if       we-error = 255
              display "No match found !" at 0841 with foreground-color 2
              go to  main-target.
*>
     move     zero  to  truth.
     add      2  to  lin.
*>
 main-loop.
*>********
*>
     display  "<N> Next; <I> Next ignore same code; <C> Cont; <Q> Quit :- [I]"
                                            at line ws-23-lines col 01  with foreground-color 2.
     move     "I"  to  seek.
*>
     perform  display-chart.
     accept   seek at line ws-23-lines col 61 with foreground-color 3 update.
     move     function upper-case (seek) to seek.
*>
     if       seek = "Q"
              move  0  to  truth
              go to  main-end.
*>
 subsid-loop.
*>**********
*>
*>     alter    gate  to  ask-clear.
     move     2 to gate-sw.
*>
     read     ledger-file  next record  at end
              move  255 to we-error.
*>
     if       we-error = 255
           or ledger-n = 9999
              go to  main-target.
*>
     if       seek = "I"
        and   ledger-nos = save-ledger
              go to  subsid-loop.
*>
     move     ledger-nos  to  save-ledger.
*>
     add      1  to  lin.
     if       lin = ws-22-lines
              perform ask-clear
       if     cob-crt-status = cob-scr-esc
*>              alter gate to do-clear
              move 1 to gate-sw
              go to main-target
        else
              perform d-head-1
              move 4 to lin
              perform second-head
              move  6   to  lin.
*>
     if       seek  not = "C" and "I"
              go to  main-loop
        else
              perform  display-chart
              go to  subsid-loop.
*>
 print-out.
*>********
*>
     open     output  print-file.
*>
     if       profit-centres
              move  "Profit Centre    "  to  l6-filler-2
     else
      if      branches
              move  "   Branch       " to  l6-filler-2
      else
              move  spaces  to  l6-filler-2.
*>
     move     to-day  to  l1-date.
     move     zero    to  page-nos.
     move     usera   to  l3-user.
     perform  page-heading.
*>
 p-loop.
*>*****
*>
     read     ledger-file  next record  at end
              move  255 to we-error.
*>
     if       we-error = 255
           or ledger-n = 9999
              go to  end-report.
*>
     move     spaces  to  l7-level-filler l7-placement l7-name.
     move     zero    to  l7-header l7-detail l7-pc z.
*>
     if       ledger-level = zero
              go to  detail-jump.
*>
     move     ledger-level  to  z.
     multiply z  by  2  giving  i.
     add      1  to  i.
     move     ledger-level  to  l7-level (i).
     move     ledger-nos    to  n-code.
     divide   n-code  by  100   giving  l7-header.
     perform  compute-placement.
     move     place (z)    to  l7-placement.
*>
 detail-jump.
*>
     if       ledger-level = zero
              move    ledger-nos  to  n-code
              divide  n-code      by  100  giving  l7-detail.
*>
     move     ledger-pc     to  l7-pc.
     move     ledger-name  to  l7-name.
*>
     write    print-record  from  line-7 after 1.
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform  page-heading.
*>
     go       to p-loop.
*>
 page-heading.
*>***********
*>
     add      1  to  page-nos.
     move     page-nos  to  l3-page.
*>
     if       page-nos not = 1
              write print-record  from  line-1 after page
     else
              write print-record  from  line-1 after 1.
     write    print-record  from  line-3 after 1.
     write    print-record  from  line-6 after 2.
*>
     move     spaces  to  print-record.
     write    print-record after 1.
     move     5 to line-cnt.
*>
 end-report.
*>*********
*>
     close    print-file.
     call     "SYSTEM" using Print-Report.
*>
 main-end.
*>*******
*>
     close    ledger-file.
*>
 main-exit.   exit section.
*>********    ****
*>
 display-chart section.
*>--------------------
*>
*>  If true set-up headings else display a line of data
*>
     if       a-false
              go to  detail-display.
*>
 second-head.
*>
     move     1 to cole.
     display  "Ledger    " at curs with foreground-color 2.
     move     11 to cole.
     display  "Sub    " at curs with foreground-color 2.
*>
     move     18 to cole.
     if       profit-centres
              display "  P/C   " at curs with foreground-color 2
     else
      if      branches
              display "Branch  " at curs with foreground-color 2
      else
              display "        " at curs.
*>
     move     26 to cole.
     display  "<---------Name--------->    Type    Level --Placement--" at curs with foreground-color 2.
*>
 main-pass.
*>
     go       to main-exit.
*>
 detail-display.
*>*************
*>
     move     2 to cole.
     display  ledger-n at curs with foreground-color 2.
     move     11 to cole.
     display  ledger-s at curs with foreground-color 2.
     move     20 to cole.
     if       profit-centres or branches
              display  ledger-pc at curs with foreground-color 2.
     move     25 to cole.
     display  ledger-name at curs with foreground-color 2.
*>
     if       ledger-type = 9
              subtract  4  from  ledger-type
      else
              add 1 to ledger-type.
*>
     move     53 to cole.
     if       ledger-type < 1 or > 5
              move "ERROR?" to ws-ledger-desc
       else
              move ledger-desc (ledger-type) to ws-ledger-desc.
     display  ws-ledger-desc at curs with foreground-color 2.
*>
     if       ledger-level not =  zero
              move 64 to cole
              display ledger-level at curs with foreground-color 2
              perform  compute-placement
              move 68 to cole
              move place (z) to ws-place
              display ws-place at curs with foreground-color 2.
*>
 main-exit.   exit section.
*>********    ****
*>
 gl030f-screen-clear         section.
*>----------------------------------
*>
 gate.
     if       doclear
              go to do-clear.
     if       askclear
              go to ask-clear.
*>      go to  do-clear.
*>
 ask-clear.
*>
     display  "Press Return for next screen " at line ws-23-lines col 01 with foreground-color 2 erase eol.
     accept   ws-reply at line ws-23-lines col 41 with foreground-color 2.
*>
 do-clear.
*>
*>     alter    gate  to  ask-clear.
     move     2 to gate-sw.
     move     lin  to  save-lin.
*>
 loop.
*>***
*>
     move     1 to cole.
     display  " " at curs with erase eol.
     add      1  to  lin.
     if       lin  <  ws-23-lines
              go to  loop.
*>
     move     save-lin  to  lin.
*>
 main-exit.
     exit     section.
*>
 gl030g section.
*>*************
*>
     open     input  ledger-file.
     if       fs-reply not = zero
              display " " at 0101 with erase eos
              display GL106 at 0901 with foreground-color 2
              go to main-exit.
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
     display  "Profit Centres Report" at 0127 with foreground-color 2.
*>
     move     zero  to  truth.
     move     999999 to  ledger-nos.
     move     zero   to  ledger-pc.
*>
     read     ledger-file  record invalid  key
              move     255  to  we-error.
*>
     if       we-error = 255
              move  spaces  to  p-c-branches
       else
              move  ledger-record  to  p-c-branches.
*>
     move     999999  to  pc-ledg.
     move     zero    to  pc-pc est.
*>
     set      pc  to  1.
     search   p-b-codes when p-b-codes (pc) = "E"
              set   est  to  pc.
*>
 print-out.
*>********
*>
     open     output  print-file.
*>
     move     to-day  to  l11-date.
     move     zero    to  page-nos.
     move     usera   to  l13-user.
     perform  page-heading.
*>
 p-loop.
*>*****
*>
     move     1  to  y.
*>
 loop-3.
*>*****
*>
     if       p-b-codes (y)  = space
              go to  loop-3-return.
*>
     move     zero   to  z.
     add      y      to  z.
     move     999999 to  ledger-nos.
     move     z      to  ledger-pc.
*>
     read     ledger-file  record  invalid key
              move  255  to  we-error.
*>
     if       we-error = 255
              move  spaces  to  ledger-name.
*>
 loop-3-back.
*>**********
*>
     move     ledger-pc  to  l15-nos.
     move     ledger-name  to  l15-name.
     write    print-record  from  line-15 after 1.
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform  page-heading.
     add      1  to  lin.
*>
 loop-3-return.
*>
     add      1  to  y.
     if       y  <  99
              go to  loop-3.
*>
     go       to end-report.
*>
 page-heading.
*>***********
*>
     add      1  to  page-nos.
     move     page-nos  to  l13-page.
*>
     if       page-nos not = 1
              write print-record from line-1 after page
     else
              write print-record from line-1 after 1.
     write    print-record  from  line-13 after 1.
     write    print-record  from  line-14 after 2.
     move     spaces  to  print-record.
     write    print-record after 1.
     move     5 to line-cnt.
*>
 end-report.
*>*********
*>
     close    print-file.
     call     "SYSTEM" using Print-Report.
*>
 main-end.
*>*******
*>
     close    ledger-file.
*>
 main-exit.
     exit section.
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
