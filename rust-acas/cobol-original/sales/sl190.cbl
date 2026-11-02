       >>source free
*>**************************************************************
*>                                                             *
*>      D U N N I N G   L E T T E R   P R O D U C T I O N      *
*>                                                             *
*>   This program produce 3 files for printing or passing to   *
*>    another program for printing as required                 *
*>    When originally written it created a file that was       *
*>     passed to MS Word in a sort/merge mail process that     *
*>       added the text for each letter type per customer      *
*>        record                                               *
*><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*
*>    NEED TO TEST linking into LibreOffice Writer          <<<*<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*
*> NOTE:  This program prints out the UK pound symbol so if    *
*>        you use something else change it                     *
*>        See line starting with currency sign (line 86)       *
*>**************************************************************
*>
 identification          division.
*>===============================
*>
      program-id.         sl190.
*>*
*>    author.             V B Coen, FBCS
*>                        For Applewood Computers.
*>*
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    remarks.            Letter Production.
*>**
*>    version.            See Prog-Name In Ws.
*>
*>    Called Modules.     maps04.
*>**
*>    Error messages used.
*>                        NONE
*>**
*>    Changes.
*> 31/03/83 Vbc - Correct Name, Address, Amount Of Letter.
*> 08/04/83 Vbc - Stop Closed Records Being Used For Letters.
*>                 Use All 3 Letter Files At Once.
*> 26/10/83 Vbc - Cis Cobol Conversion to WorkBench.
*> 01/03/84 Vbc - Support Sales-Unapplied In Read-Sales Routine.
*> 11/05/84 Vbc - Support For Indexed Openitm File.
*> 03/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 25/11/11 vbc - .01 Error msgs to SLnnn.Support for dates other than UK
*> 08/12/11 vbc - .02 Support for path+filenames BUT letter files are to local directory.
*> 09/12/11 vbc -     Updated version to 3.01.nn
*> 11/12/11 vbc - .03 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 27/02/12 vbc - .04 Changed use of array-k' in 'sales-key to sales-key (y:1) for SQL processing.
*> 25/03/12 vbc - .05 Added quotes around all non-numerics, if word processor needs it.
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of the Applewood Computers Accounting System
*> and is copyright (c) Vincent B Coen. 1976 - 2012 and later.
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
 configuration section.
*> copy "envdiv.cob".
*>
 special-names.
*>************
     currency sign "£".         *> CHANGE THIS TO YOUR CURRENCY or *> if dollars!
*>
 input-output            section.
*>------------------------------
*>
 file-control.
*>-----------
*>
 copy "selsl.cob".
 copy "seloi3.cob".
*>
     select  letter-file-1     assign        file-21-a,
                               organization  line sequential.
     select  letter-file-2     assign        file-21-b,
                               organization  line sequential.
     select  letter-file-3     assign        file-21-c,
                               organization  line sequential.

 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdsl.cob".
 copy "fdoi3.cob".
*>
 fd  letter-file-1.
*>
 01  letter-record-1     pic x(208).
*>
 fd  letter-file-2.
*>
 01  letter-record-2     pic x(208).
*>
 fd  letter-file-3.
*>
 01  letter-record-3     pic x(208).
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "SL190 (3.01.04)".
*>
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
 copy "wsoi.cob".
*>
 77  si-date              binary-long          value zero.
*>
 01  ws-amount-screen-display.
     03  ws-poundsd      pic 9(6).
     03  ws-period       pic x     value ".".
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
 01  letter-work.
     03  lf-name         pic x(34).
     03  filler          pic x     value ",".
     03  lf-line1        pic x(34).
     03  filler          pic x     value ",".
     03  lf-line2        pic x(34).
     03  filler          pic x     value ",".
     03  lf-line3        pic x(34).
     03  filler          pic x     value ",".
     03  lf-line4        pic x(34).
     03  filler          pic x     value ",".
     03  lf-account      pic x(9).       *> 184
     03  filler          pic x     value ",".
     03  lf-os2.
*>         05  lf-os       pic z(6)9.99.   *> 195
         05 lf-os        pic £(6)9.99.   *> 195
     03  filler          pic x     value ",".
     03  lf-date         pic x(12).       *> 208
*>
 01  letter-work2        pic x(208).
*>
 01  ws-data.
     03  letter-nos      pic 999      value zero.
     03  store-work      pic 9(6)v99  value zero.
     03  a               pic 99.
     03  b               pic 99.
     03  y               pic 99.
     03  truth           pic 9.
       88  a-true                     value  1.
       88  a-false                    value  0.
     03  address-A       pic x(96).
     03  address-line    pic x(36).
     03  work-1          pic s9(6)v99.
     03  customer-in     pic x(7).
     03  filler  redefines  customer-in.
       05  array-l       pic x  occurs  7.
     03  pay-date        binary-long.
     03  pay-value       pic s9(6)v99.
     03  last-read       pic x(7)        value spaces.
     03  ws-days-1       pic 99.
     03  ws-days-2       pic 99.
     03  ws-days-3       pic 99.
     03  ws-reply        pic x           value space.
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
*>     NONE
*> Module specific
*>     NONE
*>
 01  error-code          pic 999.
*>
 01  filler.
     03  file-21-a       pic x(10)       value "letter.001".
     03  file-21-b       pic x(10)       value "letter.002".
     03  file-21-c       pic x(10)       value "letter.003".
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
     if       file-status (19)  equal  1
              go to  menu-return.
*>
     move     19  to  error-code.
     call     "maps99"  using  error-code ws-calling-data.
     move     15 to error-code.
     call     "maps99" using error-code ws-calling-data.
     accept    ws-reply at 2479.
     go       to menu-exit.
*>
 menu-return.
*>**********
*>
     display  " " at 0101 with erase eos.
     display  prog-name at 0202 with foreground-color 2.
     display  "Letter Production" at 0233 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0271 with foreground-color 2.
*>
     open     output letter-file-1 letter-file-2 letter-file-3.
     perform  statements.
     close    letter-file-1 letter-file-2 letter-file-3.
*>
 menu-exit.
*>********
*>
     exit     program.
*>
*>****************************************************************
*>      P R O C E D U R E S                                      *
*>****************************************************************
*>
 statements              section.
*>==============================
*>
     display  "****************************************" at 0441 with foreground-color 2.
     display  "*Date    [  /  /    ]                  *" at 0541 with foreground-color 2.
     display  "*A/C Nos   [       ]                 ***" at 0641 with foreground-color 2.
     display  "*Value  [         ]*                   *" at 0741 with foreground-color 2.
     display  "****************************************" at 0841 with foreground-color 2
*>
     go       to main-display-end.
*>
 main-display-end.
*>
     display  "Notes" at 1201 with foreground-color 2.
     display  "*****" at 1301 with foreground-color 2.
     display  " (1) - <A/C>   :  A/Cs To Match For Printing" at 1501 with foreground-color 2.
     display  " (2) - <Value> :  Minimum O/S To Print" at 1601   with foreground-color 2.
*>
 date-input.
*>*********
*>
     display  ws-date at 0551 with foreground-color 3.
     accept   ws-date at 0551 with foreground-color 3 update.
     perform  zz050-Validate-Date.
     if       u-bin  equal  zero
              go to  date-input.
     move     u-bin   to  pay-date.
*>
 customer-input.
*>*************
*>
     accept   customer-in at 0653 with foreground-color 3.
     move     function upper-case (customer-in) to customer-in.
*>
 value-input.
*>**********
*>
     move     0750 to curs.
     perform  accept-money.
     move     amt-ok to pay-value.
*>
 amounts-input.
*>************
*>
     move     sl-days-1 to ws-days-1.
     move     sl-days-2 to ws-days-2.
     move     sl-days-3 to ws-days-3.
     display "Low Date    - [  ]" at 1820 with foreground-color 2.
     display "Medium Date - [  ]" at 1920 with foreground-color 2.
     display "High Date   - [  ]" at 2020 with foreground-color 2.
     display  ws-days-1 at 1835 with foreground-color 2.
     display  ws-days-2 at 1935 with foreground-color 2.
     display  ws-days-3 at 2035 with foreground-color 2.
*>
     accept   ws-days-1 at 1835 with foreground-color 3.
     accept   ws-days-2 at 1935 with foreground-color 3.
     accept   ws-days-3 at 2035 with foreground-color 3.
     move     ws-days-1 to sl-days-1.
     move     ws-days-2 to sl-days-2.
     move     ws-days-3 to sl-days-3.
*>
     open     input sales-file open-item-file-3.
*>
 read-sales.
*>*********
*>
     read     sales-file  next  record
              at end  go to  main-end.
*>
     if       not dunning-letters
              go to read-sales.
*>
     subtract sales-unapplied from sales-current.
*>
     if       sales-current < 0.01   *> Do not process amount below this (0.01)
              go to read-sales.      *> change this to stop reminders fot small amouunts
*>
     if       pay-value not = zero
        and   sales-current  <  pay-value
              go to  read-sales.
*>
     if       customer-in  not = spaces
              move  1  to  truth
              perform test-array varying y from 1 by 1   until y > 6
              if    a-false
                    go to  read-sales.
*>
     move     sales-address  to  address-A.
     move     spaces to address-line.
*>
     move     1  to  a.
     unstring address-A  delimited  by  sl-delim into  address-line count a pointer  a.
     move     address-line  to  lf-line1.
*>
     move     spaces  to  address-line.
     unstring address-A  delimited  by  sl-delim into  address-line count a pointer  a.
     move     address-line  to  lf-line2.
*>
     move     spaces  to  address-line.
     unstring address-A  delimited  by  sl-delim into  address-line count a pointer  a.
     move     address-line  to  lf-line3.
*>
     move     spaces to address-line.
     unstring address-A  delimited  by  sl-delim into  address-line count a pointer  a.
     move     address-line  to  lf-line4.
*>
 read-open-item.
*>*************
*>
     if       last-read = spaces
              read  open-item-file-3 next record at end
                    perform  end-statement
                    go to    main-end.
*>
     move     open-item-record-3  to  oi-header.
     move     oi-customer  to  last-read.
*>
     if       last-read  >  sales-key
              go to  end-statement.
*>
     if       last-read  not equal  sales-key
              move  spaces  to  last-read
              go to  read-open-item.
*>
*> if here then o-i transaction is for this customer.
*>
     if       oi-type  not = 2                   *> not invoices?
              move  spaces  to  last-read
              go to  read-open-item.
*>
     if       s-closed
              move spaces to last-read
              go to read-open-item.
*>
     subtract oi-date  from  pay-date  giving  work-1.
*>
     if       work-1 >  store-work
              move  work-1  to  store-work
              if    oi-date  >  si-date
                    move  oi-date  to  si-date.
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
*>
*> loop time.......get another punter.
*>
     if       store-work not < sl-days-1
              perform  letter-out.
*>
     move     zero  to  store-work  si-date.
*>
 end-statement-end.
*>
     go       to read-sales.
*>
 accept-money.
*>-----------
*>
     move     zero to ws-poundsd amt-ok ws-penced.
     display  ws-amount-screen-display at curs.
     accept   ws-amount-screen-accept at curs.
     move     ws-pound to amt-wk-pds.
     move     ws-pence to amt-wk-pence.
*>
 main-end.
*>*******
*>
     close    open-item-file-3 sales-file.
*>
 main-exit.   exit section.
*>********    ****
*>
 test-array              section.
*>==============================
*>
     if       a-false
              next sentence
     else
      if      array-l (y)  equal  space
              next sentence
      else
*>              if  array-l (y)  not equal  array-k (y)
             if     array-l (y) not = Sales-Key (y:1)
                  move  zero  to  truth.
*>
 main-exit.   exit section.
*>********    ****
*>
 letter-out               section.
*>===============================
*>
*>******************************************************************
*> WARNING:                                                        *
*>  This routine processes a fixed format comma delimited file     *
*>  that does NOT use "" around alpha data eg, name and address    *
*>                 modify it if needed                             *
*>******************************************************************
*>
     if       store-work < sl-days-2
              move  1  to  letter-nos
     else
              if    store-work  <  sl-days-3
                    move  2  to  letter-nos
      else
                    move  3  to  letter-nos.
*>
     move     sales-name  to  lf-name.
     move     sales-key  to  lf-account.
     move     sales-current  to  lf-os.
     inspect  lf-name replacing all "," by ";".              *> get rid of commas as we may not be using quotes
     inspect  lf-line1 replacing all "," by ";".
     inspect  lf-line2 replacing all "," by ";".
     inspect  lf-line3 replacing all "," by ";".
     inspect  lf-line4 replacing all "," by ";".
     inspect  lf-os2   replacing first "$" by "£".   *> change currency symbol if needed but should not be
     move     si-date  to  u-bin.
     perform  zz060-Convert-Date.
     move     ws-date  to  lf-date.
*>
*>  Uncomment this block [] if comma delimited records need quotes around all non-numerics
*> [
 Setup-comma-delimits.
    move      1 to b.
    move      spaces to letter-work2.
    string    quote         delimited by size
              lf-name       delimited by "  "
              quote         delimited by size
              ","           delimited by size
              quote         delimited by size
              lf-line1      delimited by "  "
              quote         delimited by size
              ","           delimited by size
              quote         delimited by size
              lf-line2      delimited by "  "
              quote         delimited by size
              ","           delimited by size
              quote         delimited by size
              lf-line3      delimited by "  "
              quote         delimited by size
              ","           delimited by size
              quote         delimited by size
              lf-line4      delimited by "  "
              quote         delimited by size
              ","           delimited by size
              quote         delimited by size
              sales-key     delimited by size
              quote         delimited by size
              ","           delimited by size
              lf-os2        delimited by size         *> this can produce leading spaces
              quote         delimited by size
              ","           delimited by size
              quote         delimited by size
              ws-date       delimited by size
              quote         delimited by size  into letter-work2 pointer b
     end-string
     move     letter-work2 to letter-work.
 Setup-comma-delimits-done.
*> ]
*>
     if       letter-nos = 1
              write letter-record-1  from  letter-work
     else
      if      letter-nos = 2
              write letter-record-2  from  letter-work
      else
              write letter-record-3  from  letter-work.
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
