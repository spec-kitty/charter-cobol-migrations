       >>source free
*>*****************************************************************
*>               P o s t i n g    F i l e   H a n d l e r         *
*>*****************************************************************
*>
 identification division.
 program-id.            irsub4.
*>
*>author.               Cobol conversion by Vincent B Coen
*>                      Applewood Computers.
*>
*>Security.             Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*> Remarks.             Posting File Handler.
*>                      Flat file version ONLY.
*>
*>    version.          1.10 25/10/1982.
*>                      1.11 15/01/2009.
*>                      1.12 14/04/2009.
*> Changes.
*> 15/01/09 vbc - Migration to Open Cobol.
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of the Applewood Computers Accounting System
*>   and is copyright (c) Vincent B Coen. 1976 - 2013 and later.
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
     select  posting-file    assign "post.dat"
                             organization indexed
                             access dynamic
                             record key-4
                             status fs-reply.
*>
 data division.
 file section.
*>
 fd  posting-file.
*>
 01  record-4.
     03  key-4.
         05  key-number   pic 9(5).
     03  post4-code       pic xx.
     03  post4-date       pic x(8).
     03  post4-dr         pic 9(5).
     03  post4-cr         pic 9(5).
     03  post4-amount     pic s9(7)v99   sign is leading.
     03  post4-legend     pic x(32).
     03  vat-ac-def4      pic 99.
     03  post4-vat-side   pic xx.
     03  vat-amount4      pic s9(7)v99   sign is leading.
*>
 working-storage section.
*>
 copy "wsfsrply.cob".
*>
 linkage section.
*>
 copy  "wspost.cob".
 copy  "wsfnctn.cob".
*>
 procedure division  using  posting-record file-access.
*>****************************************************
*>
 main.
*>----
*>
     move     zero to we-error.
     if       not fn-open  go to next-1.
*>
*> Open the file.
*>
     if       fn-input
              open input  posting-file
     else
      if      fn-i-o
              open i-o    posting-file
      else
       if     fn-output
              open output posting-file.
*>
     if       fs-reply9 not zeros
              display "Failure to open posting-file" at 2301 with foreground-color 4
              perform display-file-error
              move 1 to we-error.
*>
     go       to main-exit.
*>
 copy "fsdispfe.cob".
*>
 next-1.
*>-----
*>
*> Close the file
*>
     if       fn-close
              close posting-file
              go to main-exit.
*>
     if       not fn-read-indexed  go to next-2.
*>
*> Retrieve record by key
*>
     move     post-key to key-4.
     read     posting-file  invalid
              move 2 to we-error
              go to main-exit.
     move     record-4 to posting-record.
*>
     go       to main-exit.
*>
 next-2.
*>-----
*>
     if       not fn-read-next  go to next-3.
*>
 retry-2.
*>------
*>
     read     posting-file next record
              at end move 3 to we-error
              go to main-exit.
     move     record-4 to posting-record.
*>
     go       to main-exit.
*>
 next-3.
*>-----
     if       not fn-write go to next-4.
*>
*> Add record to file.
*>
 next-3-0.
*>
     move     posting-record to record-4.
     write    record-4 invalid
              add 1 to post-key
              go to next-3-0.
*>
     go       to main-exit.
*>
 next-4.
*>-----
*>
     if       not fn-delete go to next-5.
*>
*> Delete record.
*>
     delete   posting-file record.
     go       to main-exit.
*>
 next-5.
*>-----
*>
     if       not fn-re-write go to next-6.
*>
*> Update the record on disk
*>
     move     posting-record to record-4.
     rewrite  record-4.
     go       to main-exit.
*>
 next-6.
*>-----
*>
*> Start and read next.
*>
     move     post-key to key-4.
     if       not fn-equal-to go to jump-1.
     start    posting-file key = key-4
              invalid key move 2 to we-error
              go to main-exit.
*>
 jump-1.
*>-----
     if       not fn-less-than go to jump-2.
     start    posting-file key not < key-4
              invalid key move 2 to we-error
              go to  main-exit.
*>
 jump-2.
*>-----
     if       not fn-greater-than go to jump-3.
     start    posting-file key > key-4
              invalid key move 2 to we-error
              go to  main-exit.
*>
 jump-3.
*>-----
*>
*> Go back and read next record.
*>
     go       to retry-2.
*>
 main-exit.   exit program.
*>********    ************
