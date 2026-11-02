       >>source free
*>***************************************************
*>                                                  *
*>         General - Ledger  System  Menu           *
*>--------------------------------------------------*
*>  NO Final Accounts or Garbage collector          *
*>  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^          *
*>  This sub system has yet to be retested since    *
*>  migration to OC, also the archiving & spooling  *
*>  functions need a good cleanup as they are not   *
*>  necessarily fit for purpose on Linux systems.   *
*>                                                  *
*> In the meanwhile the Incomplete Records System   *
*>  (IRS) has been tested against the other         *
*>  elements of the ACAS system.                    *
*>***************************************************
*>
 identification          division.
*>================================
*>
*>**
      program-id.       general.
*>**
*>    Author.           V.B.Coen FBCS.
*>**
*>    Security.         Copyright (C) 1976-2012 Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.          G/L System Menu.
*>**
*>    Version.          see prog-name & date-comped in ws.
*>
*>    Called Modules.   maps01.
*>                      maps04. (Replaces 3)
*>                      maps99.
*>**
*>    Error messages used.
*>                      GL001
*>                      GL002
*>                      GL003
*>                      GL004
*>                      GL005
*>                      GL006
*>                      GL007
*>                      GL008
*>**
*>    Changes.
*> 27/01/09 vbc - Migration to Open Cobol v2.53 -> v3.00.0.
*>                Encrypt/Decrypt & security encoding removed for Open source versions.
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 01/06/09 vbc - Support for Stock & OE in Mapser, removed Payroll, O/E.
*> 14/09/10 vbc - Added Cob Env variables presets.
*> 02/10/11 vbc - .06 Added from acas ledgers to test for ACAS environment vars
*>                    but left commented out as not sure its needed.
*> 18/12/11 vbc - .07 Force set env variables for Esc and other keys + other cosmetics.
*>                    mod to always use current year for (C) display.
*>                    Changed to Cbl-File-Details year to xx for OC v2.
*>                    Update Env processing and pass on to all ACAS called modules
*>                    Allow being called with one/two params for working dirs that overides
*>                    ACAS_LEDGERS and ACAS_IRS in case using temp practice/test directories.
*>                    Make backup script run via ~/bin directory so needs another env var (ACAS_BIN).
*>                    Maintain version 3.00.xx until some testing has been completed
*> 24/02/12 vbc - .08 After running gl020 (defaults) save system file and reload it.
*> 17/04/13 vbc - .09 Force Invoicer = 2 when creating system.dat
*> 19/04/13 vbc - .10 Fix Bug in get-args that bypassed code - Dummy
*> 26/04/13 vbc - .11 Included version data for system record same as in sys002 & force Date entry on 1st starting
*>                    and started work system wide to use rdbms instead of or addition to, cobol flat files
*>                    and replace all batch type processing on G/L similar to IRS.
*>****
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
 77  prog-name           pic x(17) value "General (3.00.11)".
 77  z                   binary-char    value zero.
*> 77  Exception-Msg       pic x(25)    value spaces.
 77  s1x                 pic x          value space.
 77  Batch-Text          pic x(28)    value spaces.
 77  Script-Name         pic x(20)    value spaces.
 77  Run-Backup          pic x(512)   value spaces.  *> size changed
 77  Full-Backup-Script  pic x(512)   value spaces.
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
 01  WS-When-Compiled.
     03  WS-WC-YY          pic 9(4).
     03  WS-WC-MM          pic 99.
     03  WS-WC-DD          pic 99.
     03  WS-WC-HH          pic 99.
     03  WS-WC-Min         pic 99.
     03  filler            pic x(9).
*>                                                               All above new but not yet coded
 01  ws-data.
     03  menu-reply      pic x          value "A".   *> force Date entry on first starting
     03  op-display      pic x(7).
*>
     03  letters-upper   pic x(26)      value "ABCDEFGHIJKLMNOPQRSTUVWXYZ".
     03  letters.
         05  a-entry     pic x        occurs 26 indexed by q.
*>
     03  pass-word-input.
         05  ar2         pic x         occurs  4.
     03  pass-word-output.
         05  ar3         pic x         occurs  4.
     03  pass-name-input.
         05  ar4         pic x         occurs  32.
     03  pass-name-output.
         05  ar5         pic x         occurs  32.
*>
     03  ws-reply        pic x.
     03  a               pic 99        comp.
     03  option-list     pic x(60).
     03  wsmaps-ser.
         05  wsmaps-ser-xx pic xx.
         05  wsmaps-ser-nn pic 9(4).
*>
 copy "wsmaps01.cob".
 copy "wsmaps03.cob".
 copy "wscall.cob".
 copy "wstime.cob".
 copy "wsfnctn.cob".
 copy "wssys4.cob".       *> Only used by mapser
 copy "wsdflt.cob".       *> Only used by mapser / gl020
 copy "wsfinal.cob".      *> Only used by mapser
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
     03  GL001           pic x(26) value "GL001 System 1 read err = ".
     03  GL002           pic x(26) value "GL002 System 2 read err = ".
     03  GL003           pic x(26) value "GL003 System 4 read err = ".
     03  GL004           pic x(59) value "GL004 Problem with opening system file. Hit return to clear".
     03  GL006           pic x(62) value "GL006 Program Arguments limited to two and you have specified ".
     03  GL007           pic x(35) value "GL007 Program arguments incorrect: ".
     03  GL008           pic x(31) value "GL008 Note message & Hit return".
     03  GL009           pic x(53) value "GL009 Environment variables not yet set up : ABORTING".
*>
 copy "wsnames.cob".      *> hold all the file-id/names used by general
 01  error-code          pic 999    value zero.
 01  to-day              pic x(10).
*>
 procedure division.
*>=================
*>
 General-Control  Section.
*>***********************
*>
*>> Force Esc, PgUp, PgDown, PrtSC to be detected
*>
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     perform  zz020-Get-Program-Args.
     move     function current-date to wse-date-block.
*>
*>  New code taken from mapser to build system file if does not
*>  exist existing code will then go to system setup module.
*>
 Open-System.
     open     i-o system-file.
     if       fs-reply not = zero
              close system-file
              perform mapser
              open i-o system-file.
*>
 get-system-recs.
*>
     move     4 to rrn.
     read     system-file record into system-record-4.
     if       fs-reply not = zero
              display GL003 fs-reply " hit return"
              accept ws-reply
              close system-file
              stop run.
*>
*>  Final accounts processing via gl120 which opens it, hmm
*>
     move     2 to rrn.
     read     system-file record into default-record.
     if       fs-reply not = zero
              display GL002 fs-reply " hit return"
              accept ws-reply
              close system-file
              stop run.
     move     1 to rrn.
     read     system-file record.
     if       fs-reply not = zero
              display GL001 fs-reply " hit return"
              accept ws-reply
              close system-file
              stop run.
*>
 get-system-recs-end.
*>
     if       scycle = zero
              go to call-system-setup.
*>
     move     run-date to u-bin.
     call     "maps04" using maps03-ws.
     move     u-date to to-day.
     perform  zz060-Convert-Date.
*>
     if       not G-L
              move 1 to error-code
              call "maps99" using error-code ws-calling-data
              close system-file
              move 15 to error-code
              call "maps99" using error-code ws-calling-data
              go to overclose.
*>
     if       op-system = zero move "O/S"     to op-display.
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
     if       menu-reply = "A"
              go to load01.
*>
 display-menu.
*>
     display  " " at 0101 with erase eos.
     move     to-day to u-date.
     move     "General" to ws-caller.
     move     spaces to ws-called ws-del-link menu-reply.
     move     zeros to ws-term-code.
     display  maps-ser-xx at 2474 with foreground-color 3.
     move     maps-ser-nn to curs2.
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
     display  "General Ledger System Menu" at 0328 with foreground-color 2.
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
     display  "(A)  Date Entry" At 1004 with foreground-color 2.
     display  "(B)  Chart Of Accounts" At 1104            with foreground-color 2.
     display  "(C)  Default Account Maintenance" at 1204  with foreground-color 2.
     display  "(D)* Final Accounts Set-Up" At 1304        with foreground-color 2.
     display  "(E)  Enter Transactions" At 1404           with foreground-color 2.
     display  "(F)  Proof/Modify Transactions" at 1504    with foreground-color 2.
     display  "(G)  Batch Status Report" At 1604          with foreground-color 2.
     display  "(H)  Transaction Posting" At 1704          with foreground-color 2.
     display  "(I)  End Of Cycle Processing" At 1804      with foreground-color 2.
     display  "(J)  Print Trial Balance" At 1144          with foreground-color 2.
     display  "(K)  Print P&L and Balance Sheet" At 1244  with foreground-color 2.
     display  "(L)  Print Ledgers"               At 1344  with foreground-color 2.
     display  "(M)* Print Final Accounts"        At 1444  with foreground-color 2.
     display  "(X)  Exit to "                    At 1544  with foreground-color 2.
     display  op-display at 1557 with foreground-color 2.
*>     display  "(Y)*  File Garbage Collector"   at 1644  with foreground-color 2. *> change when done
     display  "(Z)  System Set Up" At 1744                with foreground-color 2.
*>
 accept-loop.
*>
     accept   menu-reply at 0644  with foreground-color 6 auto.
     move     function upper-case (menu-reply) to menu-reply.
*>
     if       menu-reply = "X"
              display " " at 0101 with erase eos
              go to overrewrite.
*>
     move     zero to z.
     move     letters-upper to letters.
     set      q  to  1.
     search   a-entry
              when a-entry (q) = menu-reply
              set z to q.
*>
     if       z not = zero
              go to load-it.
     go       to accept-loop.
*>
 call-system-setup.
*>****************
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
 overrewrite.
*>
     move     1 to rrn.
     rewrite  system-record.
     move     2 to rrn.
     rewrite  system-record from default-record.
     move     4 to rrn.
     rewrite  system-record from system-record-4.
*>
 overclose.
*>
     close    system-file.
     goback.
     stop     run.
*>
 load-it.
*>******
*>
     move     space to menu-reply.
     go       to load01 load02 load03 loadsr load05 load06 load07
                 load08 load09 load10 load11 load12 loader loader
                 loader loader loader loader loader loader loader
                 loader loader loader loadsr call-system-setup
              depending on z.
*>
 loader.
*>-----
*>
     go       to display-menu.
*>
 load00.
*>-----
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
     call     ws-called using ws-calling-data system-record default-record to-day file-defs.
     if       ws-term-code > 7
              go to overrewrite.
     cancel   ws-called.
*>
 load000-exit.
*>
     go       to display-menu.
*>
 load01.
*>-----
*>
     move     "gl000" to ws-called.
     go       to load00.
*>
 load02.
*>-----
*>
     move     "gl030" to ws-called.
     go       to load00.
*>
 load03.
*>-----
*>
     move     "gl020" to ws-called.
*>     go       to load000.
*>
*> after updating default, below should be run instead of above ??
*>    to update system record (Defaults)
*>

     perform  load000.
     perform  overrewrite.
     perform  get-system-recs.
     go       to display-menu.
*>
 load05.
*>-----
*>
     move     "gl050" to ws-called.
     perform  load000.
     perform  overrewrite.
     perform  get-system-recs.
     go       to display-menu.
*>
 load06.
*>-----
*>
     move     "gl051" to ws-called.
     perform  load00.
     perform  overrewrite.
     perform  get-system-recs.
     go       to display-menu.
*>
 load07.
*>-----
*>
     move     "gl060" to ws-called.
     go       to load00.
*>
 load08.
*>-----
*>
     move     "gl070" to ws-called.
     perform  load00.
     if       ws-term-code = 5
              go to display-menu.
     move     "gl071" to ws-called.
     perform  load00.
     move     "gl072" to ws-called.
     go       to load00.
*>
 load09.
*>-----
*>
     move     "gl080" to ws-called.
     go       to load00.
*>
 load10.
*>-----
*>
     move     "gl090" to ws-called.
     go       to load00.
*>
 load11.
*>-----
*>
     move     "gl120" to ws-called.
     go       to load00.
*>
 load12.
*>-----
*>
*>     if       not archiving
*>              display "Sorry you are not archiving post data" at 2322
*>              go to accept-loop.
*>
     move     "gl100" to ws-called.
     perform  load00.
     if       ws-term-code = 5
              go to accept-loop.
     if       ws-term-code = 4
              move 31 to error-code
              call "maps99" using error-code ws-calling-data
              move 15 to error-code
              call "maps99" using error-code ws-calling-data
              go to display-menu.
     move     "gl105" to ws-called.
     go       to load00.
*>
 load25.
*>-----
*>
     move     "gl210" to ws-called.
     go       to load00.
*>
 loadsr.
*>-----
*>
     display  "Sorry not yet available" at 2327 with foreground-color 2.
     go       to accept-loop.
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
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "ACAS System Setup Routine - Level 1" AT 0122 with foreground-color 2.
*>
*> Now Open System File for Output (overwriting existing contents)
*>
     open     output system-file.
     if       fs-reply not = zero
              display "Problem with opening system file. Hit return to clear"
                         at 1101 with foreground-color 4
              accept ws-reply at 1154
              stop run
     end-if
     initialize system-record.
     move     ws-Sys-Record-Ver-Prime      to System-Record-Version-Prime
     move     ws-Sys-Record-Ver-Secondary  to System-Record-Version-Secondary
     move     1 to date-form.                                                *> default UK format
*>
 Capture-Data.
     display  "Enter the Company Name :- [" at 1101    with foreground-color 2.
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
*>     perform  varying a from 1 by 1 until a > 32
*>              move "000" to op-gen (a)
*>     end-perform     *>  DOES THIS NEED TO BE XXX AS AGAINST 999
*>                    *>    COZ IF SO ABOVE LINES CAN GO ??????? <<
*> THIS ALL RELATES TO THE BACKUP PROC. WHICH IS BEING REPLACED
*>
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
     add      1     to  rrn.
     write    system-record  from  default-record.
*>
     move     spaces  to  final-record.
     add      1       to  rrn.
     write    system-record  from  final-record.
*>
     initialize system-record-4.
     add      1 to rrn.
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
     move     "mp9999" to wsmaps-ser.
     move     wsmaps-ser-xx to maps-ser-xx.
     move     wsmaps-ser-nn to maps-ser-nn.
*>
     display  "Using General  Ledger (Y/N) ? :- [ ]" at 1901  with foreground-color 2.
     display  "Using Purchase Ledger (Y/N) ? :- [ ]" at 2001  with foreground-color 2.
     display  "Using Sales    Ledger (Y/N) ? :- [ ]" at 2101  with foreground-color 2.
     display  "Using Invoicing       (Y/N) ? :- [ ]" at 1941  with foreground-color 2.
     display  "Using Stock Control   (Y/N) ? :- [ ]" at 2041  with foreground-color 2.
     display  "Using Order Entry     (Y/N) ? :- [ ]" at 2141  with foreground-color 2.
*>
     accept   ws-reply at 1935 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "Y"
              move  1  to  level-1     *> G/L
       else
              move zero to level-1
     end-if
     accept   ws-reply at 2035 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "Y"
              move  1  to  level-2     *> P/L
       else
              move zero to level-2
     end-if
     accept   ws-reply at 2135 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "Y"
              move  1  to  level-3     *> S/L
       else
              move zero to level-3
     end-if
     accept   ws-reply at 1975 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "Y"
              move  1  to  full-invoicing   *> Invoicing
       else
              move zero to full-invoicing
     end-if
     accept   ws-reply at 2075 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "Y"
              move  1  to  Level-4     *> Stock
     else
              move zero to Level-4
     end-if
     accept   ws-reply at 2175 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "Y"
              move  1  to  Level-5    *> O/E
     else
              move zero to Level-5
     end-if
     display  "Please confirm (Y/N) :- [ ] " at 2301  with foreground-color 2.
*>
     move     spaces  to  option-list.
     move     1  to  a.
*>
     if       g-l
              string "General " delimited by size into option-list pointer  a.
*>
     if       b-l  and  g-l
              string "/ " delimited by size into option-list pointer  a.
*>
     if       b-l
             string "Purchase " delimited by size into option-list pointer a.
*>
     if       s-l  and  g-l
        or    s-l  and  b-l
              string "/ " delimited by size into option-list pointer a.
*>
     if       s-l
              string "Sales " delimited by size into option-list pointer a.
*>
     if       s-l  and  full-invoicing = 1
              string  "/ Invoicing" delimited by size into option-list pointer a.
*>
     if       Stock
              string "/ Stock " delimited by size into option-list pointer a.
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
              go to level-setup.
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
              display GL009        at 0505 with erase eos highlight
              display GL008        at 1210 with           foreground-color 3 highlight
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
              display GL006        at 0101 with erase eos foreground-color 3
              display Arg-Number   at 0164 with           foreground-color 3
              display GL008        at 1210 with           foreground-color 3 highlight
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
                       display GL007 at 0101  with erase eos foreground-color 3
                       display GL008        at 1210 with           foreground-color 3 highlight
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
*> EXTRAS For General Ledger so that gl080 can process path
*>
     move OS-Delimiter to file-defs-os-delimiter.
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
