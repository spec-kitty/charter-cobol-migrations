       >>source free
*>*******************************************************
*>                                                      *
*>                End Of Cycle Processing               *
*>                                                      *
*>*******************************************************
*>
 identification          division.
*>===============================
*>
*>**
     Program-Id.         xl150.
*>**
*>   Author.             Cis Cobol Conversion By V B Coen FBCS, 25/10/83
*>                       For Applewood Computers.
*>**
*>   Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                       Distributed under the GNU General Public License
*>                       v2.0. Only. See the file COPYING for details.
*>**
*>   Version.            See Prog-Name In Ws.
*>
*>   Called Modules.     maps01.
*>                       maps04.
*>                       maps99.
*>**
*>   Error messages used.
*>                       XL001
*>                       XL006
*>                       XL007
*>                       XL008
*>                       XL009
*>                       XL101
*>                       XL102
*>                       XL103
*>                       XL104          .
*>**
*>  TODO :
*>
*>  1.  Check code 2 C that it will work correctly for OC
*>  2.  Add code for Stock Control (not needed) and OE
*>
*>  Changes.
*>   ------ vbc - To Zero Paid This Month (Oi-P-C)
*> 05/03/83 vbc - Remove 92 day old invoices from invoice file.
*> 31/03/83 vbc - Fix for new invoice file layout.
*> 21/02/83 vbc - To strip closed records from invoice file.
*> 07/10/83 vbc - Zap io-deduct-amt from payment records.
*> 25/10/83 vbc - Cis cobol conversion.
*> 09/12/83 vbc - Change error messages to hit return.
*> 19/12/83 vbc - Allow for system record 4.
*> 01/03/84 vbc - Support sales-unapplied in phase1 routine.
*> 10/03/84 vbc - Support for ih-day-book-flag.
*> 01/04/84 vbc - If openitm3 inv closed delete inv from inv file
*>                 but only if sl-own-nos not = y.
*>                At end of year kill value file,also accept pass
*>                 before starting & test.
*> 17/05/84 vbc - If end of quarter/year remove deleted records
*>                  from sales-file. remove deleted recs from itm3.
*> 24/08/84 vbc - Tidyup phase display,remove newyear test in phs3.
*> 25/09/84 vbc - Support for pl-payments in wssys4.
*> 08/03/85 vbc - Build prog to include pl150 & sl150.
*> 13/02/02 vbc - Va-systems = p corrected & y2k.
*> 29/01/09 vbc - Migration to Open Cobol.
*> 19/03/09 vbc - Updated Sales file layouts. 3.00.02.
*> 21/12/11 vbc - .03 Support for dates other than UK & clean up msgs
*>                    Error msgs to GLnnn,
*>                    Support for path+filenames.
*>                    replaced copy's in common to sales, purchase etc
*>                    changing field names to suit
*>**
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of ACAS the Applewood Computers Accounting
*> System and is copyright (c) Vincent B Coen. 1976-2012 and later.
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
 copy "selsl.cob".                 *> copybooks
 copy "selpl.cob".                 *> copybooks
 copy "selois.cob" in "../sales".
 copy "seloi3.cob" in "../sales".
 copy "seloi5.cob" in "../purchase".
 copy "selval.cob".                 *> copybooks
 copy "selinv.cob" in "../sales" replacing
                          invoice-file by SInvoice-file
                          invoice-key by sinvoice-key.

 copy "selpinv.cob" in "../purchase" replacing
                          invoice-file by PInvoice-file
                          invoice-key by pinvoice-key.
*>
     select temp-sales-file     assign file-21
                                access sequential
                                status fs-reply.
*>
     select temp-purchase-file  assign file-21
                                access sequential
                                status fs-reply.
*>
     select temp-invoice-file   assign file-21,
                                access sequential,
                                status fs-reply.
*>
 i-o-control.
*>
     same record area for sales-file purchase-file
     same record area for open-item-file-3 open-item-file-5
     same record area for sinvoice-file pinvoice-file
     same record area for temp-sales-file temp-purchase-file
                          temp-invoice-file
     same record area for value-file open-item-file-s.
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 COPY "fdsl.cob".                 *> copybooks
 COPY "fdpl.cob".                 *> copybooks
 COPY "fdois.cob" in "../sales".  *> this is the longer one
 COPY "fdoi3.cob" in "../sales".
 COPY "fdoi5.cob" in "../purchase".
 COPY "fdval.cob".                 *> copybooks
 COPY "fdinv.cob" in "../sales" replacing
                          invoice-file   by SInvoice-file
                          invoice-record by Sinvoice-Record
                          invoice-key    by sinvoice-key
                          invoice-nos    by sinvoice-nos
                          invoice-let    by sinvoice-let
                          item-nos       by Sitem-nos.


 COPY "fdpinv.cob" in "../purchase" replacing
                          invoice-file   by PInvoice-file
                          invoice-record by Pinvoice-Record
                          invoice-key    by pinvoice-key
                          invoice-nos    by pinvoice-nos
                          invoice-let    by pinvoice-let
                          item-nos       by Pitem-nos.

*>
 fd  temp-purchase-file.
*>
 01  temp-purch-record.
     03  filler             pic x(300).
*>
 fd  temp-sales-file.
*>
 01  temp-sales-record      pic x(300).
*>
 fd  temp-invoice-file.
*>
 01  temp-invoice-record.
     03  temp-invoice-key   pic x(10).
     03  filler             pic x(119).
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(16) value "xl150 (3.00.03)".
 77  OS-Delimiter        pic x        value "/".
 77  ACAS_BIN            pic x(512)   value spaces.  *> added
 77  ACAS_IRS            pic x(500)   value spaces.
 77  ACAS_LEDGERS        pic x(500)   value spaces.
 77  Arg-Number          pic 9        value zero.
 77  z                   binary-char  value zero.
*>
*> holds program parameter values from command line
 01  Arg-Vals                         value spaces.
     03  Arg-Value       pic x(525)  occurs 2.
 01  Arg-Test            pic x(525)   value spaces.
*>
 copy "wsmaps01.cob".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
*>
 01  ws-data.
     03  ws-reply        pic x.
     03  ws-passwd       pic x(4)        value spaces.
     03  new-quarter     pic 9           value is zero.
     03  new-year        pic 9           value zero.
     03  test-invoice    pic 9(8)        value is zero.
     03  a               pic 99.
     03  pf-test         binary-long  value zero.
     03  inv-test        pic 9(5)  comp  value zero.
     03  sl-eoc          pic 9           value zero.
     03  pl-eoc          pic 9           value zero.
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
     03  XL001          pic x(31) value "XL001 Aborting. Press return   ".
     03  XL006          pic x(62) value "XL006 Program Arguments limited to two and you have specified ".
     03  XL007          pic x(35) value "XL007 Program arguments incorrect: ".
     03  XL008          pic x(31) value "XL008 Note message & Hit return".
     03  XL009          pic x(53) value "XL009 Environment variables not yet set up : ABORTING".
*>    03  XL011           pic x(25) value "XL011 Note and hit Return".
*> Module specific
     03  XL101          pic x(50) value "XL101 WARNING..... Proofed but NOT posted invoices".
     03  XL102          pic x(50) value "XL102 !!ERROR..... Proofed but NOT posted payments".
     03  XL103          pic x(40) value "XL103 !!ERROR.... Sales Analysis NOT run".
     03  XL104          pic x(66) value "XL104 I'm confused: You appear to have rejected the run, try again".
*>
 01  error-code          pic 999.
*>
 copy "wssoi.cob" in "../sales" replacing
                    si-header     by soi-header
                    si-type       by soi-type
                    si-applied    by soi-applied
                    si-p-c        by soi-p-c
                    si-deduct-amt by soi-deduct-amt
                    si-s-closed   by ss-closed
                    si-invoice    by soi-invoice.
 copy "wsinv.cob" in "../sales".
*>
*> copy "wsoip.cob".
 copy "wssoi.cob" in "../purchase" replacing
                    si-header     by poi-header
                    si-type       by poi-type
                    si-applied    by poi-applied
                    si-p-c        by poi-p-c
                    si-deduct-amt by poi-deduct-amt
                    si-s-closed   by ps-closed
                    si-invoice    by poi-invoice.
*> copy "wspinv.cob".
 copy "wspinv.cob" in "../purchase" replacing
                    invoice-header   by pinvoice-header
                    ih-test          by pih-test
                    ih-type          by pih-type
                    applied          by papplied
                    ih-day-book-flag by pih-day-book-flag
                    ih-lines         by pih-lines.
*>
 copy "wsnames.cob".   *> here deliberately and in common
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wssys4.cob".
 01  dummy-file-defs.
     03  filler      pic x(532) occurs 10.
 01  Filler          binary-short  value zero.
*>
 01  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record system-record-4 to-day dummy-file-defs.
*>============================================================================================
 init01 section.
*>
*> We need to recompute paths etc as we use files from
*>     systems other than the one that called XL150
*>
*> Which is why a dummy file-def is in linkage and a full one is
*>    in WS
*>
*> DURING TESTING WE DISPLAY THE PATHS IN ZZ010 AND ZZ020
*>
     perform  zz020-Get-Program-Args.
*>
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     perform  display-heads.
*>
*> get today as binary to use in compares with data files
*>
     move     zero  to  u-bin.
     move     to-day to u-date.
     call     "maps04"  using  maps03-ws.
*>
     if       file-status (15)  not = 1
              move 26  to  error-code
              call  "maps99"  using  error-code ws-calling-data
              go to call-foul.
*>
 acpt-reply.
*>*********
*>
     move     "N" to ws-reply.
     display  "WARNING: MAKE SURE THAT DATE IS AT END OF CYCLE.IE END OF MONTH" at 0501 with foreground-color 4.
     display  "Have you made a Backup of ALL DATA FILES? If so; "               at 0612 with foreground-color 2.
     display  "Confirm end of Cycle Processing to be Run (Y/N) - [ ]" at 0712 with foreground-color 2.
     accept   ws-reply at 0763 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "N"
              go to  menu-error.
*>
     if       ws-reply not = "Y"
              go to acpt-reply.
*>
     if       s-flag-i = 1
        or    p-flag-i = 1
              display XL101 at 1201 with foreground-color 4
              display "ok to proceed (Y/N) - [Y]" at 1301 with foreground-color 2
              move  "Y"  to  ws-reply
              accept ws-reply at 1324  with foreground-color 2 update
              move function upper-case (ws-reply) to ws-reply
              if   ws-reply = "N"
                   go to  menu-error.
*>
     if      (s-flag-p = 1 or 2)
         or  (p-flag-p = 1 or 2)
              display XL102 at 1201 with foreground-color 4
              display XL001 at 1301 with foreground-color 2
              accept ws-reply at 1331 with foreground-color 2
              go to  menu-error.
*>
     if       s-flag-a = 1
          or  p-flag-a = 1
              display XL103   at 1201 with foreground-color 4
              display XL001   at 1301 with foreground-color 2
              accept ws-reply at 1331 with foreground-color 2
              move 1 to ws-term-code
              go to  menu-exit.
*>
     display  "Give password [****]" at 1601 with foreground-color 2.
     accept   ws-passwd at 1616 with secure foreground-color 2.
     move     spaces to pass-word of maps01-ws.
     if       ws-passwd not = spaces
              move "P" to encode
              move ws-passwd to pass-word of maps01-ws
              call "maps01" using maps01-ws.
     if       pass-word of system-record not = pass-word of maps01-ws
              move 3 to ws-term-code
              go to menu-ex.
     cancel   "maps01".
*>
 request-ledgers.
*>
     if       S-L
              display "Do you wish to run Sales Ledger? (Y/N) - [ ]"   at 1601 with foreground-color 2
              accept ws-reply at 1643 with foreground-color 6
              move function upper-case (ws-reply) to ws-reply
              if  ws-reply = "Y"
                  move 1 to sl-eoc.
     if       B-L
              display "Do you wish to run Purchase Ledger? (Y/N) - [ ]" at 1701 with foreground-color 2.
              accept ws-reply at 1746 with foreground-color 6
              move function upper-case (ws-reply) to ws-reply
              if  ws-reply = "Y"
                  move 1 to pl-eoc.
*>
     if       zero = sl-eoc and pl-eoc
              display XL104 at 1901 with foreground-color 2
              go to acpt-reply.
*>
     if       file-status (29) not = 1 and pl-eoc = 1
              move 25  to error-code
              call "maps99"  using  error-code ws-calling-data
              go to call-foul.
*>
     if       file-status (19) not = 1 and sl-eoc = 1
              move 19  to  error-code
              call "maps99"  using  error-code ws-calling-data
              go to call-foul.
*>
 display-heads.
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "End of Cycle Processing" at 0130  with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
 display-end.
*>
     perform  check-end-of-cycle.
     if       sl-eoc = 1
              perform sl-processing
              move u-bin to s-end-cycle-date.
     if       pl-eoc = 1
              perform pl-processing
              move u-bin to bl-end-cycle-date.
*>
 menu-exit.
*>********
*>
     if       sl-eoc = 1
              move "Y" to oi-3-flag.
     if       pl-eoc = 1
              move "Y" to oi-5-flag.
*>
 menu-ex.
     exit     program.
*>
 call-foul.
     move     15 to error-code.
     call     "maps99" using error-code ws-calling-data.
*>
 menu-error.
*>*********
*>
     move     2 to ws-term-code.
     go       to menu-exit.
*>
*>******************************************************
*>                     Procedures                      *
*>******************************************************
*>
 sl-processing           section.
*>==============================
*>
     display  "Phase 1  - Sales" at 1201 with foreground-color 2.
     display  "*******" at 1301 with foreground-color 2.
     display  "Please wait." at 1501 with foreground-color 2.
*>
     if       new-quarter = 1
              open output temp-sales-file
              open input  sales-file
              display "A" at 1208 with foreground-color 2
       else
              open i-o  sales-file.
*>
 phase-1.
*>******
*>
     read     sales-file  next record  at end
              go to  phase-1-end.
*>
     if       sales-current = zero
         and  sales-last    = zero
         and  sales-unapplied = zero
              move zero to  sales-status.
*>
     if       sales-current is negative
              multiply -1 by sales-current
              add sales-current to sales-unapplied
              move zero to sales-current.
*>
     move     sales-current  to  sales-last.
*>
     if       new-quarter = 1
              move  zero  to  sturnover-q (current-quarter).
*>
     if       new-year = 1
              move zero to sales-average sales-activety.
*>
     if       new-quarter = 1
              write temp-sales-record from sales-record
              go to phase-1.
*>
     rewrite  sales-record.
     go to    phase-1.
*>
 phase-1-end.
*>**********
*>
     close    sales-file.
     if       new-quarter = zero
              go to phase-1b-skip.
*>
     close    temp-sales-file.
     open     output sales-file.
     open     input temp-sales-file.
     display  "1B" at 1207 with foreground-color 2.
*>
 phase-1b.
*>
     read     temp-sales-file at end
              go to phase-1b-end.
     write    sales-record from temp-sales-record.
     go       to phase-1b.
*>
 phase-1b-end.
*>
     close    temp-sales-file sales-file.
     open     output temp-sales-file.
     close    temp-sales-file.
*>
 phase-1b-skip.
*>
     display  "2A" at 1207 with foreground-color 2.
*>
     open     input  open-item-file-3.
     open     output open-item-file-s.
     open     i-o sinvoice-file.
*>
 phase-2.
*>******
*>
     read     open-item-file-3 next record into soi-header at end
              go to  phase-2-end.
*>
     if       ss-closed
              perform kill-invoices
              go to phase-2.
     if       soi-type = 1        *> receipt (not wanted)
              go to phase-2.
     if       soi-type = 5 or 6   *> payment or Jnl unapplied cash
              move zero to soi-deduct-amt.
*>
     move     "z" to soi-applied.
     move     zero  to  soi-p-c.
*>
     write    open-item-record-s from soi-header.
     go       to phase-2.
*>
 phase-2-end.
*>**********
*>
     close    open-item-file-3 open-item-file-s sinvoice-file.
     display  "2B" at 1207 with foreground-color 2.
     open     output open-item-file-3.
     open     input  open-item-file-s.
*>
 phase-2b.
*>
     read     open-item-file-s at end
              go to phase-2b-end.
     write    open-item-record-3 from open-item-record-s.
     go       to phase-2b.
*>
 phase-2b-end.
*>
     close    open-item-file-3 open-item-file-s.
     open     output  open-item-file-s.
     close    open-item-file-s.
*>
     display  "3 " at 1207 with foreground-color 2.
*>
     if       new-year = 1
              open output value-file
              display "End of year; VALUE File reset" at 1401 with foreground-color 2 underline
              go to phase-3-end.
*>
     open     i-o  value-file.
*>
 phase-3.
*>******
*>
     read     value-file  next record   at end
              go to  phase-3-end.
*>
     if       va-system not = "S"
              go to phase-3.
*>
     move     va-t-this  to  va-t-last.
     move     zero       to  va-t-this.
     move     va-v-this  to  va-v-last.
     move     zero       to  va-v-this.
*>
     rewrite  value-record.
     go       to phase-3.
*>
 phase-3-end.
*>**********
*>
     close    value-file.
*>
     display  "4A" at 1207 with foreground-color 2.
*>
     subtract pf-retention from u-bin giving pf-test.
     subtract 92           from u-bin giving inv-test.
*>
     open     input  sinvoice-file.
     open     output temp-invoice-file.
*>
 phase-4.
*>******
*>
     read     sinvoice-file next record at end
              go to  phase-4-end.
     move     sinvoice-record to sinvoice-header.
*>
     if       sih-test not = zero
              go to copy-record-out.
*>
     if       sih-type = 4 and
              pf-test > sih-date
              perform skip-reader sih-lines times
              go to phase-4.
*>
     if       not sapplied
              go to copy-record-out.
*>
     if       sih-type < 4
              move "B" to sih-day-book-flag.
*>
     if       sih-lines not = zero and
              sih-type = 2
              perform skip-reader sih-lines times
              move zero to sih-lines
              go to copy-record-out.
*>
     if       sih-type = 1 or 3
              perform skip-reader sih-lines times
              go to phase-4.
*>
     if       sl-own-nos not = "Y"
              go to copy-record-out.
*>
*> at this point if ih-type = 2 then ih-lines must be zero
*>
     if       sih-type = 2
        and   inv-test > sih-date
              go to phase-4.
*>
 copy-record-out.
*>
     write    temp-invoice-record from sinvoice-header.
     go       to phase-4.
*>
 skip-reader.
*>
     read     sinvoice-file next record at end
              go to phase-4-end.
*>
 phase-4-end.
*>**********
*>
     close    sinvoice-file temp-invoice-file.
*>
     display  "4B" at 1207 with foreground-color 2.
     open     input  temp-invoice-file.
     open     output sinvoice-file.
*>
 phase-5.
*>******
*>
     read     temp-invoice-file at end
              go to phase-5-end.
     write    sinvoice-record from temp-invoice-record.
     go       to phase-5.
*>
 phase-5-end.
*>**********
*>
     close    sinvoice-file temp-invoice-file.
*>
 phase-6.
*>******
*>
*>  Sales now finished
*>
     display  "5 " at 1207 with foreground-color 2.
     move     sl-os-bal-this-month to sl-os-bal-last-month.
     move     zeros to sl-os-bal-this-month sl-variance
                     sl-invoices-this-month sl-payments
                     sl-credit-deductions sl-cn-unappl-this-month
                     sl-credit-notes-this-month.
*>
 phase-6-end.
*>
 main-exit.   exit section.
*>
 kill-invoices section.
*>====================
*>
     if       soi-type not = 2     *>   Account - Only kill these
              go to kill-exit.
     if       sl-own-nos = "Y"
              go to kill-exit.
*>
     move     soi-invoice to sinvoice-nos.
     move     space to sinvoice-let.
     move     zeros to sitem-nos.
*>
     read     sinvoice-file invalid key
              move 99 to fs-reply.
     if       fs-reply not = zero
              go to test-for-subs.
     move     sinvoice-record to sinvoice-header.
*>
     delete   sinvoice-file invalid key
              go to kill-exit.
     if       sih-lines = zero
              go to kill-exit.
     perform  actual-delete sih-lines times.
     go       to kill-exit.
*>
 test-for-subs.
*>
     add      1 to sitem-nos.
     read     sinvoice-file invalid key
              go to kill-exit.
     if       sinvoice-nos not = soi-invoice
              go to kill-exit.
     delete   sinvoice-file invalid key
              go to kill-exit.
     go       to test-for-subs.
*>
 actual-delete.
*>
     add      1 to sitem-nos.
     delete   sinvoice-file.
*>
 kill-exit.
     exit     section.
*>
 pl-processing   section.
*>**********************
*>
     display  "Phase 1  - Purchase" at 1201 with foreground-color 2.
     display  "*******"             at 1301 with foreground-color 2.
     display  "Please Wait"         at 1501 with foreground-color 2 blink.
*>
     if       new-quarter = 1
              open output temp-purchase-file
              open input  purchase-file
              display "A" at 1208 with foreground-color 2
       else
              open i-o  purchase-file.
*>
 phase-1.
*>******
*>
     read     purchase-file  next record  at end
              go to  phase-1-end.
*>
     if       purch-current = zero
         and  purch-last    = zero
         and  purch-unapplied = zero
              move  0  to  purch-status.
*>
     if       purch-current is negative
              multiply -1 by purch-current
              add purch-current to purch-unapplied
              move zero to purch-current.
*>
     move     purch-current  to  purch-last.
*>
     if       new-quarter = 1
              move  zero  to  pturnover-q (current-quarter).
*>
     if       new-year = 1
              move zero to purch-average purch-activety.
*>
     if       new-quarter = 1
              write temp-purch-record from purch-record
              go to phase-1.
*>
     rewrite  purch-record.
     go to    phase-1.
*>
 phase-1-end.
*>**********
*>
     close    purchase-file.
     if       new-quarter = zero
              go to phase-1b-skip.
*>
     close    temp-purchase-file.
     open     output purchase-file.
     open     input temp-purchase-file.
     display  "1B" at 1207 with foreground-color 2.
*>
 phase-1b.
*>
     read     temp-purchase-file at end
              go to phase-1b-end.
     write    purch-record from temp-purch-record.
     go       to phase-1b.
*>
 phase-1b-end.
*>
     close    temp-purchase-file purchase-file.
     open     output temp-purchase-file.
     close    temp-purchase-file.
*>
 phase-1b-skip.
*>
     display  "2A" at 1207 with foreground-color 2.
*>
     open     input  open-item-file-5.
     open     output open-item-file-s.
     open     i-o pinvoice-file.
*>
 phase-2.
*>******
*>
     read     open-item-file-5 next record into poi-header at end
              go to  phase-2-end.
*>
     if       ps-closed
              perform kill-invoicep
              go to phase-2.
     if       poi-type = 1
              go to phase-2.
     if       poi-type = 5 or 6
              move zero to poi-deduct-amt.
*>
     move     "z" to poi-applied.
     move     zero  to  poi-p-c.
*>
     write    open-item-record-s from poi-header.
     go       to phase-2.
*>
 phase-2-end.
*>**********
*>
     close    open-item-file-5 open-item-file-s pinvoice-file.
     display  "2B" at 1207 with foreground-color 2.
     open     output open-item-file-5.
     open     input  open-item-file-s.
*>
 phase-2b.
*>
     read     open-item-file-s at end
              go to phase-2b-end.
     write    open-item-record-5 from open-item-record-s.
     go       to phase-2b.
*>
 phase-2b-end.
*>
     close    open-item-file-5 open-item-file-s.
     open     output  open-item-file-s.
     close    open-item-file-s.
*>
     display  "3 " at 1207 with foreground-color 2.
*>
     if       new-year = 1
              open output value-file
              display "End of year; VALUE File reset" at 1401 with foreground-color 2 underline
              go to phase-3-end.
*>
     open     i-o  value-file.
*>
 phase-3.
*>******
*>
     read     value-file  next record   at end
              go to  phase-3-end.
*>
     if       va-system not = "P"
              go to phase-3.
*>
     move     va-t-this  to  va-t-last.
     move     zero       to  va-t-this.
     move     va-v-this  to  va-v-last.
     move     zero       to  va-v-this.
*>
     rewrite  value-record.
     go       to phase-3.
*>
 phase-3-end.
*>**********
*>
     close    value-file.
*>
     display  "4A" at 1207 with foreground-color 2.
*>
     open     input  pinvoice-file.
     open     output temp-invoice-file.
*>
 phase-4.
*>******
*>
     read     pinvoice-file next record at end
              go to  phase-4-end.
     move     pinvoice-record to pinvoice-header.
*>
     if       pih-test not = zero
              go to copy-record-out.
*>
     if       not papplied
              go to copy-record-out.
*>
     if       pih-type < 4
              move "B" to pih-day-book-flag.
*>
     if       pih-type = 1 or 3
              perform skip-reader pih-lines times
              go to phase-4.
*>
     if       pih-lines not = zero and
              pih-type = 2
              perform skip-reader pih-lines times
              move zero to pih-lines.
*>
*> at this point if PIH-type = 2 then PIH-lines must be zero
*>
 copy-record-out.
*>
     write    temp-invoice-record from pinvoice-header.
     go       to phase-4.
*>
 skip-reader.
*>
     read     pinvoice-file next record at end
              go to phase-4-end.
*>
 phase-4-end.
*>**********
*>
     close    pinvoice-file temp-invoice-file.
*>
     display  "4B" at 1207 with foreground-color 2.
     open     input  temp-invoice-file.
     open     output pinvoice-file.
*>
 phase-5.
*>******
*>
     read     temp-invoice-file at end
              go to phase-5-end.
     write    pinvoice-record from temp-invoice-record.
     go       to phase-5.
*>
 phase-5-end.
*>**********
*>
     close    pinvoice-file temp-invoice-file.
*>
 phase-6.
*>******
*>
     display  "5 " at 1207 with foreground-color 2.
     move     pl-os-bal-this-month to pl-os-bal-last-month.
     move     zeros to pl-os-bal-this-month pl-variance
                     pl-invoices-this-month pl-payments
                     pl-credit-deductions pl-cn-unappl-this-month
                     pl-credit-notes-this-month.
*>
 phase-6-end.
*>
 main-exit.   exit section.
*>
 kill-invoicep section.
*>====================
*>
     if       poi-type not = 2     *>   Account - Only kill these
              go to kill-exit.
*>
     move     poi-invoice to pinvoice-nos.
     move     zeros to pitem-nos.
*>
     read     pinvoice-file invalid key
              move 99 to fs-reply.
     if       fs-reply not = zero
              go to test-for-subs.
     move     pinvoice-record to pinvoice-header.
*>
     delete   pinvoice-file invalid key
              go to kill-exit.
     if       pih-lines = zero
              go to kill-exit.
     perform  actual-delete pih-lines times.
     go       to kill-exit.
*>
 test-for-subs.
*>
     add      1 to pitem-nos.
     read     pinvoice-file invalid key
              go to kill-exit.
     if       pinvoice-nos not = poi-invoice
              go to kill-exit.
     delete   pinvoice-file invalid key
              go to kill-exit.
     go       to test-for-subs.
*>
 actual-delete.
*>
     add      1 to pitem-nos.
     delete   pinvoice-file.
*>
 kill-exit.
     exit     section.
*>
 check-end-of-cycle      section.
*>==============================
*>
     add      1  to  cyclea.
     if       period = 3
              perform  monthly-check
     else
      if      period = 13
              perform  weekly-check
       else
              perform  query-check.
*>
     go       to main-exit.
*>
 monthly-check.
*>************
*>
     if       cyclea = 4  or  7  or 10
              add   1  to  current-quarter
              move  1  to  new-quarter
     else
     if       cyclea = 13
              move 1 to cyclea
                        current-quarter new-year new-quarter.
*>
 weekly-check.
*>***********
*>
     if       cyclea = 14  or  27  or  40
              add   1  to  current-quarter
              move  1  to  new-quarter
     else
      if      cyclea = 53
              move 1 to cyclea
                        current-quarter new-year new-quarter.
*>
 query-check.
*>**********
*>
     display  "Is this the end of a quarter (Y/N) - [ ]" at 1601 with foreground-color 2.
     accept   ws-reply at 1639 with foreground-color 6.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "N"
              go to  main-exit.
*>
     if       ws-reply not = "Y"
              go to  query-check.
*>
     if       current-quarter not = 4
              add   1  to  current-quarter
              move  1  to  new-quarter
       else
              move 1 to cyclea
                        current-quarter new-year new-quarter.
*>
 main-exit.   exit section.
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
              display XL009    at 0505 with erase eos foreground-color 3 highlight
              display XL008    at 1210 with           foreground-color 3 highlight
              accept ws-reply  at 1243
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
              display XL006        at 0101 with erase eos foreground-color 3
              display Arg-Number   at 0164 with           foreground-color 3
              display XL008        at 1210 with           foreground-color 3 highlight
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
                       display XL007   at 0101 with erase eos foreground-color 3
                       display XL008   at 1210 with           foreground-color 3 highlight
                       accept ws-reply at 1243
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
     display space at 0101 with erase eos.
     perform  File-Defs-Count times
              add 1 to z
              move space to Arg-Test
              string ACAS_LEDGERS          delimited by space
                     OS-Delimiter          delimited by size
                     System-File-Names (z) delimited by space
                                             into Arg-Test
              end-string
              move     Arg-Test to System-File-Names (z)
              display  System-File-Names (z) at line z col 1 *> TEMp for TESTING
     end-perform
*>
*> Don't do posting file to IRS as not used
*>
     move space to Arg-Test.
     string   ACAS_IRS delimited by space
              OS-Delimiter delimited by size
              file-8 delimited by space into Arg-Test.
     move     Arg-Test to file-8.
     add      1 to z.
*>     display  file-8 at line z col 1. *> TEMp for TESTING
*>     display XL008 at 2301.           *> TEMp for TESTING
*>     accept ws-reply at 2333.         *> TEMp for TESTING
     move     zero to z.
*>
 zz020-Exit.
     exit   section.
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
