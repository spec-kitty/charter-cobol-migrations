       >>source free
*>*****************************************************************
*>                                                                *
*>  Sales Ledger Customer Creation For Invoice Entry Program      *
*>     This module does not create everything that sl010 does, eg *
*>          Notes etc. use main menu option B to add if needed    *
*>                                                                *
*>*****************************************************************
*>
 identification          division.
*>===============================
*>
      program-id.         sl960.
*>**
*>    author.             Cis Cobol Conversion By V B Coen, FBCS 18/10/83
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Sales Ledger Customer File Creation For
*>                        Invoice Data Entry Program (Sl910).
*>**
*>    Version.            See Prog-Name & Date-Comped In Ws.
*>**
*>    Called Modules.     Maps09.
*>                        Maps99.
*>**
*>    Error messages used.
*>                        NONE
*>**
*>    Changes.
*> 16/02/83 vbc - 240570-680:Fixes Date Err On Sales-Last Etc.
*> 20/03/83 Vbc - 320210:Fix On Sales Rec Not Fount Error.
*> 22/04/83 Vbc - Fix Display Deliv Name ,310220.
*> 10/10/83 Vbc - Chg Printer To Use Line-Cnt,Also Clear Display
*>                Fault On Cust Setup.
*> 22/10/83 Vbc - Conversion To Cis Cobol.
*> 30/10/83 Vbc - Converted From Sl010.
*> 06/03/84 Vbc - Support New Sales File Fields Pay-Average Etc.
*> 28/04/84 Vbc - Support New Sales File Fields Ext, Tlx.
*> 12/07/84 Vbc - Move Escape Box 5 Chars Right.
*> 03/03/09 Vbc - Migration to Open Cobol v3.00.00.
*> 26/11/11 vbc - .01 Error msgs to SLnnn.Support for dates other than UK (Neither used here)
*> 08/12/11 vbc - .02 Support for path+filenames.
*> 09/12/11 vbc -     Updated version to 3.01.nn
*> 27/02/12 vbc - .03 Changed use of check-digit' in 'sales-key to sales-key (7:1) for SQL processing.
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
 copy "envdiv.cob".

 input-output            section.
*>------------------------------
*>
 file-control.
*>-----------
*>
 copy "selsl.cob".
 copy "seldel.cob".
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdsl.cob".
 copy "fddel.cob".
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "SL960 (3.01.03)".
 copy "wsfnctn.cob".
 copy "wsmaps09.cob".
*>
 01  ws-data.
     02  filler.
     03  ws-reply        pic x.
     03  a               pic 999.
     03  y               pic 99.
     03  z               pic 9.
     03  error-flag      pic 9           value zero.
     03  escape-code     pic x.
     03  truth           pic 9.
         88  a-true                   value  1.
         88  a-false                  value  0.
     03  test-address    pic x(92).
     03  ws-spaces-10                    value spaces.
         05  ws-spaces-7 pic x(7).
         05  filler      pic xxx.
     03  d24-02          pic x           value space.
     03  d24-03          pic x           value space.
     03  d24-check.
         05  filler      pic x(13)       value "Check Digit {".
         05  d24-digit   pic x           value space.
         05  filler      pic x           value "}".
     03  A01-Notes.
         05  a01-Notes-1 pic x(48)       value spaces.
         05  a01-Notes-2 pic x(48)       value spaces.
     03  a01-late-charg  pic x           value space.
     03  a01-dun-letter  pic x           value space.
     03  ws-env-lines    pic 999         value zero.
     03  ws-lines        binary-char unsigned value zero.
     03  ws-23-lines     binary-char unsigned value zero.
*>
 01  All-My-Constants    pic 9(4).
     copy "screenio.cpy".
*>
 01  error-code          pic 999.
*>
 linkage section.
*>==============
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
*>
 01  to-day              pic x(8).
*>
 screen section.
*>=============
*>
 01  display-02                  background-color cob-color-black
                                 foreground-color cob-color-green.
     03  value "Customer Nos : ["    line  4 col  6.
*> >>>>>>>> customer no here <<<<<<<
     03  from d24-02          pic x  line  4 col 28.
     03  from d24-03          pic x          col 29.
     03  from d24-check       pic x(15)      col 31.
     03  value "Customer Name: ["    line  6 col  6.
     03  using sales-name  pic x(30) line  6 col 22.
     03  value "]"                   line  6 col 52.
     03  value "Addr: ["             line  7 col 15.
     03  using sales-addr1    pic x(48)      col 22.
     03  value "]"                   line  7 col 70.
     03  value "["                   line  8 col 21.
     03  using sales-addr2    pic x(48)      col 22.
     03  value "]"                   line  8 col 70.
     03  value "Delivery name: ["    line  9 col  6.
     03  using deliv-name     pic x(30)      col 22.
     03  value "]"                           col 52.
     03  value "Addr: ["             line 10 col 15.
     03  using deliv-addr1    pic x(48)      col 22.
     03  value "]"                           col 70.
     03  value "["                   line 11 col 21.
     03  using deliv-addr2    pic x(48)      col 22.
     03  value "]"                           col 70.
     03  value "Telephone    : ["    line 13 col  6.
     03  using sales-phone    pic x(13)      col 22.
     03  value "]"                           col 35.
     03  value "Ext: ["                      col 37.
     03  using sales-ext      pic x(4)       col 43.
     03  value "]"                           col 47.
     03  value "Fax : ["                     col 50.
     03  using sales-fax      pic x(13)      col 57.
     03  value "]"                           col 70.
     03  value "Email Sales  : ["    line 14 col  6.
     03  using sales-email    pic x(30)      col 22.
     03  value "]"                           col 52.
     03  value "Late charges : ["    line 15 col  6.
     03  using a01-late-charg  pic x         col 22.
     03  value "]"                           col 23.
     03  value "Minimum balance before late charge : [" col 31.
     03  using sales-late-min pic 9(4)       col 69.
     03  value "]"                           col 73.
     03  value "Late letters : ["    line 16 col  6.
     03  using a01-dun-letter  pic x         col 22.
     03  value "]"                           col 23.
     03  value "Maximum late charge"         col 31.
     03  value ": ["                         col 66.
     03  using sales-late-max pic 9(4)       col 69.
     03  value "]"                           col 73.
     03  value "Credit period: ["    line 17 col  6.
     03  using sales-credit   pic 99         col 22.
     03  value "]"                           col 24.
     03  value "Credit limit : ["    line 18 col  6.
     03  using sales-limit    pic 9(7)       col 22.
     03  value "] Discount : ["              col 29.
     03  using sales-discount pic 99v99      col 43.
     03  value "]"                           col 47.
     03  value "Unapplied Bal: {"    line 19 col  6.
     03  value "}"                           col 34.
     03  value "*******************"         col 61.
     03  value "Current Bal  : {"    line 20 col  6.
*> value entered by individual display
     03  value "}"                           col 34.
     03  value "* Escape Code ["             col 61.
     03  using escape-code    pic x          col 76.
     03  value "] *"                         col 77.
     03  value "Last invoice : {"    line 21 col  6.
*> value entered by individual display
     03  value "}"                           col 30.
     03  value "* <B> = Back      *"         col 61.
     03  value "Last payment : {"    line 22 col  6.
*> value entered by individual display
     03  value "}"                           col 30.
     03  value "* <S> = Save      *"         col 61.
     03  value "* <Q> = Quit      *" line 23 col 61.
     03  value "*******************" line 24 col 61.
*>
 procedure division using ws-calling-data, system-record, to-day file-defs.
*>========================================================================
 init01 section.
*>
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     accept   ws-env-lines   from lines.
     if       ws-env-lines < 24
              move  24 to ws-env-lines ws-lines
     else
              move  ws-env-lines   to ws-lines
     end-if
     subtract 1 from ws-lines giving ws-23-lines.
     display  prog-name at 0101 with erase eos foreground-color 2.
*>
     open     i-o sales-file
                  delivery-file.
     if       fs-reply not = zero
              close delivery-file
              open  output delivery-file        *> OC doesnt create in i-o mode
              close delivery-file
              open  i-o delivery-file.
     display " " at line 3 col 1 with erase eos.
*>
     perform  setup-customers.
     close    sales-file delivery-file.
*>
 menu-end.
     exit     program.
*>
 setup-customers         section.
*>==============================
*>
 customer-input.
*>*************
*>
     display  display-02.
     move     spaces to customer-nos.
*>
 customer-accept.
*>**************
*>
     accept   customer-nos at 0422 with foreground-color 3 update.
     if       customer-nos  = spaces
              go to  main-end.
     move     function upper-case (customer-nos) to customer-nos.
     display  customer-nos at 0422 with foreground-color 3.
*>
     perform  clear-error-line.
*>
     move     "C"  to  maps09-reply.
     perform  maps09.
     if       maps09-reply  not = "Y"
              go to  customer-input.
*>
     move     check-digit of maps09-ws  to   Sales-Key (7:1).
     display  Sales-Key (7:1) at 0444 with foreground-color 3.
*>     move     check-digit of maps09-ws  to   check-digit of sales-record.
*>     display  check-digit of sales-record at 0444 with foreground-color 3.
*>
     move     customer-code  to  sales-key.
*>
     read     sales-file  invalid key
              go to  customer-details.
*>
*> if here record already exists.
*>
     move     5  to  error-code.
     perform  maps99.
*>
     go       to customer-accept.
*>
 customer-details.
*>***************
*>
     initialize sales-record   delivery-record.
     move     customer-code  to  sales-key.
     move     sl-charges to  sales-late.
     move     sl-dunning to  sales-dunning.
     move     sl-credit  to  sales-credit.
     move     sl-disc    to  sales-discount.
     move     sl-min     to  sales-late-min.
     move     sl-max     to  sales-late-max.
     move     sl-limit   to  sales-limit.
     move     run-date to sales-create-date.
     move     1       to  sales-status.                   *>  Live
*>
 get-details.
*>**********
*>
     perform  customer-data.
*>
     move     "S"  to   escape-code.
     perform  test-escape.
*>
 main-output.
*>**********
*>
     if       escape-code  = "B"
              go to get-details.
*>
     if       escape-code  = "Q"
              go to  main-end.
     write    sales-record.
*>
     if       delivery-tag  not = zero
              move   "D"       to Deliv-Key-Type
              move   Sales-Key to Deliv-Sales-Key
              write  delivery-record.
*>
 main-end.    exit section.
*>*******    ****
*>
 oddsnsods section.
*>****************
*>
 maps09.
     call     "maps09"  using  customer-code.
*>
 maps99.
     call     "maps99"  using  error-code ws-calling-data.
*>
 clear-error-line.
*>***************
*>
     display  " " at 2301 with erase eol.
*>
 clear-error-line-24.
*>******************
*>
     display  " " at 2401 with erase eol.
*>
 test-escape  section.
*>===================
*>
     display  escape-code at 2076 with foreground-color 6.
*>
 get-escape.
*>*********
*>
     accept   escape-code at 2076 with foreground-color 6 update.
     move     function upper-case (escape-code) to escape-code.
*>
     if       escape-code not = "B" and not = "S" and not = "Q"
              go to get-escape.
*>
 main-exit.   exit section.
*>********    ****
*>
 customer-data           section.
*>==============================
*>
     move     zero to error-flag.
     accept   display-02.
*>
     move     sales-address  to  test-address.
     perform  validate-address.
*>
     if       a-false
              display "Addr Err" at 0771 with foreground-color 4
              move 1 to error-flag
      else
              display ws-spaces-10 at 0771.
*>
     if       deliv-name  = spaces
              move  zero  to  delivery-tag
              go to bypass-deliv-test.
*>
     move     deliv-address  to  test-address.
     perform  validate-address.
*>
     if       a-false
              display "Addr Err" at 1071 with foreground-color 4
              move 1 to error-flag
      else
              display ws-spaces-10 at 1071.
*>
     move     1  to  delivery-tag.
*>
 bypass-deliv-test.
*>****************
*>
     move     a01-late-charg to ws-reply.
*>
     perform  validate-response.
*>
     if       a-true
              move  z  to  sales-late
              display ws-spaces-7 at 1524
     else
              display "Error" at 1524 with foreground-color 4
              move 1 to error-flag.
*>
     move     a01-dun-letter to ws-reply.
*>
     perform  validate-response.
*>
     if       a-true
              display ws-spaces-7 at 1624
              move  z  to  sales-dunning
     else
              display "Error" at 1624 with foreground-color 4
              go to customer-data.
*>
     if       error-flag not = zero
              go to customer-data.
*>
 main-exit.   exit section.
*>********    ****
*>
 validate-address        section.
*>==============================
*>
     move     zero  to  a.
     inspect  test-address  tallying a for all sl-delim.
*>
     if       a  >  4  or  <  1
              move  zero  to  truth
     else
              move  1  to  truth.
*>
     move     zero  to  a.
     inspect  test-address  tallying  a for  characters  before initial  sl-delim.
*>
     if       a  >  30
              move  zero  to  truth.
*>
 main-exit.   exit section.
*>********    ****
*>
 validate-response       section.
*>==============================
*>
     move     1  to  truth.
*>
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply  = "Y"
              move  1  to  z
     else
      if      ws-reply  = "N"
              move  0  to  z
      else
              move  0  to  truth.
*>
     if       a-false
              move  18 to  error-code
              perform  maps99
              go to main-exit.
*>
     perform  clear-error-line-24.
*>
 main-exit.   exit section.
*>
