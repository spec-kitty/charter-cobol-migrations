       >>source free
*>*****************************************************************
*>                                                                *
*>    N o m i n a l  F i x  u p   P r o g r a m                   *
*>                                                                *
*>*****************************************************************
 identification division.
 program-id.            irs080.
*>
*>author.               V.B.Coen   AIDPM FBCS
*>                      Applewood Computers.
*>
*>Security.             Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*>
*>remarks.              NL Fixup Program
*>
*>Version.              See Prog-Name in WS.
*>
*>  calls.              irsub1 (Nominal)
*>                      irsub3 (Defaults)
*>                      irsub4 (Posting)
*>
*> changes.
*>
*> 11/07/83 vbc - Date vet 2 vet for month/day < 1,year < 70.
*> 13/07/83 vbc - Reset save-sequ if post file changed.
*> 26/07/83 vbc - Rewrite date vet routine.
*> 07/12/83 vbc - Tidyup display.
*> 16/02/84 vbc - Changed to irs080.
*> 28/05/84 vbc - Hilite display heads.
*> 26/09/89 vbc - Mods for cobol/2.
*> 23/01/09 vbc - Migration to Open Cobol as version 3
*> 21/02/09 vbc - Added support for env's LINES and COLUMNS as needed.
*> 07/04/09 vbc - Added colour to displays & replace direct NL file
*>                processing to using irsub1.
*> 14/03/10 vbc - Cleanup multi field displays to comply with standards.
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
 copy  "envdiv.cob".
 input-output section.
 file-control.
*>
 data division.
 file section.
*>
 working-storage section.
*>-----------------------
 77  prog-name           pic x(16) value "irs080 (3.01.13)".
*>
 01  filler.
     03  fs-replyx.
         05  fs-reply    pic 99.
     03  ws-reply        pic x.
*>
     03  ws-pass         pic x(4).
     03  y               pic 99.
     03  error-flag      pic 9.
     03  post-record-cnt pic 9(5)    value zero.
*>
 copy "wsnl.cob".
 copy "wsfnctn.cob".
 copy "wsdflt.cob".
 copy "wspost.cob".
*>
*>  Working Storage for NL Default rec 31
*>
 01  nl31-record.
     03  nl31-key.
         05  nl31-owning   pic 9(5).
         05  nl31-sub-nominal pic 9(5).
     03  nl31-type         pic a.
     03  nl31-data.
         05  nl31-name     pic x(24).
         05  nl31-dr       pic 9(8)v99   comp.
         05  nl31-cr       pic 9(8)v99   comp.
         05  nl31-dr-last  pic 9(8)v99   comp  occurs  4.
         05  nl31-cr-last  pic 9(8)v99   comp  occurs  4.
         05  nl31-ac       pic a.
*>
*>  Working Storage for NL Default rec 32
*>
 01  nl32-record.
     03  nl32-key.
       05  nl32-owning     pic 9(5).
       05  nl32-sub-nominal pic 9(5).
     03  nl32-type         pic a.
     03  nl32-data.
       05  nl32-name       pic x(24).
       05  nl32-dr         pic 9(8)v99   comp.
       05  nl32-cr         pic 9(8)v99   comp.
       05  nl32-dr-last    pic 9(8)v99   comp  occurs  4.
       05  nl32-cr-last    pic 9(8)v99   comp  occurs  4.
       05  nl32-ac         pic a.
*>
 linkage section.
*>***************
*>
 copy "wssystem.cob".
*>
 procedure division using system-record.
*>======================================
*>
 init01       section.
*>********************
*>
*> first get date & user information..
*>
     move     system-files to file-names.
     move     zero to save-sequ post-record-cnt.
*>
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "Fixup Accounts File" at 0129 with foreground-color 1 background-color 7.
     display  run-date at 0173  with foreground-color 2.
     display  "You have, made a backup of all the data files? If not do it NOW!!" at 0301
                               with foreground-color 4.
     display  "To quit, just enter an invalid password" at 0410 with foreground-color 2.
*>
     display  "Enter pass word - [****]" at 0501 with foreground-color 2.
     accept   ws-pass at 0520 with secure.
     if       ws-pass not = pass-word
              go to main99-exit.
     display  "Clearing Nominal Ledger of totals" at 0101 with erase eos foreground-color 2.
*>
*>   open i-o nominal-ledger.
*>
     move     1  to  file-function.
     move     2  to  access-type.
     call     "irsub1"  using  nl-record  file-access.
*>
 clear-nl.
*>
*> Read next NL record
*>
     move     3 to file-function.
     call     "irsub1"  using  nl-record  file-access.
     if       we-error = 3
              go to clear-end.
     move     zero to nl-dr nl-cr.
*>
*> Rewrite rec
*>
     move     7 to file-function.
     call     "irsub1"  using  nl-record  file-access.
     add      1 to post-record-cnt.
     go       to clear-nl.
*>
 clear-end.
     display  "Cleared Nominal Ledger of totals" at 0201 with foreground-color 2.
     display  post-record-cnt at 0234.
     move     zero to post-record-cnt.
*>
*>   get default record
*>
     move     3  to  file-function.
     call     "irsub3"  using  default-record  file-access.
     display  "Got Default record" at 0301 with foreground-color 2.
*>
     move     def-acs (31)  to  nl-owning.
     move     zero     to  nl-sub-nominal.
     move     4        to  file-function.
     call     "irsub1" using  nl-record  file-access.
     if       we-error not = zero
              display "IRSUB1-31 returns " at 2301 with foreground-color 4 highlight
              display we-error at 2319 with foreground-color 4 highlight
              accept we-error at 2340
              stop run.
     move     nl-record to nl31-record.
*>
     move     def-acs (32)  to  nl-owning.
     move     zero     to  nl-sub-nominal.
     move     4        to  file-function.
     call     "irsub1" using  nl-record  file-access.
     if       we-error not = zero
              display "IRSUB1-32 returns " at 2301 with foreground-color 4 highlight
              display we-error at 2319 with foreground-color 4 highlight
              accept we-error at 2340
              stop run.
     move     nl-record to nl32-record.
*>
 repost.
*>-----
*>
*>   open    input post-file.
*>
     display  "Updating Nominal Ledger" at 0401 with foreground-color 2.
     move     1  to  file-function.
     move     1  to  access-type.
     call     "irsub4"  using  posting-record  file-access.
     if       we-error not = zero
              display "No Postings Available" at 2301 with foreground-color 2
              go to eoj.
*>
 input-loop.
*>
     move     zero  to  we-error.
     move     3  to  file-function.
     call     "irsub4"  using  posting-record  file-access.
     if       we-error = 3
              go to  eoj.
     add      1 to post-record-cnt.
*>
*> processing for DR
*>
     move     post-dr  to  nl-owning.
     move     zero     to  nl-sub-nominal.
     move     4        to  file-function.
     call     "irsub1" using  nl-record  file-access.
     if       we-error = 2
              display "Invalid key 1 = " at 2301 with foreground-color 4 highlight
              display post-dr at 2317 with foreground-color 4 highlight
              accept we-error at 2340
              go to input-loop.
     add      post-amount  to  nl-dr.
     if       post-vat-side = "CR"
              add  vat-amount  to  nl-dr.
*>
*>  rewrite
*>
     move     7  to  file-function.
     call     "irsub1" using  nl-record  file-access.
*>
*> processing for CR
*>
     move     post-cr  to  nl-owning.
     move     zero     to  nl-sub-nominal.
     move     4        to  file-function.
     call     "irsub1" using  nl-record  file-access.
     if       we-error = 2
              display "Invalid key 2 = " at 2301 with foreground-color 4 highlight
              display post-cr at 2317 with foreground-color 4 highlight
              accept we-error at 2340
              go to input-loop.
     add      post-amount  to  nl-cr.
     if       post-vat-side = "DR"
              add  vat-amount  to  nl-cr.
*>
     move     7  to  file-function.
     call     "irsub1" using  nl-record  file-access.
*>
*> processing for VAT
*>
     if       vat-ac-def = zero
              go to  input-loop.
*>
     if       vat-ac-def = 31
         and  post-vat-side = "CR"
              add  vat-amount  to  nl31-cr
     else
       if     vat-ac-def = 31
         and  post-vat-side = "DR"
              add  vat-amount  to  nl31-dr
       else
        if    vat-ac-def = 32
          and post-vat-side = "CR"
              add  vat-amount  to  nl32-cr
        else
         if   vat-ac-def = 32
          and post-vat-side = "DR"
              add  vat-amount  to  nl32-dr.
     go to    input-loop.
*>
 eoj.
*>
     move     7  to  file-function.
     move     nl31-record to nl-record.
     call     "irsub1" using  nl-record  file-access.
*>
     move     nl32-record to nl-record.
     call     "irsub1" using  nl-record  file-access.
*>
     move     2  to  file-function.
     call     "irsub4"  using  posting-record  file-access.
     call     "irsub1"  using  nl-record  file-access.
     display   " " at 0501 with erase eol.
     display  "Processing Complete on 12345 records" at 0501 with foreground-color 2.
     display  post-record-cnt at 0524 with foreground-color 2.
     display  "Note counts. messages and Hit return for menu" at 0701 with foreground-color 2.
     accept   ws-reply at 0747 with foreground-color 2.
*>
 main99-exit.
     exit     program.
