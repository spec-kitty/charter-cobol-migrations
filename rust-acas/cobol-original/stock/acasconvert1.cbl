       >>source free
 identification division.
 program-id.                 acasconvert1.
*>Author.                    Vincent B Coen, MBCS. 02/05/09.
*>
*>Security.                  Copyright (C) 1982-2009, Vincent Bryan Coen.
*>                           Distributed under the GNU General Public License
*>                           v2.0. Only. See the file COPYING for details.
*>
*>Purpose.                   Convert ACAS system file/s for Stock & OE.
*>
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of the Applewood Computers Accounting System
*>   and is copyright (c) Vincent B Coen. 1976 - 2009 and later.
*>
*> This program is free software; you can redistribute it and/or modify it
*> under the terms of the GNU General Public License as published by the
*> Free Software Foundation; version 2 ONLY.
*>
*> Cobxref is distributed in the hope that it will be useful, but WITHOUT
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
 configuration section.
 source-computer.        Linux.
 object-computer.        Linux.
 input-output section.
 file-control.
 copy "selsys.cob".

 data division.
 file section.
 copy "fdsys.cob".
*>
 01  new-system-record.
*>******************
*>   system data   *
*>******************
     03  vat-rates                    comp.
         05 vat-rate-1   pic 99v99.
         05 vat-rate-2   pic 99v99.
         05 vat-rate-3   pic 99v99.
     03  vat-rate redefines vat-rates pic 99v99 comp occurs 3.
     03  cyclea          binary-char.
     03  scycle redefines cyclea  binary-char.
     03  period          binary-char.
     03  next-invoice    binary-long.
     03  run-date        binary-long.
     03  start-date      binary-long.
     03  end-date        binary-long.
     03  usera           pic x(32).
     03  user-code       pic x(32).
     03  address-1       pic x(24).
     03  address-2       pic x(24).
     03  address-3       pic x(24).
     03  address-4       pic x(24).
     03  filler          pic x(96).                 *>  ??
     03  file-status     pic 9          occurs 32.  *> ???
     03  pass-value      pic 9.
     03  level.
         05  level-1     pic 9.
             88  g-l                    value 1.
         05  level-2     pic 9.
             88  b-l                    value 1.
         05  level-3     pic 9.
             88  s-l                    value 1.
     03  pass-word       pic x(4).
     03  host            pic 9.
         88  multi-user                 value 1.
     03  Op-System       pic 9.
         88  Dos                        value 1.
         88  Windows                    value 2.
         88  Mac                        value 3.
         88  Os2                        value 4.
         88  Unix                       value 5.
         88  Linux                      value 6.
     03  Current-Quarter pic 9.
     03  filler          pic x(12).
*>***************
*>   G/L Data   *
*>***************
     03  p-c             pic x.
         88  profit-centres             value "P".
         88  branches                   value "B".
     03  p-c-grouped     pic x.
         88  grouped                    value "Y".
     03  p-c-level       pic x.
         88  revenue-only               value "R".
     03  comps           pic x.
         88  comparatives               value "Y".
     03  comps-active    pic x.
         88  comparitves-active         vaLUE "Y".
     03  m-v             pic x.
         88  minimum-validation         vaLUE "Y".
     03  arch            pic x.
         88  archiving                  value "Y".
     03  trans-print     pic x.
         88  mandatory                  value "Y".
     03  trans-printed   pic x.
         88  trans-done                 value "Y".
     03  header-level    pic 9.
     03  sales-range     pic 9.
     03  purchase-range  pic 9.
     03  vat             pic x.
         88  auto-vat                   value "Y".
     03  batch-id        pic x.
         88  preserve-batch             value "Y".
     03  SL-Day-Book     pic 9.
     03  SL-Own-Nos      pic x.
     03  ledger-2nd-index pic x.
         88  index-2                    value "Y".
     03  SL-Late-Per     pic 9v99     comp.
     03  Ledger-Sec      binary-short.
     03  updates         binary-short.
     03  postings        binary-short.
     03  Next-Batch      binary-short.  *> should be unsigned used for all ledgers
     03  First-SL-Batch  binary-short.  *> should be unsigned - unused ?
     03  First-SL-Inv    binary-long.
     03  Extra-Charge-ac binary-long.
     03  VAT-ac          binary-long.
     03  maps-ser.
         05  maps-ser-xx pic xx.
         05  maps-ser-nn binary-short.
     03  irs-instead     pic x.
         88  Irs-Used                  value "Y".
     03  filler          pic x(11).
*>***************
*>   B/L Data   *
*>***************
     03  Age-To-Pay      binary-char.  *> should be unsigned
     03  BL-Next-Batch   binary-short.  *> should be unsigned - unused ?
     03  Next-Folio      binary-long.
     03  BL-Pay-Ac       binary-long.
     03  P-Creditors     binary-long.
     03  BL-Purch-Ac     binary-long.
     03  BL-End-Cycle-Date binary-long.
     03  Purchase-Ledger pic x.
         88  P-L-Exists                 value "Y".
     03  PL-Delim        pic x.
     03  Entry-Level     pic 9.
     03  P-Flag-A        pic 9.
     03  P-Flag-I        pic 9.
     03  P-Flag-P        pic 9.
     03  filler          pic x(12).
*>***************
*>   S/L Data   *
*>***************
     03  Sales-Ledger    pic x.
         88  S-L-Exists                 value "Y".
     03  SL-Delim        pic x.
     03  Oi-3-Flag       pic x.
     03  Cust-Flag       pic x.
     03  Oi-5-Flag       pic x.
     03  S-Flag-Oi-3     pic x.
     03  Full-Invoicing  pic 9.
     03  S-Flag-A        pic 9.
     03  S-Flag-I        pic 9.
     03  S-Flag-P        pic 9.
     03  SL-Dunning      pic 9.
     03  SL-Charges      pic 9.
     03  SL-Stats-Run    pic 9.
     03  invoicer        pic 9.
         88  I-Level-0                  value 0.
         88  I-Level-1                  value 1.
         88  I-Level-2                  value 2.
         88  not-invoicing              value 9.
     03  Extra-Desc      pic x(14).
     03  Extra-Type      pic x.
         88  Discount                   value "D".
         88  Charge                     value "C".
     03  SL-Disc         pic 99v99    comp.
     03  Extra-Rate      pic 99v99    comp.
     03  SL-Days-1       binary-char.
     03  SL-Days-2       binary-char.
     03  SL-Days-3       binary-char.
     03  SL-Credit       binary-char.
     03  Delivery        binary-short.
     03  SL-Min          binary-short.
     03  SL-Max          binary-short.
     03  PF-Retention    binary-short.
     03  SL-Limit        binary-long.
     03  SL-Pay-Ac       binary-long.
     03  S-Debtors       binary-long.
     03  SL-Sales-Ac     binary-long.
     03  S-End-Cycle-Date binary-long.
     03  Extra-Print     pic x.               *> move this with other extras
     03  filler          pic x(13).
*>***************
*> Stock Data   *
*>***************
*>  --- need to clean up record and create convert prog ----
*>
     03  Stock-Control-Block.
         05  Stk-Abrev-Ref  pic x(6).
         05  Stk-Debug      pic 9.   *> T/F (1/0).
         05  Stk-Manu-Used  pic 9.   *> T/F (Bomp/Wip)
         05  Stk-OE-Used    pic 9.   *> T/F.
         05  Stk-Audit-Used pic 9.   *> T/F.
         05  Stk-Mov-Audit  pic 9.   *> T/F.
         05  Stk-Period-Cur pic x.   *> M=Monthly, Q=Quarterly, Y=Yearly
         05  Stk-Period-dat pic x.   *>  --  ditto  --
         05  Stk-Date-Form  pic 9.
             88  Date-UK                value 1.  *> dd/mm/yyyy
             88  Date-USA               value 2.  *> mm/dd/yyyy
             88  Date-Intl              value 3.  *> yyyy/mm/dd
         05  Stock-Control  pic x.
             88  Stock-Control-Exists   value "Y".
         05  Level-4        pic 9.
             88  Stock                  value 1.
         05  Level-5        pic 9.
             88  Order-Entry            value 1.
         05  Stk-Averaging  pic 9.   *> T/F.
             88  Stock-Averaging        value 1.
         05  Stk-Activity-Rep-Run pic 9.  *> T/F.  =18 bytes
         05  Stk-Page-Lines binary-char unsigned.
         05  Stk-Audit-No   binary-char unsigned.  *> 22 bytes
     03  Order-Entry-Block.
         05  filler-Dummy   pic x.

*>
 working-storage section.
 77  prog-name           pic x(18)  value "IRSconv2 (1.00.00)".
 01  fs-reply            pic 99.
 01  rec-count           pic 9(4)   value zero.

 procedure division.
 AA000-Start.
    open     input post-In.
    if       fs-reply not = "00"
             display "Error on opening input postings " fs-reply
             stop run.
    open     output postings.
    if       fs-reply  not = "00"
             display  "Failure to Open output postings" fs-reply
             close post-in
             stop run.
    Display  prog-name " Starts".

 AA010-Read.
    read     post-In  next record at end
             close post-In postings
             display " "
             display "Converting Postings Completed "
                     rec-count " written."
             Display  prog-name " Ends"
             stop run.
    if fs-reply not = zero
        display "Error on reading postings = " fs-reply
            stop run.
    display "*" no advancing.
*>
    move     POST-KEY1      to post-key     .
    move     POST-CODE1     to post-code    .
    move     POST-DATE1     to post-date    .
    move     POST-DR1       to post-dr      .
    move     POST-CR1       to post-cr      .
    move     POST-AMOUNT1   to post-amount  .
    move     POST-LEGEND1   to post-legend  .
    move     VAT-AC-DEF1    to vat-ac-def   .
    move     POST-VAT-SIDE1 to post-vat-side.
    move     VAT-AMOUNT1    to vat-amount   .
*>
*>    display "writing rec = " I-key-1.
    write    posting-record invalid key
             display "Link/record exists " post-key.
    if fs-reply not = zero
             display "Error writ post = " fs-reply " on rec = " post-key
             close post-In postings
             stop run.
    add 1 to rec-count.
    go       to AA010-Read.
