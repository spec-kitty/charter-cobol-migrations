       >>source free
*>
*>**************************************************
*>                                                 *
*>         Purchase  Ledger  System  Menu          *
*>                                                 *
*>**************************************************
*>
 identification          division.
*>===============================
*>
      program-id.         purchase.
*>**
*>    author.             V.B.Coen FBCS, FIDM
*>                        Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            P/L System Menu.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>   Calls:               Maps01
*>                        Maps04
*>                        Maps99.
*>                        Sys002.
*>**
*>    Error messages used.
*>                        PL006
*>                        PL007
*>                        PL008
*>   Changes.
*> 10/07/84 Vbc - Fix Display Head Positioning.
*> 25/09/84 Vbc - Support For Pl100 Using Wssys4.
*> 07/01/85 Vbc - Change Of Copyright Notice.
*> 28/04/85 Vbc - Change Of End Of Cycle Prog Name.
*> 01/04/09 vbc - Added pl190.
*> 04/04/09 vbc - Added pl165 sort before pl120 - Aged Cred Rep
*>                Clean up menu calls ie, renumbering.
*> 09/04/09 vbc - Run backup script at exit.
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 01/06/09 vbc - .08 Support for Stock & OE in Mapser
*> 04/06/09 vbc - .09 Minor display bug in menu
*> 14/09/10 vbc - .10 Added Cob Env variables presets.
*> 15/09/10 vbc - .11 mod to always use current year for (C) display.
*> 02/10/11 vbc - .12 Changed to Cbl-File-Details year to xx for OC v2.

*> 11/12/11 vbc - .13 Added support for other than UK date format
*>                    Update Env processing and pass on to all ACAS called modules
*>                    Allow being called with one/two params for working dirs that overides
*>                    ACAS_LEDGERS and ACAS_IRS in case using temp practice/test directories.
*>                    Make backup script run via ~/bin directory so needs another env var.
*>                    Updated version to 3.01.nn
*> 20/12/11 vbc - .14 Missing 'into' when creating file paths and OC didnt comment
*> 17/04/13 vbc - .15 Force Invoicer = 2 when creating system.dat
*> 19/04/13 vbc - .16 Fix Bug in get-args that bypassed code - Dummy
*> 26/04/13 vbc - .17 Included version data for system record same as in sys002.
*> 28/04/13 vbc - .18 Include test for file-8 in zz020.
*> 18/05/13 vbc - .19 Zero new fields in ws-calling-data. Used in SL070 if called by Stock.
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
*>------------
*>
 copy "selsys.cob".
 Data  Division.
*>=============
*>
 File Section.
*>-----------
*>
 copy "fdsys.cob".
 working-storage section.
*>----------------------
 77  prog-name           pic x(18)    value "Purchase (3.01.19)".
 77  z                   binary-char.
 77  Batch-Text          pic x(28)    value spaces.
 77  Script-Name         pic x(20)    value spaces.
 77  Run-Backup          pic x(512)   value spaces.  *> size changed
 77  Full-Backup-Script  pic x(512)   value spaces.
 77  OS-Delimiter        pic x        value "/".
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
*> holds program parameter values from command line
 01  Arg-Vals                         value spaces.
     03  Arg-Value       pic x(525)  occurs 2.
 01  Arg-Test            pic x(525)   value spaces.
*>
 01  Backup-Sw           pic 9     value zero.
     88  Backup-Script-Found       value 1.
 01  Linux-Backup-Script-Name   pic x(20) value "acasbkup.sh".
 01  Windows-Backup-Script-Name pic x(20) value "acasbkup.bat".
 01  OS2-Backup-Script-Name     pic x(20) value "acasbkup.cmd".
 01  Exit-To-System             pic x(18) value "to Linux".
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
     03  menu-reply      pic x        value "A".
     03  op-display      pic x(6).
*>
     03  letters-upper   pic x(26)    value "ABCDEFGHIJKLMNOPQRSTUVWXYZ".
     03  letters.
         05  a-entry     pic x          occurs  26  indexed by q.
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
     03  PL006           pic x(62) value "PL006 Program Arguments limited to two and you have specified ".
     03  PL007           pic x(35) value "PL007 Program arguments incorrect: ".
     03  PL008           pic x(31) value "PL008 Note message & Hit return".
     03  PL009           pic x(53) value "PL009 Environment variables not yet set up : ABORTING".
*> Module specific
*>
 copy "wsnames.cob".
 01  error-code          pic 999    value zero.
 01  to-day              pic x(10).
*>
 procedure division.
*>=================
*>
 Purchase-Main.
*>------------
*>
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     perform  zz020-Get-Program-Args.
     move     function current-date to wse-date-block.
*>
 Open-System.
     open     i-o system-file.
     if       fs-reply not = zero
              close system-file
              perform mapser
              open i-o system-file.
*>
     move     4 to rrn.
     read     system-file record into system-record-4.
     move     1 to rrn.
     read     system-file record.
*>
     if       scycle = zero
              go to call-system-setup.
*>
     move     run-date to u-bin.
     call     "maps04" using maps03-ws.
     move     u-date to to-day.
     perform  zz060-Convert-Date.
*>
     if       not B-L
              move 1 to error-code
              call "maps99" using error-code ws-calling-data
              close system-file
              move 15 to error-code
              call "maps99" using error-code ws-calling-data
              go to overclose.
*>
     if       op-system = zero move "O/S" to op-display.
     if       linux   move "Linux"   To op-display
     else if  Windows move "Windows" To op-display
     else if  Mac     move "Mac"     To op-display
     else if  OS2     move "OS/2"    To op-display
     else if  unix    move "Unix"    To op-display
     else if  dos     move "Dos"     To op-display.
*>
     if       Dos or Windows
              move Windows-Backup-Script-Name to Script-Name
     else if  OS2
              move OS2-Backup-Script-Name to Script-Name
     else if  Linux or Unix or Mac
              move Linux-Backup-Script-Name to Script-Name.
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
     move     zeros to ws-Process-Func ws-Sub-Function.
     if       menu-reply = "A"
              go to load01.
*>
 display-menu.
*>
     display  " " at 0101 with erase eos.
     move     to-day to u-date.
     move     "purchase" to ws-caller.
     move     spaces to ws-called ws-del-link menu-reply.
     move     zeros to ws-term-code.
     move     maps-ser-nn to curs2.
     display  maps-ser-xx at 2474 with foreground-color 3.
     display  curs2 at 2476 with foreground-color 3.
     display  "Copyright (c) 1976-" at 2401 with foreground-color 3.
     display  wse-year at 2420 with foreground-color 3.
     display  " Applewood Computers" at 2424 with foreground-color 3.
     display  usera at 0101 with foreground-color 3.
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
 display-go.
*>
     display  prog-name at 0301 with foreground-color 2.
     display "Purchase Ledger System Menu" at 0326 with foreground-color 2.
*>
     accept   wsb-time from time.
     if       wsb-time not = "00000000"
              move wsb-hh to wsd-hh
              move wsb-mm to wsd-mm
              move wsb-ss to wsd-ss
              display "at " at 0355 with foreground-color 2
              display wsd-time at 0358 with foreground-color 2.
*>
*> if using variable date format this needs to go?
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
     display  "(A)  Date Entry" at 1004 with foreground-color 2.
     display  "(B)  Supplier File Maintenance" at 1104    with foreground-color 2.
     display  "(C)  Purchase Ledger Enquiry" at 1204      with foreground-color 2.
     display  "(D)  Purchase Transactions Input" at 1304  with foreground-color 2.
     display  "(E)  Purchase Transactions Amend" at 1404  with foreground-color 2.
     display  "(F)  Purchase Transactions Delete" at 1504 with foreground-color 2.
     display  "(G)  Purchase Transactions Proof" at 1604  with foreground-color 2.
     display  "(H)  Purchase Transactions Post" at 1704   with foreground-color 2.
     display  "(I)  Payment Input" at 1804                with foreground-color 2.
     display  "(J)  Payment Amend" at 1904                with foreground-color 2.
     display  "(K)  Payment Proof" at 2004                with foreground-color 2.
     display  "(L)  Payment Post" at 2104                 with foreground-color 2.
     display  "(M)  Set-Up Purchase Analysis Codes" at 2204 with foreground-color 2.
     display  "(N)  Purchase Analysis Report" at 1044     with foreground-color 2.
     display  "(O)  Purchase Day Book" at 1144            with foreground-color 2.
     display  "(P)  Aged Creditors Report" at 1244        with foreground-color 2.
     display  "(Q)  Alphabetical Supplier List" at 1344   with foreground-color 2.
     display  "(R)  Supplier Turnover Report" at 1444     with foreground-color 2.
     display  "(S)  Cheque  Sub-System" at 1544           with foreground-color 2.
     display  "(T)  End Of Cycle Processing" at 1644      with foreground-color 2.
     display  "(U)  Invoice Parameter Amend" at 1744      with foreground-color 2.
     display  "(V)  Supplier File Dump" At 1844           with foreground-color 2.
     display  "(X)  Exit to " at 1944                     with foreground-color 2.
     display  op-display at 1957 with foreground-color 2.
     display  batch-text at 2049 with foreground-color 2.
*>     display  "(Y)  File Fix Up" at 2144 with foreground-color 2.
     display  "(Z)  System Set Up" at 2244                with foreground-color 2.
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
     move     letters-upper  to  letters.
     set      q  to  1.
     search   a-entry
              when  a-entry (q) = menu-reply
              set z to q.
     if       z = zero
              go to accept-loop.
*>
     go       to load-it.
*>
 call-system-setup.
*>*****************
*>
     move     zero to ws-term-code.
     move     1 to rrn.
     rewrite  system-record.
     close    system-file.
     move     "sys002" to ws-called.
     call     ws-called using ws-calling-data file-defs.
     if       ws-term-code > 7
              stop run.
     go       to Open-System.
*>
 pre-overrewrite.
     if       not Backup-Script-Found
              go to overrewrite.
*>
     if       Linux or Unix or Mac
              string "nohup " delimited by size
                      Script-Name delimited by space
                    " 0</dev/null &>/dev/null &" delimited by size    into Run-Backup
              end-string
     else
      if      Dos or Windows
              move Script-Name to Run-Backup
      else
       if     OS2
              move Script-Name to Run-Backup.
     perform  overrewrite.
     call     "SYSTEM" using Run-Backup.
     goback.
     stop     run.
*>
 overrewrite.
     move     1 to rrn.
     rewrite  system-record.
     move     4 to rrn.
     rewrite  system-record from system-record-4.
     close    system-file.
*>
 overclose.
     goback.
     stop     run.
*>
 load-it.
*>*******
*>
     move     space to menu-reply.
     go       to load01 load02 load03 load04 load05 load06 load07
                 load08 load09 load10 load11 load12 load13 load14
                 load15 load16 load17 load18 load19 load20 load21
                 load22 loadre loadre loadsr call-system-setup
              depending on z.
*>
 loadre.
*>-------
*>
     go       to display-menu.
*>
 load00.
*>------
*>
     move     zero to ws-term-code.
     call     ws-called using ws-calling-data system-record to-day file-defs.
     if       ws-term-code > 7
              go to overrewrite.
     cancel   ws-called.
*>
 load00-exit.
*>
     go       to display-menu.
*>
 load000.
*>------
*>
     move     zero to ws-term-code.
     call     ws-called using ws-calling-data system-record system-record-4 to-day file-defs.
     if       ws-term-code > 7
              go to overrewrite.
     cancel   ws-called.
*>
 load000-exit.
*>
     go       to display-menu.
*>
 load01.
*>------
*>
     move     "pl000" to ws-called.
     go       to load00.
*>
 load02.
*>------
*>
     move     "pl010" to ws-called.
     go       to load00.
*>
 load03.
*>-------
*>
     move     "pl015" to ws-called.
     go       to load00.
*>
 load04.
*>------
*>
     move     "pl020" to ws-called.
     go       to load00.
*>
 load05.
*>------
*>
     move     "pl030" to ws-called.
     go       to load00.
*>
 load06.
*>------
*>
     move     "pl040" to ws-called.
     go       to load00.
*>
 load07.
*>------
*>
     if       p-flag-i not = 1 or
              file-status (26) = zero
              move 14 to error-code
              go to message-run.
*>
     move     "pl050" to ws-called.
     go       to load00.
*>
 load08.
*>------
*>
     if       p-flag-i not = 1 or
              file-status (26) = zero
              move 14 to error-code
              go to message-run.
*>
     move     "pl055" to ws-called.
     perform  load000.
     move     "pl060" to ws-called.
     go       to load000.
*>
 load09.
*>------
*>
     if       p-flag-i = 1
              move 28 to error-code
              go to message-run.
     if       file-status (29) = zero
              move 25 to error-code
              go to message-run.
*>
     move     "pl080" to ws-called.
     go       to load00.
*>
 load10.
*>------
*>
     move     "pl085" to ws-called.
     go       to load00.
*>
 load11.
*>------
*>
     move     "pl090" to ws-called.
     perform  load00.
     move     "pl095" to ws-called.
     go       to load00.
*>
 load12.
*>------
*>
     move     "pl100" to ws-called.
     go       to load000.
*>
 load13.
*>------
*>
     move     "pl070" to ws-called.
     go       to load00.
*>
 load14.
*>------
*>
     move     "pl130" to ws-called.
     go       to load00.
*>
 load15.
*>------
*>
     move     "pl140" to ws-called.
     go       to load00.
*>
 load16.
*>------
*>
     move     zero to error-code.
     move     "pl165" to ws-called.
     perform  load00.
     move     "Y" to oi-5-flag.
     move     "pl115" to ws-called.
     perform  load00.
     if       error-code = zero
              move  "pl120" to ws-called
              go  to load000.
     go       to display-menu.
*>
 load17.
*>------
*>
     move     "pl165" to ws-called.
     perform  load00.
     move     "pl160" to ws-called.
     go       to load00.
*>
 load18.
*>------
*>
     move     "pl170" to ws-called.
     go       to load00.
*>
 load19.
*>------
*>
     move     "pl900" to ws-called.
     go       to load00.
*>
 load20.
*>------
*>
     if       ws-term-code = 3
              go to load20a.
*>
     move     "pl140" to ws-called.
     perform  load00.
*>
 load20a.
*>
     move     "xl150" to ws-called.
     perform  load000.
     if       ws-term-code = 2 or 3
              go to display-menu.
     if       ws-term-code = 1
              move "pl130" to ws-called
              perform load00
              move zero to ws-term-code
              go to load20a.
*>
     go       to display-menu.
*>
 load21.
*>------
*>
     move     "pl180" to ws-called.
     go       to load00.
*>
 load22.
*>------
*>
     move     "pl190" to ws-called.
     go       to load00.
*>
 loadsr.
*>------
*>
     display  "Sorry not yet available" at 2331 with foreground-color 2.
     go       to accept-loop.
*>
 message-run.
*>
     perform  display-menu.
     call     "maps99" using error-code ws-calling-data.
     move     15 to error-code.
     call     "maps99" using error-code ws-calling-data.
     go       to display-menu.
*>
 main-exit.
     goback.
     stop     run.
*>
 mapser section.
*>*************
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
              display "Problem with opening system file. Hit return to clear"
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
     display  "Please verify that name is correct (Y/N) :- [ ]" at 1301 with foreground-color 2.
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
 main-exit.
     exit section.
*>
 Level-Setup  section.
*>*******************
*>
     move     "mp9999" to wsmaps-ser.
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
*>
     if       ws-reply = "Y"
              move  1  to  level-1     *> G/L
     else
              move zero to level-1
     end-if
     accept   ws-reply at 2035 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "Y"
              move  1  to  level-2     *> P/L
     else
              move zero to level-2
     end-if
     accept   ws-reply at 2135 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "Y"
              move  1  to  level-3     *> S/L
     else
              move zero to level-3
     end-if
     accept   ws-reply at 1975 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "Y"
              move  1  to  full-invoicing   *> Invoicing
     else
              move zero to full-invoicing
     end-if
     accept   ws-reply at 2075 with foreground-color 6 update.
*>
     if       ws-reply = "Y" or "y"
              move  1  to  Level-4     *> Stock
     else
              move zero to Level-4
     end-if
     accept   ws-reply at 2175 with foreground-color 6 update.
*>
     if       ws-reply = "Y" or "y"
              move  1  to  Level-5     *> O/E
     else
              move zero to Level-5
     end-if
     display  "Please confirm (Y/N) :- [ ] " at 2301  with foreground-color 2.
*>
     move     spaces  to  option-list.
     move     1  to  a.
*>
     if       G-L
              string "General " delimited by size into option-list with pointer a.
*>
     if       B-L  and  G-L
              string "/ " delimited by size into option-list      with pointer a.
*>
     if       B-L
              string "Purchase " delimited by size into option-list with pointer a.
*>
     if       S-L  and  G-L
        or    S-L  and  B-L
              string "/ " delimited by size            into option-list with pointer a.
*>
     if       S-L
              string "Sales " delimited by size        into option-list with pointer a.
*>
     if       S-L  and  full-invoicing = 1
              string  "/ Invoicing" delimited by size  into option-list with pointer  a.
*>
     if       Stock
              string "/ Stock " delimited by size      into option-list pointer a.
*>
     if       O-E
              string "/ Order Entry" delimited by size into option-list pointer a.
*>
*>  option-list now max 60 chars used
*>
     display  option-list at 2401 with foreground-color 2.
     accept   ws-reply at 2326 with foreground-color 6.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply not = "Y"
              go to Level-Setup.
*>
 main-exit.
     exit section.
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
              display PL009        at 0505 with erase eos highlight
              display PL008        at 1210 with           foreground-color 3 highlight
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
              display PL006        at 0101 with erase eos foreground-color 3
              display Arg-Number   at 0164 with           foreground-color 3
              display PL008        at 1210 with           foreground-color 3 highlight
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
                       display PL007 at 0101  with erase eos foreground-color 3
                       display PL008        at 1210 with           foreground-color 3 highlight
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
              if   System-File-Names (z) = file-8
                   string ACAS_IRS              delimited by space
                          OS-Delimiter          delimited by size
                          System-File-Names (z) delimited by space into Arg-Test
                   end-string
              else
                   string ACAS_LEDGERS          delimited by space
                          OS-Delimiter          delimited by size
                          System-File-Names (z) delimited by space into Arg-Test
                   end-string
              end-if
              move Arg-Test to System-File-Names (z)
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
