       >>source free
*>************************************************
*>                                               *
*>            Payment  Proof  Sort               *
*>                                               *
*>************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl090.
*>**
*>    Author.             Cis Cobol Conversion By V B Coen FBCS, 17/04/84
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Payment Proof Sort.
*>*
*>    Version.            See Prog-Name & Date-Comped In Ws.
*>**
*>    Called Modules.     None.
*>****
*> Changes:
*>
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00,
*> 03/04/09 vbc - Remove displays, not needed.
*> 15/12/11 vbc - .01 Support for path+filenames.
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
 copy "seloi5.cob".
 copy "selois.cob".
     select       sort-file   assign  file-21.
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdoi5.cob".
*>
 01  oi-header.
     02  oi-key.
         03  oi-supplier.
             05  oi-nos     pic x(6).
             05  oi-check   pic 9.
         03  oi-invoice     binary-long.
     02  filler.
         03  oi-date        binary-long.
         03  oi-batch                        comp.
             05  oi-b-nos   pic 9(5).
             05  oi-b-item  pic 999.
         03  oi-type        pic 9.
*>
 copy "fdois.cob".
*>
 sd  sort-file.
*>
 01  sort-record.
     03  s-supplier       pic x(7).
     03  s-invoice        binary-long.
     03  s-date           binary-long.
     03  s-batch                         comp.
         05  s-b-nos      pic 9(5).
         05  s-b-item     pic 999.
     03  s-type           pic 9.
     03  filler           pic x(83).
*>
 working-storage section.
*>----------------------
 77  prog-name            pic x(15) value "PL090 (3.01.01)".
*>
 copy "wsfnctn.cob".
*>
 01  error-code          pic 999.
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
     display  " " at 0101 with erase eos.
     if       p-flag-p = 0
              move 30 to error-code
              call "maps99" using error-code ws-calling-data
              move 15 to error-code
              call "maps99" using error-code ws-calling-data
              go to menu-exit.
*>
     move     "Y" to oi-5-flag.
     perform  sorting-1.
*>
 menu-exit.
     exit     program.
*>
 sorting-1               section.
*>==============================
*>
     sort     sort-file
              on ascending key  s-b-nos
                                s-b-item
              on descending key s-type
              on ascending key  s-date
                                s-invoice
              input procedure input-to-sort
              giving open-item-file-s.
*>
 main-exit.   exit section.
*>********    ****
 input-to-sort  section.
*>=====================
*>
     open     input  open-item-file-5.
     if       fs-reply not = zero
              close open-item-file-5
              open output open-item-file-s
              close open-item-file-s
              go to main-exit.
*>
 process-input.
*>************
*>
     read     open-item-file-5 next record at end
              go to  end-of-input.
*>
     if       oi-type = 1 or 3
              go to process-input.
     if       zero = oi-b-nos and oi-b-item
              go to process-input.
*>
     release  sort-record from  open-item-record-5.
     go       to  process-input.
*>
 end-of-input.
*>***********
*>
     close    open-item-file-5.
*>
 main-exit.   exit section.
