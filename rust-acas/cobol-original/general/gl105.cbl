       >>source free
*>******************************************
*>                                         *
*>              Ledger Print               *
*>                                         *
*>******************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         gl105.
*>**
*>    author.             V.B.Coen, FBCS,
*>                        Converted For Cis January 85,
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Ledger Print.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     None
*>**
*>    Error messages used.
*>                        GL114
*>                        GL115
*>                        GL118
*>                        GL119
*>**
*> Changes:
*> 28/01/09 vbc - Migration to Open Cobol.
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 07/09/10 vbc - Mod lpr.
*> 21/12/11 vbc - .04 Support for dates other than UK & clean up msgs
*>                    Error msgs to GLnnn,
*>                    Support for path+filenames.
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
     select  archive    assign  arc-out-name
                        access  sequential
                        status  fs-reply
                        organization  line sequential.
*>
 copy "selprint.cob".
 copy "seledger.cob".
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 fd  archive.
*>
 01  arc-trans-record.
     03  arc-batch       pic 9(5).
     03  arc-post        pic 9(5).
     03  arc-code        pic xx.
     03  arc-date        pic x(8).
     03  arc-ac          pic 9(6).
     03  arc-pc          pic 99.
     03  arc-amount      pic s9(8)v99.
     03  arc-legend      pic x(32).
     03  arc-c-ac        pic 9(6).
     03  arc-c-pc        pic 99.
*>
 copy "fdprint.cob".
 copy "fdledger.cob".
*>
 working-storage section.
*>----------------------
*>
 77  prog-name           pic x(15) value "gl105 (3.00.04)".
 77  keyed-reply         pic x      value space.
 77  a                   pic 99     value zero.
 copy "print-spool-command.cob".
 01  filler.
     03  line-cnt        pic 99  comp    value zero.
     03  countx          pic 999         value zero.
     03  sheet           pic 99          value zero.
     03  save-ac         pic 9(6)        value zero.
     03  save-pc         pic 99          value zero.
     03  tot-dr          pic s9(8)v99    value zero.
     03  tot-cr          pic s9(8)v99    value zero.
     03  ac-to-print     pic 9(6)        value zero.
     03  pc-to-print     pic 99          value zero.
     03  ws-reply        pic x           value "N".
*>
 01  Arg-Test            pic x(525)   value spaces.
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
*> Module specific
    03  GL114           pic x(70) value "GL114 Enter <0> to signify change made or <9> to abort this run :- [ ]".
    03  GL115           pic x(48) value "GL115 Ensure Archive USB Memory Stick is in path".
    03  GL118           pic x(19) value "GL118 A/C Not Found".
    03  GL119           pic x(19) value "GL119 P/C Not Found".
*>
 01  arc-out-name        pic x(532)       value "workarc.tmp".
*>
 copy "wsfnctn.cob".
*>
 01  line-1.
     03  l1-prog         pic x(54).
     03  filler          pic x(70)       value "Ledger - Print".
     03  filler          pic x(5)        value "Page ".
     03  l1-page         pic zz9.
*>
 01  line-3.
     03  l3-user         pic x(122).
     03  l3-date         pic x(10).
*>
 01  line-4.
     03  l4-filler       pic x(10)       value "Account - ".
     03  l4-ac           pic zzz9.99.
     03  filler          pic xxx         value " / ".
     03  l4-pc           pic 99bbbb      blank when zero.
     03  l4-ac-name      pic x(98).
     03  filler          pic x(6)        value "Sheet ".
     03  l4-sheet        pic z9.
*>
 01  line-5.
     03  filler          pic x(75)       value
         "Transaction     Code    <--Date-->    <------------Legend------------>     ".
     03  filler          pic x(57)       value
         "<--Contra-->   <--Debit-->   <-Credit-->    <--Balance-->".
*>
 01  line-6.
     03  filler          pic x(75)       value spaces.
     03  filler          pic x(12)       value "Account P.C.".
*>
 01  line-7.
     03  l7-batch        pic zzzz9.
     03  filler          pic x           value "/".
     03  l7-post         pic zzzz9bbbbbb.
     03  l7-code         pic x(7).
     03  l7-date         pic x(14).
     03  l7-legend       pic x(37).
     03  l7-c-ac         pic zzz9.99bb   blank when zero.
     03  l7-c-pc         pic z9bbbb      blank when zero.
     03  l7-debit        pic z(7)9.99    blank when zero.
     03  filler          pic xxx         value spaces.
     03  l7-credit       pic z(7)9.99    blank when zero.
*>
 01  line-8.
     03  filler          pic x(90)       value spaces.
     03  filler          pic x(25)       value "===========   ===========".
*>
 01  line-9.
     03  filler          pic x(75)       value spaces.
     03  filler          pic x(15)       value "B a l a n c e".
     03  l9-debit        pic z(7)9.99bbb.
     03  l9-credit       pic z(7)9.99bbbb.
     03  l9-balance      pic z(7)9.99cr  blank when zero.
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
*>
 77  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 main.
*>---
*>
     move     Print-Spool-Name to PSN.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Ledger Print" at 0135 with foreground-color 2.
     move     prog-name to l1-prog.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
     move     ws-date to l3-date.
     move     usera  to  l3-user.
     display  usera at 0301 with foreground-color 3.
*>
*> its just creating the path/name to the archive
*>
     perform  disk-change.
     display  space at 1201 with erase eos. *> clear from above
*>
     open     input  ledger-file.
*>
     display  "Print All Accounts? (Y/N) [ ]" at 0621 with foreground-color 2.
*>
 get-1.
*>****
*>
     move     "Y" to ws-reply.
     accept   ws-reply at 0648 with foreground-color 3 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "Y"
              go to  get-3.
     if       ws-reply not = "N"
              go to  get-1.
*>
 get-2.
*>****
*>
     display  "Enter Account to print   [     ]" at 0821 with foreground-color 2.
     accept   ac-to-print at 0847 with foreground-color 3 update.
*>
     if       ac-to-print = zero
              go to  get-1.
*>
     move     ac-to-print  to  ledger-nos.
     move     zero         to  ledger-pc.
*>
     read     ledger-file  invalid key
              display GL118 at 0854
              go to  get-2.
*>
     display  space at 0854 with erase eol.
*>
 get-3.
*>****
*>
     move     "Y" to ws-reply.
     display  "Print all P/Cs ?    (Y/N) [ ]" at 1221  with foreground-color 2.
     accept   ws-reply at 1248 with foreground-color 3 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "Y"
              go to  start-run.
*>
     if       ws-reply not = "N"
              go to  get-3.
*>
 get-4.
*>****
*>
     display  "Enter P/C to Print       [     ]" at 1421 with foreground-color 2.
     accept   pc-to-print at 1447 with foreground-color 3 update.
*>
     if       pc-to-print = zero
              go to  get-3.
*>
     if       ac-to-print = zero
              go to  start-run.
*>
     move     pc-to-print  to  ledger-pc.
*>
     read     ledger-file  invalid key
              display GL119 at 1454 with foreground-color 2
              go to  get-4.
*>
     display  space at 1454 with erase eol.
*>
 start-run.
*>********
*>
     open     input  archive.
     open     output print-file.
*>
 loop.
*>***
*>
     read     archive at end
              perform  ac-end
              go to  main-end.
*>
     if       ac-to-print = zero
              go to  by-pass-1st-test.
*>
     if       ac-to-print  <  arc-ac
              go to  loop.
*>
     if       ac-to-print  >  arc-ac
              perform  ac-end
              go to  main-end.
*>
 by-pass-1st-test.
*>***************
*>
     if       pc-to-print = zero
              go to  by-pass-2nd-test.
*>
     if       pc-to-print not = arc-pc
              go to  loop.
*>
 by-pass-2nd-test.
*>***************
*>
     if       save-ac = zero
              perform  new-ac
              go to  by-pass-3rd-test.
*>
     if       arc-ac not = save-ac
           or arc-pc not = save-pc
              perform  ac-end
              perform  new-ac.
*>
 by-pass-3rd-test.
*>***************
*>
     move     arc-batch  to  l7-batch.
     move     arc-post   to  l7-post.
     move     arc-code   to  l7-code.
     move     arc-date   to  l7-date.
     move     arc-legend to  l7-legend.
     divide   arc-c-ac   by  100  giving  l7-c-ac.
     move     arc-c-pc   to  l7-c-pc.
*>
     if       arc-amount  >  zero
              move  arc-amount  to  l7-debit
              move  zero        to  l7-credit
              add   arc-amount  to  tot-dr
     else
              move  arc-amount  to  l7-credit
              move  zero        to  l7-debit
              add   arc-amount  to  tot-cr.
*>
     write    print-record  from  line-7 after 1.
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform  headings.
*>
     go       to loop.
*>
 new-ac.
*>*****
*>
     move     arc-ac  to  ledger-nos.
     move     arc-pc  to  ledger-pc.
*>
     read     ledger-file  invalid key
              move  "***Unknown***" to  ledger-name.
*>
     divide   arc-ac  by  100  giving  l4-ac.
     move     arc-ac  to  save-ac.
     move     arc-pc  to  l4-pc  save-pc.
     move     ledger-name  to  l4-ac-name.
     move     zero  to  sheet.
*>
     perform  headings.
*>
 headings.
*>*******
*>
     add      1  to  countx.
     add      1  to  sheet.
     move     countx to  l1-page.
     move     sheet  to  l4-sheet.
*>
     if       countx not = 1
              write print-record from line-1 after page
              write print-record  from  line-3 after 1
              write print-record  from  line-4 after 1
              move  spaces  to  print-record
              write print-record after 1
     else
              write print-record  from  line-1 before 1
              write print-record  from  line-3 before 1
              write print-record  from  line-4 before 1
     end-if
     write    print-record  from  line-5 after 1.
     write    print-record  from  line-6 after 1.
     move     spaces  to  print-record.
     write    print-record after 1.
     move     7 to line-cnt.
*>
 ac-end.
*>*****
*>
     move     tot-dr  to  l9-debit.
     move     tot-cr  to  l9-credit.
     add      tot-dr  tot-cr  giving  l9-balance.
*>
     write    print-record  from  line-8 after 2.
     write    print-record  from  line-9 after 1.
     write    print-record  from  line-8 after 1.
     move     zero  to  tot-dr  tot-cr.
*>
 main-end.
*>*******
*>
     close    print-file ledger-file archive.
     call     "SYSTEM" using Print-Report.
*>
 main-exit.
*>
     exit     program.
*>
 disk-change  section.
*>-------------------
*>     Copied from gl080
*>     *****************
*>
*> Build path for archive file/s
*>    this set up for testing but need to change to accept
*>     path to usb memory stick (full path) but will work as is
*>       assuming users changes path and the system KNOWS about
*>         the memory stick
*>
*>
*>  This is for the temp file used by gl105 (the Ledger Print)
*>
     move     space to Arg-Test.
     string   file-24        delimited by space
              "archives"     delimited by size
              file-defs-os-delimiter
                             delimited by size
              arc-out-name   delimited by space
                            into Arg-Test.
     move     Arg-Test to arc-out-name.
*>
     display  GL115 at 1201 with erase eol foreground-color 2.
     display  Gl114 at 1301 with erase eol foreground-color 2.
*>
 accept-option.
*>************
*>
     accept   a at 1369.
     if       a = 9
              go to  main-exit.
     if       a  not = zero
              go to  accept-option.
*>
*>  Hopefully can remove these after testing
*>
     display  "Current path is :" at 1401 with foreground-color 2 erase eol.
     display  arc-out-name        at 1501 with foreground-color 2 erase eol.
     accept   arc-out-name        at 1501 with foreground-color 2 update.
     if       arc-out-name (1:1) = space
              go to accept-option.
 main-exit.   exit.
*>********    ****
*>
 zz070-Convert-Date     section.
*>*****************************
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
