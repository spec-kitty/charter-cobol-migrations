       >>source free
*>*****************************************************
*>                                                    *
*>              Cheque/Bacs  Register                 *
*>                                                    *
*>*****************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl950.
*>**
*>    Author.             V B Coen FBCS, 19/04/84
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    remarks.            Cheque/Bacs payment register.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps04.
*>**
*>    Error messages used.
*>                        PL002
*>                        PL132
*>                        PL904
*>                        PL905
*>**
*>    Changes.
*> 13/11/82 Vbc - Paging For Reports Remove Page Flip At Eoj.
*> 14/11/82 Vbc - Remove Sort,Create New Prog Pl955.
*> 25/04/84 Vbc - Zeroise,Spacefill Unused Fields On Writing Pay
*>                Record To Oi.
*> 22/06/84 Vbc - Support For Indexed Openitem File.
*> 26/06/84 Vbc - Fix Various Bugs In Loop-Outer Routine.
*> 20/07/84 Vbc - Fix Various Bugs Regarding Oi-Deduct-Amt.
*> 23/07/84 Vbc - Fix Re-Init Bugs In Main-End & Loop-Outer.
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 05/04/09 vbc - Support for sortcode/account-no on report.
*> 11/04/09 vbc - Added posting files O/P as per PL060 & PL100
*>                and New feature Env variable ACAS_IRS.
*>                  NOW REMOVED see below, re path+filenames
*> 13/04/09 vbc - make pay-ac post-cr instead of dr
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 15/09/10 vbc - .08 Support for print-spool-name.
*> 16/12/11 vbc - .09 Error msgs to SLnnn.Support for dates other than UK
*>                    Support for path+filenames.
*>                    Updated version to 3.01.nn
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
*>------------
*>
 copy "selpl.cob".
 copy "selpay.cob".
 copy "seloi5.cob".
 copy "selpost.cob".
 copy "selpost-irs.cob".
 copy "selval.cob".
 copy "selbatch.cob".
 copy "selprint.cob".
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdpl.cob".
 copy "fdpay.cob".
 copy "fdoi5.cob".
 copy "fdpost.cob".
 copy "fdpost-irs.cob".
 copy "fdval.cob".
 copy "fdbatch.cob".
 copy "fdprint.cob".
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "PL950 (3.01.09)".
 77  exception-msg       pic x(25)    value spaces.
 copy "print-spool-command-p.cob".
*>
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
 copy "wsoi.cob".
*>
 01  ws-data.
     03  pay-series      binary-short        value zero.
     03  z               pic 99.
     03  xx              pic 99.
     03  first-time      pic 9               value zero.
     03  work-1          pic s9(6)v99.
     03  p               pic 99              value zero.
     03  m               pic z(7)9.
     03  b               binary-char           value zero.
     03  c               binary-char           value zero.
     03  aprop-amount    pic s9(7)v99        value zero.
     03  t-deduct        pic s9(7)v99 comp-3 value zero.
     03  deduct-taken    pic s9(7)v99 comp-3 value zero.
     03  n-deduct        binary-long           value zero.
     03  line-cnt        binary-char         value zero.
     03  bal-t           pic 9(7)v99         value zero.
     03  ws-reply        pic xxx             value space.
     03  ws-account-details.
         05 ws-sortcode  pic 9(6).
         05 filler       pic x               value space.
         05 ws-accountno pic 9(8).
         05 filler       pic x               value space.
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
     03  PL002          pic x(31) value "PL002 Note error and hit return".
*>     03  PL005          pic x(18) value "PL005 Invalid Date".
*> Module specific
     03  PL132          pic x(32) value "PL132 Err on Batch file write : ".
     03  PL904          pic x(38) value "PL904 PE 950-01:Hit return to continue".
     03  PL905          pic x(38) value "PL905 PE 950-02:Hit return to continue".
*>
 01  error-code          pic 999.
*>
 01  line-1.
     03  l1-prog         pic x(33)       value spaces.
     03  filler          pic x(39)       value "Cheque/Bacs Register".
     03  filler          pic x(5)        value "Page ".
     03  l3-page         pic zz9.
*>
 01  line-2.
     03  l2-user         pic x(33)       value spaces.
     03  filler          pic x(15)       value spaces.
     03  filler          pic x(22)       value spaces.
     03  l1-date         pic x(10).
*>
 01  line-3.
     03  filler          pic x(16)       value "Cheques Date - ".
     03  l3-date         pic x(10).
*>
 01  line-4.
     03  filler          pic x(66)       value
         "Cheque Nos     <------------ Payee ------------->      <--Value-->".
*>
 01  line-4-a.
     03  filler          pic x(16)       value " Sort  Account".
     03  filler          pic x(24)       value "Account             Name".
*>
 01  line-5.
     03  l5-bacs-details.
         05  l5-cheque   pic z(9)9.
         05  l5-acf      pic x(6)        value spaces.
     03  l5-account      pic x(9).
     03  l5-supplier     pic x(30).
     03  l5-value        pic z(7)9.99.
*>
 01  line-6.
     03  filler          pic x(55)       value spaces.
     03  filler          pic x(11)       value all "=".
*>
 01  line-7.
     03  filler          pic x(25)       value spaces.
     03  filler          pic x(30)       value "    total".
     03  l7-value        pic z(7)9.99.
*>
 linkage section.
*>==============
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
*>
 01  to-day              pic x(10).
*>
 procedure  division using ws-calling-data system-record to-day file-defs.
*>=======================================================================
*>
 init01 section.
 disp-head.
*>
     perform  zz070-Convert-Date.
     move     prog-name  to  l1-prog.
     move     ws-date     to  l1-date.
     move     usera       to  l2-user.
     move     Print-Spool-Name to PSN.
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Cheque Register" at 0132 with foreground-color 2.
     display  ws-date at 0171 with foreground-color 2.
*>
 re-accpt.
     display  "Warning: Updating Open Item File. Do You Wish to Continue (YES/NO) [   ]" at 1201
                                        with foreground-color 2.
     accept   ws-reply at 1269 with foreground-color 6.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "NO"
              exit program.
     if       ws-reply not = "YES"
              go to re-accpt.
*>
     display  " " at 1201 with erase eol.
     open     input purchase-file pay-file.
     open     output print-file.
*>
 read-purchase.
     read     pay-file next record
              at end go to main-end.
*>
     if       first-time = zero
              move  pay-date  to  u-bin
              perform  zz060-Convert-Date
              move  ws-date  to  l3-date
              perform  headings
              move  9  to  first-time.
*>
     move     pay-supl-key  to  purch-key.
     read     purchase-file invalid key
              move "Record Missing" to purch-name.
*>
     move     purch-key  to  l5-account.
     move     purch-name to  l5-supplier.
*>*     if       pay-cheque = zero
*>*              go to  read-purchase.
*>
*> Don't want the above, but can it happen other than BACS?
*>
     if       pay-cheque not = zero
              move pay-cheque to  l5-cheque
              move spaces to l5-acf
     else
              move pay-sortcode to ws-sortcode
              move pay-account  to ws-accountno
              move ws-account-details to l5-bacs-details.
*>
     move     pay-gross  to  l5-value.
     add      pay-gross  to  bal-t.
*>
     write    print-record  from  line-5 after 1.
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform  headings.
*>
     go       to read-purchase.
*>
 main-end.
     move     bal-t  to  l7-value.
     write    print-record  from  line-6 after 2.
     write    print-record  from  line-7 after 1.
     write    print-record  from  line-6 after 1.
     close    print-file pay-file.
*>
*>  As reporting is finished, print it while
*>        completing remaining processing
*>
     call     "SYSTEM" using Print-Report.
     open     input  pay-file.
     open     i-o    open-item-file-5.
     if       G-L
              perform  BL-Open.  *> open right posting file
*>
     if       bl-next-batch = zero
              move 1 to bl-next-batch.
*>
 loop-outer.
     read     pay-file  next record
              at end  go to  end-run.
*>
     move     pay-supl-key to oi5-supplier purch-key.
     read     purchase-file invalid key
              move "Record Missing" to purch-name.
*>
     move     zero to aprop-amount.
     add      1 to pay-series.
     if       pay-series > 999
              move 1 to pay-series
              add 1 to bl-next-batch.
*>
     perform  loop-inner through loop-inner-end
               varying z from 1 by 1 until z > 9.
*>
     multiply 1000 by bl-next-batch giving oi-invoice.
     add      pay-series to oi-invoice.
*>
     move     zero to oi-carriage oi-c-vat oi-vat oi-discount
                      oi-status oi-p-c oi-extra oi-e-vat oi-cr.
     move     zero to oi-deduct-days oi-days oi-deduct-vat.
     move     spaces to oi-order oi-hold-flag oi-applied.
     move     pay-supl-key to oi-supplier.
     move     bl-next-batch to oi-b-nos.
     move     pay-series to oi-b-item.
     move     pay-date   to oi-date oi-date-cleared.
*>
     move     oi-date  to  u-bin.
     perform  zz060-Convert-Date.  *> u-date is now set in UK format but ws-date in local
*>
     move     pay-gross    to oi-paid.
     move     aprop-amount to oi-approp.
     move     deduct-taken to oi-deduct-amt.
     if       oi-deduct-amt not = zero
              add 1 to n-deduct.
     move     pay-cheque   to oi-ref.
     move     5            to oi-type.
     write    open-item-record-5 from oi-header.
*>
     if       G-L
              perform  BL-Write.
     add      deduct-taken to t-deduct.
     move     zero to deduct-taken aprop-amount.
     go       to loop-outer.
*>
 loop-inner.
*>*********
*>
     if       pay-value (z) = zero
              go to  loop-inner-end.
*>
 oi-read.
*>******
*>
     move     pay-folio (z) to oi5-invoice.
     read     open-item-file-5 invalid key
              go to loop-inner-end.
*>
     move     open-item-record-5  to  oi-header.
*>
*>   SHOULD only have type 2 and matching keys
*>      otherwise a progam bug elsewhere
*>
     if       oi-type not = 2
              display PL904   at 2401  with foreground-color 4
              accept ws-reply at 2441
              go to loop-inner-end.
     if       oi-supplier not = pay-supl-key
       or     oi-invoice not = pay-folio (z)
              display PL905   at 2401  with foreground-color 4
              accept ws-reply at 2441
              go to  loop-inner-end.
*>
     add      pay-value (z)  to  oi-paid.
     add      oi-net oi-carriage oi-vat oi-c-vat giving  work-1.
     subtract pay-deduct (z) from work-1.
     if       oi-paid  =  work-1
              move  1  to  oi-status
              subtract pay-deduct (z) from oi-net
              add  pay-deduct (z) to deduct-taken
              move zero to oi-deduct-amt
              move bl-next-batch to oi-b-nos
              move pay-series to oi-b-item
              move pay-date to oi-date-cleared.
*>
     rewrite  open-item-record-5 from oi-header.
     add      pay-value (z)  to  aprop-amount.
     add      pay-value (z)  to  oi-p-c.
     multiply 100 by pay-value (z) giving oi-cr.
*>
 loop-inner-end.
     exit.
*>
 end-run.
*>******
*>
     add      1 to bl-next-batch.
     close    open-item-file-5 pay-file purchase-file.
     open     output  pay-file.
     close    pay-file.
     if       t-deduct not = zero
              open i-o value-file
              perform analise-deductions
              close value-file.
*>
     if       G-L
              perform  BL-Close.
*>
     exit     program.
*>
 headings     section.
*>===================
*>
     add      1  to  p.
     move     p  to  l3-page.
*>
     if       p not = 1
              write print-record from line-1 after page
              write print-record from line-2 after 1
              move  spaces to print-record
              write print-record after 1
     else
              write print-record from line-1 before 1
              write print-record from line-2 before 1
     end-if
     write    print-record from line-3 after 1.
     write    print-record from line-4 after 2.
     write    print-record from line-4-a after 1.
     move     spaces to print-record.
     write    print-record after 1.
     move     8 to line-cnt.
*>
 main-exit.   exit section.
*>
 analise-deductions   section.
*>===========================
*>
     move     "Pzb" to va-code.
     read     value-file  invalid key
              go to main-exit.
*>
     subtract n-deduct from va-t-this.
     subtract n-deduct from va-t-year.
     subtract t-deduct from va-v-this.
     subtract t-deduct from va-v-year.
*>
     rewrite  value-record.
*>
     move     space  to  va-second.
     read     value-file  invalid key
              go to main-exit.
*>
     subtract n-deduct from va-t-this.
     subtract n-deduct from va-t-year.
     subtract t-deduct from va-v-this.
     subtract t-deduct from va-v-year.
     rewrite  value-record.
*>
 main-exit.   exit section.
*>
 bl-open      section.
*>===================
*>
     open     i-o  batch-file.
     if       fs-reply not = zero
              close batch-file
              open output batch-file.
*>
     move     bl-next-batch  to  batch-nos.
     move     2  to  ledger.
     add      1  to  bl-next-batch.
*>
     move     zero  to  batch-status
                        cleared-status.
     move     scycle of system-record
              to  bcycle of batch-record.
     move     run-date  to  entered.
*>
     move     "Purchase Ledger Payments"  to  description.
     move     zero  to  bdefault
                        batch-def-ac
                        batch-def-pc
                        items
                        input-gross  input-vat
                        actual-gross actual-vat.
*>
     move     "DR"  to  convention.
     move     "PL"  to  batch-def-code.
     move     "I"   to  batch-def-vat.
     add      postings  1  giving  batch-start.
*>
     if       irs-used
              open extend irs-post-file     *> needed: -  bug in OC
              if fs-reply not = zero
                 close irs-post-file
                 open output irs-post-file
              end-if
     else
              open i-o  posting-file
              if  fs-reply not = zero
                  close posting-file
                  open output posting-file.
     move     batch-start  to  rrn.
*>
 main-exit.   exit section.
*>********    ****
*>
 bl-write     section.
*>===================
*>
*><<<<<<<<<<<<<<<<<<<<<<<<<<< READ THIS >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*>**********************************************************************
*>  This will write a posting record to GL or IRS for EACH line item   *
*>   in EACH invoice                                                   *
*> so, to use it, you MUST have set up the GL account number for EVERY *
*>  analysis code via pl070. It also assumes that you have followed    *
*>  the convention in IRS & GL that default a/c 31 points to VAT input *
*>  and default a/c 32 is VAT output tax.                              *
*>**********************************************************************
*>  u-date is in uk format
*>
     move     u-date (1:6) to post-date (1:6). *> using UK format
     move     u-date (9:2) to post-date (7:2).
     add      1       to items.
     move     items   to post-number.
     move     oi-paid to post-amount.
*>
*> using folio/invoice no + ' : ' supplier name instead of batch/item
*>  on posting file for both IRS & GL.
*>
     move     batch-nos  to  batch.
     move     oi-invoice to m.
     move     zero to b.
     inspect  m tallying b for leading space.
     subtract b from 8 giving c.
     add      1 to b.
     move     1  to  xx.
*>
     string   m (b:c)     delimited by size
              " : "       delimited by size
              purch-name  delimited by size into post-legend pointer  xx.
*>
     move     p-creditors  to  post-dr.
     move     bl-pay-ac    to  post-cr.
*>
     move     zero  to  dr-pc
                        cr-pc
                        vat-ac of posting-record
                        vat-pc
                        vat-amount.
*>
     move     spaces  to  post-vat-side.
*>
     add      post-amount  to  input-gross.
     add      post-amount  to  actual-gross.
*>
     move     "PL" to post-code in posting-record.
     move     "DR" to post-vat-side.
*>
     if       irs-used
              move post-key      to irs-post-key
              move post-code in posting-record   to irs-post-code
              move post-date     to irs-post-date
              move post-dr       to irs-post-dr
              move post-cr       to irs-post-cr
              move post-amount   to irs-post-amount
              move post-legend   to irs-post-legend
              move 31            to irs-vat-ac-def
              move post-vat-side to irs-post-vat-side
              move vat-amount    to irs-vat-amount
              write irs-posting-record
     else
              write posting-record
     end-if
     if       not irs-used
              add 1  to  rrn.
*>
     if       items = 99
              perform  bl-close
              perform  bl-open.
*>
 main-exit.   exit section.
*>********    ****
*>
 bl-close     section.
*>===================
*>
     write    batch-record.
     if       fs-reply not = zero
              display PL132    at 2301
              perform Eval-Status
              display fs-reply at 2333
              display exception-msg at 2336
              display PL002                       at 2401 with foreground-color 2
              accept ws-reply at 2430.
     if       not irs-used
              move rrn  to  postings.
     close    batch-file.
     if       not irs-used
              close  posting-file
     else
              close irs-post-file.
*>
  main-exit.   exit section.
*>
 Eval-Status        section.
*>=========================
*>
 copy "FileStat-Msgs.cpy"  replacing STATUS by fs-reply
                                     msg    by exception-msg.
*>
 main-exit.   exit section.
*>
 zz050-Validate-Date        section.
*>*********************************
*>
*>  Converts USA/Intl to UK date format for processing.
*>*******************************
*> Input:   ws-test-date
*> output:  u-date/ws-date as uk date format
*>          u-bin not zero if valid date
*>
     move     ws-test-date to ws-date.
     if       Date-Form = zero
              move 1 to Date-Form.
     if       Date-UK
              go to zz050-test-date.
     if       Date-USA                *> swap month and days
              move ws-days to ws-swap
              move ws-month to ws-days
              move ws-swap to ws-month
              go to zz050-test-date.
*>
*> So its International date format
*>
     move     "dd/mm/ccyy" to ws-date.  *> swap Intl to UK form
     move     ws-test-date (1:4) to ws-Year.
     move     ws-test-date (6:2) to ws-Month.
     move     ws-test-date (9:2) to ws-Days.
*>
 zz050-test-date.
     move     ws-date to u-date.
     move     zero to u-bin.
     perform  maps04.
*>
 zz050-exit.
     exit     section.
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
 maps04       section.
*>*******************
*>
     call     "maps04"  using  maps03-ws.
*>
 maps04-exit.
     exit     section.
*>
