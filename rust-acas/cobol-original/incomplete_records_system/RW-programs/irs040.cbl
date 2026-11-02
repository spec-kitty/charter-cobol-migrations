       >>source free
*>*****************************************************************
*>                                                                *
*>                  T r i a l   B a l a n c e                     *
*>                                                                *
*> This module uses the Report Writer function in Gnu COBOL v2.1  *
*>        the one without RW is called irs040-non-rw.cbl          *
*>*****************************************************************
*>
 identification division.
*>***********************
*>
      program-id.       irs040.
*>
*>    author.           Cobol conversion by Vincent B Coen, FBCS 23/10/82
*>                      for Applewood Computers.
*>
*>
*>    Security.         Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*>    remarks.          Trial Balance Display / Print.
*>
*>    version.          see prog-name in ws.
*>
*>    calls.            irsub1
*>
*>    changes.
*> 25/03/83 vbc - Fix clear screen after display of balance 001110.
*> 25/07/83 vbc - Fix print err,preset accept data to zero.
*> 28/05/84 vbc - Hilite display heads.
*> 14/04/85 vbc - Change print to 79 chars.
*> 26/09/89 vbc - Mods for cobol/2.
*> 22/01/09 vbc - Migration to Open Cobol as version 3
*> 15/02/09 vbc - Cosmetic bugs on accept.
*> 21/02/09 vbc - Added support for env's LINES and COLUMNS as needed.
*> 23/02/09 vbc - Rewritten code for handling Summary display & reports
*>                as original lost and was very broken. Now added into
*>                to the Open Source version.
*>                Print and Display very duplicated but left as is, as it
*>                makes it more readable than removal.
*>             >> If a count appears on the total print line at far left it
*>                means there is a logic errror. also shows for display to
*>                right of 'hit return for menu' <<<
*> 21/09/10 vbc - Added print spool.
*>                .12 fix for portrait printing
*> 17/12/13 vbc - .63 Rewritten for GNU Cobol Report Writer functions in V2.1.
*>                     LATEST version without rw is called irs040-non-rw but 
*>                          check version number (just in case).
*>                    A bit of a cheat as rw data taken from original data lines
*>                    that are used for displaying the results as original code.
*> 18/12/13 vbc - .13 Build Renumbered less 50 after testing.
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
*>*******************
*>
 copy  "envdiv.cob".
*>
 input-output section.
 file-control.
*>
     select  print-file     assign "prt-1"
                            organization line sequential.
*>
 data division.
 file section.
*>   				USES 80 cc prints
 fd  print-file
     report Trial-Balance-Report.
*>
 working-storage section.
*>
 77  prog-name           pic x(16)  value "irs040 (3.01.13)".
 copy "print-spool-command-p.cob".
 01  filler.
     03  ws-env-lines    pic 999       value zero.
     03  ws-lines        binary-char unsigned value zero.
     03  ws-show-lines   binary-char unsigned value zero.
     03  ws-22-lines     binary-char unsigned value zero.
     03  ws-accept-lines binary-char unsigned value zero.
*>
     03  output-reply    pic x.
     03  output-reply2   pic x.
     03  ws-reply        pic x.
     03  tipe            pic x          value "D".
         88  summary          value  "S".
         88  detaile          value  "D".
     03  empty           PIC X          value space.
         88  do-print         value  "Y".
         88  nodo-print       value  "N".
     03  counter         pic 99         value zero.
     03  total-dr        pic s9(7)v99   value zero.
     03  total-cr        pic s9(7)v99   value zero.
     03  sub-dr          pic s9(7)v99   value zero.
     03  sub-cr          pic s9(7)v99   value zero.
     03  work-dr         pic s9(7)v99   value zero.
     03  work-cr         pic s9(7)v99   value zero.
     03  main-cr         pic s9(7)v99 comp value zero.
     03  main-dr         pic s9(7)v99 comp value zero.
     03  main-ac         pic 9(5)       value zero.
     03  main-name       pic x(24)      value space.
     03  ws-sub-not      pic 9(4)       value zero.
     03  rstats          pic 9          value zero.
     03  flag            pic 9          value zero.
     03  line-cnt        pic 99   comp  value 99.
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
 copy "wsnl.cob".
 copy "wsfnctn.cob".
 01  filler.
     03  line-1.
       04  Line-1A.
         05  p-user      pic x(24).
         05  filler      pic x(5)     value spaces.
         05  p-report    pic x(8).
         05  l1-a        pic x(13)    value "Trial Balance".
         05  filler      pic x(6)     value spaces.
         05  p-date      pic x(8).
         05  filler      pic x(7)     value spaces.
         05  l1-b        pic x(5)     value "Page ".
       04  Line-1B.
         05  p-page      pic zz9.
     03  line-3.
         05  p-client    pic x(24).
         05  l3-a        pic x(17)    value "    Start Date - ".
         05  p-start     pic x(8).
         05  l3-b        pic x(22)    value "           End Date - ".
         05  p-end       pic x(8).
     03  line-4.
         05  l4-a        pic x(37)    value " Account     ----------Name----------".
         05  filler      pic x(19)    value "   Type".
         05  l4-b        pic x(24)    value "   --Debit--   --Credit-".
     03  line-5.
         05  filler      pic x        value space.
         05  p-account   pic zzzz9     blank when zero.
         05  filler      pic x(6)     value spaces.
         05  p-name      pic x(24).
         05  filler      pic x(4)     value spaces.
         05  p-legend    pic x(16).
         05  p-debit     pic z(8)9.99  blank when zero.
         05  p-credit    pic z(8)9.99  blank when zero.
     03  line-6.
         05  filler      pic x(57)    value spaces.
         05  l6-a        pic x(23)    value "=========== ===========".
     03  line-7.
         05  filler.
             07  l7-errcnt pic zzzz      blank when zero.
             07  filler  pic x(37)    value spaces.
         05  l7-a        pic x(15)    value "T o t a l      ".
         05  t-debit     pic z(8)9.99.
         05  t-credit    pic z(8)9.99.
*>
 linkage section.
*>---------------
*>
 copy  "wssystem.cob".
*>
 report section.
*>**************
*>
 rd  Trial-Balance-Report
     control is final
     page limit is 75
     heading 1
     first detail 7
     last  detail 75.
*>
 01  Report-Head-Group type page heading.
     03  line 1.
         05  col  1      pic x(76)     source Line-1A.
         05  col 77      pic zz9       source Page-Counter.
     03  line + 2.
         05  col  1      pic x(79)     source Line-3.
     03  line + 2.
         05  col  1      pic x(80)     source Line-4.
*>
 01  Trial-Balance-Detail type detail.
     03  line plus 1.
         05  col  1      pic x(80)     source Line-5.
*>
 01  type control footing final.
     03  line + 3.
         05  col  1      pic x(80)     source Line-6.
*>     
     03  line + 1.
         05  col  1      pic x(80)     source Line-7.
*>
     03  line + 1.
         05  col  1      pic x(80)     source Line-6.

*>
 procedure division using system-record.
*>**************************************
*>
 init01 section.
*>**************
*>
*> first get date & user information..
*>
     move     system-files to file-names.
     accept   ws-env-lines   from lines.
     if       ws-env-lines < 24
              move  24 to ws-env-lines ws-lines
     else
              move  ws-env-lines   to ws-lines
     end-if
     subtract 1 from ws-lines giving ws-accept-lines.
     subtract 2 from ws-lines giving ws-22-lines.
     subtract 3 from ws-lines giving ws-show-lines.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name to PSN.
*>
 run-loop.
*>--------
*>
     move     zero  to  total-dr  total-cr ws-sub-not.
     display  " "             at 0101 with erase eos.
     display  prog-name       at 0101 with foreground-color 2.
     display  "Trial Balance" at 0131 with foreground-color 1 background-color 7.
     display  run-date        at 0173 with foreground-color 2.
*>
     display  "Summary or Detail <S> or <D>......[ ]" AT 0501 with foreground-color 2.
     display  "Zero balances to Print (Y/N)......[ ]" at 0701 with foreground-color 2.
     display  "Press <Return> to exit"                at 0741 with foreground-color 2.
     display  "Display or Print  <D> or <P>......[ ]" at 0901 with foreground-color 2.
*>
     move     spaces to output-reply2.
     accept   output-reply2  at 0536 with auto.
     move     function upper-case (output-reply2) to tipe.
     if       tipe = space
              go to main01-exit.
     if       not summary and not detaile
              go to run-loop.
     if       summary
              move  "Summary" to p-report
     else
              move  "Detail " to p-report.
*>
 ask-zero-bal.
     move     spaces to output-reply2.
     accept   output-reply2 at 0736 with auto.
     move     function upper-case (output-reply2) to empty.
     if       empty = space
              go to main01-exit.
     if       not do-print and not nodo-print
              go to ask-zero-bal.
*>
 output-select.
     move     spaces to output-reply2.
     accept   output-reply2 at 0936 with auto.
     move     function upper-case (output-reply2) to output-reply.
     if       output-reply not = "D" and not = "P"
              go to  output-select.
     move     suser      to p-user.
     move     client     to p-client.
     move     start-date to p-start.
     move     end-date   to p-end.
     move     run-date   to p-date.
     move     zero       to main-cr main-dr main-ac ws-sub-not.
     move     spaces     to main-name.
     if       output-reply = "D"
              go to  display-tb.
     if       output-reply = "P"
              go to  print-tb.
*>
*>------------------------------------------------------
*>                      Procedures
*>------------------------------------------------------
*>
 display-tb.
     move     1  to  file-function access-type.
     call     "irsub1"  using  nl-record file-access.
     move     zero to total-cr total-dr counter.
     move     1 to p-page.
*>
 disp-head-1.
     display  line-1         at 0101 with foreground-color 2 erase eos.
     display  p-report       at 0130 with foreground-color 1 background-color 7.
     display  l1-a           at 0138 with foreground-color 1 background-color 7.
     display  line-3         at 0301 with foreground-color 3.
     display  "Start Date -" at 0329 with foreground-color 2.
     display  "End Date -"   at 0361 with foreground-color 2.
     display  line-4         at 0501 with foreground-color 2.
     display  "Enter <N> for next screen <X> to exit....[ ]"
                                at line ws-lines col 01 with foreground-color 2.
*>
 disp-head-end.
     move     6 to lin.
     move     zero to flag.
     add      1 to counter.
*>
 main-loop.
     if       we-error = 3
              go to total-display.
     perform  get-record.
     move     spaces to line-5.
     if       we-error = 3
              move zero to nl-owning nl-cr nl-dr
     end-if
     if       we-error = 3
         and  not summary
              go to total-display.
*>
     if       not summary
              go to its-not-summary.
*>
     if       nl-sub-nominal = zero       *> we have a main a/c
              perform
                   if    main-ac = zero   *> only for 1st nl record
                         exit perform
                   end-if
                   if    main-dr = main-cr and not do-print
                         exit perform
                   end-if
                   if    main-dr > main-cr
                         subtract main-cr from main-dr giving work-dr
                         move work-dr to p-debit
                         move zero to p-credit work-cr
                         add  work-dr  to  total-dr
                   else
                         subtract main-dr from main-cr giving work-cr
                         move work-cr to p-credit
                         move zero to p-debit work-dr
                         add  work-cr  to  total-cr
                   end-if
                   move  "Main" to p-legend
                   move  main-ac        to p-account
                   move  main-name      to p-name
                   move  nl-owning to main-ac
                   move  nl-name   to main-name
                   move  nl-dr     to main-dr
                   move  nl-cr     to main-cr
                   go to main-display-1
              end-perform
              move nl-owning to main-ac
              move nl-dr     to main-dr
              move nl-cr     to main-cr
              move nl-name   to main-name
              go to main-loop
     end-if
*>
     if       nl-sub-nominal not = zero
         and  nl-owning = main-ac
              add nl-dr to main-dr
              add nl-cr to main-cr
              go to main-loop.
*>
     if       nl-sub-nominal not = zero
              add nl-dr to main-dr
              add nl-cr to main-cr
              add 1 to ws-sub-not
              go to main-loop.
*>
 its-not-summary.
     if       nl-dr = nl-cr and not do-print
              go to main-loop.
*>
     if       nl-dr > nl-cr
              subtract  nl-cr from nl-dr giving work-dr
              move work-dr to p-debit
              move zero to p-credit work-cr
              add  work-dr  to  total-dr
     else
              subtract nl-dr from nl-cr giving work-cr
              move work-cr to p-credit
              move zero to p-debit work-dr
              add  work-cr  to  total-cr
     end-if
     if       nl-sub-nominal = zero
              move "Main" to p-legend
              move nl-owning to p-account
     else
              move "Sub"  to p-legend
              move nl-sub-nominal to p-account
     end-if
     move     nl-name to p-name.
*>
 main-display-1.
     move     1 to cole.
     display  line-5 at curs with foreground-color 3.
     move     zero  to  nl-dr nl-cr sub-dr sub-cr.
     if       we-error = 3
              go to  total-display.
     add      1  to  lin.
     if       lin  < ws-show-lines
              go to  main-loop.
     move     6  to  lin.
     accept   output-reply2 at line ws-lines col 43 with auto.
     move     function upper-case (output-reply2) to ws-reply.
     if       ws-reply = "X"
              move 2  to  file-function
              call "irsub1" using nl-record file-access
              go to  run-loop.
*>
 screen-clear.
     move     spaces to ws-reply.
     add      1 to counter.
     move     counter to p-page.
     perform  disp-head-1.
     go to    main-loop.
*>
 total-display.
     display  line-6 at line ws-show-lines col 01 with foreground-color 2.
     move     total-dr to t-debit.
     move     total-cr to t-credit.
     display  line-7 at line ws-22-lines col 01 with foreground-color 3.
     display  line-6 at line ws-accept-lines col 01 with foreground-color 2.
     display  " " at line ws-lines col 01 with erase eol.
     display  "Press Return for menu" at line ws-lines col 01 with foreground-color 2.
     if       ws-sub-not not = zero
              display ws-sub-not at line ws-lines col 26 with foreground-color 3 highlight.
     accept   ws-reply at line ws-lines col 23.
     move     2  to  file-function.
     call     "irsub1"  using  nl-record file-access.
     go to    run-loop.
*>
 print-tb.
     display  " " at 0101 with erase eos.
     perform  print-tb-1 thru print-tb-exit.
     go to    run-loop.
*>
 print-tb-1.
     move     zero to total-cr total-dr.
     open     output  print-file.
     initiate Trial-Balance-Report.
     move     zero  to  flag  rstats.
     move     1  to  file-function access-type.
     call     "irsub1"  using  nl-record file-access.
*>
 main-loop-p.
     if       we-error = 3
              go to main-end.
     perform  get-record.
     move     spaces to line-5.
     if       we-error = 3
              move zero to nl-owning nl-cr nl-dr
     end-if
     if       we-error = 3
         and  not summary
              go to main-end
     end-if
     if       not summary
              go to p-its-not-summary.
*>
     if       nl-sub-nominal = zero        *> we hame a main a/c
              perform
                   if    main-ac = zero    *> only for 1st nl record
                         exit perform
                   end-if
                   if    main-dr = main-cr and not do-print
                         exit perform
                   end-if
                   if    main-dr > main-cr
                         subtract main-cr from main-dr giving work-dr
                         move work-dr to p-debit
                         move zero to p-credit work-cr
                         add  work-dr  to  total-dr
                   else
                         subtract main-dr from main-cr giving work-cr
                         move work-cr to p-credit
                         move zero to p-debit work-dr
                         add  work-cr  to  total-cr
                   end-if
                   move  "Main" to p-legend
                   move  main-ac        to p-account
                   move  main-name      to p-name
                   move  nl-owning to main-ac
                   move  nl-name   to main-name
                   move  nl-dr     to main-dr
                   move  nl-cr     to main-cr
                   go to main-print-1
              end-perform
              move nl-owning to main-ac
              move nl-dr     to main-dr
              move nl-cr     to main-cr
              move nl-name   to main-name
              go to main-loop-p
     end-if
*>
     if       nl-sub-nominal not = zero
         and  nl-owning = main-ac
              add nl-dr to main-dr
              add nl-cr to main-cr
              go to main-loop-p.
*>
     if       nl-sub-nominal not = zero         *> this should not used
              add nl-dr to main-dr
              add nl-cr to main-cr
              add 1 to ws-sub-not               *> but just in case count usage but dont print
              go to main-loop-p.
*>
 p-its-not-summary.
     if       nl-dr  >  nl-cr
              subtract  nl-cr from nl-dr giving work-dr
              move  work-dr to p-debit
              move  zero to p-credit work-cr
              add   work-dr  to  total-dr
     else
              subtract  nl-dr from nl-cr giving work-cr
              move  work-cr to p-credit
              move  zero to p-debit work-dr
              add   work-cr  to  total-cr.
     if       nl-sub-nominal = zero
              move  "Main" to p-legend
              move  nl-owning to p-account
     else
              move  "Sub"  to p-legend
              move  nl-sub-nominal to p-account.
     move     nl-name to p-name.
*>
 main-print-1.
     generate Trial-Balance-Detail.
     move     zero  to  nl-dr nl-cr sub-dr sub-cr.
     if       we-error = 3
              go to  main-end.
     go to    main-loop-p.
*>
 main-end.
     move     total-dr  to  t-debit.
     move     total-cr  to  t-credit.
     if       ws-sub-not not = zero           *> count for a logic error if none zero
              move ws-sub-not to l7-errcnt
     else
              move zero to l7-errcnt
     end-if
     terminate Trial-Balance-Report.
     close    print-file.
     call     "SYSTEM" using Print-Report.
     move     2  to  file-function.
     call     "irsub1"  using  nl-record file-access.
*>
 print-tb-exit.
     exit.
*>
 main01-exit.
     exit     program.
*>
 get-record section.
     move     3  to  file-function.
     call     "irsub1"  using  nl-record file-access.
*>
 main-exit.
     exit.
