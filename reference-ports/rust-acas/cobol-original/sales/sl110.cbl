       >>source free
*>****************************************************
*>                                                   *
*>      S T A T E M E N T   P R O D U C T I O N      *
*>                                                   *
*>    Needs to be changed to suit your statements.   *
*>    see body and end of statements section         *
*>      eg, the last 170 or so lines of Cobol code   *
*>      but also copied below here:                  *
*>****************************************************
*>
*>**************************************************************************************************
*>=================================================================================================*
*> You might want to change the (Cups) spool name to reflect the printer containing any preprinted *
*>   special paper, eg continuous forms or a laser that has the statement Template pre-loaded.     *
*>   See next statement then you can uncomment the call statement below.                           *
*> NOTE that at the moment the program spools & printed with                                       *
*>   the system name of prt-2. See manual for further notes on this.                       *
*>-------------------------------------------------------------------------------------------------*
*>                 Similar issues will apply to invoice production as well.                        *
*>=================================================================================================*
*>
*>##################################################################################################
*> Open Source users without IT support or skills in Cobol can contact programmer support at       #
*>      Applewood Computers for assistance in this or any other matter.                            #
*>##################################################################################################
*>
*>**************************************************************************************************
*>
 identification          division.
*>===============================
*>
      program-id.         sl110.
*>*
*>    author.             V B Coen FBCS, 24/10/83
*>                        For Applewood Computers.
*>
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Statment Production.
*>                        Setup to Use pre-printed continous forms or a laser Template file
*>
*>**
*>    Version.            See Prog-Name In Ws.
*>
*>    called modules.     maps04.
*>                        maps99.
*>**
*>    Error messages used.
*>                        SL003
*>                        SL150
*>**
*>    changes.
*> 14/02/83 vbc - 053970-990
*> 23/03/83 Vbc - Correct Flavour Lines.
*> 31/03/83 Vbc - Correct Name, Address, Amount Lines For Letter.
*> 02/05/83 Vbc - Stop Letter Routine Using Closed Records.
*> 24/10/83 Vbc - Cis Cobol Conversion.
*> 01/03/84 Vbc - Support For Sales-Unapplied.
*> 30/03/84 Vbc - Don't Check For Oi-Invoice = 99999999,Not Applic
*>                 Remove Code For Letters, Now A Separate Program.
*> 02/10/84 Vbc - Support For Sixth Address Line.
*> 30/11/84 Vbc - Fix Bug Re Flavour2.
*> 03/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 25/11/11 vbc - .04 Error msgs to SLnnn.Support for dates other than UK
*> 08/12/11 vbc - .05 Support for path+filenames.
*> 09/12/11 vbc -     Updated version to 3.01.nn
*> 11/12/11 vbc - .06 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 20/05/13 vbc - .07 Removed double sided printing from print-spool-command.cob.
*> 28/05/13 vbc - .08 Spooling set to prt-2 with PSN2
*>                    removed all outstanding Adobe Reader API code as its a chargable product.
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
 environment             division.
 copy "envdiv.cob".
 input-output            section.
 file-control.
*>-----------
*>
 copy "selsl.cob".
 copy "selois.cob".
 copy "selprint.cob" replacing "prt-1" by "prt-2".
 data                    division.
 file section.
*>-----------
*>
 copy "fdsl.cob".
 copy "fdois.cob".
 copy "fdprint.cob".
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "SL110 (3.01.08)".
 copy "print-spool-command.cob" replacing "page-right=10 sides=two-sided-long-edge cpi=12 lpi=8' -P " by
                                          "page-right=10 cpi=12 lpi=8' -P "
                                          ==PSN== by ==PSN2==
                                          "prt-1" by "prt-2".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
 copy "wsoi.cob".
*>
 01  flavour-line1                            value spaces.
     03  filler          pic x.
     03  flavour1        pic x(64).
 01  flavour-line2                            value spaces.
     03  filler          pic x.
     03  flavour2.
         05 fl2-back-tag pic x.
         05 fl2-rest     pic x(63).
*>
 01  ws-data.
     03  menu-reply      pic 9.
     03  ws-reply        pic x.
     03  a               pic 99.
     03  y               pic 99.
     03  z               pic 99.
     03  ws-inv8         pic z(7)9.
     03  ws-inv redefines ws-inv8 pic x(8).
     03  truth           pic 9.
         88  a-true                        value  1.
         88  a-false                       value  0.
     03  address-A       pic x(96).
     03  address-line    pic x(36).
     03  first-time      pic 9           value zero.
     03  ws-spaces       pic x(80)       value spaces.
     03  st-date         pic x(10)       value spaces.
     03  work-1          pic s9(6)v99.
     03  work-2          pic s9(6)v99.
     03  i               pic 99.
     03  j               pic 99.
     03  k               pic 99.
     03  l-p             pic 99 value zero.
     03  customer-in     pic x(7) value space.
     03  filler  redefines  customer-in.
         05  array-l     pic x  occurs  7.
     03  pay-date        binary-long        value zero.
     03  pay-value       pic s9(6)v99       value zero.
     03  pay-paid        pic s9(6)v99.
     03  escape-code     pic x.
     03  last-read       pic x(7)           value spaces.
     03  inv-amount      pic s9(7)v99.
     03  amount-out      pic s9(7)v99.
     03  pay-amount      pic s9(7)v99.
*>
 01  ws-amount-screen-display.
     03  ws-poundsd      pic 9(6).
     03  ws-period       pic x              value ".".
     03  ws-penced       pic v99.
 01  ws-amount-screen-accept redefines ws-amount-screen-display.
     03  ws-pound        pic 9(6).
     03  filler          pic x.
     03  ws-pence        pic v99.
*>
 01  ws-amount-work.
     03  amt-wk-pds      pic 9(6).
     03  amt-wk-pence    pic v99.
 01  ws-amount-ok redefines ws-amount-work.
     03  amt-ok          pic 9(6)v99.
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
     03  SL003          pic x(28) value "SL003 Hit Return To Continue".
*> Module specific
     03  SL150          pic x(39) value "SL150 Re-align statement to top of form".
*>
 01  error-code          pic 999.
*>
 01  balances        comp-3.
     03  bal-0           pic s9(7)v99 value zero.
     03  bal-30          pic s9(7)v99 value zero.
     03  bal-60          pic s9(7)v99 value zero.
     03  bal-90          pic s9(7)v99 value zero.
     03  bal-t           pic s9(7)v99 value zero.
*>
 01  line-1.
     03  filler          pic x(24)       value spaces.
     03  l1-s-name       pic x(32).
*>
 01  line-2.
     03  filler          pic x(24)       value spaces.
     03  l2-s-address    pic x(24).
     03  filler          pic x(21)       value spaces.
     03  l2-r-name       pic x(23).
*>
 01  line-3.
     03  filler          pic x(24)       value spaces.
     03  l3-s-address    pic x(24).
     03  filler          pic x(21)       value spaces.
     03  l3-r-address    pic x(23).
*>
 01  line-4.
     03  filler          pic x(24)       value spaces.
     03  l4-s-address    pic x(24).
     03  filler          pic x(21)       value spaces.
     03  l4-r-address    pic x(23).
*>
 01  line-5.
     03  filler          pic x(24)       value spaces.
     03  l5-s-address    pic x(24).
     03  filler          pic x(21)       value spaces.
     03  l5-r-address    pic x(23).
*>
 01  line-7.
     03  filler          pic x(9)        value spaces.
     03  l7-c-name       pic x(32).
*>
 01  line-8.
     03  filler          pic x(9)        value spaces.
     03  l8-c-address    pic x(32).
     03  filler          pic x(15)       value spaces.
     03  l8-s-date       pic x(10).
     03  filler          pic x(3)        value spaces.
     03  l8-r-date       pic x(10).
     03  filler          pic x(5)        value spaces.
     03  l8-r-cust       pic x(7).
*>
 01  line-9.
     03  filler          pic x(9)        value spaces.
     03  l9-c-address    pic x(32).
*>
 01  line-10.
     03  filler          pic x(9)        value spaces.
     03  l10-c-address   pic x(32).
*>
 01  line-11.
     03  filler          pic x(9)        value spaces.
     03  l11-c-address   pic x(32).
     03  filler          pic x(18)       value spaces.
     03  l11-s-cust      pic x(7).
*>
 01  line-12.
     03  filler          pic xx          value spaces.
     03  l12-s-invoice   pic z(7)9       blank when zero.
     03  filler          pic xxx         value spaces.
     03  l12-date        pic x(11).
     03  l12-desc        pic x(31).
     03  l12-s-amount    pic z(6)9.99cr.
     03  filler          pic xxx         value spaces.
     03  l12-r-invoice   pic z(7)9       blank when zero.
     03  l12-r-amount    pic z(7)9.99cr.
*>
 01  line-13.
     03  l13-amount1     pic z(6)9.99cr.
*>    blank when zero.
     03  filler          pic x(2)        value spaces.
     03  l13-amount2     pic z(6)9.99cr.
*>    blank when zero.
     03  filler          pic x           value spaces.
     03  l13-amount3     pic z(6)9.99cr.
*>    blank when zero.
     03  filler          pic x           value spaces.
     03  l13-amount4     pic z(6)9.99cr.
*>    blank when zero.
     03  filler          pic x           value spaces.
     03  l13-amount5     pic z(6)9.99cr.
*>    blank when zero.
     03  filler          pic x(12)       value spaces.
     03  l13-amount6     pic z(6)9.99cr.
*>    blank when zero.
*>
 01  line-14.
     03  filler          pic x(9) value spaces.
     03  l14-c-address   pic x(32).
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
*>
 01  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 init01 section.
*>
     if       file-status (19) not = 1
              move 19  to  error-code
              call "maps99"  using  error-code ws-calling-data
              move 15 to error-code
              call "maps99" using error-code ws-calling-data
              go to menu-exit.
*>
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name2 to PSN2.			*> Spool 2
*>
     move     to-day to u-date.
     display  prog-name at 0202 with foreground-color 2 erase eos.
     display  "Statement Production" at 0232 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0271 with foreground-color 2.
*>
     perform  statements.
*>
     call     "SYSTEM" using Print-Report.
*>
 menu-exit.
*>********
*>
     exit     program.
*>
 accept-money.
*>-----------
*>
     move     zero to ws-poundsd amt-ok ws-penced.
     display  ws-amount-screen-display at curs  with foreground-color 3.
     accept   ws-amount-screen-accept at curs   with foreground-color 3 update.
     move     ws-pound to amt-wk-pds.
     move     ws-pence to amt-wk-pence.
*>
*>****************************************************************
*>                  P r o c e d u r e s                          *
*>****************************************************************
*>
 statements              section.
*>==============================
*>
     display  "****************************************" at 0441 with foreground-color 2.
     display  "*Date    [  /  /    ]*                 *" at 0541 with foreground-color 2.
     display  "*A/C Nos    [       ]*               ***" at 0641 with foreground-color 2.
     display  "*Value    [         ]*                 *" at 0741 with foreground-color 2.
     display  "****************************************" at 0841 with foreground-color 2.
*>
     display  "Notes" at 1101 with foreground-color 2.
     display  "*****" at 1201 with foreground-color 2.
     display  " (1)  -   <Date>  :  Appears on statement" AT 1401 with foreground-color 2.
     display  " (2)  -   <A/C>   :  A/C's to match for printing" at 1501 with foreground-color 2.
     display  " (3)  -   <Value> :  Minimum O/S to print" AT 1601 with foreground-color 2.
*>
 date-input.
*>*********
*>
     display  ws-date at 0551 with foreground-color 3.
     accept   ws-date at 0551 with foreground-color 3 update.
     if       ws-date = spaces
              go to main-exit.
*>
     move     ws-date to ws-test-date.
     perform  zz050-Validate-Date.
     if       u-bin = zero
              go to  date-input.
*>
*>     move     u-date  to  st-date.  *> UK default date, ws-test-date is in display/accept format
     move     u-bin to pay-date.      *> this one is in binary days since 31/12/1599
*>
 customer-input.
*>*************
*>
     accept   customer-in at 0654 with foreground-color 2 update.
     move     function upper-case (customer-in) to customer-in.
*>
 value-input.
*>**********
*>
     move     0752 to curs.
     perform  accept-money.
     move     amt-ok to pay-value.
*>
 flavour-in.
*>*********
*>
     display  "Msg Line 1 - [" at 1801 with foreground-color 2.
     display  "]" at 1879 with foreground-color 2.
     display  "Msg Line 2 - [" at 1901 with foreground-color 2.
     display  "]" at 1979 with foreground-color 2.
*>
     accept   flavour1 at 1815 with foreground-color 3 update.
     accept   flavour2 at 1915 with foreground-color 3 update.
     if       fl2-back-tag = "<"
              go to flavour-in.
*>
     open     input sales-file open-item-file-s.
     open     output print-file.
*>
     if       customer-in = spaces
              go to read-sales.
*>
     move     customer-in to sales-key.
     start    sales-file key not < sales-key invalid key
              move 1 to y.
     inspect  customer-in replacing all spaces by "Z".
*>
 read-sales.
*>*********
*>
     read     sales-file  next  record
              at end  go to  main-end.
*>
     if       sales-unapplied not = zero
              subtract sales-unapplied from sales-current.
*>
     if       sales-current  = zero
              go to read-sales.
*>
     if       pay-value not = zero
       and    sales-current  <  pay-value
              go to  read-sales.
*>
     if       customer-in not =   spaces
        and   sales-key > customer-in
              go to main-end.
*>
     move     sales-address  to  address-A.
*>
     move     sales-name  to  l7-c-name.
*>
     move     1  to  a.
     unstring address-A  delimited  by  sl-delim into  address-line count a pointer  a.
     move     address-line  to  l8-c-address.
*>
     move     spaces  to  address-line.
     unstring address-A  delimited  by  sl-delim into  address-line count a pointer  a.
     move     address-line  to  l9-c-address.
*>
     move     spaces  to  address-line.
     unstring address-A delimited  by  sl-delim  into  address-line count a pointer  a.
     move     address-line  to  l10-c-address.
*>
     move     spaces to address-line.
     unstring address-A delimited  by  sl-delim into  address-line  count a pointer  a.
     move     address-line  to  l14-c-address.
*>
     move     spaces to address-line.
     unstring address-A delimited  by  sl-delim into  address-line  count a pointer  a.
     move     address-line  to  l11-c-address.
*>
     move     usera  to l1-s-name         l2-r-name.
     move     address-1  to  l2-s-address l3-r-address.
     move     address-2  to  l3-s-address l4-r-address.
     move     address-3  to  l4-s-address l5-r-address.
     move     address-4  to  l5-s-address.
*>
*> Note that ws-test-date still has the pre-converted date from the accept
*>
     move     ws-test-date  to  l8-s-date l8-r-date.
*>
     move     sales-key  to  l8-r-cust l11-s-cust.
*>
     perform  headings-1.
*>
     if       sales-unapplied = zero
              go to read-open-item.
*>
*> Note that ws-test-date still has the pre-converted date from the accept
*>
     move     zero to l12-s-invoice l12-r-invoice.
     move     ws-test-date to l12-date.
     move     "Unapplied Credit Balance" to l12-desc.
     multiply -1 by sales-unapplied.
     move     sales-unapplied to l12-s-amount l12-r-amount.
     add      sales-unapplied to bal-0.
     add      sales-unapplied to bal-t.
     add      1 to l-p.
     write    print-record from line-12 after 1.
*>
 read-open-item.
*>*************
*>
     if       last-read = spaces
              read  open-item-file-s  record at end
                    perform  end-statement thru end-stat-do
                    go to    main-end
     end-if
*>
     move     open-item-record-s  to  oi-header.
     move     oi-customer  to  last-read.
*>
     if       last-read  >  sales-key
              go to  end-statement.
*>
     if       last-read  not = sales-key
              move  spaces  to  last-read
              go to  read-open-item.
*>
*> O-I transaction is for this customer.
*>
     if       oi-type = 1  or  4
              move  spaces  to  last-read
              go to  read-open-item.
*>
*> can safely ignore receipts & pro-formas.
*>
     if       oi-type = 5 or 6
              move  zero  to  oi-invoice.
*>
     move     oi-invoice  to  l12-s-invoice
                              l12-r-invoice.
*>
     move     oi-date  to  u-bin.
     perform  zz060-Convert-Date.
     move     ws-date   to  l12-date.
*>
     move     spaces  to  l12-desc.
     move     1  to  z.
*>
     if       oi-type = 2
              string  "Goods As Per - "  delimited  by size into l12-desc  pointer  z
              string  oi-description  delimited  by  "  "   into l12-desc  pointer  z
     else
      if      oi-type = 3
              move  1  to  y
              string  "Credit Note Re. Inv - " delimited by size into l12-desc  pointer  y
              move oi-cr to ws-inv8
              string  ws-inv delimited  by  size into l12-desc  pointer  y
      else
       if     oi-type = 6
              move "Unapplied Credit Allocated" to l12-desc
       else
              move  "Payment. Received With Thanks" to  l12-desc.
*>
     if       oi-type = 2 and
              oi-description = spaces
              move "Goods" to l12-desc.
*>
     add      oi-net        oi-extra      oi-carriage
              oi-vat        oi-discount   oi-e-vat
              oi-deduct-amt oi-deduct-vat oi-c-vat     giving  inv-amount.
*>
*> Invoices Only Here
*>
     if       oi-type = 2
              subtract   oi-paid  from  inv-amount  giving  amount-out
              add   amount-out oi-p-c  giving l12-s-amount
              move  amount-out  to  l12-r-amount.
     if       oi-type = 2
       and    amount-out = zero
       and    oi-p-c = zero
              move  inv-amount  to  l12-s-amount.
*>
*> Cr. Notes Only Here.
*>
     if       oi-type = 3
              move  inv-amount to  l12-s-amount
              add   oi-paid    to inv-amount
              move inv-amount  to l12-r-amount.
*>
*> Payments  Only Here.
*>
     if       oi-type = 5  or  6
              if  oi-paid  not negative
                  multiply  -1  by  oi-paid.
     if       oi-type = 5  or  6
              if  oi-approp  not negative
                  multiply  -1  by  oi-approp.
     if       oi-type = 5  or  6
              subtract oi-approp from oi-paid giving amount-out
              move  amount-out  to  l12-r-amount
              move  oi-paid  to  l12-s-amount.
*>
     subtract oi-date  from  pay-date  giving  work-1.
*>
*> now work out ageing
*> (dont worry if paid in full - routine still works ok)
*>
     if       work-1  <  30
              add  amount-out  to  bal-0
     else
      if      work-1  <  60
              add  amount-out  to  bal-30
      else
       if     work-1  <  90
              add  amount-out  to  bal-60
       else
              add  amount-out  to  bal-90.
*>
     add      amount-out  to  bal-t.
*>
 bypass-ageing.
*>
     move     zero  to  amount-out.
*>
*> now to print. What joy!!!!!!.
*>
     add      1  to  l-p.
*>
     if       l-p  >  28
              move  spaces  to  print-record
              write  print-record after 8 lines
              perform  headings-1
              move  1  to  l-p.
*>
     write    print-record  from  line-12 after 1.
*>
*> now loop back for next item....
*>
     move     spaces  to  last-read.
     go       to read-open-item.
*>
*> can only get here at the end of a statement.
*>
 end-statement.
*>************
*>
*> now let us (or cabbage) compute the skip......wow!!!!!!
*>
     compute  l-p  =  32  -  l-p.
*>
     if       l-p  <  6
              go to  end-stat-do.
     subtract 4  from  l-p.
     write    print-record  from  flavour-line1 after l-p.
     write    print-record  from  flavour-line2 after 1.
     move     3  to  l-p.
*>
 end-stat-do.
*>**********
*>
     move     bal-0   to  l13-amount1.
     move     bal-30  to  l13-amount2.
     move     bal-60  to  l13-amount3.
     move     bal-90  to  l13-amount4.
     move     bal-t   to  l13-amount5
                          l13-amount6.
*>
     write    print-record from line-13 after l-p lines.
*>
*> now set-up the form for the next one then zeroise counter fields
*>
     move     spaces  to  print-record.
     write    print-record after 4 lines.
*>
*> now as promised some zeroising.
*>
     move     zero  to  bal-0   bal-30
                        bal-60  bal-90
                        bal-t   l-p.
*>
*> loop time.......get another punter.
*>
 end-statement-end.
*>
     go       to read-sales.
*>
 main-end.
*>*******
*>
     close    open-item-file-s sales-file print-file.
     open     output open-item-file-s.                *> clear down temp file
     close    open-item-file-s.
*>*************************************************************************************************
*>================================================================================================*
*>  Here you might want to change the spool name to reflect the printer containing any preprinted *
*>   special paper, eg continuous forms or a laser that has the statement Template pre-loaded.    *
*>================================================================================================*
*>*************************************************************************************************
*>
 main-exit.   exit section.
*>********    ****
*>
 headings-1          section.
*>==========================
*>
     write    print-record  from  line-1 after 1.
     write    print-record  from  line-2 after 1.
     write    print-record  from  line-3 after 1.
     write    print-record  from  line-4 after 1.
     write    print-record  from  line-5 after 1.
     write    print-record  from  line-7 after 2.
     write    print-record  from  line-8 after 1.
     write    print-record  from  line-9 after 1.
     write    print-record  from  line-10 after 1.
     write    print-record  from  line-14 after 1.
     write    print-record  from  line-11 after 1.
*>
     if       first-time  not = zero
              go to  main-end.
*>
*>####################################################################################################
*>  These lines are for directly used printers, spooled systems do not need this unless the spooler
*>       can not handle alignment tests etc so adjust to suit your needs. For those spoolers that
*>       do just hit return on first question
*>####################################################################################################
*>
     display  "Statement correctly aligned.... (Y/N) ? - [ ]" at 2001 with foreground-color 2.
*>
     move     "Y"  to  ws-reply.
     accept   ws-reply at 2044 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "Y"
              go to  main-end.
*>
     display  SL150    at 2101 with foreground-color 2. *> realign paper msg
     display  SL003    at 2201 with foreground-color 2. *> hit ret
     accept   ws-reply at 2044 with foreground-color 2.
*>
     display  " " at 2101 with erase eol.
     display  " " at 2201 with erase eol.
     go       to headings-1.
*>
 main-end.
*>*******
*>
     if       first-time = zero
              display ws-spaces at 2001.
     move     1 to first-time.
     move     spaces  to  print-record.
     write    print-record after 3 lines.
*>
 main-exit.   exit section.
*>
 zz050-Validate-Date        section.
*>*********************************
*>
*>  Converts USA/Intl to UK date format for processing.
*>****************************************************
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
