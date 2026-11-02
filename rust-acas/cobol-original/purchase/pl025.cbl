       >>source free
*>*****************************************************************
*>                                                                *
*>       Purchase Ledger Creation For Invoice Entry Program       *
*>       This is very similar to sl960                            *
*>*****************************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl025.
*>**
*>    Author.             V B Coen, FBCS For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    remarks.            Purchase Ledger Customer File Creation
*>                        for Invoice Data entry program (PL020).
*>**
*>    Version.            See Prog-Name In Ws.
*>
*>    Called Modules.     Maps09.
*>                        Maps99.
*>**
*>    Error messages used.
*>                        NONE
*>**
*>    Changes.
*> 18/05/84 Vbc - Support For Ext, Telex.
*> 12/07/84 Vbc - Move Escape Box 5 Chars Right.
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00
*> 22/03/09 vbc - replace Telex for fax system wide.
*> 27/03/09 vbc - Added Notes & account details to match pl010 etc.
*> 01/04/09 vbc - Changed tag to Purch-Notes-Tag.
*> 12/12/11 vbc - .05 Error msgs to SLnnn.Support for dates other than UK (Neither used here)
*>                    Support for path+filenames.
*>                    Updated version to 3.01.nn
*> 27/02/12 vbc - .06 Changed use of check-digit' in 'Purch-key to Purch-key (7:1) for SQL processing.
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
*>-----------
*>
 copy "selpl.cob".
 copy "seldel.cob".
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdpl.cob".
 copy "fddel.cob".
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "PL025 (3.01.06)".
 copy "wsfnctn.cob".
 copy "wsmaps09.cob".
*>
 01  ws-data.
     03  ws-reply        pic x.
     03  a               pic 999.
     03  y               pic 99.
     03  z               pic 9.
     03  escape-code     pic x.
     03  truth           pic 9.
         88  a-true                   value  1.
         88  a-false                  value  zero.
     03  test-address    pic x(92).
     03  d24-02          pic x           value space.
     03  d24-03          pic x           value space.
     03  d24-check.
         05  filler      pic x(13)       value "Check Digit {".
         05  d24-digit   pic x           value space.
         05  filler      pic x           value "}".
     03  A01-Notes.
         05  a01-Notes-1 pic x(48)       value spaces.
         05  a01-Notes-2 pic x(48)       value spaces.
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
 01  to-day              pic x(10).
*>
 screen section.
*>=============
*>
 01  display-02                  background-color cob-color-black
                                 foreground-color cob-color-green.
     03  value "Supplier Nos : ["    line  4 col  6.
*> >>>>>>>> customer no here <<<<<<<
     03  from d24-02          pic x  line  4 col 28.
     03  from d24-03          pic x          col 29.
     03  from d24-check       pic x(15)      col 31.
     03  value "Supplier Name: ["    line  6 col  6.
     03  using Purch-name  pic x(30) line  6 col 22.
     03  value "]"                   line  6 col 52.
     03  value "Addr: ["             line  7 col 15.
     03  using Purch-addr1 pic x(48)         col 22.
     03  value "]"                   line  7 col 70.
     03  value "["                   line  8 col 21.
     03  using Purch-addr2    pic x(48)      col 22.
     03  value "]"                   line  8 col 70.
     03  value "Suppliers Bank Details"
                                     line  9 col  6.
     03  value "Sort Code  : ["      line 10 col  8.
     03  using Purch-SortCode pic 9(6)       col 22.
     03  value "]"                           col 28.
     03  value "Account No : ["      line 11 col  8.
     03  using Purch-AccountNo pic 9(8)      col 22.
     03  value "]"                           col 30.
     03  value "Supplier Note: ["    line 12 col  6.
     03  using a01-Notes-1    pic x(48)      col 22.
     03  value "]"                           col 70.
     03  value "["                   line 13 col 21.
     03  using a01-Notes-2    pic x(48)      col 22.
     03  value "]"                           col 70.
     03  value "Telephone    : ["    line 14 col  6.
     03  using Purch-phone    pic x(13)      col 22.
     03  value "]"                           col 35.
     03  value "Ext: ["                      col 37.
     03  using Purch-ext      pic x(4)       col 43.
     03  value "]"                           col 47.
     03  value "Fax : ["                     col 50.
     03  using Purch-fax      pic x(13)      col 57.
     03  value "]"                           col 70.
     03  value "Email Sales  : ["    line 15 col  6.
     03  using Purch-email    pic x(30)      col 22.
     03  value "]"                           col 52.
     03  value "Credit Period: ["    line 18 col  6.
     03  using Purch-credit   pic 99         col 22.
     03  value "]"                           col 24.
     03  value "Credit limit : ["    line 19 col  6.
     03  using Purch-limit    pic 9(7)       col 22.
     03  value "] Discount : ["              col 29.
     03  using Purch-discount pic 99v99      col 43.
     03  value "]"                           col 47.
     03  value "*******************" line 19 col 61.
     03  value "Unapplied Bal: {"    line 20 col  6.
     03  value "}"                           col 34.
     03  value "* Escape Code ["     line 20 col 61.
*>  value entered by individual display
     03  value "] *"                         col 77.
     03  value "Current Bal  : {"    line 21 col  6.
*> value entered by individual display
     03  value "}"                           col 34.
     03  value "* <B> = Back      *"         col 61.
     03  value "Last invoice : {"    line 22 col  6.
*> value entered by individual display
     03  value "}"                           col 30.
     03  value "* <S> = Save      *"         col 61.
     03  value "Last payment : {"    line 23 col  6.
*> value entered by individual display
     03  value "}"                           col 30.
     03  value "* <Q> = Quit      *" line 23 col 61.
     03  value "*******************" line 24 col 61.
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
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
     display  prog-name at 0101 with foreground-color 2.
*>
     open     i-o purchase-file
     open     i-o delivery-file.
     if       fs-reply not = zero
              close delivery-file
              open output delivery-file        *> OC doesnt create in i-o mode
              close delivery-file
              open  i-o delivery-file.
     display  " " at line 3 col 1 with erase eos
*>
     perform  setup-suppliers.
     close    purchase-file delivery-file.
*>
 menu-end.
     exit     program.
*>
 setup-suppliers         section.
*>==============================
*>
     move     spaces to customer-nos.
     move     spaces to a01-Notes-1  a01-Notes-2 d24-03. *> not in sl960
     move     "]" to d24-02.                     *> not in sl960
     display  display-02.
*>
 supplier-accept.
*>**************
*>
     accept   customer-nos at 0422 with foreground-color 3.
     if       customer-nos = spaces
              go to  main-exit.
     move     function upper-case (customer-nos) to customer-nos.
     display  customer-nos at 0422 with foreground-color 3.
*>
     display  " " at line ws-23-lines col 1 with erase eol.
*>
     move     "C"  to  maps09-reply.
     perform  maps09.
     if       maps09-reply not = "Y"
              go to  supplier-accept.
*>
     move     check-digit of maps09-ws to Purch-Key (7:1).
*>check-digit of purch-record.
     display  Purch-Key (7:1) at 0444 with foreground-color 3.
*>
     move     "]" to d24-03.                  *> not in sl960
     move     customer-code  to  purch-key.
     read     purchase-file   invalid key
              go to  supplier-details.
*>
*> Record already exists.
*>
     move     22 to  error-code.
     perform  maps99.
     go       to supplier-accept.
*>
 supplier-details.
*>***************
*>
     initialize purch-record  delivery-record.
     move     run-date      to purch-create-date.
     move     1             to purch-status.      *> Live
     move     customer-code to purch-key.
     move     age-to-pay    to purch-credit.
*>
 get-details.
*>**********
*>
     perform  supplier-data.
*>
     move     "S"  to   escape-code.
     perform  test-escape.
*>
 main-output.
*>**********
*>
     if       escape-code = "B"
              go to get-details.
*>
     if       escape-code = "Q"
              go to  main-exit.
     write    purch-record.
*>
     if       Purch-Notes-Tag not = zero
              move   "D"       to Deliv-Key-Type
              move   Purch-Key to Deliv-Purchase-Key
              move   spaces    to  deliv-name
              move   A01-Notes to deliv-address
              write  delivery-record.
*>
 main-exit.   exit section.
*>********    ****
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
*>
 supplier-data           section.
*>==============================
*>
     accept   display-02.
*>
     move     purch-address  to  test-address.
     perform  validate-address.
*>
      if      a-false
              display "Addr Err" at 0771 with foreground-color 4
              go to supplier-data
      else
              display " " at 0771 with erase eol.
*>
     if       A01-Notes = spaces
              move zero to Purch-Notes-Tag
     else
              move 1    to Purch-Notes-Tag.
*>
 main-exit.   exit section.
*>
 validate-address        section.
*>==============================
*>
     move     zero  to  a.
     inspect  test-address  tallying  a  for all pl-delim.
*>
     if       a  >  4  or  <  1
              move  zero  to  truth
     else
              move  1  to  truth.
*>
     move     zero  to  a.
     inspect  test-address tallying a for characters before initial pl-delim.
*>
     if       a  >  30
              move  zero  to  truth.
*>
 main-exit.   exit section.
*>
