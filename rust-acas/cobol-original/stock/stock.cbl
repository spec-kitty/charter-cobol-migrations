       >>source free
*>********************************************
*>                                           *
*>       Stock Control System  Menu          *
*>                                           *
*>********************************************
*>
 identification          division.
*>================================
*>
*>**
     program-id.         stock.
*>**
*>   author.             V.B.Coen FBCS.
*>                       For Applewood Computers.
*>**
*>   Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                       Distributed under the GNU General Public License
*>                       v2.0. Only. See the file COPYING for details.
*>**
*>   Remarks.            Stock System Menu.
*>**
*>   Version.            See prog-name in Ws.
*>**
*>   Called Modules.     maps01 - Encrypt/Decrypt (OpenSource version ONLY).
*>                       maps04 - Date testing and conversion.
*>                       maps99 - Error Message (ACAS wide only) production.
*>**
*>   Error messages used.
*>                       ST001.
*>                       ST004.
*>                       ST006
*>                       ST007
*>                       ST008
*>**
*>   Changes.
*> 22/04/09 vbc - Rewritten in Cobol from scratch but skipped some of the weird stuff.
*> 01/06/09 vbc - Updated Stock info to Purchase, Sales, General & sys002.
*> 12/06/09 vbc - .05 Cosmetic Menu screen clean up.
*> 18/06/09 vbc - .06 Add st030 to menu
*> 06/08/10 vbc - .07 Force set env variables for Esc and other keys + other cosmetics.
*> 15/09/10 vbc - .09 mod to always use current year for (C) display.
*> 02/10/11 vbc - .10 Changed to Cbl-File-Details year to xx for OC v2.
*> 27/11/11 vbc - .11 Update Env processing and pass on to all ACAS called modules
*>                    Allow being called with one/two params for working dirs that overides
*>                    ACAS_LEDGERS and ACAS_IRS in case using temp practice/test directories.
*>                    Make backup script run via ~/bin directory so needs another env var (ACAS_BIN).
*> 11/12/11 vbc -     Changed version from 1.00.xx to 3.01.xx, in keeping with the rest of ACAS
*>                .12 Changed usage of Date-Form to the global field Date-Form making former redundent.
*> 20/12/11 vbc - .13 Missing 'into' when creating file paths and OC didnt comment
*> 17/04/13 vbc - .14 Force Invoicer = 2 when creating system.dat
*> 19/04/13 vbc - .15 Fix Bug in get-args that bypassed code - Dummy
*> 26/04/13 vbc - .16 Included version data for system record same as in sys002.
*> 12/05/13 vbc - .17 Changed wsnames to in common as pl010 called in st010.
*> 16/05/13 vbc - .18 Changed wsnames to in copybook see above.
*> 11/06/13 vbc - .19 Hidden ST060 import stock file data from menu
*>                    IF it is to be used must be unremarked out and compiled etc
*>                    and MODIFIED to match imported file specifications.
*>**
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
 77  prog-name           pic x(17)    value "Stock (3.01.19)".
 77  z                   binary-char  value zero.
*> 77  Exception-Msg       pic x(25)    value spaces.
 77  Batch-Text          pic x(28)    value spaces.
 77  Script-Name         pic x(20)    value spaces.
 77  Run-Backup          pic x(512)   value spaces.  *> size changed
 77  Full-Backup-Script  pic x(512)   value spaces.
 77  OS-Delimiter        pic x        value "/".
 77  ACAS_BIN            pic x(512)   value spaces.  *> added
 77  ACAS_IRS            pic x(500)   value spaces.
 77  ACAS_LEDGERS        pic x(500)   value spaces.
 77  Arg-Number          pic 9        value zero.
*>========================================================
*>  in case file layout upgrade is needed.
*>   Using a file update program.
*>
 77  ws-Sys-Record-Ver-Prime          binary-char value 1.
 77  ws-Sys-Record-Ver-Secondary      binary-char value 1.
*>^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*>
*> holds program parameter values from command line
 01  Arg-Vals                         value spaces.
     03  Arg-Value       pic x(525)  occurs 2.
 01  Arg-Test            pic x(525)   value spaces.
*>
 01  Backup-Sw           pic 9               value zero.
     88  Backup-Script-Found                 value 1.
 01  Linux-Backup-Script-Name   pic x(20)    value "acasbkup.sh         ".
 01  Windows-Backup-Script-Name pic x(20)    value "acasbkup.bat        ".
 01  OS2-Backup-Script-Name     pic x(20)    value "acasbkup.cmd        ".
 01  Exit-To-System             pic x(18)    value "to Linux".
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
 01  WS-When-Compiled.
     03  WS-WC-YY          pic 9(4).
     03  WS-WC-MM          pic 99.
     03  WS-WC-DD          pic 99.
     03  WS-WC-HH          pic 99.
     03  WS-WC-Min         pic 99.
     03  filler            pic x(9).
*>
 01  ws-data.
     03  menu-reply      pic x          value "A".
     03  op-display      pic x(7).
*>
*> Better ways of doing it but in keeping with the rest of ACAS
*>
     03  letters-upper   pic x(26)      value "ABCDEFGHIJKLMNOPQRSTUVWXYZ".
     03  letters.
         05  a-entry     pic x        occurs 26 indexed by q.
*>
*>  Not used in Open Source versions (code modules removed)
*>
*>     03  pass-word-input.
*>         05  ar2         pic x         occurs  4.
*>     03  pass-word-output.
*>         05  ar3         pic x         occurs  4.
*>     03  pass-name-input.
*>         05  ar4         pic x         occurs  32.
*>     03  pass-name-output.
*>         05  ar5         pic x         occurs  32.
*>     03  pass-phase-input.
*>         05  ar6         pic x         occurs 1024.
*>     03  pass-phase-output.
*>         05  ar7         pic x         occurs 1024.
*>
     03  ws-reply        pic x.
     03  a               pic 99        comp.
     03  option-list     pic x(60). *> 50 to 60
     03  wsmaps-ser.
         05  wsmaps-ser-xx pic xx.
         05  wsmaps-ser-nn pic 9(4).
*>
 01  ws-date-formats.
     03  ws-swap             pic xx.
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
 copy "wsmaps01.cob".
 copy "wsmaps03.cob".
 copy "wscall.cob".
 copy "wstime.cob".
 copy "wsfnctn.cob".
 copy "wsnames.cob".
*>
 copy "wsdflt.cob".    *> Only used by mapser
 copy "wsfinal.cob".   *> Only used by mapser
 copy "wssys4.cob".    *> Only used by mapser
*>
 01  Error-Messages.
*> System Wide
     03  ST001          pic x(26) value "ST001 System 1 read err = ".
     03  ST004          pic x(59) value "ST004 Problem with opening system file. Hit return to clear".
     03  ST006          pic x(62) value "ST006 Program Arguments limited to two and you have specified ".
     03  ST007          pic x(35) value "ST007 Program arguments incorrect: ".
     03  ST008          pic x(31) value "ST008 Note message & Hit return".
     03  ST009          pic x(53) value "ST009 Environment variables not yet set up : ABORTING".
*>
 01  error-code         pic 999    value zero.
 01  to-day             pic x(10).
*>
 procedure division.
*>=================
*>
 aa000-General-Control  Section.
*>*****************************
*>
*> Force Esc, PgUp, PgDown, PrtSC to be detected
*>
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     perform  zz020-Get-Program-Args.
*>
     move     function current-date to wse-date-block.
*>
*>  New code taken from mapser to build system file if does not
*>  exist existing code will then go to system setup module.
*>
 aa005-Open-System.
     open     i-o system-file.
     if       fs-reply not = zero
              close system-file
              perform ba000-mapser
              open i-o system-file.
*>
 aa010-get-system-recs.
*>
     move     1 to rrn.
     read     system-file record.
     if       fs-reply not = zero
              display ST001 fs-reply
              move 33 to error-code
              call "maps99" using error-code ws-calling-data
              move 15 to error-code
              call "maps99" using error-code ws-calling-data
              close system-file
              stop run.
*>
*> aa020-get-system-recs-end.
*>
     if       scycle = zero
              go to aa060-Call-System-Setup.
*>
     if       file-status (15) = zero
              move 1 to ws-Process-Func
              call "sl070" using ws-calling-data system-record to-day file-defs
     end-if
*>
     move     run-date to u-bin.
     call     "maps04" using maps03-ws.
     move     u-date to to-day.
*>
     if       not Stock
              move 1 to error-code
              call "maps99" using error-code ws-calling-data
              move 15 to error-code
              call "maps99" using error-code ws-calling-data
              go to aa080-OverClose.
*>
     if       op-system = zero move "O/S" to op-display.
     if       windows  move "Windows" to op-display.
     if       dos      move "Dos"     to op-display.
     if       os2      move "OS/2"    to op-display.
     if       Mac      move "Mac"     to op-display.
     if       unix     move "Unix"    to op-display.
     if       linux    move "Linux"   to op-display.
*>
     if       Dos or Windows
              move Windows-Backup-Script-Name to Script-Name
     else if  OS2
              move OS2-Backup-Script-Name to Script-Name
     else if  Linux or Unix or Mac
              move Linux-Backup-Script-Name to Script-Name.
*>
*> Test if script in users bin directory
*>
     string   ACAS_BIN     delimited by space
              OS-Delimiter delimited by size
              Script-Name  delimited by space  into Run-Backup
     end-string
     call     "CBL_CHECK_FILE_EXIST" using Run-Backup  Cbl-File-Details
     end-call
     if       Return-Code not = zero
*>          and Batch-Text (1:1) not = space
              move "No BackUp Script in Bin/Data" to Batch-Text
     else
              move 1 to Backup-Sw
              string "Using "    delimited by size
                     Script-Name delimited by space into Batch-Text
     end-if
*>
     if       menu-reply = "A"
              go to load01.
*>
 aa030-display-menu.
     display  " " at 0101 with erase eos.
     move     to-day to u-date.
     move     "stock" to ws-caller.
     move     spaces to ws-called ws-del-link menu-reply.
     move     zeros to ws-term-code.
     display  maps-ser-xx at 2474 with foreground-color 3.
     move     maps-ser-nn to curs2.
     display  curs2  at 2476 with foreground-color 3.
     display  "Copyright (c) 1976-" at 2401 with foreground-color 3.
     display  wse-year at 2420 with foreground-color 3.
     display  " Applewood Computers" at 2424 with foreground-color 3.
     display  usera  at 0101 with foreground-color 3.
*>
*> Convert from UK to selected form
*>
     if       Date-Form not > zero and < 4
              move 1 to Date-Form.
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
     end-if
     display  u-date at 0171 with foreground-color 3.
*>
 aa040-Display-Go.
*>
     display  prog-name at 0301 with foreground-color 2.
     display  "Stock Control System Menu"    at 0328 with foreground-color 2.
*>
     accept   wsb-time from time.
     if       wsb-time not = "00000000"
              move wsb-hh to wsd-hh
              move wsb-mm to wsd-mm
              move wsb-ss to wsd-ss
              display "at "    at 0355 with foreground-color 2
              display wsd-time at 0358 with foreground-color 2.
*>
     display  "Select one of the following by letter  :- [ ]" at 0601 with foreground-color 2.
*>
     display  "(A)  Date Entry"                  at 1004 with foreground-color 2.
     display  "(B)  Stock Item Maintenance"      at 1104 with foreground-color 2.
     display  "(C)  Stock Movements"             at 1204 with foreground-color 2.
     display  "(D)  Reports"                     at 1304 with foreground-color 2.
     display  "(E)  End of Cycle Processing"     at 1044 with foreground-color 2.
*>     display  "(F)  Stock File Import"           at 1104 with foreground-color 2.
     display  "(X)  Exit to "                    at 1244 with foreground-color 2.
     display  op-display                         at 1257 with foreground-color 2.
     display  batch-text at 1249 with foreground-color 2.
     display  "(Y)  Stock File Compression"      at 1344 with foreground-color 2.
     display  "(Z)  System Set Up"               at 1444 with foreground-color 2.
*>
 aa050-Accept-Loop.
     accept   menu-reply at 0644  with foreground-color 6 auto.
     move     function upper-case (menu-reply) to menu-reply.
*>
     if       menu-reply = "X"
              display " " at 0101 with erase eos
              go to aa070-Pre-OverRewrite.
*>
     move     zero to z.
     move     letters-upper to letters.
     set      q  to  1.
     search   a-entry
              when a-entry (q) = menu-reply
              set z to q.
*>
     if       z not = zero
              go to aa090-Load-It.
     go       to aa050-Accept-Loop.
*>
 aa060-Call-System-Setup.
     move     zero to ws-term-code.
     move     1 to rrn.
     rewrite  system-record.
     close    system-file.
     move     "sys002" to ws-called.
     call     ws-called using ws-calling-data file-defs.
     if       ws-term-code > 7
              stop run.
     go       to aa005-Open-System.
*>
 aa070-Pre-OverRewrite.
     if       not Backup-Script-Found
              go to aa070-OverRewrite.
*>
*>   27/11/11 More changes here
*>
     if       Linux or Unix or Mac
              string "nohup " delimited by size
                      Run-Backup delimited by space
*>                                                         Script-Name delimited by space
                    " 0</dev/null &>/dev/null &" delimited by size     into Full-Backup-Script
              end-string
     else
      if      Dos or Windows                                          *> whats the correct string to add
              move Script-Name to Full-Backup-Script
      else
       if     OS2                                                     *> whats the correct string to add
              move Script-Name to Full-Backup-Script.
     perform  aa070-OverRewrite.
     close    system-file.
     call     "SYSTEM" using Full-Backup-Script.
     goback.
     stop     run.
*>
 aa070-OverRewrite.
     move     1 to rrn.
     rewrite  system-record.
*>
 aa080-OverClose.
     close    system-file.
     goback.
     stop     run.
*>
 aa090-Load-It.
     move     space to menu-reply.
     go       to load01 load02 load03 load04 load05 loader loader              *> load06 loader
                 loader loader loader loader loader loader loader
                 loader loader loader loader loader loader loader
                 loader loader aa070-OverRewrite load25 aa060-Call-System-Setup
              depending on z.
*>
 loader.
     go       to aa030-display-menu.
*>
 load00.
     move     zero to ws-term-code.
     call     ws-called using ws-calling-data system-record to-day file-defs.
     if       ws-term-code > 7
              go to aa070-OverRewrite.
*>
 load00-exit.
     go       to aa030-display-menu.
*>
 load000.                                    *> Not in Use
     move     zero to ws-term-code.
     call     ws-called using ws-calling-data system-record default-record to-day file-defs.
     if       ws-term-code > 7
              go to aa070-OverRewrite.
*>
 load000-exit.                               *> Not in Use
     go       to aa030-display-menu.
*>
 load01.
     move     "st000" to ws-called.
     go       to load00.
*>
 load02.
     move     "st010" to ws-called.
     go       to load00.
*>
 load03.
     move     "st020" to ws-called.
     go       to load00.
*>
 load04.
     move     "st030" to ws-called.
     go       to load00.
*>
 load05.
     move     "st040" to ws-called.
     go       to load00.
*>
 load06.
     move     "st060" to ws-called.
     go       to load00.
*>
 load25.
     move     "st050" to ws-called.
     go       to load00.
*>
 loadsr.
     display  "Sorry not yet available" at 2327 with foreground-color 2.
     go       to aa050-Accept-Loop.
*>
 aa999-exit.
     goback.
     stop     run.
*>
*> Not used
*>
*> Eval-Status        section.
*>=========================
*>
*>     move     spaces to exception-msg.
*> copy "FileStat-Msgs.cpy"  replacing STATUS by fs-reply
*>                                     msg    by exception-msg.
*>
*> Eval-Status-exit.
*>     exit section.
*>***************
*>
 ba000-mapser section.
*>*******************
*>
*> Encrypt/Decrypt coding and other security code removed for
*>    Open Source release
*>
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "ACAS System Setup Routine - Level 1" at 0122 with foreground-color 2.
*>
*> Now Open System File for Output (overwriting existing contents)
*>
     open     output system-file.
     if       fs-reply not = zero
              display ST004 at 1101 with foreground-color 4
              accept ws-reply at 1154
              stop run
     end-if
     initialize system-record.
     move     ws-Sys-Record-Ver-Prime      to System-Record-Version-Prime
     move     ws-Sys-Record-Ver-Secondary  to System-Record-Version-Secondary
     move     1 to date-form.                                                *> default UK format
*>
 ba010-Capture-Data.
     display  "Enter the Company name :- [" at 1101 with foreground-color 2.
     display  "]" at 1160 with foreground-color 2.
*>
     accept   usera at 1128 with foreground-color 3 update.
*>
     display  "Please verify that name is correct (Y/N) :- [ ]" at 1301 with foreground-color 2.
     move     "Y"  to  ws-reply.
     accept   ws-reply  at 1346 with foreground-color 6 update.
*>
     if       ws-reply not = "Y" and not = "y"
              go to ba010-Capture-Data
     end-if
     move     "N" to encode.
     move     usera to pass-name.
     call     "maps01" using maps01-ws.
     move     pass-name to user-code.
     move     "P" to encode.
     move     "pass" to pass-word of maps01-ws
                        pass-word of system-record.
     call     "maps01" using maps01-ws.
     move     pass-word of maps01-ws  to  pass-word of system-record.
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
     perform  ca000-level-setup.
*>
     move     1  to  op-system.
     move     1  to  sales-range.
     move     2  to  purchase-range.
     move     1  to  next-batch.
     move     1  to sl-dunning sl-charges.
     move     2  to Invoicer.
     move     30 to sl-credit.
     move     "\" to sl-delim.
*>
     move     1  to  rrn.
     write    system-record.
*>
     initialize default-record.
     move     2     to  rrn.
     write    system-record  from  default-record.
*>
     move     spaces  to  final-record.
     move     3       to  rrn.
     write    system-record  from  final-record.
*>
     initialize system-record-4.
     move     4 to rrn.
     write    system-record from system-record-4.
*>
     close    system-file.
*>
 ba999-exit.
     exit     section.
*>
 ca000-level-setup  section.
*>*************************
*>
     move     "mp9999" to wsmaps-ser.
     move     wsmaps-ser-xx to maps-ser-xx.
     move     wsmaps-ser-nn to maps-ser-nn.
*>
     display  "Using General  Ledger (Y/N) ? :- [ ]"  at 1901 with foreground-color 2.
     display  "Using Purchase Ledger (Y/N) ? :- [ ]"  at 2001 with foreground-color 2.
     display  "Using Sales    Ledger (Y/N) ? :- [ ]"  at 2101 with foreground-color 2.
     display  "Using Invoicing       (Y/N) ? :- [ ]"  at 1941 with foreground-color 2.
     display  "Using Stock Control   (Y/N) ? :- [ ]"  at 2041 with foreground-color 2.
     display  "Using Order Entry     (Y/N) ? :- [ ]"  at 2141 with foreground-color 2.
*>
     accept   ws-reply at 1935 with foreground-color 6 update.
*>
     if       ws-reply = "Y" or "y"
              move  1  to  level-1
     else
              move zero to level-1
     end-if
     accept   ws-reply at 2035 with foreground-color 6 update.
*>
     if       ws-reply = "Y" or "y"
              move  1  to  level-2
     else
              move zero to level-2
     end-if
     accept   ws-reply at 2135 with foreground-color 6 update.
*>
     if       ws-reply = "Y" or "y"
              move  1  to  level-3
     else
              move zero to level-3
     end-if
     accept   ws-reply at 1975 with foreground-color 6 update.
*>
     if       ws-reply = "Y" or "y"
              move  1  to  full-invoicing
     else
              move zero to full-invoicing
     end-if
     accept   ws-reply at 2075 with foreground-color 6 update.
*>
     if       ws-reply = "Y" or "y"
              move  1  to  Level-4
     else
              move zero to Level-4
     end-if
     accept   ws-reply at 2175 with foreground-color 6 update.
*>
     if       ws-reply = "Y" or "y"
              move  1  to  Level-5
     else
              move zero to Level-5
     end-if
     display  "Please confirm (Y/N) :- [ ] " at 2301 with foreground-color 2.
*>
     move     spaces  to  option-list.
     move     1  to  a.
*>
     if       G-L
              string "General "      delimited by size into option-list pointer a.
*>
     if       B-L  and  G-L
              string "/ "            delimited by size into option-list pointer a.
*>
     if       B-L
              string "Purchase "     delimited by size into option-list pointer a.
*>
     if       (S-L  and  G-L)
        or    (S-L  and  B-L)
              string "/ "            delimited by size into option-list pointer a.
*>
     if       S-L
              string "Sales "        delimited by size into option-list pointer a.
*>
     if       S-L  and  Full-Invoicing = 1
              string  "/ Invoicing " delimited by size into option-list pointer a.
*>
     if       Stock
              string "/ Stock "      delimited by size into option-list pointer a.
*>
     if       O-E
              string "/ Order Entry" delimited by size into option-list pointer a.
*>
*>  option-list now max 60 chars used
*>
     display  option-list at 2401 with foreground-color 2.
     accept   ws-reply at 2326 with foreground-color 6.
     if       ws-reply not = "Y" and not = "y"
              go to ca000-level-setup.
*>
 ca999-exit.
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
              display ST009   at 0505 with erase eos highlight
              display ST008   at 1210 with           foreground-color 3 highlight
              accept ws-reply at 1243
              stop run
     end-if
     if       ACAS_LEDGERS (1:1) = "/"   *> Its Linux/Unix/OSX
              move "/" to OS-Delimiter.
     if       ACAS_LEDGERS (1:1) = "\"   *> Its Windoz/Dos-Box
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
              display ST006        at 0101 with erase eos foreground-color 3
              display Arg-Number   at 0164 with           foreground-color 3
              display ST008        at 1210 with           foreground-color 3 highlight
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
                       display ST007 at 0101  with erase eos foreground-color 3
                       display ST008        at 1210 with           foreground-color 3 highlight
                       accept ws-reply      at 1243
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
     if       ACAS_LEDGERS (1:1) = "/"   *> Its Linux/Unix
              move "/" to OS-Delimiter.
     if       ACAS_LEDGERS (1:1) = "\"   *> Its Windoz
              move "\" to OS-Delimiter.
*>
*>  Put absolute path with file names into the file-id areas over-writing filename.
*>    Note that count in perform is equal to number of files used in system & wsnames.cob held
*>       in File-Defs-Count
*>
 zz020-Set-the-Paths.
     move     zero to z.
     perform  File-Defs-Count times
              add 1 to z
              move space to Arg-Test
              string ACAS_LEDGERS          delimited by space
                     OS-Delimiter          delimited by size
                     System-File-Names (z) delimited by space
                                             into Arg-Test
              end-string
              move     Arg-Test to System-File-Names (z)
     end-perform
     move     zero to z.
*>
 zz020-Exit.
     exit   section.
*>
