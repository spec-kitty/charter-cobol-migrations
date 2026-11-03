       >>source free
*>*****************************************************************
*>                                                                *
*>      P O S T F I L E   A N A L Y S I S   R E P O R T           *
*>                                                                *
*> This module uses the Report Writer function in Gnu COBOL v2.1  *
*>      the one without RW is called irs090-non-rw.cbl            *
*>                                                                *
*>*****************************************************************
*>
 identification division.
 program-id.            irs090.
*>
*> author.              V.B.COEN, MBCS for Applewood Computers.
*>
*>Security.             Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*>
*> remarks.             Report of posting file by month.
*>
*> version.             see prog-name in ws.
*>
*> changes.
*> 28/05/84 vbc - hilite display heads.
*> 03/03/85 vbc - modify where amounts are added to ws-years.
*> 26/09/89 vbc - mods for cobol/2.
*> 23/01/09 vbc - Migration to Open Cobol as version 3.
*> 20/02/09 vbc - It is not a bug for there to be minus zero in reports.
*> 21/02/09 vbc - Added support for env's LINES and COLUMNS as needed. NOT
*> 28/02/09 vbc - Get rid of the -0 figures with no success must be a OC issue.
*> 07/09/10 vbc - .10 Mod lpr.
*> 21/09/10 vbc - Added print spool.
*> 16/12/13 vbc - .11 Rewritten for GNU Cobol Report Writer functions in V2.1.
*>                     LATEST version without rw is called irs020-non-rw but
*>                          check version number (just in case).
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
*> copy "envdiv.cob".
 configuration section.
 source-computer.      Linux.
 object-computer.      Linux.
*> special-names.
*>     console is crt.
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
     select  work-file       assign "workpost.tmp"
                             organization sequential
                             status fs-reply.
*>
     select  work-file-2     assign "work2.tmp"
                             organization indexed
                             access dynamic
                             record wl4-no
                             status fs-reply.
*>
     select  print-file      assign "prt-1"
                             organization line sequential.
*>
 data division.
*>**************
*>
 file section.
*>-------------
*>
 fd  work-file.
*>
 01  work-record.
     03  work-mm         pic 99.
     03  work-account    pic 9(5)      comp.
     03  work-amount     pic s9(7)v99  comp.
*>
 fd  nominal-ledger.
*> copy "fdwsnl.cob".
*>
*> Chg'd 16/01/09 money to 99M
*>
 01  record-1.
     03  key-1.
         05  owning      pic 9(5).
         05  sub-nominal pic 9(5).
     03  tipe            pic x.
         88 nl-sub-ac               value "S".
     03  record-data.
         05  nl-name     pic x(24).
         05  dr          pic 9(8)v99   comp.
         05  cr          pic 9(8)v99   comp.
         05  dr-last     pic 9(8)v99   comp  occurs  4.
         05  cr-last     pic 9(8)v99   comp  occurs  4.
         05  ac          pic x.
     03  filler  redefines  record-data.
         05  rec-pointer pic 9(5).
*>
 fd  work-file-2.
*>
 01  work-record-2.
     03  filler.
         05  wl4-no      pic 9(5)  comp.
     03  wl4-group       pic x(126).
*>
 fd  print-file
     report Postfile-Analysis-Report.
*>
 working-storage section.
 77  prog-name           pic x(16)  value "irs090 (3.01.11)".
 77  fs-reply            pic xx.
 77  sr-reply            pic 99     value zeros.
*> copy "print-spool-command.cob".
*>
*> Landscape
*>
 01  Print-Report.
     03  filler          pic x(117)     value
     "lpr -r -o 'orientation-requested=4 page-left=18 page-top=48 " &
     "page-right=10 sides=two-sided-long-edge cpi=12 lpi=8' -P ".
     03  PSN             pic x(48)      value "HPLJ4TCP ".  *> This is the Cups print spool, change it for yours
     03  filler          pic x(15)      value "prt-1".      *> Don't change this line
*>
 01  filler.
     03  nl-file         pic x(11).
     03  a               pic 99        comp            value zero.
     03  b               pic 99        comp            value zero.
     03  z               pic s9(8)      comp           value zero.
     03  ws-saved-account pic 9(5)     comp            value zero.
     03  ws-mths         pic s9(8)v99   comp     occurs 12.
     03  ws-years        pic s9(8)      comp               value zero.
     03  ws-mlits-a      pic x(60)    value " JAN  FEB MARCHAPRIL " &
          "MAY  JUNEJULY  AUG SEPT  OCT  NOV  DEC ".
     03  ws-mlits-b  redefines ws-mlits-a
                         pic x(5) occurs 12.
*>
     03  ws-l4-group.
         05  ws-l4-type   pic xb.
         05  ws-l4-name   pic x(20).
         05  ws-l4-month  pic -(7)9    occurs 12.
         05  ws-l4-total  pic -(7)9.
*>
     03  ws-Head-Months.
         05  ws-l3-lmonths                occurs 12.
             07  filler         pic xxx.
             07  ws-l3-litmonth pic x(5).
*>
*> copy "wsfnctn.cob".
*>**********************************
*>                                 *
*>  Sub-Program Control Functions  *
*>                                 *
*>**********************************

 01  file-access.
     03  file-function   pic 9.
         88  fn-open            value is 1.
         88  fn-close           value is 2.
         88  fn-read-next       value is 3.
         88  fn-read-indexed    value is 4.
         88  fn-write           value is 5.
         88  fn-spare           value is 6.
         88  fn-re-write        value is 7.
         88  fn-delete          value is 8.
         88  fn-start           value is 9.

     03  access-type     pic 9.
         88  fn-input           value is 1.
         88  fn-i-o             value is 2.
         88  fn-output          value is 3.
         88  fn-extend          value is 4.
         88  fn-equal-to        value is 5.
         88  fn-less-than       value is 6.
         88  fn-greater-than    value is 7.

     03  we-error        pic 999.
     03  file-names.
         05  file-1      pic x(9).
         05  file-2      pic x(10).
         05  file-3      pic x(8).
         05  file-4      pic x(8).
         05  file-5      pic x(12).
         05  file-6      pic x.
         05  filler      pic x.
*>
*>
 linkage   section.
*>*****************
*>
*> copy "wssystem.cob".
*>*******************************************
*>                                          *
*>  Working Storage for the System File     *
*>   Incomplete Records System ONLY         *
*>                                          *
*>*******************************************
*> 256 bytes (01/03/09)
*> 288 bytes 21/09/10 - added print-spool-name
*> 312 bytes 21/11/11 - Added first-time-flag, two extra vat rates and 15 byte filler
*>
 01  system-record.
     03  run-date           pic x(8).
     03  suser              pic x(24).
     03  client             pic x(24). *> 56
     03  address-1          pic x(24). *> 80
     03  address-2          pic x(24).
     03  address-3          pic x(24). *> 128
     03  address-4          pic x(24). *> 152
     03  start-date         pic x(8).  *> 160
     03  end-date           pic x(8).  *> 168
     03  system-files.
       05  fn-1             pic x(9).  *> acts 177
       05  fn-2             pic x(10). *> system  187
       05  fn-3             pic x(8).  *> dflt  195
       05  fn-4             pic x(8).  *> post 203
       05  fn-5             pic x(12). *> prn  215
       05  filler           pic x.
       05  system-ops       pic x.     *> 217  (49 + 168)
     03  pass-word          pic x(4).  *> 221
     03  next-post          pic 9(5).  *> 226
     03  vat-rates.
         05  vat            pic 99v99. *> 230   *> Standard
         05  vat2           pic 99v99. *> 234   *> reduced 1 [not yet used]
         05  vat3           pic 99v99. *> 238   *> reduced 2 [not yet used]
     03  vat-group redefines vat-rates.
         05  vat-psent      pic 99v99    occurs 3.
     03  pass-value         pic 9.
     03  save-sequ          pic 9.     *> 240
     03  system-work-group  pic x(18). *> 258
     03  PL-App-Created     pic x.     *> 259
     03  PL-Approp-AC       pic 9(5).  *> 264
     03  Print-Spool-Name   pic x(32). *> 296
     03  First-Time-FLag    pic 9.     *> 297
     03  filler             pic 9(7).  *> 304
     03  filler             pic x(8).  *> 312
*>
 report section.
*>**************
*>
 rd  Postfile-Analysis-Report
     control is final
     page limit is 48
     heading 1
     first detail 6
     last  detail 48.
*>
 01  type page heading.
     03  line 1.
         05  col   1     pic x(32)     source client.
         05  col  56     pic x(23)    value "Monthly Analysis Report".
         05  col 109     pic x(8)      source run-date.
         05  col 125     pic x(4)     value "Page".
         05  col 130     pic zz9       source Page-Counter.
*>
     03  line + 2.
         05  col   1     pic x(28)    value "<----------Account--------->".
         05  col  30     pic x        value "<".
         05  col  31     pic x(46)    value all "-".
         05  col  77     pic x(4)     value "Year".
         05  col  81     pic x(43)    value all "-".
         05  col 124     pic x        value ">".
*>
     03  line + 1.
         05  col   3     pic x(26)    value "No Typ      Name".
         05  col  29     pic x(96)     source ws-Head-Months.
         05  col 127     pic x(5)     value "Total".
*>
 01  Analysis-Detail type detail.
     03  line + 1.
         05  col   1     pic z(4)9     source Wl4-No.
         05  col   6     pic x(126)    source WL4-Group.
*>
 01  type control footing final line plus 3.
     03  line + 3.
         05  col 1        pic x(46)   value "Note that above values are subject to rounding".
*>
 procedure division using system-record.
*>**************************************
*>
 la-control section.
*>***************
*>
     perform  lb-init.
     perform  lc-process.
     perform  ld-output-final.
     perform  le-close.
*>
 laa-exit.
     exit     program.
*>
 lb-init section.
*>****************
*>
     move     system-files to file-names.
     move     file-1 to nl-file.
     move     zero to a b.
     perform  varying b from 1 by 1 until b > 12 move zeros to ws-mths (b)
     end-perform.
*>
 lbb-screen-heads.
*>
     display  prog-name                               at 0101 with foreground-color 2 erase eos.
     display  "Monthly Analysis Report"               at 0130 with foreground-color 1 background-color 7.
     display  run-date                                at 0173 with foreground-color 2.
     display  "You will need 132 column wide paper"   at 0623 with foreground-color 3.
     display  "Which Month does your Tax Year start (01-12)  [  ]" at 1201 with foreground-color 2.
*>
 lbc-get-year-start.
*>
     accept   sr-reply at 1248 with foreground-color 3.
     if       sr-reply < 01 or > 12
              go to lbc-get-year-start.
*>
     open     input  work-file nominal-ledger.
     open     output  print-file work-file-2.
     initiate Postfile-Analysis-Report.
     perform  lzc-set-report-months thru lzc-exit.
     move     zero to a b.
*>
 lbz-exit.    exit section.
*>
 lc-process section.
*>******************
*>
 lca-start.
*>
     read     work-file at end
              perform  lze-print-line thru lzf-exit
              go to lcz-exit.
     if       ws-saved-account = zero
              perform lzf-get-nominal thru lzf-exit
              move work-account to ws-saved-account.
*>
     if       ws-saved-account not = work-account
              perform lze-print-line thru lze-exit
              perform lzf-get-nominal thru lzf-exit
              move work-account to ws-saved-account.
     if       work-mm < 01 or > 12
              move 01 to work-mm.
     add      work-amount to ws-mths (work-mm).
     go       to lca-start.
*>
 lcz-exit.    exit section.
*>
 ld-output-final section.
*>***********************
*>
     close    nominal-ledger work-file-2.
     open     input nominal-ledger work-file-2.
*>
 ldb.
*>
     perform  lzg-read-nl-seq thru lzg-exit.
     if       fs-reply = "FE"
              go to ldz-exit.
     move     owning to wl4-no.
     read     work-file-2  invalid key
              go to ldb.
*>
     if       wl4-no not = owning
              go to ldb.
     generate Analysis-Detail.
     go       to ldb.
*>
 ldz-exit.    exit section.
*>
 le-close section.
*>****************
*>
     close    print-file work-file nominal-ledger work-file-2.
     terminate Postfile-Analysis-Report.
     move     Print-Spool-Name to PSN.
     call     "SYSTEM" using Print-Report.
     open     output  work-file-2 work-file.			*> clear down file data
     close    work-file-2 work-file.
*>
 lez-exit.    exit section.
*>*********************************************
*>                                            *
*>  Common routines used in the above code    *
*>                                            *
*>*********************************************
*>
 lz-common-routines section.
*>**************************
*>
 lzc-set-report-months.
*>
     move     1 to a.
     move     sr-reply to b.
*>
 lzc-set-mth.
*>
     move     ws-mlits-b (b)  to  ws-l3-litmonth (a).
     add      1 to a.
     add      1 to b.
     if       a > 12
              go to lzc-exit.
     if       b > 12
              move 1 to b.
*>
     go       to lzc-set-mth.
*>
 lzc-exit.    exit.
*>
 lze-print-line.
*>
     move     1 to a.
     move     sr-reply to b.
*>
 lze-set-mth.
*>
     if       (ws-mths (b) = 0 and ws-mths (b) negative)
           or ws-mths (b) = -0
              move +0 to ws-mths (b).    *> yep , but it doesnt work
     move     ws-mths (b)  to  z.
     add      z to ws-years.
     move     ws-mths (b)  to  ws-l4-month (a).
     add      1 to a.
     add      1 to b.
     if       a > 12
              go to lze-work.
     if       b > 12
              move 1 to b.
     go       to lze-set-mth.
*>
 lze-work.
*>
     move     nl-name to ws-l4-name.
     if       sub-nominal = zero
              move owning to wl4-no
              move "M" to ws-l4-type
       else
              move sub-nominal to wl4-no
              move "S" to ws-l4-type.
*>
     move     ws-years to ws-l4-total.
     move     zero to ws-years.
     perform  varying b from 1 by 1 until b > 12
              move zero to ws-mths (b)
     end-perform
     move     ws-l4-group to wl4-group.
     write    work-record-2 invalid key
              move "FF" to fs-reply.
     if       fs-reply not = zero
              display "090-01 Reply - " at 1601
              display fs-reply at 1616
              display "NOTE ERROR & Hit Return" at 1625
              accept fs-reply at 1740
              go to lcz-exit.
*>
 lze-exit.    exit.
*>
 lzf-get-nominal.
*>
     move     work-account to owning.
     move     zero    to sub-nominal.
*>
 lzf-read.
*>
     read     nominal-ledger invalid key
              display owning at 1401 with foreground-color 3
              display "Does not exist..Aborting" at 1407 with foreground-color 2
              display "Note error & Hit return to continue" at 1434
              accept fs-reply at 1471
              stop run.
*>
*>    Get pointer to Sub nominal to find main a/c
*>
     if       tipe = "S"
              move owning to sub-nominal
              move rec-pointer to owning
              go to lzf-read.
*>
*>    At this point, we have got the record we want
*>
 lzf-exit.    exit.
*>
 lzg-read-nl-seq.
*>
     read     nominal-ledger next record at end
              move "FE" to fs-reply.
*>
     if       fs-reply = "FE"
              go to lzg-exit.
*>
     if       tipe = "S"
              go to lzg-read-nl-seq.
     if       sub-nominal not = zeros
              move sub-nominal to owning.
*>
 lzg-exit.    exit.
