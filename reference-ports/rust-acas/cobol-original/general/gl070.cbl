       >>source free
*>******************************************************
*>                                                     *
*>                Transaction  Posting                 *
*>                                                     *
*>******************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         gl070.
*>**
*>    author.             V.B.Coen, FBCS,
*>                        Converted For Cis January 85,
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Transaction Pre-Process & If Errors Batch
*>                        Display.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps04.
*>**
*>    Error messages used.
*>                        NONE
*>**
*>   Changes:
*> 28/01/09 vbc - Migration to Open Cobol.
*> 20/12/11 vbc - .02 Support for dates other than UK & clean up msgs
*>                    Error msgs to GLnnn, Support for path+filenames.
*>                    Support for Page-Lines instead of fixed number.
*>
*>>*************************************************************************
*>>
*>> Copyright Notice.
*>>*****************
*>>
*>> This file/program is part of the Applewood Computers Accounting System
*>> and is copyright (c) Vincent B Coen. 1976-2012 and later.
*>>
*>> This program is free software; you can redistribute it and/or modify it
*>> under the terms of the GNU General Public License as published by the
*>> Free Software Foundation; version 2 ONLY.
*>>
*>> ACAS is distributed in the hope that it will be useful, but WITHOUT
*>> ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
*>> FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
*>> for more details. If it breaks, you own both pieces but I will endevor
*>> to fix it, providing you tell me about the problem.
*>>
*>> You should have received a copy of the GNU General Public License along
*>> with ACAS; see the file COPYING.  If not, write to the Free Software
*>> Foundation, 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
*>>*************************************************************************
*>>
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
     select  pre-trans  assign  pre-trans-name,
                        access  sequential
                        status  fs-reply
                        organization  line sequential.
*>
 copy "selpost.cob".
*>
 copy "selbatch.cob".
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 fd  pre-trans.
*>
 01  pre-trans-record.
     03  pre-batch       pic 9(5).
     03  pre-post        pic 9(5).
     03  pre-code        pic xx.
     03  pre-date        pic x(8).
     03  pre-ac          pic 9(6).
     03  pre-pc          pic 99.
     03  pre-amount      pic s9(8)v99.
     03  pre-legend      pic x(32).
*>
 copy "fdpost.cob".
 copy "fdbatch.cob".
 working-storage section.
*>----------------------
*>
 77  prog-name               pic x(15)  value "gl070 (3.00.02)".
*>
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
*>
 01  work-fields.
     03  a                   pic 9.
     03  y                   binary-char  value zero.
     03  ws-reply            pic x.
*>
     03  ws-env-lines    pic 999       value zero.
     03  ws-lines        binary-char unsigned value zero.
     03  ws-23-lines     binary-char unsigned value zero.
     03  ws-22-lines     binary-char unsigned value zero.
     03  ws-21-lines     binary-char unsigned value zero.
     03  ws-20-lines     binary-char unsigned value zero.
     03  Body-lines      binary-char unsigned value zero.
*>
 01  All-My-Constants    pic 9(4).
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
*> 01  Error-Messages.
*> System Wide
*>    03  GL010           pic x(16) value "GL010 Hit Return".
*> Module specific
*>    03  GL110           pic x(24) value "GL110 No check on items.".
*>
 01  line-1.
     03  l1-prog             pic x(31).
     03  l1-lit1             pic x(41)   value "Batch Status Report".
     03  l1-lit2             pic x(6)    value " Page ".
     03  l1-page             pic z9.
*>
 01  line-3.
     03  l3-lit1             pic x(8)    value "Cycle - ".
     03  l3-cycle            pic z9.
     03  l3-lit2             pic x(60)   value spaces.
     03  l3-date             pic x(10).
*>
 01  line-4.
     03  l4-lit1             pic x(48)   value "Ledger  Batch  Status       Last".
     03  l4-lit2             pic x(32)   value "---------Batch Controls---------".
*>
 01  line-5.
     03  l5-lit1             pic x(48)   value "------  -----  ------     Activity".
     03  l5-lit2             pic x(32)   value "Items  ---Gross---- -----VAT----".
*>
 01  line-6.
     03  l6-ledger           pic x(8).
     03  l6-batch            pic z(4)9bb.
     03  l6-status           pic x(11).
     03  l6-date             pic x(14).
     03  l6-lit1             pic x(9)    value "Header   ".
     03  l6-items            pic z9bbbb.
     03  l6-gross            pic z(8)9.99b.
     03  l6-vat              pic z(8)9.99  blank when zero.
*>
 01  line-7.
     03  filler              pic x(40)   value spaces.
     03  l7-lit1             pic x(9)    value "Actual   ".
     03  l7-items            pic z9bbbb.
     03  l7-gross            pic z(8)9.99b.
     03  l7-vat              pic z(8)9.99  blank when zero.
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
 01  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 init01 section.
*>*************
*>
     accept   ws-env-lines   from lines.
     if       ws-env-lines < 24
              move  24 to ws-env-lines ws-lines
     else
              move  ws-env-lines   to ws-lines
     end-if
     subtract 1 from ws-lines giving ws-23-lines.
     subtract 2 from ws-lines giving ws-22-lines.
*>     subtract 3 from ws-lines giving ws-21-lines.
*>     subtract 4 from ws-lines giving ws-20-lines.
*>     subtract 11 from ws-lines giving Body-Lines.
*>
*> Force Esc, PgUp, PgDown, PrtSC to be detected
*>
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     perform  zz070-convert-date.
     move     ws-date to l3-date.
 menu-input.
*>*********
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Transaction Posting" at 0132  with foreground-color 2.
     display  ws-date at 0171 with foreground-color 2.
*>
 menu-input2.
*>
     move     zero  to  a.
     display  "Phase - 1.  Batch Check" at 0801  with foreground-color 2.
     perform  gl071a.
*>
     if       a = 1
              perform gl060a
              move 5 to ws-term-code
              go to  main-exit.
*>
     display  "Phase - 2.  Transaction Pre-process" at 0801 with foreground-color 2.
     perform  gl071b.
*>
 main-exit.
*>********
*>
     exit     program.
*>
 gl071a section.
*>*************
*>
     open     input  batch-file.
*>
 loop.
*>***
*>
     read     batch-file  next record  at end
              go to  end-run.
*>
     if       bcycle not = scycle
              go to  loop.
     if       status-open
              move  1  to  a.
     go       to loop.
*>
 end-run.
*>******
*>
     close    batch-file.
*>
 main-exit.   exit section.
*>
 gl060a section.
*>*************
*>
     perform  menu-input.
*>
     perform  zz070-convert-date.
     move     ws-date to l3-date.
     display  line-1 at 0301 with foreground-color 2.
     move     scycle  to  l3-cycle.
     move     1      to  y.
     move     y      to  l1-page.
     display  l3-lit1 at 0301 with foreground-color 2.
     display  l3-cycle at 0309 with foreground-color 2.
     display  line-4 at 0501 with foreground-color 2.
     display  line-5 at 0601 with foreground-color 2.
     move     7  to   lin.
     move     1 to cole.
     open     input  batch-file.
*>
 loop.
*>***
*>
     read     batch-file  next record  at end
              go to  end-report.
*>
     if       bcycle not = scycle
              go to  loop.
*>
     if       gl-batch
              move  " G/L"  to  l6-ledger.
     if       pl-batch
              move  " P/L"  to  l6-ledger.
     if       sl-batch
              move  " S/L"  to  l6-ledger.
*>
     move     batch-nos     to  l6-batch.
*>
     if       stored not = zero
              move  stored  to  u-bin
              perform  zz060-Convert-Date
              go to next-1.
*>
     if       posted not = zero
              move  posted  to  u-bin
              perform  zz060-Convert-Date
              go to next-1.
*>
     if       proofed not = zero
              move  proofed  to  u-bin
              perform  zz060-Convert-Date
              go to next-1.
*>
     if       entered not = zero
              move  entered  to  u-bin
              perform  zz060-Convert-Date.
*>
 next-1.
*>*****
*>
     move     ws-date  to  l6-date.
*>
     if       status-open
              move  "Open"  to  l6-status.
*>
     if       status-closed
       and    waiting
              move  "Waiting"  to  l6-status.
     if       status-closed
       and    processed
              move  "Processed"  to  l6-status.
     if       status-closed
       and    archived
              move  "Archived"  to  l6-status.
*>
     move     items  to  l6-items l7-items.
     move     input-gross  to  l6-gross.
     move     input-vat    to  l6-vat.
     move     actual-gross  to  l7-gross.
     move     actual-vat    to  l7-vat.
*>
     add      0100 curs giving curs2.
*>
     display  line-6 at curs2 with foreground-color 2.
     add      1 to lin2.
     display  line-7 at curs2 with foreground-color 2.
     add      3  to  lin.
*>
     if       lin  <  ws-21-lines
              go to  loop.
*>
     display  "Enter <N> for next screen or <X> to exit :- [ ]" at line ws-22-lines col 01 with foreground-color 2.
*>
 screen-option.
*>************
*>
     accept   ws-reply at line ws-22-lines col 46 with foreground-color 6.
*>
     if       ws-reply = "X"  or  "x"
              go to  end-report.
*>
     perform  screen-clear.
     go       to  loop.
*>
 screen-clear.
*>***********
*>
     move     7  to  lin.
     display  " " at curs with erase eos.
*>
 end-report.
*>*********
*>
     display  "Type return to exit." at line ws-22-lines col 01.
     accept   ws-reply at line ws-22-lines col 22 with foreground-color 2.
     close    batch-file.
*>
 main-exit.   exit section.
*>
 gl071b section.
*>*************
*>
     open     output  pre-trans.
     open     input  batch-file.
*>
 loop.
*>***
*>
     read     batch-file  next record  at end
              go to  end-run.
*>
     if       bcycle not = scycle
              go to  loop.
*>
     if       status-open
           or not waiting
           or not gl-batch
              go to  loop.
*>
     perform  gl071b-pre-process.
     close    posting-file.
     go       to loop.
*>
 end-run.
*>******
*>
     close    batch-file pre-trans.
*>
 main-exit.   exit section.
*>
 gl071b-pre-process section.
*>-------------------------
*>
     move     batch-nos  to  pre-batch.
     open     input  posting-file.
*>
 loop.
*>***
*>
     read     posting-file  next record  at end
              go to  main-exit.
*>
     if       post-key = zero
              go to  loop.
     if       batch  not = batch-nos
              go to  loop.
*>
     move     batch        to  pre-batch.
     move     post-number  to  pre-post.
     move     post-code in posting-record   to  pre-code.
     move     post-date    to  pre-date.
     move     post-legend  to  pre-legend.
*>
     move     post-dr      to  pre-ac.
     move     dr-pc        to  pre-pc.
     if       post-vat-side = "CR"
              add  post-amount  vat-amount  giving  pre-amount
     else
              move post-amount  to  pre-amount.
*>
     write    pre-trans-record.
*>
     move     post-cr      to  pre-ac.
     move     cr-pc        to  pre-pc.
     if       post-vat-side = "DR"
              add  post-amount  vat-amount  giving  pre-amount
     else
              move post-amount  to  pre-amount.
*>
     multiply pre-amount  by  -1  giving  pre-amount.
*>
     write    pre-trans-record.
*>
     if       vat-ac of posting-record = zero
           or vat-amount = zero
              go to  loop.
*>
     move     vat-ac of posting-record  to  pre-ac.
     move     vat-pc           to      pre-pc.
     move     vat-amount       to      pre-amount.
*>
     if       post-vat-side = "CR"
              multiply  pre-amount  by  -1 giving pre-amount.
*>
     write    pre-trans-record.
     go       to loop.
*>
 main-exit.   exit section.
*>********    ****
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
