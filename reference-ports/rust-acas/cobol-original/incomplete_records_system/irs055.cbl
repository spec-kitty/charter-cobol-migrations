       >>source free
*>*****************************************************************
*>         Posting File  Sort By Code / Date / Transaction        *
*>*****************************************************************
 identification division.
 program-id.            irs055.
*>author.               Cobol conversion by Vincent B Coen, FBCS 23.10.82
*>                      for Applewood Computers.
*>
*>Security.             Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*>
*>
*>remarks.              Posting File Code Sort.
*>
*>version.              see prog-name in ws.
*>
*> calls.               none.
*>
*>Changes.
*> 22/01/09 vbc - Migration to Open Cobol as version 3.
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
     select  posting-file    assign  post-file
                             organization indexed
                             access  dynamic
                             record  post-key
                             status  fs-reply.
     select  output-file     assign  "postsort.dat"
                             organization line sequential.
     select  sort-file       assign  "work.tmp"
                             status fs-reply.
*>
 data division.
 file section.
*>
 fd  posting-file.
*>
 copy "wspost.cob".
*>
 fd  output-file.
*>
 01  output-record.
     03  output-key        pic 9(5).
     03  output-code       pic xx.
     03  output-date       pic x(8).
     03  output-dr         pic 9(5).
     03  output-cr         pic 9(5).
     03  output-amount     pic s9(7)v99  sign is leading.
     03  output-legend     pic x(32).
     03  out-vat-ac-def    pic 99.
     03  output-vat-side   pic xx.
     03  out-vat-amount    pic s9(7)v99  sign is leading.
*>
 sd  sort-file.
*>
 01  sort-record.
     03  sort-key        pic 9(5).
     03  sort-code       pic xx.
     03  sort-date.
       05  sort-days     pic xx.
       05  filler        pic x.
       05  sort-month    pic xx.
       05  filler        pic x.
       05  sort-year     pic xx.
     03  sort-dr         pic 9(5).
     03  sort-cr         pic 9(5).
     03  sort-amount     pic s9(7)v99  sign is leading.
     03  sort-legend     pic x(32).
     03  sort-vat-ac-def pic 99.
     03  sort-vat-side   pic xx.
     03  sort-vat-amount pic s9(7)v99  sign is leading.
*>
 working-storage section.
*>-----------------------
 77  prog-name           pic x(16) value "irs055 (3.01.00)".
 77  fs-reply            pic 99.
 77  post-file           pic x(11).
*>
 copy  "wsfnctn.cob".
*>
 linkage section.
*>---------------
*>
 copy "wssystem.cob".
*>
 procedure division using system-record.
*>=====================================
*>
 init01 section.
*>*************
*>
     move     system-files to file-names.
     move     file-4 to post-file.
     if       save-sequ  equal  1
              sort sort-file
                 on ascending key sort-code sort-year sort-month sort-days sort-key
              input procedure is  input-to-sort
              giving output-file.
*>
     if       save-sequ  equal  2
              sort sort-file
                 on ascending key sort-year sort-month sort-days sort-code sort-key
              input procedure is input-to-sort
              giving output-file.
*>
     if       save-sequ  equal  3
              sort  sort-file on ascending key sort-key
              input procedure is  input-to-sort
              giving output-file.
*>
     if       fs-reply not = zero
              display "Sort Failed = " at 2301
              display fs-reply at 2315
              display "Note error and hit return" at 2410
              accept fs-reply at 2450.
*>
 main-exit.
     exit     program.
*>
 input-to-sort section.
*>---------------------
*>
     open     input  posting-file.
*>
 process-input-record.
*>
     read     posting-file  next
              at end  go to  end-of-input.
*>
     release  sort-record  from  posting-record.
     go       to process-input-record.
*>
 end-of-input.
     close    posting-file.
*>
