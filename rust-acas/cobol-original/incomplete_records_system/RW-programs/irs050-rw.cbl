       >>source free
*>*****************************************************************
*>                                                                *
*>  A u d i t   T r a i l / V A T   R e p o r t / L e d g e r s   *
*>                                                                *
*> This module uses the Report Writer function in Gnu COBOL v2.1  *
*>        the one without RW is called irs050.cbl as against      *
*>                                        irs-rw.cbl              *
*> >>>>>>>>>>> WORK IN PROGRESS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< *
*>*****************************************************************
 identification division.
 program-id.            irs050.
*>
*> Author.              Cobol conversion by Vincent B Coen. FBCS 23/10/82
*>                      for Applewood Computers.
*>
*> Security.            Copyright (C) 1982-2014, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*>
*> Remarks.             Posting File Reports.
*>
*> Version.             see prog-name in ws.
*>
*> Calls.               irsub1 (Nominal Ledger)
*>                      irsub3 (Accounts Default)
*>                      irsubp (Sorted Postings)
*>
*> Changes.
*> 05/09/83 vbc - Minor changes to display & report formats.
*> 06/12/83 vbc - Fix date test on vat reports & stop eop at eor.
*> 22/02/84 vbc - Change format of ledgers report.
*> 28/05/84 vbc - Hilite display heads.
*> 14/04/85 vbc - Change print to 79 chars.
*> 26/09/89 vbc - Mods for cobol/2.
*> 09/10/89 vbc - Dont print record for zero vat on vat i/p o/p acc.
*> 22/01/09 vbc - Migraton to OC as version 3.
*> 15/02/09 vbc - Fix bug if posting file empty
*> 18/02/09 vbc - Bug fixes for spool print missing, stop disp/print on empty
*>                ledgers where no postings exist and this one has always been
*>                present. ie, not one user complained (except me).
*> 21/02/09 vbc - Added support for env's LINES and COLUMNS as needed.
*> 13/04/09 vbc - Add sign to ledger line items.
*> 21/09/10 vbc - Added print spool.
*>                .13 fix for portrait printing
*> 17/12/13 vbc - .63 Rewritten for GNU Cobol Report Writer functions in V2.1.
*>                     LATEST version without rw is called irs050 but this one
*>                     using RW is irs050-rw.cbl
*>                          check version number (just in case).
*>                    A bit of a cheat as rw data taken from original data lines
*>                    that are used for displaying the results & printing
*>                    as per the original code.
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of the Applewood Computers Accounting System
*> and is copyright (c) Vincent B Coen. 1976 - 2014 and later.
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
     report Audit-Report.
*> fd  print-file.
*>*>
*> 01  print-record          pic x(79).
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(16) value "irs050 (3.01.63)".
 77  sort-sequ           pic 9.
 77  use-code            pic xx       value spaces.
 77  save-code           pic xx       value spaces.
 77  ac-marker           pic 9        value zero.
 77  vat-check           pic 9        value zero.
 77  line-cnt            pic 99  comp value 99.
 77  ws-account-used     pic 9        value zero.
 copy "print-spool-command-p.cob".
 01  filler.
     03  ws-env-lines    pic 999       value zero.
     03  ws-lines        binary-char unsigned value zero.
     03  ws-22-lines     binary-char unsigned value zero.
     03  ws-21-lines     binary-char unsigned value zero.
     03  ws-17-lines     binary-char unsigned value zero.
     03  ws-accept-lines binary-char unsigned value zero.
*>
     03  ws-reply        pic x.
     03  empty           pic x.
         88  do-print         value  is  "Y".
     03  counter         pic 999        value zero.
     03  ws-pass         pic x(4).
     03  total-in-net    pic s9(7)v99   value zero.
     03  total-in-vat    pic s9(7)v99   value zero.
     03  total-out-net   pic s9(7)v99   value zero.
     03  total-out-vat   pic s9(7)v99   value zero.
     03  total-dr        pic s9(7)v99   value zero.
     03  total-cr        pic s9(7)v99   value zero.
     03  p               pic 99         value zero.
     03  target-account  pic 9(5).
     03  check-account   pic 9(5).
     03  hold-owning     pic 9(5).
     03  test-date.
         05  t-days      pic 99.
         05  filler      pic x.
         05  t-month     pic 99.
         05  filler      pic x.
         05  t-year      pic 99.
     03  wsa-date.
         05  wsa-yy      pic 99.
         05  wsa-mm      pic 99.
         05  wsa-dd      pic 99.
     03  wsa-post-date   redefines wsa-date pic 9(6).
     03  wsb-date.
         05  wsb-yy      pic 99.
         05  wsb-mm      pic 99.
         05  wsb-dd      pic 99.
     03  wsb-start-date  redefines wsb-date pic 9(6).
     03  wsc-date.
         05  wsc-yy      pic 99.
         05  wsc-mm      pic 99.
         05  wsc-dd      pic 99.
     03  wsc-end-date    redefines wsc-date pic 9(6).
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
 01  screen-bits         pic 9(4).
     copy "screenio.cpy".
*>
 01  ws-system-work-group.
     03  tipe            pic x.
         88  Valid-Tipe       values "A" "L" "D".
         88  Audit            value  "A".
         88  Ledgers          value  "L".
         88  Vat-Report       value  "D".
     03  output-reply    pic x.
     03  period-start.
         05  p-s-days    pic 99.
         05  p-s-sl1     pic x.
         05  p-s-month   pic 99.
         05  p-s-sl2     pic x.
         05  p-s-year    pic 99.
     03  period-end.
         05  p-e-days    pic 99.
         05  p-e-sl1     pic x.
         05  p-e-month   pic 99.
         05  p-e-sl2     pic x.
         05  p-e-year    pic 99.
 01  filler.
     03  p-sub-legend.
        05 filler        pic x(26)    value "Sub-Nominal Balance A/C - ".
        05 p-sub-account pic z(4)9.
     03  c-continue      pic x(39)   value "Press return to continue or Esc to quit".
     03  c-exit	         pic x(44)   value "Return for next screen or <X> to exit....[ ]".
*>
 copy "wspost.cob".
 copy "wsfnctn.cob".
 copy "wsnl.cob".
 copy "wsdflt.cob".
 01  filler  redefines default-record.
     03  filler          pic 9(5)  occurs 30.
     03  def-acs-31      pic 9(5).
     03  def-acs-32      pic 9(5).
     03  filler          pic x(96).
*>
 01  print-lines.
     03  line-1.
       05  p-user        pic x(24).
       05  filler        pic x(5)     value spaces.
       05  p-report      pic x(36).
       05  filler        pic x(6)     value spaces.
       05  p-date        pic x(8).
     03  q-report.
       05  l1-a          pic x(28)    value " Day Book      Quarter  To".
       05  q-date        pic x(8).
*>
     03  line-3.
      04  Line-3A.
       05  p-client      pic x(24).
       05  l3-a          pic x(15)     value "    End Date - ".
       05  p-end         pic x(8).
       05  filler        pic x(24)     value spaces.
       05  l3-b          pic x(5)      value "Page ".
      04 Line-3B.
       05  p-page        pic zz9.
*>
     03  line-4-a.
       05  l4-a          pic x(43)    value "Transaction    Date    Code   ---Account---".
       05  l4-b          pic x(35)    value "   Net Amount    VAT Amount    Type".
*>
     03  line-5-a.
       05  l5-a          pic x(43)    value "-----------    ----    ----   Debit  Credit".
       05  l5-b          pic x(35)    value "   ----------    ----------    ----".
*>
     03  line-4-v.
       05  l4-c          pic x(37)    value "Transaction    Date     Code         ".
       05  l4-d          pic x(42)    value "-----Input Tax-----   ----Output Tax------".
*>
     03  line-5-v.
       05  l5-c          pic x(37)    value "-----------    ----     ----         ".
       05  l5-d          pic x(42)    value "   Net        VAT        Net        VAT   ".
*>
     03  line-4-l.
       05  l4-e          pic x(79)    value
           "Code/Nos  --Date--  ------------Legend------------- Contra --Debit--  -Credit--".
*>
     03  line-6-a.
       05  p-tran-a      pic bbbzzzz9.
       05  filler        pic x(5)     value spaces.
       05  p-date-a      pic x(8).
       05  filler        pic x(3)     value spaces.
       05  p-code-a      pic x(2).
       05  filler        pic x(4)     value spaces.
       05  p-debit       pic zzzz9.
       05  filler        pic xxx      value spaces.
       05  p-credit      pic zzzz9.
       05  p-net         pic -(9)9.99.
       05  filler        pic x        value space.
       05  p-vat-amount  pic -(9)9.99.
       05  filler        pic x(4)     value spaces.
       05  p-vat-type    pic x(6).
*>
     03  line-6-v.
       05  p-tran-v      pic bbbzzzz9.
       05  filler        pic x(5)     value spaces.
       05  p-date-v      pic x(8).
       05  filler        pic x(4)     value spaces.
       05  p-code-v      pic x(2).
       05  filler        pic x(8)     value spaces.
       05  p-in-net      pic -(7)9.99   blank when zero.
       05  p-in-vat      pic -(7)9.99   blank when zero.
       05  p-out-net     pic -(7)9.99   blank when zero.
       05  p-out-vat     pic -(7)9.99   blank when zero.
*>
     03  line-6-l.
       05  p-code-l      pic xx.
       05  p-spacer-l    pic x        value "/".
       05  p-tran-l      pic zzzz9.
       05  filler        pic xx       value spaces.
       05  p-date-l      pic x(8).
       05  filler        pic xx       value spaces.
       05  p-legend-l    pic x(32)    value spaces.
       05  p-contra-l    pic zzzz9.
       05  p-debit-l     pic -(7)9.99    blank when zero.
       05  p-credit-l    pic -(7)9.99    blank when zero.
*>
     03  line-7.
       05  filler        pic x(36)    value spaces.
       05  l7-a          pic x(22)    value "---------- ---------- ".
       05  l7-b          pic x(21)    value "---------- ----------".
*>
     03  line-7-a.
       05  filler        pic x(44)    value spaces.
       05  l7-c          pic x(25)    value "===========   ===========".
*>
     03  line-7-l.
       05  filler        pic x(58)    value spaces.
       05  l7-d1         pic x(10)    value "==========".
       05  filler        pic x        value space.
       05  l7-d2         pic x(10)    value "==========".
*>
     03  line-7-m.
       05  filler        pic x(58)    value spaces.
       05  l7-e          pic x(21)    value "---------- ----------".
*>
     03  line-8.
       05  filler        pic xxx      value spaces.
       05  l8-a          pic x(5)     value "Total".
       05  filler        pic x(27)    value spaces.
       05  t-in-net      pic -(7)9.99    blank when zero.
       05  t-in-vat      pic -(7)9.99    blank when zero.
       05  t-out-net     pic -(8)9.99    blank when zero.
       05  t-out-vat     pic -(7)9.99    blank when zero.
*>
     03  line-8-a.
       05  l8-b          pic x(24)    value "Transaction Type   -   ".
       05  p-code-8      pic x(2).
       05  l8-c          pic x(18)    value "    Total        ".
       05  a-in-net      pic -(8)9.99.
       05  filler        pic xx       value spaces.
       05  a-in-vat      pic -(8)9.99.
*>
     03  line-8-l.
       05  filler        pic x(58)    value space.
       05  t-dr-total    pic -(6)9.99    blank when zero.
       05  t-cr-total    pic -(7)9.99    blank when zero.
*>
     03  line-9-l.
       05  filler        pic x(18)    value spaces.
       05  bal-name      pic x(40)    value spaces.
       05  b-dr-total    pic -(6)9.99    blank when zero.
       05  b-cr-total    pic -(7)9.99    blank when zero.
*>
     03  line-ledger.
       05  l10-a         pic x(10)    value "Account - ".
       05  ledg-account  pic zzzz9.
       05  filler        pic x(4)     value spaces.
       05  ledg-name     pic x(24).
*>
 linkage section.
*>**************
*>
 copy "wssystem.cob".
*>
 report section.
*>**************
*>
 rd  Audit-Report
 *>    control is final
     page limit is 78
     heading 1
     first detail 7
     last  detail 74.
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
 01  Audit-Detail type detail.
     03  line plus 1.
         05  col  1      pic x(80)     source Line-5.
*> ????
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
*>======================================
*>
 main-flow section.
*>*****************
*>
*> first get date & user information..
*>
     accept   ws-env-lines   from lines.
     if       ws-env-lines < 24
              move  24 to ws-env-lines ws-lines
     else
              move  ws-env-lines   to ws-lines
     end-if
     subtract 1 from ws-lines giving ws-accept-lines.
     subtract 2 from ws-lines giving ws-22-lines.
     subtract 3 from ws-lines giving ws-21-lines.
     subtract 7 from ws-lines giving ws-17-lines.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name to PSN.
*>
     move     system-files to file-names.
     move     3 to file-function.
     call     "irsub3"  using  default-record  file-access.
*>
 run-loop.
*>---------
*>
     move     zero to total-in-net   total-in-vat
                        total-out-net  total-out-vat
                        total-dr       total-cr.
*>
     display  " " at 0101 with erase eos.
     display  prog-name                               at 0101 with foreground-color 2.
     display  "Posting  Reports"   at 0128 with foreground-color 1 background-color 7.
     display  run-date                                at 0173 with foreground-color 2.
*>
     display  "Input Report required by letter...[ ]" at 0501 with foreground-color 2.
     display  "Press <RETURN> to exit"                at 0541 with foreground-color 2.
     display  "(A) - Audit Report"                    at 0701 with foreground-color 2.
     display  "(L) - Ledgers"                         at 0801 with foreground-color 2.
     display  "(D) - VAT Day Book"                    at 0901 with foreground-color 2.
*>
     display  "Display or Print  <D> or <P>......[ ]" at 1101 with foreground-color 2.
*>
     display  "Select required sort by number....[ ]" at 1301 with foreground-color 2.
     display  "(1) - Code order sequence"             at 1501 with foreground-color 2.
     display  "(2) - Date order sequence"             at 1601 with foreground-color 2.
     display  "(3) - Transaction number sequence"     at 1701 with foreground-color 2.
*>
     move     spaces to tipe ws-reply.
*>
 run-loop-accept.
*>
     accept   tipe at 0536 with foreground-color 6.
     move     function upper-case (tipe) to tipe.
     if       tipe = spaces
              go to main99-exit.
*>
     if       not Valid-Tipe     *>  audit and not vat-report and not ledgers
              go to run-loop.
     if       not vat-report
              go to output-select.
*>
 date-select.
*>
     display  "Period Start Date  .......[dd/mm/yy]" at 0741 with foreground-color 2.
     display  "Period End Date  .........[dd/mm/yy]" at 0941 with foreground-color 2.
     move     Start-Date to Period-Start.
     move     End-Date   to Period-End.
     accept   period-start at 0768 with foreground-color 3 update.
     accept   period-end   at 0968 with foreground-color 3 update.
*>
     if       p-s-days not numeric
        or    p-s-month not numeric
        or    p-s-year not numeric
        or    p-e-days not numeric
        or    p-e-month not numeric
        or    p-e-year not numeric
              go to date-select.
*>
     move     p-s-days  to wsb-dd.
     move     p-s-month to wsb-mm.
     move     p-s-year  to wsb-yy.
     move     p-e-days  to wsc-dd.
     move     p-e-month to wsc-mm.
     move     p-e-year  to wsc-yy.
*>
 output-select.
*>
     accept   output-reply at 1136  with foreground-color 6.
     move     function upper-case (output-reply) to output-reply.
     if       output-reply not = "D" and not = "P"
              go to output-select.
*>
 sort-select.
*>
     accept   sort-sequ at 1336 with foreground-color 6.
     if       sort-sequ < 1 or > 3
              go to sort-select.
     if       sort-sequ = save-sequ
              go to proceed-run.
*>
*> save period date info and sort sequence (if re-sort in same run)
*>
     move     sort-sequ to save-sequ.
     move     ws-system-work-group to system-work-group.
     call     "irs055" using system-record.
*>
 sort-reset.
     move     system-work-group to ws-system-work-group.
*>
 proceed-run.
*>
     move     suser    to p-user.
     move     client   to p-client.
     move     end-date to p-end.
     move     run-date to p-date.
*>
     if       ledgers
              perform ledger-report
              go to run-loop.
*>
     move     1 to file-function  access-type.
     perform  call-irsubp.
     if       we-error = 99
              display "No Posting data present" at line ws-accept-lines col 01
                                                        with foreground-color 4
              go to run-loop-accept.
*>
     if       output-reply = "D"
              perform display-report
              go to  run-loop.
     if       output-reply = "P"
              perform report-print
              go to run-loop.
*>  TEMP for testing   (what is this?)
*>
 call-irsubp.
     call     "irsubp" using posting-record file-access system-record.
 call-irsub1.
     call     "irsub1" using nl-record file-access.
 main99-exit.
*>**********
*>
*>    move     zero to save-sequ.
*>
 main-term.
     exit     program.
*>
 sub-nominal-search section.
*>-------------------------
*>
     move     space to p-spacer-l.
     move     nl-owning to hold-owning.
*>
 detail-loop.
*>
     move     3 to file-function.
     perform  call-irsub1.
*>
     if       we-error = 3
              go to main-end.
     if       nl-owning not = hold-owning
              go to main-end.
*>
     if       nl-dr = nl-cr
              go to detail-loop.
*>
     if       ac-marker = zero and output-reply = "P"
              perform account-headings.
*>
     move     1 to ws-account-used.
     move     spaces to p-code-l  p-date-l.
     move     zero to p-tran-l  p-contra-l.
*>
     move     nl-sub-nominal to p-sub-account.
     move     p-sub-legend  to p-legend-l.
*>
     if       nl-dr  > nl-cr
              add      nl-dr to   total-dr
              subtract nl-cr from total-dr
              subtract nl-cr from nl-dr giving p-debit-l
              move     zero to p-credit-l.
*>
     if       nl-cr  > nl-dr
              add      nl-cr to   total-cr
              subtract nl-dr from total-cr
              subtract nl-dr from nl-cr giving p-credit-l
              move     zero to p-debit-l.
*>
     move     space to empty.
*>
     if       output-reply = "P"
              go to output-print.
*>
     move     1 to cole.
     display  line-6-l at curs   with foreground-color 3.
     add      1 to lin.
     if       lin < ws-22-lines
              go to detail-loop.
*>
     display  c-continue at line ws-accept-lines col 01 with foreground-color 2.
     accept   ws-reply at line ws-accept-lines col 43.
     if       cob-crt-status = cob-scr-esc
              go to main-end.
*>
     move     7 to lin.
*>
 clr-scrn.
*>
     move     1 to cole.
     display  " " at curs with erase eol.
     add      1 to lin.
     if       lin < ws-accept-lines
              go to clr-scrn.
*>
     move     7 to lin.
     go       to detail-loop.
*>
 output-print.
*>
     write    print-record from line-6-l after 1.
     add      1 to line-cnt.
     if       line-cnt > 79
              perform print-headings
              perform account-headings.
*>
     go       to detail-loop.
*>
 main-end.
*>
     move     "/" to p-spacer-l.
     move     hold-owning to nl-owning.
     move     zero to nl-sub-nominal.
     move     9 to file-function.
     move     5 to access-type.
*>
     perform  call-irsub1.
*>
 main-exit.
     exit.
*>
 get-input-vat section.
*>--------------------
*>
     if       vat-ac-def not = 31
              move 9 to vat-check
              go to main-exit.
*>
     if       post-vat-side = "CR"
              move post-dr   to p-contra-l
              move vat-amount to p-credit-l
              move zero      to p-debit-l
              add  vat-amount to total-cr.
*>
     if       post-vat-side = "DR"
              move post-cr   to p-contra-l
              move vat-amount to p-debit-l
              move zero      to p-credit-l
              add  vat-amount to total-dr.
*>
 main-exit.
     exit.
*>
 get-output-vat section.
*>---------------------
*>
     if       vat-ac-def not = 32
              move 9 to vat-check
              go to main-exit.
*>
     if       post-vat-side = "CR"
              move post-dr   to p-contra-l
              move vat-amount to p-credit-l
              move zero      to p-debit-l
              add  vat-amount to total-cr.
*>
     if       post-vat-side = "DR"
              move post-cr   to p-contra-l
              move vat-amount to p-debit-l
              move zero      to p-credit-l
              add  vat-amount to total-dr.
*>
 main-exit.
     exit.
*>
*>-----------------------------------------------------------------
*>                      procedures
*>-----------------------------------------------------------------
*>
 display-report section.
*>*********************
*>
     move     zero to counter.
     move     space to use-code.
     if       not audit
              go to display-proceed.
*>
     display  " " at 0101 with erase eos.
     display  "Input Code to Print (blank for all) ....[  ]" at 0501 with foreground-color 2.
     accept   use-code at 0542 with foreground-color 6.
*>
 display-proceed.
*>
     add      1 to counter.
     move     counter to p-page.
     display  " " at 0101 with erase eos.
     if       vat-report
              move period-end to q-date
              move q-report   to p-report
     else
              move "Audit  Trail" to p-report.
*>
     display  line-1           at 0101 with foreground-color 2.
     display  line-3           at 0301 with foreground-color 3.
     display  "End Date -"     at 0329 with foreground-color 2.
     display  "Page"           at 0372 with foreground-color 2.
     if       vat-report
              display line-4-v at 0501 with foreground-color 2
              display line-5-v at 0601 with foreground-color 2
     else
              display line-4-a at 0501 with foreground-color 2
              display line-5-a at 0601 with foreground-color 2.
*>
     display  c-exit           at line ws-lines col 01  with foreground-color 2.
     move     8 to lin.
*>
 main-loop.
*>--------
     move     3 to file-function.
     perform  call-irsubp.
     if       we-error = 3 or = 99
              go to end-display1.
*>
     if       vat-report
              go to vat-area.
*>
     if       use-code not = spaces
         and  use-code not = post-code
              go to main-loop.
*>
     move     post-key to p-tran-a.
     move     post-code to p-code-a.
     move     post-date to p-date-a.
     move     post-dr to p-debit.
     move     post-cr to p-credit.
     move     post-amount to p-net.
     move     vat-amount to p-vat-amount.
     move     spaces     to p-vat-type
     if       vat-ac-def not numeric
              move  zero to vat-ac-def.
     if       vat-ac-def  = 31
              move  "Input" to p-vat-type.
     if       vat-ac-def  = 32
              move  "Output" to p-vat-type.
     go       to main-display.
*>
 vat-area.
*>
     move     post-key to p-tran-v.
     move     post-code to p-code-v.
     move     post-date to p-date-v  test-date.
     move     t-year  to wsa-yy.
     move     t-month to wsa-mm.
     move     t-days  to wsa-dd.
     if       wsa-post-date < wsb-start-date or > wsc-end-date
              go to  main-loop.
*>
     if       vat-ac-def not numeric
              move  zero to vat-ac-def.
*>
     if       vat-ac-def < 31 or > 32
              go to main-loop.
     if       vat-ac-def = 31
              move post-amount to p-in-net
              move vat-amount to p-in-vat
              move zero to p-out-net  p-out-vat.
     if       vat-ac-def = 31
       and    post-vat-side = "DR"
              add post-amount to total-in-net
              add vat-amount to total-in-vat.
     if       vat-ac-def = 31
       and    post-vat-side = "CR"
              subtract post-amount from total-in-net
              subtract vat-amount from total-in-vat
              multiply post-amount by -1 giving p-in-net
              multiply vat-amount by -1 giving p-in-vat.
     if       vat-ac-def = 32
              move post-amount to p-out-net
              move vat-amount to p-out-vat
              move zero to p-in-net  p-in-vat.
     if       vat-ac-def = 32
       and    post-vat-side = "CR"
              add post-amount to total-out-net
              add vat-amount to total-out-vat.
     if       vat-ac-def = 32
       and    post-vat-side = "DR"
              subtract post-amount from total-out-net
              subtract vat-amount from total-out-vat
              multiply post-amount by -1 giving p-out-net
              multiply vat-amount by -1 giving p-out-vat.
*>
 main-display.
*>-----------
*>
     move     1 to cole.
     if       audit
              display line-6-a at curs with foreground-color 3
     else
              display line-6-v at curs with foreground-color 3
     end-if
     add      1 to lin.
     if       lin < ws-accept-lines
              go to main-loop.
*>
     move     8 to lin.
     move     space to ws-reply.
     accept   ws-reply at line ws-lines col 43 with foreground-color 6.
     if       ws-reply = "X" or "x"
           or cob-crt-status = cob-scr-esc
              go to fast-quit-1.
*>
 screen-clear.
*>
     move     spaces to ws-reply.
     go       to display-proceed.
*>
 end-display1.
*>-----------
*>
     if       audit
              go to end-display1-return.
*>
     if       lin < ws-21-lines
              go to end-total-display.
*>
     move     8 to lin.
     accept   ws-reply at line ws-lines col 43.
*>
 end-screen-clear.
*>
     move     1 to cole.
     display  " " at curs  with erase eol.
     add      1 to lin.
     if       lin < ws-accept-lines
              go to end-screen-clear.
*>
     move     8 to lin.
     move     spaces to ws-reply.
*>
     add      1 to counter.
     move     counter to p-page.
     display  line-3 at 0301 with foreground-color 3.
*>
 end-total-display.
*>
     display  line-7 at line ws-21-lines col 01 with foreground-color 2.
     move     total-in-net  to t-in-net.
     move     total-in-vat  to t-in-vat.
     move     total-out-net to t-out-net.
     move     total-out-vat to t-out-vat.
     display  line-8 at line ws-22-lines col 01 with foreground-color 3.
     display  line-7 at line ws-accept-lines col 01 with foreground-color 2.
*>
 end-display1-return.
     display  "Press return for menu" at line ws-lines col 01 with erase eol foreground-color 2.
     accept   ws-reply at line ws-lines col 23.
*>
 fast-quit-1.
*>**********
*>
     move     2 to file-function.
     perform  call-irsubp.
*>
 display-report-exit.
     exit.
*>
 report-print section.
*>*******************
     move     spaces to save-code use-code.
     if       not audit
              go to print-proceed.
*>
     display  " " at 0101 with erase eos.
     display  "Input Code to Print (blank for all) ....[  ]" at 0501 with foreground-color 2.
     accept   use-code at 0542 with foreground-color 6.
*>
 print-proceed.
*>
     open     output print-file.
     initiate Audit-Report.
     move     zero to counter.
*>
     if       vat-report
              move period-end to q-date
              move q-report  to p-report
     else
              move "Audit  Trail" to p-report.
*>
     perform  headings.
*>
 main-loop-p.
*>-----------
     move     3 to file-function.
     perform  call-irsubp.
     if       we-error = 3 or = 99
              go to end-print.
*>
     if       vat-report
              go to vat-area-p.
*>
     if       use-code not = spaces
         and  use-code not = post-code
              go to main-loop-p.
*>
     if       sort-sequ = 1
         and  save-code not = post-code
         and  save-code not = spaces
              perform tran-total
              perform headings.
*>
     move     post-key to p-tran-a.
     move     post-code to p-code-a  save-code.
     move     post-date to p-date-a.
     move     post-dr to p-debit.
     move     post-cr to p-credit.
     move     post-amount to p-net.
     move     vat-amount to p-vat-amount.
     add      post-amount to total-in-net.
     add      vat-amount to total-in-vat.
     move     spaces     to p-vat-type
*>
     if       vat-ac-def not numeric
              move  zero to vat-ac-def.
*>
     if       vat-ac-def = 31
              move "Input" to p-vat-type.
     if       vat-ac-def = 32
              move "Output" to p-vat-type.
     go       to main-print.
*>
 vat-area-p.
*>
     if       vat-amount = zero
        and   post-amount = zero
              go to main-loop-p.
*>
     move     post-key to p-tran-v.
     move     post-code to p-code-v.
     move     post-date to p-date-v  test-date.
     move     t-year  to wsa-yy.
     move     t-month to wsa-mm.
     move     t-days  to wsa-dd.
     if       wsa-post-date < wsb-start-date or > wsc-end-date
              go to main-loop-p.
*>
     if       vat-ac-def not numeric
              move zero to vat-ac-def.
*>
     if       vat-ac-def < 31 or > 32
              go to  main-loop-p.
     if       vat-ac-def = 31
              move post-amount to p-in-net
              move vat-amount to p-in-vat
              move zero to p-out-net  p-out-vat.
     if       vat-ac-def = 31
       and    post-vat-side = "DR"
              add post-amount to total-in-net
              add vat-amount to total-in-vat.
     if       vat-ac-def = 31
       and    post-vat-side = "CR"
              subtract post-amount from total-in-net
              subtract vat-amount from total-in-vat
              multiply post-amount by -1 giving p-in-net
              multiply vat-amount by -1 giving p-in-vat.
     if       vat-ac-def = 32
              move post-amount to p-out-net
              move vat-amount to p-out-vat
              move zero to p-in-net  p-in-vat.
     if       vat-ac-def = 32
       and    post-vat-side = "CR"
              add post-amount to total-out-net
              add vat-amount to total-out-vat.
     if       vat-ac-def = 32
       and    post-vat-side = "DR"
              subtract post-amount from total-out-net
              subtract vat-amount from total-out-vat
              multiply post-amount by -1 giving  p-out-net
              multiply vat-amount by -1 giving  p-out-vat.
*>
 main-print.
*>---------
*>
     if       audit
              move line-6-a to print-record
     else
              move line-6-v to print-record.
*>
     write    print-record  after 1.
     add      1 to line-cnt.
     if       line-cnt > 79
              perform  headings.
     go       to main-loop-p.
*>
 end-print.
*>--------
*>
     if       line-cnt > 74
              perform headings.
     if       audit  go to tran-total.
*>
     move     total-in-net to t-in-net.
     move     total-in-vat to t-in-vat.
     move     total-out-net to  t-out-net.
     move     total-out-vat to  t-out-vat.
     write    print-record from line-7 after 2 lines.
     write    print-record from line-8 after 1.
     write    print-record from line-7 after 1.
     add      4 to line-cnt.
     go       to end-returne.
*>
 tran-total.
*>
     if       use-code not =  spaces
              move p-code-a to p-code-8
              move total-in-net to a-in-net
              move zero to total-in-net
              move total-in-vat to a-in-vat
              move zero to total-in-vat
              write print-record from line-7-a after 2
              write print-record from line-8-a after 1
              write print-record from line-7-a after 1
              add 4 to line-cnt.
*>
 end-returne.
*>----------
     terminate Audit-Report.
     close    print-file.
     call     "SYSTEM" using Print-Report.
     move     2 to file-function.
     perform  call-irsubp.
*>
 report-print-exit.
     exit.
*>
*> headings section.
*>---------------
*>
*>     add      1 to counter.
*>     move     counter to p-page.
*>     if       counter > 1
*>              write print-record from line-1 after page
*>     else
*>              write print-record from line-1 after 1
*>     end-if
*>     write    print-record from line-3 after 1.
*>     if       vat-report
*>              write print-record from line-4-v after 1
*>              write print-record from line-5-v after 1
*>     else
*>              write print-record from line-4-a after 1
*>              write print-record from line-5-a after 1
*>     end-if
*>     move     4 to line-cnt.
*>
*> main-exit.   exit.
*>********    ****
*>
 ledger-report section.
*>--------------------
*>
     move     1 to counter  p-page.
     move     1 to file-function  access-type.
     perform  call-irsub1.
     move     "L e d g e r s" to p-report.
     if       output-reply not = "P"
              go to start-ledgers.
     open     output  print-file.
     initiate Audit-Report.
     if       counter > 1
              write  print-record from line-1 after page
     else
              write  print-record from line-1 after 1.
     write    print-record from line-3   after 2.
     write    print-record from line-4-l after 2.
     move     5 to line-cnt.
*>
 start-ledgers.
*>
     display  " " at 0101 with erase eos.
     display  "Enter account code required (zero for all)............  [     ]"
                                                at 0601 with foreground-color 2.
     move     zero to target-account.
     accept   target-account at 0658 with foreground-color 6.
     if       target-account = zero
              go to main-loop.
*>
     move     target-account to nl-owning.
     move     zero  to nl-sub-nominal.
     move     4     to file-function.
     perform  call-irsub1.
     if       we-error = 2
              go to  start-ledgers.
*>
     perform  get-postings.
     go       to main-exit.
*>
 main-loop.
*>
     move     3 to file-function.
     perform  call-irsub1.
     if       we-error = 3
              go to main-exit.
*>
     perform  get-postings.
     if       ws-reply = "X"
          or  cob-crt-status = cob-scr-esc
              go to main-exit.
     go       to main-loop.
*>
 main-exit.
*>
     move     2 to file-function.
     perform  call-irsub1.
*>
     if       output-reply equal "P"
              terminate Audit-Report
              close  print-file
              call "SYSTEM" using Print-Report.
*>
 main-end.    exit.
*>
 get-postings section.
*>-------------------
*>
     if       nl-sub-nominal = zero
              move nl-owning to ledg-account  check-account
     else
              move nl-sub-nominal to ledg-account check-account.
*>
     move     nl-name to ledg-name.
*>
     if       output-reply equal "P"
              go to detaile.
*>
 main-display.
*>
     display  " "          at 0101 with erase eos.
     display  line-1       at 0101 with foreground-color 2.
     display  line-3       at 0301 with foreground-color 3.
     display  "End Date -" at 0329 with foreground-color 2.
     display  "Page"       at 0372 with foreground-color 2.
     display  line-ledger  at 0401 with foreground-color 3.
     display  "Account -"  at 0401 with foreground-color 2.
     display  line-4-l     at 0501 with foreground-color 2.
     move     7 to lin.
     add      1 to counter.
     move     counter to p-page.
*>
 detaile.
*>
     move     1 to file-function  access-type.
     perform  call-irsubp.
*>
     move     zero to total-dr  total-cr ws-account-used.
     move     "Y" to empty.
*>
 detail-loop.
*>
     move     3 to file-function.
     perform  call-irsubp.
*>
     if       we-error = 3
              go to totals.
     if       we-error = 99
              go to total-jump.
*>
     if       check-account not = post-dr and not = post-cr
                        and not = def-acs-31 and not = def-acs-32
              go to detail-loop.
*>
     if       do-print and output-reply = "P"
              perform  account-headings
              move space to empty.
     move     1 to ws-account-used.
     move     post-code to p-code-l.
     move     post-key  to p-tran-l.
     move     post-date to p-date-l.
     move     spaces    to p-legend-l.
     string   post-legend delimited by low-value into p-legend-l.
*>
     if       check-account = post-dr
              move post-cr    to p-contra-l
              move post-amount to p-debit-l
              move zero       to p-credit-l
              add  post-amount to total-dr.
*>
     if       check-account = post-dr
         and  post-vat-side = "CR"
              add  vat-amount to post-amount
              move post-amount to p-debit-l
              add  vat-amount to total-dr.
*>
     if       check-account = post-cr
              move post-dr    to p-contra-l
              move post-amount to p-credit-l
              move zero       to p-debit-l
              add  post-amount to total-cr.
*>
     if       check-account = post-cr
        and   post-vat-side = "DR"
              add  vat-amount to post-amount
              move post-amount to p-credit-l
              add  vat-amount to total-cr.
*>
     if       check-account = def-acs-31
              perform get-input-vat
              if      vat-amount = zero
                      move zero to vat-check
                      go to detail-loop.
*>
     if       check-account = def-acs-32
              perform get-output-vat
              if      vat-amount = zero
                      move zero to vat-check
                      go to detail-loop.
*>
     if       vat-check = 9
              move  zero to vat-check
              go to detail-loop.
*>
     if       output-reply equal "P"
              go to output-print.
*>
     move     1 to cole.
     display  line-6-l at curs with foreground-color 3.
     add      1 to lin.
     if       lin < ws-accept-lines
              go to detail-loop.
*>
     display  c-exit   at line ws-lines col 01 with foreground-color 2.
     accept   ws-reply at line ws-lines col 43.
     if       ws-reply = "x" or "X"
           or cob-crt-status = cob-scr-esc
              move "X" to ws-reply
              go to total-jump.
*>
     perform  main-display.
     go       to detail-loop.
*>
 output-print.
*>
     write    print-record from line-6-l after 1.
     add      1 to line-cnt.
     if       line-cnt > 74
              perform print-headings
              perform account-headings.
     go       to detail-loop.
*>
 totals.
*>
     if       nl-sub-nominal = zero
              perform sub-nominal-search.
*>
     if       ws-account-used = zero   *> had no postings so skip
              go to total-jump.
     if       do-print and output-reply = "P"
              go to total-jump.
*>
     move     total-cr to t-cr-total.
     move     total-dr to t-dr-total.
*>
     move     spaces to bal-name l7-d1 l7-d2.
     move     1 to p.
     string   nl-name delimited by "  " into bal-name pointer p.
     string   "  Balance" delimited by size into bal-name pointer p.
     subtract total-cr from total-dr.
     if       total-dr  > zero
              move total-dr to b-dr-total
              move zero    to b-cr-total
              move all "=" to l7-d1
     else
              move all "=" to l7-d2
              move total-dr to b-cr-total
              move zero    to b-dr-total.
*>
     if       output-reply = "P" and
              line-cnt > 78
              perform print-headings.
*>
     if       output-reply equal "P"
              write print-record from line-7-m after 1
              write print-record from line-8-l after 1
              write print-record from line-7-m after 1
              write print-record from line-9-l after 1
              write print-record from line-7-l after 1
              add 5 to line-cnt
              go to total-jump.
*>
     if       lin > ws-17-lines
              perform total-cont
              if  cob-crt-status = cob-scr-esc
                  move "X" to ws-reply
                  go to total-jump
              end-if
              perform main-display.
*>
     add      1 to lin.
     move     1 to cole.
     display  line-7-m at curs with foreground-color 2.
     add      1 to lin.
     display  line-8-l at curs with foreground-color 3.
     add      1 to lin.
     display  line-7-m at curs with foreground-color 2.
     add      1 to lin.
     display  line-9-l at curs with foreground-color 3.
     add      1 to lin.
     display  line-7-l at curs with foreground-color 2.
*>
 total-cont.
*>
     display  " "  at line ws-lines col 01 with erase eol.
     display  c-continue at line ws-lines col 01 with foreground-color 2.
     accept   ws-reply   at line ws-lines col 43.
*>
 total-jump.
*>
     move     zero to ac-marker.
     move     2 to file-function.
     perform  call-irsubp.
*>
 main-exit.   exit.
*>
 account-headings section.
*>========================
*>
     if       line-cnt > 70
              perform  print-headings.
     move     1 to ac-marker.
     write    print-record from line-ledger after 2.
     move     spaces to print-record.
     write    print-record after 1.
     add      3 to line-cnt.
*>
 main-exit.   exit.
*>
 print-headings section.
*>======================
*>
     add      1 to counter.
     move     counter to p-page.
     if       counter > 1
              write print-record from line-1 after page
     else
              write print-record from line-1 after 1.
     write    print-record from line-3 after 2.
     write    print-record from line-4-l after 2.
     move     5 to line-cnt.
*>
 main-exit.   exit.
