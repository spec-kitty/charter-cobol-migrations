       >>source free
*>*****************************************************************
*>                                                                *
*>      F I N A L   A C C O U N T S   P R O D U C T I O N         *
*>                                                                *
*>*****************************************************************

 identification division.
*>************************
*>
 program-id.            irs060.
*>
*> author.              Cobol conversion by Vincent B Coen, FBCS 24/10/82
*>                      for Applewood Ccomputers.
*>
*>Security.             Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*>
*>Remarks.              P&L and Balance Sheet.
*>
*>version.              see prog-name in ws.
*>
*> calls.               irsub3 irsub4 irsub5.
*>
*> changes.
*>  1/7/83  vbc - improve running time, split prog into 2 (irs065)
*>                thru-put increased by 650%.
*>  2/7/83  vbc - tidy up final reports, tb & fa.
*>  8/7/83  vbc - correct date-validate routine, for end of year
*>                 and begining of new year.
*>  9/7/83  vbc - fix end of year processing by adding new routine
*>                pl-capital-ac-tidyup.
*> 13/7/83  vbc - reset save-sequ if changing post file.
*> 20/7/83  vbc - reduce size of nl file.
*> 22/7/83  vbc - fix ratios,fix eop processing.
*> 26/7/83  vbc - rewrite date vet routine.
*> 10/8/83  vbc - validate & reject if ness, p/l account earlier
*>                squash up vat a/c's,ditto code accounts same as
*>                p/l account at end of period processing.
*>  6/9/83  vbc - fix bugs:- dont create otb post rec at eop;
*>                           in pl-capital-ac-tidyup, group add
*>                           all records with same type (ac);
*>                           check otb balance to zero.
*> 26/03/84 vbc - y & p on report request 2 b reversed.
*> 28/05/84 vbc - hilite display heads.
*> 14/04/85 vbc - change print to 79 chars.
*> 26/09/89 vbc - mods for cobol/2.
*> 23/01/09 vbc - Migration to Open Cobol as version 3.
*> 20/02/09 vbc - Centre client in reports.
*> 21/02/09 vbc - Added support for env's LINES and COLUMNS as needed.
*> 21/09/10 vbc - Added print spool.
*>                .11 fix for portrait printing
*> 16/12/13 vbc - .12 Removed security test/password prior to print report.
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
 copy "envdiv.cob".
*>
 input-output section.
 file-control.
*>
     select  nominal-ledger  assign nl-file
                             organization indexed
                             access dynamic
                             record key-1
                             status fs-reply.
*>
     select  work-file       assign "worksort.tmp"
                             organization sequential
                             status fs-reply.
*>
     select  print-file      assign "prt-1"
                             organization line sequential.
*>
 i-o-control.
     same record area for nominal-ledger work-file.
*>
 data division.
 file section.
*>
 fd  work-file.
*>
 01  work-record.
     03  work-key        pic 9(10).
     03  work-type       pic a.
     03  work-data.
         05  work-name   pic x(24).
         05 work-dr      pic 9(8)v99  comp.
         05 work-cr      pic 9(8)v99  comp.
         05 work-dr-last pic 9(8)v99  comp  occurs 4.
         05 work-cr-last pic 9(8)v99  comp  occurs 4.
         05 work-ac      pic a.
    03  filler  redefines work-data.
        05 work-pointer  pic 9(5).
*>
 fd  nominal-ledger.
 copy "fdwsnl.cob".
 fd  print-file.
*>
 01  print-record        pic x(79).
*>
 working-storage section.
 77  prog-name           pic x(16)    value "irs060 (3.01.12)".
 77  fs-reply            pic 99       value zero.
 77  a                   binary-char  value zero.
 77  b                   binary-char  value zero.
 77  ws-client           pic x(24)    value spaces.
 77  Final-Acs-In-Use    pic 9        value zero.  *> 1 if true
 copy "print-spool-command-p.cob".
*>
 01  filler.
     03  w-date.
         05  filler      pic x(6).
         05  w-year      pic 99.
     03  ws-reply        pic x.
     03  total-1         pic s9(8)v99  comp occurs 26.
     03  total-2         pic s9(8)v99  comp occurs 26.
     03  level-11        pic s9(8)v99  comp value zero.
     03  level-12        pic s9(8)v99  comp value zero.
     03  level-21        pic s9(7)v99  comp value zero.
     03  level-22        pic s9(7)v99  comp value zero.
     03  net-1           pic s9(7)v99  comp value zero.
     03  net-2           pic s9(7)v99  comp value zero.
     03  pl-ac           pic 9(5)     value zero.
     03  letters         pic x(26)    value "ABCDEFGHIJKLMNOPQRSTUVWXYZ".
     03  filler  redefines  letters.
         05  ar0         pic x       occurs  26  indexed by  w.
     03  j               pic 9.
     03  y               pic 99.
     03  z               pic 99.
     03  group-level     pic x.
         88  sub-total                value "T".
     03  work-1          pic s9(9)v99  comp value zero.
     03  work-2          pic s9(9)v99  comp value zero.
     03  work-3          pic s9(9)v99  comp value zero.
     03  pl-title        pic x(40).
     03  pl-rep-type     pic x.
     03  pl-rep-type2    pic x.
     03  nl-file         pic x(11).
     03  ws-pass         pic x(4).
     03  ws-hypens       pic x(9)     value "---------".
     03  ws-equals       pic x(9)     value "=========".
     03  ws-ac           pic x        value space.
     03  ws-ac2          pic x        value space.
     03  ac2             pic x.
*>
 01  filler.
     03  line-1.
         05  filler      pic x(28)    value spaces.
         05  l1-client   pic x(24).
         05  filler      pic x(27)    value spaces.
*>
     03  line-2.
         05  filler      pic x(20)    value spaces.
         05  l2-title    pic x(40).
         05  filler      pic x(19)    value spaces.
*>
     03  line-3.
       05  line-3a.
         07  filler      pic x(19).
         07  l3a-t1      pic x(20).
         07  l3a-date1   pic x(8).
         07  l3a-t2      pic xxxx.
         07  l3a-date2   pic x(8).
         07  filler      pic x(20).
       05  line-3b redefines line-3a.
         07  filler      pic x(25).
         07  l3b-t1      pic x(19).
         07  l3b-date    pic x(8).
         07  filler      pic x(27).
*>
     03  line-5.
       05  filler        pic x(34)    value spaces.
       05  l5-grp1b.
         07  l5-g1a      pic x(10)    value "--------20".
         07  l5-year1    pic 99       value zero.
         07  l5-g1c      pic x(8)     value all "-".
       05  l5-grp1 redefines l5-grp1b pic x(20).
       05  filler        pic x(5)     value spaces.
       05  l5-grp2b.
         07  l5-g2a      pic x(10)    value "--------20".
         07  l5-year2    pic 99       value zero.
         07  l5-g2c      pic x(8)     value all "-".
       05  l5-grp2 redefines l5-grp2b pic x(20).
*>
     03  line-7.
       05  filler        pic xx       value spaces.
       05  l7-name       pic x(27).
       05  filler        pic x(5)     value spaces.
       05  l7-sign1      pic x.
       05  l7-value1     pic z(6)9    blank when zero.
       05  l7-sign2      pic x.
       05  filler        pic xx       value spaces.
       05  l7-sign3      pic x.
       05  l7-value2     pic z(6)9    blank when zero.
       05  l7-sign4      pic x.
       05  filler        pic x(5)     value spaces.
       05  l7-sign5      pic x.
       05  l7-value3     pic z(6)9    blank when zero.
       05  l7-sign6      pic x.
       05  filler        pic xx       value spaces.
       05  l7-sign7      pic x.
       05  l7-value4     pic z(6)9    blank when zero.
       05  l7-sign8      pic x.
*>
     03  line-8.
       05  filler        pic x(34)    value spaces.
       05  l8-underline1 pic x(9).
       05  filler        pic x(2)     value spaces.
       05  l8-underline2 pic x(9).
       05  filler        pic x(5)     value spaces.
       05  l8-underline3 pic x(9).
       05  filler        pic x(2)     value spaces.
       05  l8-underline4 pic x(9).
*>
     03  line-9.
       05  l9-name       pic x(34).
       05  l9-sign1      pic x.
       05  l9-value1     pic z(6)9    blank when zero.
       05  l9-sign2      pic x.
       05  filler        pic x(16)    value spaces.
       05  l9-sign3      pic x.
       05  l9-value2     pic z(6)9    blank when zero.
       05  l9-sign4      pic x.
       05  filler        pic x(11)    value spaces.
*>
     03  line-10.
       05  l10-client    pic x(24).
       05  filler        pic x(6)     value spaces.
       05  filler        pic x(23)    value "    Sales Ratios    ".
       05  filler        pic x(18)    value "      Period To - ".
       05  l10-date      pic x(8).
*>
     03  line-11.
       05  l11-name      pic x(24).
       05  l11-ratio     pic zzz9.99.
*>
 copy "wsfinal.cob".
*>
 copy "wsnl.cob".
 copy "wsfnctn.cob".
 copy "wspost.cob".
 copy "wsdflt.cob".
 01  maps03-ws.
     03  u-date          pic x(8).
     03  filler  redefines  u-date.
       05  u-days        pic 99.
       05  filler        pic x.
       05  u-month       pic 99.
       05  filler        pic x.
       05  u-year        pic 99.
     03  u-bin           pic s9(5)    comp.
*>
 01  date-fields.
     03  q                 pic s99    comp  value zero.
*>
     03  days-in-month     pic x(24)  value "312831303130313130313031".
     03  filler  redefines  days-in-month.
       05  days            pic 99     occurs 12.
*>
     03  ws-work1          pic s9(5)   comp.
     03  ws-work2          pic s9(5)   comp.
     03  save-date         pic s9(5)   comp.
*>
 linkage   section.
*>****************
*>
 copy "wssystem.cob".
*>
 procedure division using system-record.
*>**************************************
*>
 init01   section.
*>***************
*>
     move     system-files to file-names.
     move     file-1 to nl-file.
     move     zero to y.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name to PSN.
*>
*> fix up client to justified centre
*>
     move     client to ws-client.
     call     "C$JUSTIFY" using ws-client "C".
*>
 screen-heads.
*>
     display  " " at 0101 with erase eos.
     display  prog-name                   at 0101 with foreground-color 2.
     display  "Final Accounts Production" at 0129 with foreground-color 1 background-color 7.
     display  run-date                    at 0173 with foreground-color 2.
*>
 sh-ends.
*>
*>     display  "Enter pass-word - [****]"  at 0501 with foreground-color 2.
*>     accept   ws-pass at 0520 with secure.
*>     if       ws-pass not = pass-word
*>              go to e-o-p-end.
*>
     perform  varying y from 1 by 1 until y > 26
              move zeros to total-1 (y) total-2 (y)
     end-perform
     move     3  to  file-function.
*>    call     "irsub5"  using  final-record  file-access.
*>
 ml-b.
*>---
*>
     display  "Enter comparative to use (0 to 4) -  [ ]" at 0801 with foreground-color 2.
     accept   j  at 0839 with foreground-color 3.
     if       j  <  0  or  >  4
              go to  ml-b.
*>
*> *** get profit & loss report title ***
*>
     display  "Enter Profit & Loss Report Title     [" at 1001 with foreground-color 2.
     display  "]" at 1079 with foreground-color 2.
     move     "Profit and Loss Report" to pl-title.
     accept   pl-title at 1039 with update foreground-color 3.
*>
 ml-1.
*>---
*>
     display  "Period Report (P) or Year Report (Y) [ ]" at 1201 with foreground-color 2.
     accept   pl-rep-type2 at 1239 with foreground-color 6.
     move     function upper-case (pl-rep-type2) to pl-rep-type.
     if       pl-rep-type not = "P" and not = "Y"
              go to ml-1.
     move     end-date to w-date   l10-date.
     move     w-year   to l5-year1 l5-year2.
     subtract 1  from  l5-year2.
     if       j = zero
              move spaces to l5-grp2.
*>    display  "Give Title 1 - [" at 1301 with foreground-color 2.
*>    display  "]"                at 1337 with foreground-color 2.
*>    display  l5-grp1            at 1317 with foreground-color 3.
*>    accept   l5-grp1            at 1317 with foreground-color 3 update.
*>    if       j not = zero
*>             display "2"        at 1312 with foreground-color 2
*>             display l5-grp2    at 1317 with foreground-color 3
*>             accept  l5-grp2    at 1317 with foreground-color 3 update.
*>
     display  "Checking Accounts Please Wait" at 1601 with foreground-color 2.
     open     input  work-file.
     if       fs-reply  not = zero
              display "failure to open Work File!!!!" at 2401 with foreground-color 2
              display "Hit return for menu" at 2441
              accept ws-reply at 2461
              close work-file
              stop run.
*>
*> ***   this section reads the nominal ledger identifying       ***
*> ***   main accounts only. the grand total for each A/C type   ***
*> ***   & its required comparative are calculated               ***
*>
 read-loop.
*>--------
*>
     read     work-file
              at end  go to  read-end.
*>
     set      w  to  1.
     move     function upper-case (ac) to ac2.
     search   ar0
              when  ar0 (w)  =  ac2
              go to  accumulate.
     display  space.
     display  "Ledgers Incorrectly Coded! Aborting." at 0501 with foreground-color 2.
     display  "ACCOUNT  - " at 0701          with foreground-color 2.
     display  owning at 0713                 with foreground-color 2.
     display  "/" at 0718                    with foreground-color 2.
     display  sub-nominal at 0719            with foreground-color 2.
     display  "Hit return for menu" at 0701
     accept   ws-reply at 0721
     close    work-file.
     stop run.
*>
 accumulate.
*>---------
*>
     if       ac  <  "E"
              perform  cr-total
              go to read-loop.
     if       ac  >  "D"  and  <  "I"
              perform  dr-total
              go to read-loop.
     if       ac  = "I"  or  "J"
              perform  cr-total
              go to read-loop.
     if       ac  >  "J"  and  <  "U"
              perform  dr-total
              go to read-loop.
     if       ac  >  "T"
              perform  cr-total.
     go       to read-loop.
*>
 read-end.
*>-------
*>
     display  "Printing Account Ledgers. Please Wait" at 1601 with foreground-color 2.
     close    work-file.
*>
*> *** This section produces the P & L Report ***
*>
*> *** reopen nominal ledger & open print-file ***
*>
     open     input  work-file.
     open     output  print-file.
*>
*> *** set up title lines ***
*>
     move     pl-title to l2-title.
     call     "C$JUSTIFY" using l2-title "C".
     move     spaces   to line-3.
     if       pl-rep-type = "Y"
              move end-date to l3b-date
              move "For the Year Ended " to l3b-t1
     else
              move "For the Period From " to l3a-t1
              move " to "                 to l3a-t2
              move start-date             to l3a-date1
              move end-date               to l3a-date2.
     move     ws-client to l1-client.
     move     client    to l10-client.
     write    print-record  from  line-1 after 1.
     write    print-record  from  line-2 after 2.
     write    print-record  from  line-3 after 2.
     write    print-record  from  line-5 after 2.
     move     spaces  to  print-record.
     write    print-record after 1.
     move     1  to  y.
     read     work-file at end
              display "PE 005946" at 2401
              display "Hit return for menu" at 2441
              accept ws-reply at 2461
              close work-file
              stop run.
*>
 loop-1.
*>-----
*>
*>  do account types A - D
*>
     perform  line-total.
     add      1  to  y.
     if       y  <  5
              go to  loop-1.
     move     "Total Income"  to  l7-name.
     perform  group-total.
     move     level-11  to  level-21.
     move     level-12  to  level-22.
     move     zero  to  level-11  level-12.
     move     spaces  to  print-record.
     write    print-record after 1.
     move     spaces  to  print-record.
     write    print-record after 1.
*>
 loop-2.
*>-----
*>
*>  do account types E - H
*>
     perform  line-total.
     add      1  to  y.
     if       y  <  9
              go to  loop-2.
     move     "Less Total Direct Costs"  to  l7-name.
     perform  group-total.
     subtract level-11  from  level-21.
     subtract level-12  from  level-22.
     move     level-21  to  level-11.
     move     level-22  to  level-12.
     move     "T"  to  group-level.
     move     "Gross Profit"  to  l7-name.
     move     ws-hypens to l8-underline2.
     if       j > zero
              move ws-hypens to l8-underline4.
     write    print-record from line-8 after 1.
     move     spaces  to  line-8.
     perform  group-total.
     move     zero  to  level-11  level-12.
     move     spaces  to  print-record  group-level.
     write    print-record after 1.
*>
 loop-3.
*>-----
*>
*>  do account types I - J
*>
     perform  line-total.
     add      1  to  y
     if       y  <  11
              go to  loop-3.
     move     "Plus Sundry Income"  to  l7-name.
     perform  group-total.
     add      level-11  to  level-21.
     add      level-12  to  level-22.
     move     spaces  to  print-record.
     write    print-record after 1.
     move     zero  to  level-11  level-12.
     move     spaces  to  print-record.
     write    print-record after 1.
*>
 loop-4.
*>-----
*>
*>  do account types K - N
*>
     perform  line-total.
     add      1  to  y.
     if       y  <  15
              go to  loop-4.
     move     "Less Total Indirect Costs"  to  l7-name.
     perform  group-total.
     subtract level-11  from  level-21.
     subtract level-12  from  level-22.
     move     level-21  to  level-11  net-1.
     move     level-22  to  level-12  net-2.
     move     "T"  to  group-level.
     move     "Net Profit"  to  l7-name.
     move     ws-hypens to l8-underline2.
     if       j > zero
              move ws-hypens to l8-underline4.
     write    print-record from line-8 after 1.
     move     spaces to line-8.
     perform  group-total.
     move     space to  group-level.
     move     zero  to  level-11  level-12
                        level-21  level-22.
     move     ws-equals to l8-underline2.
     if       j > zero
              move ws-equals to l8-underline4.
     write    print-record from line-8 after 1.
     move     spaces to line-8.
*>
*> *** this section produces the balance sheet ***
*>
     write    print-record  from  line-1 after page.
     move     "             Balance Sheet              " to l2-title.
     write    print-record  from  line-2 after 2.
     write    print-record  from  line-3 after 2.
     write    print-record  from  line-5 after 2.
     move     spaces to line-8.
*>
 loop-5.
*>-----
*>
*>  do account types O - Q
*>
     perform  line-total.
     add      1  to  y.
     if       y  <  18
              go to  loop-5.
     move     "Fixed Asset Total"  to  l7-name.
     perform  group-total.
     move     level-11  to  level-21.
     move     level-12  to  level-22.
     move     zero  to  level-11  level-12.
     move     spaces  to  print-record.
     write    print-record after 1.
*>
 loop-6.
*>-----
*>
*>  do account types R - T
*>
     perform  line-total.
     add      1  to  y.
     if       y  <  21
              go to  loop-6.
     move     "Plus Total Current Assets"  to  l7-name.
     perform  group-total.
     add      level-11  to  level-21.
     add      level-12  to  level-22.
     move     level-21  to  level-11.
     move     level-22  to  level-12.
     move     "T"  to  group-level.
     move     "Total Assets"  to  l7-name.
     move     ws-hypens to l8-underline2.
     if       j > zero
              move ws-hypens to l8-underline4.
     write    print-record from line-8 after 1.
     move     spaces to line-8.
     perform  group-total.
     move     zero  to  level-11  level-12.
     move     spaces to print-record  group-level.
     write    print-record after 1.
 loop-8.
*>-----
*>
*>  do account types U - V
*>
     perform  line-total.
     add      1  to  y.
     if       y  <  23
              go to  loop-8.
     move     "Less Current Liabilities"  to  l7-name.
     perform  group-total.
     subtract level-11  from  level-21.
     subtract level-12  from  level-22.
     move     zero  to  level-11  level-12.
     move     level-21  to  level-11.
     move     level-22  to  level-12.
     move     ws-hypens to l8-underline2.
     if       j > zero
              move ws-hypens to l8-underline4.
     write    print-record from line-8 after 1.
     move     spaces to line-8.
     move     "T"  to  group-level.
     move     "Net Current Assets"  to  l7-name.
     perform  group-total.
     move     ws-equals to l8-underline2
     if       j > zero
              move ws-equals to l8-underline4.
     write    print-record from line-8 after 1.
     move     zero  to  level-11  level-12
                        level-21  level-22.
     move     spaces  to  print-record  group-level.
     move     spaces to l8-underline2 l8-underline4.
     write    print-record after 2.
 loop-9.
*>-----
*>
*>  do account types W - Z
*>
     perform  line-total.
     add      1  to  y.
     if       y  <  27
              go to  loop-9.
     move     "Capital Account Total"  to  l7-name.
     perform  group-total.
     write    print-record  from  line-8 after 1.
     move     level-11  to  level-21.
     move     level-12  to  level-22.
     move     zero  to  level-11  level-12.
     move     "Net Profits"  to  l7-name.
     move     spaces  to  line-8.
     move     spaces  to  print-record.
     write    print-record after 1.
     move     net-1  to  level-11.
     move     net-2  to  level-12.
     perform  group-total.
     add      level-11  to  level-21.
     add      level-12  to  level-22.
     move     zero  to  level-11  level-12.
     move     level-21  to  level-11.
     move     level-22  to  level-12.
     move     "T"  to  group-level.
     move     "Net Current Assets"  to  l7-name.
     move     ws-hypens to l8-underline2.
     if       j > zero
              move ws-hypens to l8-underline4.
     write    print-record from line-8 after 1.
     move     spaces  to  line-8.
     perform  group-total.
     move     zero  to  level-11  level-12
                        level-21  level-22.
     move     ws-equals to l8-underline2.
     if       j > zero
              move ws-equals to l8-underline4.
     write    print-record from line-8 after 1.
     close    work-file.
*>
*> *** End of p&l and bal sheet reports ***
*>
     perform  ratio.
     close    print-file.
     call     "SYSTEM" using Print-Report.
*>
*> *** end of sales ratio report ***
*>
     perform  screen-heads.
     display  "End of period processing outputs the current year f" &
              "igures to a comparative." at 0501 with foreground-color 2.
     display  "Revenue accounts are zeroed but Capital Accounts re" &
              "tain their value." at 0601 with foreground-color 2.
*>
 e-o-p-option.
*>-----------
*>
     display  "Do you require end of period processing (Y/N) :- " at 0901 with foreground-color 2.
     accept   ws-reply at 0950 with foreground-color 6.
     if       ws-reply  = "N"  OR = "n"
              go to  e-o-p-end.
     if       ws-reply not = "Y" and not = "y"
              go to  e-o-p-option.
*>
     move     3 to file-function.
*>
*>    open input default-file and get record.
*>
     call     "irsub3" using default-record file-access.
*>
 e-o-p-comp.
*>---------
*>
     display  "Comparative field to use - " at 1101 with foreground-color 2.
     accept   j  at 1128 with foreground-color 6.
     if       j  <  1  or  >  4
              go to  e-o-p-comp.
*>
 chk-defs.
*>-------
*>
     if       zeros = def-acs (30) or def-acs (31)
              display "Default A/C 30 or 31 Not setup" at 1201 with foreground-color 4
              stop run.
*>
 get-pl.
*>------
*>
     display "Enter P/L Appropriation or Capital A/C :- " at 1301 with foreground-color 2.
     accept   pl-ac at 1343 with foreground-color 3.
*>
 get-pl-rest.
*>----------
     display  "You have selected end of period processing overwrit" &
              "ing comparative field - " at 1501 with foreground-color 2.
     display  j at 1577 with foreground-color 2.
     display  "with P/L or Capital A/C - " at 1601 with foreground-color 2.
     display  pl-ac at 1627 with foreground-color 2.
     display  "Is This Correct ? (Y/N) - " at 1701 with foreground-color 2.
     accept   ws-reply at 1727 with foreground-color 6.
     if       ws-reply not = "Y" and not = "y"
              go to  e-o-p-option.
     open     input nominal-ledger.
*>
     move     pl-ac  to  owning.
     move     zero   to  sub-nominal.
*>
     read     nominal-ledger  invalid key
              display " " at 0101 with erase eos
              display pl-ac at 0505 with foreground-color 2
              display "Does not exist. Hit return, then Check & re-enter" at 0513
                                                  with foreground-color 2
              accept ws-reply at 0565 with foreground-color 2
              close nominal-ledger
              go to get-pl.
*>
     move     function upper-case (ac) to ws-ac2.
     move     ws-ac2 to ws-ac.
*>
     close    nominal-ledger.
     open     i-o nominal-ledger.
*>
 loop-a.
*>-----
*>
     read     nominal-ledger  next record  at end
              go to  e-o-p-fin.
*>
 by-pass.
*>------
*>
*>     Processing main a/c only
*>
     move     record-1  to  nl-record.
     if       sub
              go to  loop-a.
     move     dr  to  dr-last (j)
     move     cr  to  cr-last (j).
     if       ac  <  "O"
              move  zero  to  dr  cr.
     rewrite  record-1.
*>
 loop-b.
*>-----
*>
     read     nominal-ledger next record
                at end go to  e-o-p-fin.
     if       tipe = "S"
              go to loop-b.
     if       sub-nominal  = zero
              go to  by-pass.
     move     dr  to  dr-last (j)
     move     cr  to  cr-last (j).
     if       nl-ac  <  "O"
              move  zero  to  dr  cr.
     move     nl-ac  to  ac.
     rewrite  record-1.
     go       to loop-b.
*>
 e-o-p-fin.
*>--------
*>
     perform  vat-ac-tidyup.
     perform  pl-capital-ac-tidyup.
*>
     move     pl-ac  to  owning.
     move     zero   to  sub-nominal.
*>
 jump-back.
*>--------
*>
     read     nominal-ledger  invalid key
              display "PE 009610" at 0505
              display "Hit return for menu" at 0701
              accept ws-reply at 0721
              close work-file
              stop run.
     if       tipe  = "O"
              go to  update-pl.
     move     owning  to  sub-nominal.
     move     rec-pointer  to  owning.
     go       to jump-back.
*>
 update-pl.
*>--------
*>
     if       net-1  >  zero
              add  net-1  to  cr
     else
              add  net-1  to  dr.
     rewrite  record-1.
     close    nominal-ledger.
     perform  reset-postings.
*>
 e-o-p-end.
     exit     program.
*>
 cr-total     section.
*>-------------------
*>
     set      z to w.
     add      cr  to    total-1 (z).
     subtract dr  from  total-1 (z).
     if       j = zero
              go to main-exit.
     add      cr-last (j)  to    total-2 (z).
     subtract dr-last (j)  from  total-2 (z).
*>
 main-exit.   exit.
*>
 dr-total     section.
*>-------------------
     set      z to w.
     add      dr  to    total-1 (z).
     subtract cr  from  total-1 (z).
     if       j = zero
              go to main-exit.
     add      dr-last (j)  to    total-2 (z).
     subtract cr-last (j)  from  total-2 (z).
*>
 main-exit.   exit.
*>
 line-total   section.
*>-------------------
*>
*>    move     ar1 (y)  to  l7-name.
     multiply total-1 (y)  by  1  giving  l7-value1  rounded.
     if       j > zero
              multiply total-2 (y) by 1 giving l7-value3 rounded
              add total-2 (y)  to  level-12.
*>
     add      total-1 (y)  to  level-11.
     if       total-1 (y)  <  zero
              move  "("  to  l7-sign1
              move  ")"  to  l7-sign2
     else
              move  space  to  l7-sign1  l7-sign2.
*>
     if       total-2 (y)  <  zero and j > zero
              move  "("  to  l7-sign5
              move  ")"  to  l7-sign6
     else
              move  space  to  l7-sign5  l7-sign6.
     go       to by-pass.
*>
 loop-1.
*>
     read     work-file  at end
              go to  main-end.
*>
 by-pass.
*>
     if       ac  <   ar0 (y)
              display "PE009865" at 2001
              display "Note error and Hit return to continue" at 2411
              accept ws-reply at 2451
              go to  loop-1.
     if       ac > ar0 (y)
              go to main-end.
*>
     move     record-1  to  nl-record.
     move     nl-name of nl-data to  l9-name.
*>
 loop-2.
*>
     read     work-file  at end
              go to  main-end.
*>
     if       sub-nominal  = zero
              perform  write-out
              go to  by-pass.
*>
     add      dr  to  nl-dr.
     add      cr  to  nl-cr.
     if       j = zero
              go to loop-2.
     add      dr-last (j)  to  nl-dr-last (j).
     add      cr-last (j)  to  nl-cr-last (j).
     go       to loop-2.
*>
 main-end.
*>---------
*>
     perform  write-out.
*>
*>    write    print-record  from  line-7 after 1.
*>
 main-exit.   exit.
*>
*>
 group-total  section.
*>--------------------
     multiply level-11  by  1  giving  l7-value2  rounded.
     if       j > zero
              multiply level-12 by 1 giving l7-value4 rounded.
*>
*>    if       not  sub-total
*>             multiply  level-11  by  1
*>                       giving  l7-value1  rounded
*>    if       j > zero
*>             multiply  level-12  by  1
*>                       giving  l7-value3  rounded.
     if       sub-total
              move  zero  to  l7-value1  l7-value3.
*>
     if       level-11  <  zero
              move  "("  to  l7-sign3
*>                            l7-sign1
              move  ")"  to  l7-sign4
*>                            l7-sign2
     else
              move  space  to  l7-sign3  l7-sign4.
*>
     if       level-12  <  zero and j > zero
              move  "("  to  l7-sign7
*>                            l7-sign5
              move  ")"  to  l7-sign8
*>                            l7-sign6
     else
              move  space  to  l7-sign7  l7-sign8.
     move     ws-hypens  to  l8-underline1.
     if       j > zero
              move ws-hypens to  l8-underline3.
     if       not  sub-total
              write  print-record  from  line-8 after 1.
     write    print-record  from  line-7 after 1.
*>
     move     spaces to l7-sign1 l7-sign2 l7-sign3 l7-sign4  l7-sign5
                        l7-sign6 l7-sign7 l7-sign8.
*>
     move     zero  to  l7-value1  l7-value2 l7-value3  l7-value4.
     move     spaces to line-8.
*>
 main-exit.   exit.
*>
 write-out    section.
*>-------------------
     if       nl-ac  <  "E"
              perform  cr-value.
     if       nl-ac  >  "D"  AND  <  "J"
              perform  dr-value.
     if       nl-ac  = "I"  OR  "J"
              perform  cr-value.
     if       nl-ac  >  "J"  AND  <  "U"
              perform  dr-value.
     if       nl-ac  >  "T"
              perform  cr-value.
     go       to main-print.
*>
 cr-value.
*>
     move     zero  to  work-1.
     move     zero  to  work-2.
     add      nl-cr to   work-1.
     subtract nl-dr from work-1.
*>
     if       j > zero
              add       nl-cr-last (j)  to    work-2
              subtract  nl-dr-last (j)  from  work-2.
*>
 dr-value.
*>
     move     zero  to  work-1.
     move     zero  to  work-2.
     add      nl-dr to   work-1.
     subtract nl-cr from work-1.
*>
     if       j > zero
              add       nl-dr-last (j)  to    work-2
              subtract  nl-cr-last (j)  from  work-2.
*>
 main-print.
*>
     if       work-1  = zero
       and    work-2  = zero
              go to  main-end.
*>
     if       l9-name = spaces
              go to main-end.
*>
     if       work-1  <  zero
              move  "("  to  l9-sign1
              move  ")"  to  l9-sign2
     else
              move  space  to  l9-sign1  l9-sign2.
*>
     if       work-2  <  zero and j > zero
              move  "("  to  l9-sign3
              move  ")"  to  l9-sign4
     else
              move  space  to  l9-sign3  l9-sign4.
*>
     multiply work-1  by  1  giving  l9-value1  rounded.
     if       j > zero
              multiply work-2 by 1 giving l9-value2 rounded.
*>
     write    print-record  from  line-9 after 1.
*>
 main-end.
*>
     move     spaces  to  l9-name.
     move     zero    to  work-1  work-2.
*>
 main-exit.   exit.
*>********    ****
*>
 ratio        section.
*>-------------------
*>
     write    print-record  from  line-1 after page.
     write    print-record  from  line-2 after 2.
     write    print-record  from  line-10 after 2.
     move     spaces  to  print-record.
     write    print-record after 1.
*>
     add      total-1 (1) total-1 (2) total-1 (3) total-1 (4) giving work-1.
     add      total-1 (5) total-1 (6) total-1 (7) total-1 (8) giving work-2.
     subtract work-2 from work-1 giving work-2.
     divide   work-1 by 100 giving work-3.
     divide   work-2 by work-3 giving l11-ratio rounded.
     move     "Gross Profit % to Sales"  to  l11-name.
     write    print-record  from  line-11 after 2  lines.
*>
     subtract total-1 (11) total-1 (12) total-1 (13) total-1 (14) from work-2.
     divide   work-2 by work-3 giving l11-ratio rounded.
     move     "Net Profit % to Sales"  to  l11-name.
     write    print-record  from  line-11 after  2  lines.
*>
 main-exit.   exit.
*>********    ****
*>
 date-validate section.
*>--------------------
*>
*>************************************************
*>                                               *
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
*>                                               *
*>************************************************
*>
     if       u-bin  >  zero
              go to  ws-unpack.
     move     zero to q.
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
     if       u-days > 29 and u-month = 2
              go to main-exit.
*>
     divide   u-year by 4 giving save-date.
     multiply save-date by 4 giving q.
     if       u-month = 2 and
              u-days > 28 and
              q not = u-year
              go to main-exit.
*>
     if       u-days > days (u-month) and
              u-month not = 2
              go to main-exit.
*>
*>********************************************
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
     move     zero  to  u-bin.
     move     1     to  ws-work1.
     move     zero  to  ws-work2.
*>
     if       u-year not = zero
              compute u-bin = u-year * 365.
*>
     if       u-bin <   zero
              move  zero  to  u-bin
              go to  pack-end.
*>
 pack-loop-1.
     if       u-year  >  ws-work2
              add  1  to  u-bin
              add  4  to  ws-work2
              go to  pack-loop-1.
*>
     if       u-year =  ws-work2
       and    u-month  >  2
              add  1  to  u-bin.
*>
 pack-loop-2.
     if       u-month  >  12
              move  zero  to  u-bin
              go to pack-end.
     if       u-month  >  ws-work1
              add  days (ws-work1)  to  u-bin
              add  1  to  ws-work1
              go to pack-loop-2.
*>
     if       u-days  not  >  days (ws-work1)
              add  u-days  to  u-bin
              go to  pack-end.
     if       u-days   = 29
        and   u-month  = 2
        and   u-year   = ws-work2
              add  u-days  to   u-bin
     else
              move  zero  to u-bin.
*>
 pack-end.
     go       to main-exit.
*>
*>*************************************
*>                                    *
*>   binary date conversion routine   *
*>   ==============================   *
*>                                    *
*>                                    *
*>  requires  binary input in u-bin   *
*>  &  returns date  in u-date        *
*>                                    *
*>*************************************
*>
 ws-unpack.
*>========
*>
     move     u-bin  to  save-date.
*>
     move     "00/00/00"  to  u-date.
     move     zero  to  u-year.
     move     1  to  u-month.
     move     0  to  u-days.
     move     1  to  ws-work1.
     move     zero  to  ws-work2.
*>
 unpack-loop-1.
*>
     subtract 365  from  save-date.
*>
     if       save-date  >  zero
              add  1  to  u-year
     else
              add  365  to  save-date
              go to  unpack-loop-2.
*>
     if       u-year = ws-work2
          and save-date > 59
              add  4  to  ws-work2
              subtract  1   from  save-date.
*>
     if       save-date  = zero
              subtract  1  from  u-year
              move  365  to  save-date
              go to unpack-loop-2.
*>
     go       to unpack-loop-1.
*>
 unpack-loop-2.
*>
     if       save-date  = 365
              move  31  to   u-days
              move  12  to  u-month
              go to  unpack-end.
*>
 unpack-loop-3.
*>
     subtract days (ws-work1)  from  save-date.
*>
     if       save-date  >  zero
              add  1  to  ws-work1
              add  1  to  u-month
              go to  unpack-loop-3.
*>
     add      save-date  days (ws-work1)  to  u-days.
*>
 unpack-end.
*>
 main-exit.   exit.
*>********    ****
*>
 pl-capital-ac-tidyup  section.
*>****************************
 pl-start.
*>
     move     zero to nl-cr nl-dr.
     close    nominal-ledger.
     open     i-o nominal-ledger.
*>
 pl-a.
*>---
*>
     read     nominal-ledger next record at end
              go to pl-a-end.
     move     function upper-case (ac) to ac2.
     if       ac2 not = ws-ac
              go to pl-a.
     if       tipe = "S"
              go to pl-a.
*>
*>   Got record with same type as PL/capital record
*>
     move     ac2 to ac.
     add      cr to nl-cr.
     add      dr to nl-dr.
     move     zero to cr dr.
     rewrite  record-1.
     if       fs-reply not = zero
              display "PE 014900" at 2301
              display "Hit return to continue" at 2401
              accept ws-reply at 2421
              stop run.
     go       to pl-a.
*>
 pl-a-end.
*>-------
*>
     move     pl-ac to owning.
     move     zero  to sub-nominal.
     read     nominal-ledger invalid key
              display "PE 015000" at 2301
              display "Hit return to continue" at 2401
              accept ws-reply at 2421
              stop run.
*>
     if       tipe = "S"
              display  pl-ac at 2301 with foreground-color 2
              display  "is a Sub-nominal account, you must give me" &
                       " a main-account only..ABORTING!!" at 2307 with foreground-color 2
              display "Hit return for menu" at 2441
              accept ws-reply at 2461
              goback.
*>
     move     nl-dr to dr.
     move     nl-cr to cr.
     rewrite  record-1.
     if       fs-reply not = zeros
              display "PE 015100" at 2301
              display "Hit return to continue" at 2401
              accept ws-reply at 2421
              stop run.
     go       to pl-exit.
*>
 pl-exit.     exit.
*>******      ****
*>
 vat-ac-tidyup         section.
*>****************************
 vat-a.
*>
     move     def-acs (31) to owning.
     move     zero    to sub-nominal.
*>
 vat-b.
*>----
*>
     read     nominal-ledger invalid key
              display " " at 0101 with erase eos
              display owning at 0501  with foreground-color 2
              display "(Default 31 A/C) does not exist..ABORTING" at 0507 with foreground-color 2
              display "Hit return " at 2441
              accept ws-reply at 2461
              close nominal-ledger
              stop run.
*>
     if       tipe = "S" and
              rec-pointer = owning
              display " " at 0101 with erase eos
              display "PE VAT01: Problems with CoA file" at 2301
              display "Hit return " at 2441
              accept ws-reply at 2461
              close nominal-ledger
              stop run.
*>
*>    Get pointer to Sub nominal to find main a/c
*>
     if       tipe = "S"
              move rec-pointer to owning
              go to vat-b.
*>
*>    At this point, we have got the VAT control Main Account
*>
     move     record-1 to nl-record.
*>
 vat-c.
*>----
*>
     read     nominal-ledger next record at end
              go to vat-finalize.
*>
     if       owning not = nl-owning
              go to vat-finalize.
*>
     if       tipe = "S"
              go to vat-c.
*>
     add      dr   to nl-dr.
     add      cr   to nl-cr.
     move     zero to dr  cr.
*>
     rewrite  record-1.
     if       fs-reply not = zero
              display "PE 015370: Problems with CoA file cant rewrite" at 2301
              display "Hit return for menu" at 2401
              accept ws-reply at 2421
              stop run.
     go       to vat-c.
*>
 vat-finalize.
*>-----------
*>
     move     nl-record to record-1.
     rewrite  record-1.
     if       fs-reply not = zero
              display "PE 015470: Problems on rewrite for CoA file" at 2301
              display "Hit return for menu" at 2401
              accept ws-reply at 2421
              stop run.
     go       to vat-exit.
*>
 vat-exit.
     exit.
*>
 reset-postings        section.
*>****************************
     open     input nominal-ledger.
     move     1 to file-function.
     move     3 to access-type.
*>
*>    open  output post-file.
*>
     call     "irsub4" using posting-record file-access.
     move     zero to u-bin pl-ac save-sequ.
     move     end-date to u-date.
     perform  date-validate.
     add      1 to u-bin.
     move     spaces to u-date.
     perform  date-validate.
     move     5 to file-function.
*>
 read-n.
*>
     read     nominal-ledger next record at end
              go to main-end.
     if       nl-sub-ac
              go to read-n.
     if       cr = zero and
              dr = zero
              go to read-n.
*>
     if       dr = cr
              go to read-n.
*>
     if       dr > cr
              subtract cr from dr
              move zero to cr
       else   subtract dr from cr
              move zero to dr.
*>
     move     u-date to post-date.
     move     spaces to post-vat-side.
     add      1 to pl-ac.
     move     pl-ac to post-key.
     move     def-codes (30) to post-code.
     move     zero to vat-ac-def vat-amount.
     move     "Balance Forward" to post-legend.
     move     def-acs (30) to post-cr post-dr.
     if       sub-nominal not = zero
              move sub-nominal to owning.
*>
     if       dr > zero
              move owning to post-dr
              move dr to post-amount
     else
      if      cr > zero
              move owning to post-cr
              move cr to post-amount.
*>
     if       def-acs (30) = post-cr and post-dr
              go to read-n.
*>
     move     5 to file-function.
     call     "irsub4" using posting-record file-access.
     go       to read-n.
*>
 main-end.
     close    nominal-ledger.
     move     2 to file-function.
     call     "irsub4" using posting-record file-access.
     move     pl-ac to next-post.
*>
 main-exit.
     exit.
