       >>source free
*>*****************************************************************
*>                                                                *
*>   Posting  File  Sort  By  Acct.No / Year / Month              *
*>                                                                *
*>*****************************************************************
 identification division.
 program-id.            irs085.
*>
*> author.              V B COEN, FBCS for Applewood Computers.
*>
*> Security.            Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*>
*> remarks.             Posting File Code Sort.
*>
*> version.             see prog-name in ws.
*>
*> calls.               irsub3.
*>
*> changes.
*>
*> 26/09/89 vbc - mods for cobol/2.
*> 23/01/09 vbc - Migration to Open Cobol as version 3.
*> 01/03/09 vbc - Get rid of displays with modern cpu speeds not needed.
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
*>
 input-output section.
 file-control.
*>
     select  posting-file    assign  post-file
                             organization  indexed
                             access  dynamic
                             record  post-key
                             status  fs-reply.
     select  output-file     assign  "workpost.tmp"
                             organization  sequential.
     select  sort-file       assign  "work.tmp".
*>
 data division.
 file section.
*>
 fd  posting-file.
*>
 copy "wspost.cob".
*>
 01  filler.
     03  filler          pic 9(5).
     03  filler          pic xx.
     03  filler.
         05  filler      pic xxx.
         05  post-mm     pic 99.
         05  filler      pic xxx.
*>
 fd  output-file.
*>
 01  output-record.
     03  output-date     pic 99.
     03  output-account  pic 9(5)      comp.
     03  output-amount   pic s9(7)v99  comp.
*>
 sd  sort-file.
*>
 01  sort-record.
     03  sort-month      pic 99.
     03  sort-account    pic 9(5)        comp.
     03  sort-amount     pic s9(7)v99    comp.
*>
 working-storage section.
*>-----------------------
 77  prog-name           pic x(16) value "irs085 (3.01.03)".
 77  fs-reply            pic 99.
 77  post-file           pic x(11).
 77  ws-reply            pic x     value space.
*>
 copy "wsfnctn.cob".
 copy "wsdflt.cob".
*>
 linkage section.
 copy "wssystem.cob".
*>
 procedure division using system-record.
*>======================================
*>
 init01 section.
*>**************
     move     system-files to file-names.
     move     file-4 to post-file.
     move     3 to file-function.
     call     "irsub3" using default-record file-access.
     sort     sort-file on ascending key sort-account sort-month
                  input procedure is input-to-sort
                              giving output-file.
*>
 main-exit.   exit program.
*>********    ************
*>
 input-to-sort section.
*>---------------------
     open     input  posting-file.
     if       fs-reply not zero
              display "Error opening postings = " at 2401 with foreground-color 4
              display fs-reply at 2426 with foreground-color 4
              accept ws-reply at 2478
              go to end-of-input.
*>
 process-input-record.
*>
     read     posting-file next record
              at end go to end-of-input.
*>
     move     post-mm to sort-month.
     move     post-amount to sort-amount.
*>
     move     post-cr to sort-account.
     release  sort-record.
*>
     multiply -1 by sort-amount.
     move     post-dr to sort-account.
     release  sort-record.
*>
     if       vat-ac-def = zero
              go to process-input-record.
     move     vat-amount to sort-amount.
     move     def-acs (vat-ac-def) to sort-account.
     release  sort-record.
*>
     go to    process-input-record.
*>
 end-of-input.
*>
     close    posting-file.
*>
