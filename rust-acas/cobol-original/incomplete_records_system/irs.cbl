       >>source free
*>**************************************************************
*>                                                             *
*>          System  Menu  and  System  File  Handler           *
*>                                                             *
*>**************************************************************
*>
 identification division.
*>**********************
*>
 program-id.            irs.
*>
*> Author.              Cobol conversion by V B Coen, MBCS
*>                      for Applewood Computers.
*>
*> Security.            Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*> Remarks.             System Menu and System File Maintenance Program.
*>
*> Calls.
*>                      maps04.
*> Changes.
*>
*> 11/07/83 vbc - fix out of memory fault,build in date validation.
*> 25/07/83 vbc - hilite displays where needed.
*> 26/07/83 vbc - test for numeric in date vet routine.
*> 16/09/83 vbc - fix next post = zero.
*> 22/12/83 vbc - zeroise menu-reply before accept, 2 clr bug.
*> 28/12/83 vbc - new progs - irs080,085,090
*> 28/05/84 vbc - hilite display heads.
*> 14/04/85 vbc - fix bug in disp of prog-name in set-up.
*> 05/09/88 vbc - modify for cobol/2.
*> 15/01/09 vbc - start of conversion to open cobol
*> 17/01/09 vbc - moving screens to screen section and adjust
*>                accept/displays.
*> 22/01/09 vbc - Migration to Open Cobol as version 3.
*> 20/02/09 vbc - Update date from todays on entry when dates differ.
*>                Generally added support env's LINES and COLUMNS
*>                within system but not needed for this module.
*> 22/02/09 vbc - Changed names of Account fixup  and Posting amaendment
*>                Programs to better reflect what they do.
*> 25/02/09 vbc - Support for OS type by asking user as no mechanism exists to
*>                obtain by Cobol code, Call backup script after getting 'X'
*>                if script found in current directory or ~/bin. Few more
*>                very minor bugs cleared.
*>                Changed progs, specs & manual to match.
*> 01/03/09 vbc - Transferred all code changes to commercial versions incl.
*>                MySQL and Oracle multi client/company versions.
*>                Include rewrite Final accounts into OOo exports for
*>                Company House and HMRC etc with all notes. Amend docs.
*> 14/09/10 vbc - Added Cob Env variables presets.
*> 21/09/10 vbc - .16 added test for Mac OSX
*>                    added print spool name processing.
*> 02/10/11 vbc - .17 Changed to Cbl-File-Details year to xx for OC v2.
*> 21/11/11 vbc - .18 Initialise system-record on system setup & add prelim code
*>                    for processing ACAS-IRS env variable but more needs to be done.
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
 environment division.
*>*******************
*>
 copy "envdiv.cob".
 data division.
*>************
*>
 working-storage section.
*>----------------------
 77  Prog-Name                   pic x(14) value "IRS (3.01.18)".
 77  Call-Prog                   pic x(6)  value spaces.
 77  Batch-Text                  pic x(28) value spaces.
 77  Script-Name                 pic x(20) value spaces.
 77  Run-Backup                  pic x(80) value spaces.
 77  OS-Delimiter                pic x     value "/".                    *> Not yet utilised
 77  ACAS_IRS                    pic x(256) value spaces.                *> Not yet utilised
*>
 01  Backup-Sw                   pic 9     value zero.
     88  Backup-Script-Found               value 1.
 01  Linux-Backup-Script-Name    pic x(20) value "irsbakup.sh".
 01  Windows-Backup-Script-Name  pic x(20) value "irsbakup.bat".
 01  OS2-Backup-Script-Name      pic x(20) value "irsbakup.cmd".
 01  Exit-To-System              pic x(18) value "to Linux".
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
 01  Test-Spool-Name.
     03  Spool-Test          pic x.
         88  Spool-Valid            values "A" thru "Z" "a" thru "z" "0" thru "9".
     03  filler              pic x(31).
*>
*> the following for oc and screen
*>
 01  All-My-Constants        pic 9(4).
 copy "screenio.cpy".
*>
 01  maps03-ws.
     03  u-date          pic x(8).
     03  filler  redefines  u-date.
         05  u-days      pic 99.
         05  filler      pic x.
         05  u-month     pic 99.
         05  filler      pic x.
         05  u-year      pic 99.
     03  u-bin           pic s9(5)    usage comp.
*>
 01  maps03b-ws.
     03  u-date2         pic x(10).
     03  filler  redefines  u-date2.
         05  u-days2     pic 99.
         05  filler      pic x.
         05  u-month2    pic 99.
         05  filler      pic x.
         05  u-year2     pic 9999.
     03  u-bin2          binary-long.
*>
 01  maps03c-ws.
     03  u-date3.
         05  u-year3     pic 99.
         05  u-month3    pic 99.
         05  u-days3     pic 99.
 01  maps03e-ws.
     03  u-dd            pic 99.
     03  filler          pic x   value "/".
     03  u-mm            pic 99.
     03  filler          pic x   value "/".
     03  u-yy            pic 99.
*>
 01  date-fields.
     03  q               pic s99     comp  value zero.
*>
     03  days-in-month   pic x(24)  value "312831303130313130313031".
     03  filler  redefines  days-in-month.
         05  days        pic 99     occurs 12.
*>
     03  ws-work1        pic s9(5)   comp.
     03  ws-work2        pic s9(5)   comp.
*>
 copy "wsfnctn.cob".
*>
 01  filler.
     03  ws-pass         pic x(4)   value spaces.
     03  ws-date-error   pic x(10)  value "Date error".
     03  ws-spaces       pic x(10)  value spaces.
     03  menu-reply      pic x      value space.
     03  wsfile          pic x(12).
*>
 copy "wssystem.cob".
*>
 01  data-files.
     03  filler          pic x(9)     value "acnts.dat".
     03  filler          pic x(10)    value "system.dat".
     03  filler          pic x(08)    value "dflt.dat".
     03  filler          pic x(08)    value "post.dat".
     03  filler          pic x(12)    value "prn".
     03  filler          pic x        value space.
     03  op-system       pic 9.
         88  valid-os-type            values 1 2 3 4 5 6.
         88  No-OS                    value zero.
         88  Dos                      value 1.
         88  Windows                  value 2.
         88  Mac                      value 3.
         88  Os2                      value 4.
         88  Unix                     value 5.
         88  Linux                    value 6.
*>
 01  resulta             pic 99       value zero.
     88  Success                      value '00'.
     88  Success_Duplicate            value '02'.
     88  Success_Incomplete           value '04'.
     88  Success_Optional             value '05'.
     88  Success_No_Unit              value '07'.
     88  End_of_File                  value '10'.
     88  Out_of_Key_Range             value '14'.
     88  Key_Invalid                  value '21'.
     88  Key_Exists                   value '22'.
     88  Key_Not_Exists               value '23'.
     88  Permanent_Error              value '30'.
     88  Inconsistent_Filename        value '31'.
     88  Boundary_Violation           value '34'.
     88  Not_Exists                   value '35'.
     88  Permission_Denied            value '37'.
     88  Closed_with_Lock             value '38'.
     88  Conflict_Attribute           value '39'.
     88  Already_Open                 value '41'.
     88  Not_Open                     value '42'.
     88  Read_not_Done                value '43'.
     88  Record_Overflow              value '44'.
     88  Read_Error                   value '46'.
     88  Input_Denied                 value '47'.
     88  Output_Denied                value '48'.
     88  I_O_Denied                   value '49'.
     88  Record_Locked                value '51'.
     88  I_O_Linage                   value '57'.
     88  File_Sharing                 value '61'.
     88  Not_Available                value '91'.
*>
 screen section.
*>-------------
*>
 01  Menu-Screen-1                                       background-color cob-color-black
                                                         foreground-color cob-color-green.
     03  pic x(14) from prog-name          line 1 col 1     blank screen.
     03  value "S Y S T E M   M E N U"     line 1 col 31 foreground-color cob-color-white
                                                         background-color cob-color-blue
                                                                  reverse-video.
     03  pic x(8) from run-date            line 1 col 73.
     03  value "Client -"                  line 3 col 1.
     03  pic x(29) from client             line 3 col 10 foreground-color cob-color-cyan.
     03  value "Start date -"              line 3 col 39.
     03  pic x(8) from start-date          line 3 col 52 foreground-color cob-color-cyan.
     03  value "End date -"                line 3 col 62.
     03  pic x(8) from end-date            line 3 col 73 foreground-color cob-color-cyan.
     03  value "Select the required function    ["
                                           line 5 col 1.
     03  pic x using menu-reply  auto      line 5 col 34 foreground-color cob-color-yellow.
     03  value "]"                         line 5 col 35.
     03  value "(1)  System Set-Up & Maintenance"   line  7 col 6.
     03  value "(2)  Accounts Set-Up & Maintenance" line  8 col 6.
     03  value "(3)  Default A/Cs Set-Up & Maintenance"
                                           line  9 col 6.
     03  value "(4)  Posting"              line 10 col 6.
     03  value "(5)  Trial Balance"        line 11 col 6.
     03  value "(6)  Audit Trail"          line 12 col 6.
     03  value "(7)  Accounts Production"  line 13 col 6.
     03  value "(8)  Posting Amendments"   line 14 col 6.
     03  value "(9)  Analysis Report"      line 15 col 6.
     03  value "(A)  Nominal File Fix up"  line 16 col 6.
     03  value "(X)  Exit"                 line 20 col 6.
     03  pic x(18) from Exit-To-System     line 20 col 16.
     03  pic x(28) from Batch-Text         line 20 col 41 foreground-color 3.
     03  value "F1 to F10 = options 1 to A;  Return to Accept " &
             "data;   Escape to quit"      line 23 col 1
                                                highlight foreground-color cob-color-white.
*>
 01  Menu-Screen-2                                        background-color cob-color-black
                                                          foreground-color cob-color-green.
     03  pic x(14) from prog-name          line  1 col 1   blank screen.
     03  value "SYSTEM FILE SET-UP"        line  1 col 32 foreground-color cob-color-white
                                                          background-color cob-color-blue
                                                                 reverse-video.
     03  pic x(8) from run-date            line  1 col 73.
     03  value "Date - {"                  line  4 col  6.
     03  pic x(8)  using run-date          line  4 col 14 foreground-color cob-color-yellow.
     03  value "}"                         line  4 col 22.
     03  value "Pass Word - {"             line  4 col 46.
     03  pic x(4)  using ws-pass  secure   line  4 col 59 foreground-color cob-color-yellow.
     03  value "}"                         line  4 col 63.
*>
 01  Menu-Screen-3                                        background-color cob-color-black
                                                          foreground-color cob-color-green.
*>
*> this overlays screen-2 as screen2 has the password that has to
*>    be processed before this screen
*>
     03  value "User - ["                  line  6 col  6.
     03  pic x(24) using suser             line  6 col 14 foreground-color cob-color-yellow.
     03  value "]"                         line  6 col 38.
     03  value "VAT Rate  - ["             line  6 col 46.
     03  pic 99v99  using vat              line  6 col 59 foreground-color cob-color-yellow.
     03  value "]"                         line  6 col 63.
     03  value "Client        Name - ["    line  8 col  6.
     03  pic x(24) using client            line  8 col 28 foreground-color cob-color-yellow.
     03  value "]"                         line  8 col 52.
     03  value "Addr - ["                  line  9 col 20.
     03  pic x(24) using address-1         line  9 col 28 foreground-color cob-color-yellow.
     03  value "]"                         line  9 col 52.
     03  value "["                         line 10 col 27.
     03  pic x(24) using address-2         line 10 col 28 foreground-color cob-color-yellow.
     03  value "]"                         line 10 col 52.
     03  value "["                         line 11 col 27.
     03  pic x(24) using address-3         line 11 col 28 foreground-color cob-color-yellow.
     03  value "]"                         line 11 col 52.
     03  value "["                         line 12 col 27.
     03  pic x(24) using address-4         line 12 col 28 foreground-color cob-color-yellow.
     03  value "]"                         line 12 col 52.
     03  value "Period"                    line 14 col 6.
     03  value "Start Date - ["            line 14 col 20.
     03  pic x(8) using start-date         line 14 col 34 foreground-color cob-color-yellow.
     03  value "]"                         line 14 col 42.
     03  value "End   Date - ["            line 15 col 20.
     03  pic x(8) using end-date           line 15 col 34 foreground-color cob-color-yellow.
     03  value "]"                         line 15 col 42.
     03  value "Operating System "         line 17 col 02.
     03  value "- ["                       line 17 col 20.
     03  using op-system  pic 9            line 17 col 23 foreground-color cob-color-yellow.
     03  value "]"                         line 17 col 24.
     03  from exit-to-system(3:10) pic x(10) line 17 col 26.
     03  value "(1=Dos, 2=Windows, 3=Mac OS/10," &
          " 4=OS/2, 5=Unix, 6=Linux)"      line 18 col 02.
     03  value "Cups Spool Name - ["       line 20 col 02.
     03  using Print-Spool-Name pic x(32)  line 20 col 21.
     03  value "]"                         line 20 col 53.
*>
     03  value "Escape to quit;  Tab for next field  Ret. to Accept data"
                                           line 23 col  1 foreground-color cob-color-white
                                                                      highlight.
*>
 procedure division.
*>*****************
*>
 main section.
*>***********
*>
*> first get Date & User Information
*>
*>
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
*>
     initialize system-record.
     move     "system.dat"  to  fn-2.
     move     3  to  file-function.
     call     "irsub2" using system-record file-access.
     if       we-error = 1
              move zero to  next-post
              accept u-date3  from date
              move   u-year3  to u-yy
              move   u-month3 to u-mm
              move   u-days3  to u-dd
              move  maps03e-ws to run-date
              perform set-up.
     move     system-files to data-files.
     move     Print-Spool-Name to Test-Spool-Name.
     if       not Spool-Valid    *> A-Z a-z 0-9 = updating old system record layout
              move spaces to Print-Spool-Name
              perform set-up
     end-if
     if       op-system = 1
              move "to Dos" to Exit-To-System
     else  if op-system = 2
              move "to Windows" to Exit-To-System
     else  if op-system = 3
              move "to Mac OS/X" to Exit-To-System
     else  if op-system = 4
              move "to OS/2" to Exit-To-System
     else  if op-system = 5
              move "to Unix" to Exit-To-System
     else  if op-system = 6
              move "to Linux" to Exit-To-System
     else     move "to Unknown System" to Exit-To-System.  *> should never happen
*>
     accept   u-date3  from date.
     move     u-year3  to u-yy.
     move     u-month3 to u-mm.
     move     u-days3  to u-dd.
     if       maps03e-ws not = run-date
              move  maps03e-ws to run-date
              perform set-up
     end-if
     if       Dos or Windows
              move Windows-Backup-Script-Name to Script-Name
     else if  OS2
              move OS2-Backup-Script-Name to Script-Name
     else if  Linux or Unix or Mac
              move Linux-Backup-Script-Name to Script-Name
     end-if
     call     "CBL_CHECK_FILE_EXIST" using Script-Name Cbl-File-Details
     end-call
     if       Return-Code not = zero
              move "Back Up Script Not Found" to Batch-Text
     else
              move 1 to Backup-Sw
              string "Using " delimited by size Script-Name delimited by space into Batch-Text
     end-if.
     perform  Get-Env-Set-Files.  *> if we use this we need to get the info to the irsub's routines !!!!
*>
 main-loop.
*>--------
     move     space to menu-reply.
     display  Menu-Screen-1.
     accept   Menu-Screen-1.
     if       menu-reply = "1" or Cob-Crt-Status = Cob-Scr-F1
              perform  set-up
              go to main-loop.
     if       menu-reply = "2" or Cob-Crt-Status = Cob-Scr-F2
              call   "irs010" using system-record
              end-call
              go to main-loop.
     if       menu-reply = "3" or Cob-Crt-Status = Cob-Scr-F3
              call   "irs020" using system-record
              end-call
              go to main-loop.
     if       menu-reply = "4" or Cob-Crt-Status = Cob-Scr-F4
              call   "irs030" using system-record
              end-call
              go to main-loop.
     if       menu-reply = "5" or Cob-Crt-Status = Cob-Scr-F5
              call   "irs040" using system-record
              end-call
              go to main-loop.
     if       menu-reply = "6" or Cob-Crt-Status = Cob-Scr-F6
              call   "irs050" using system-record
              end-call
              go to main-loop.
     if       menu-reply = "7" or Cob-Crt-Status = Cob-Scr-F7
              call   "irs065" using system-record
              end-call
              call   "irs060" using system-record
              end-call
              go to main-loop.
     if       menu-reply = "8" or Cob-Crt-Status = Cob-Scr-F8
              call   "irs070" using system-record
              end-call
              go to main-loop.
     if       menu-reply = "9" or Cob-Crt-Status = Cob-Scr-F9
              call   "irs085" using system-record
              end-call
              call "irs090" using system-record
              end-call
              go to main-loop.
*> allows call to another cobol module during testing
     if       menu-reply = "|"
              move  spaces to call-prog     *> should remove this
              accept call-prog at 0101
              call call-prog using system-record
              end-call
              go to main-loop.
     if       menu-reply = "a" or "A"
           or Cob-Crt-Status = Cob-Scr-F10
              call "irs080" using system-record
              end-call
              go to main-loop.
     if       menu-reply not = "X" and not = "x"
              and Cob-Crt-Status not = Cob-Scr-Esc
              go to main-loop.
 eoj.
     move     5 to file-function.
     call     "irsub2" using system-record file-access
     move     2 to file-function.
     call     "irsub2" using system-record file-access
     if       not Backup-Script-Found
              stop run.
*>
     if       Linux or Unix or Mac
              string "nohup " delimited by size
                      Script-Name delimited by space
                      " 0</dev/null &>/dev/null &" delimited by size into Run-Backup
              end-string
     else
      if      Dos or Windows
              move Script-Name to Run-Backup
      else
       if     OS2
              move Script-Name to Run-Backup.
     call     "SYSTEM" using Run-Backup.
     stop     run.
*>
 maps03.
*>*****
*>
     call     "maps04"  using  maps03b-ws.
*>
 set-up section.
*>-------------
     display  Menu-Screen-2.
*>
 get-run-date.
*>
     accept   run-date at 0414 with update foreground-color cob-color-yellow.
     if       Cob-Crt-Status = Cob-Scr-Esc
              go to main-exit.
     move     run-date to u-date.
     perform  date-validate.
     if       u-bin = zero
              display ws-date-error at 0424 with foreground-color 4
              go to get-run-date.
     display  ws-spaces at 0424.
     move     u-date to run-date.
*>
     move     spaces to ws-pass.
     accept   ws-pass at 0459 with secure.
     if       Cob-Crt-Status = Cob-Scr-Esc
              go to main-exit.
     if       ws-pass not = pass-word
              go to  main-exit.
     display  "New " at 0465 with blink foreground-color 3.
     accept   pass-word at 0459 with update secure.
     if       Cob-Crt-Status = Cob-Scr-Esc
              go to main-exit.
     display  "    " at 0465 with erase eol.
     if       not valid-os-type
              move zero to op-system.
*>
     display  Menu-Screen-3.
     accept   Menu-Screen-3.
*>
 get-startd.
*>*********
     move     start-date to u-date.
     perform  date-validate.
     if       u-bin = zero
              display ws-date-error at 1444 with blink foreground-color 3
              accept  start-date at 1434 with update   foreground-color cob-color-yellow
              end-accept
              go to get-startd.
     display  ws-spaces at 1444.
     move     u-date to start-date.
*>
 get-endd.
*>*******
     move     end-date to u-date.
     perform  date-validate.
     if       u-bin = zero
              display ws-date-error at 1544 with blink foreground-color 3
              accept end-date at 1534       with update foreground-color cob-color-yellow
              end-accept
              go to get-endd.
     display  ws-spaces at 1544.
     move     u-date to end-date.
*>
 get-os.
     if       not valid-os-type
              display "Invalid option" at 1726 with blink foreground-color 3
              accept op-system at 1723         with update foreground-color cob-color-yellow
              end-accept
              go to get-os
     end-if
     if       op-system = 1
              display "DOS" at 1730 with foreground-color 3 blink
     else     if op-system = 2
              display "Windows" at 1730 with foreground-color 3 blink
     else     if op-system = 3
              display "Mac OSX" at 1730 with foreground-color 3 blink
     else     if op-system = 4
              display "OS/2" at 1730 with foreground-color 3 blink
     else     if op-system = 5
              display "Unix" at 1730 with foreground-color 3 blink
     else     if op-system = 6
              display "Linux" at 1730 with foreground-color 3 blink.
*>
     move     data-files  to  system-files.
     move     spaces to system-work-group.
     move     zero to pass-value save-sequ First-Time-Flag.
     if       next-post  not numeric
              move zeros  to  next-post.
     move     5  to  file-function.
     call     "irsub2" using system-record file-access.
     move     spaces  to  ws-pass.
     move     system-files to data-files.
*>
 main-exit.
     exit.
*>
 date-validate section.
*>--------------------
*>
*>************************************************
*> Should revisit this using function date-to-integer ?    *
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
*>          yy = 00 thru 99                      *
*>                                               *
*>************************************************
*>
     move     zero to u-bin q.
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
*>********************************************
*>                                           *
*>                                           *
*>       date validation & conversion        *
*>       ============================        *
*>                                           *
*>                                           *
*>  requires  date input in u-date           *
*>  & returns  date as binary days since     *
*>    01/01/2000  in  u-bin                  *
*>  date errors returned as u-bin equal zero *
*>                                           *
*>********************************************
*>
     move     1     to  ws-work1.
     move     zero  to  ws-work2
                        u-bin.
*>
     if       u-year not = zero
              compute u-bin  = u-year * 365.
*>
     if       u-bin <  zero
              move  zero  to  u-bin
              go to  main-exit.
*>
 pack-loop-1.
*>**********
*>  do leaps
     if       u-year  >  ws-work2
              add  1  to  u-bin
              add  4  to  ws-work2
              go to  pack-loop-1.
*>
     if       u-year = ws-work2
        and   u-month  >  2
              add  1  to  u-bin.
*>
 pack-loop-2.
*>**********

     if       u-month  >  12
              move  zero  to  u-bin
              go to main-exit.
     if       u-month  >  ws-work1
              add  days (ws-work1)  to  u-bin
              add  1  to  ws-work1
              go to pack-loop-2.
*>
     if       u-days  not  >  days (ws-work1)
              add  u-days  to  u-bin
              go to  main-exit.
     if       u-days  equal  29
        and   u-month equal  2
        and   u-year  equal  ws-work2
              add  u-days  to   u-bin
     else
              move  zero  to u-bin.
*>
 main-exit.   exit.
*>********    ****
*>
 Get-Env-Set-Files section.                              *> NOT YET USED
*>************************
*>
     accept   ACAS_IRS from Environment "ACAS_IRS".
*>
     if       ACAS_IRS (1:1) = space
              display "Environment variable not yet set up : ABORTING" at 0505 with erase eos blink
              stop run
     end-if
     if       ACAS_IRS (1:1) = "/"   *> Its Linux/Unix
              move "/" to OS-Delimiter.
     if       ACAS_IRS (1:1) = "\"   *> Its Windoz
              move "\" to OS-Delimiter.
*>     string   ACAS_IRS delimited by space
*>               OS-Delimiter delimited by size
*>                "postings2irs.dat" delimited by size       into PostFileName.
*>
 GESF-Exit.
     Exit     section.
