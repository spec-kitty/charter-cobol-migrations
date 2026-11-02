       >>source free
*>****************************************************************
*>                                                               *
*>      S o r t e d   P o s t i n g    F i l e   H a n d l e r   *
*>                                                               *
*>****************************************************************
*>
 identification division.
 program-id.           irsubp.
*>author.              Cobol conversion by Vincent B Coen
*>                     for Applewood Computers.
*>
*>Security.            Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                     Distributed under the GNU General Public License
*>                     v2.0. Only. See the file COPYING for details.
*>
*>
*>remarks.             Sorted Posting File Handler.
*>
*>version.             1.10 25/10/1982.
*>                     1.11 15/01/2009.
*>                     1.12 15/02/2009.
*>Changes.
*> 22/01/09 vbc - Migration to Open Cobol.
*> 15/02/09 vbc - produce error 99 if no input file.
*> 07/05/13 vbc - Change file to line seq in line with 055.
*>
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
 input-output section.
 file-control.
*>
     select  posting-file    assign "postsort.dat"
                             organization line sequential
                             file status fs-reply.
*>
 data division.
 file section.
*>
 fd  posting-file
     label records standard.
*>
 01  record-4.
     03  key-4           pic 9(5).
     03  post-code4      pic xx.
     03  post-date4      pic x(8).
     03  post-dr4        pic 9(5).
     03  post-cr4        pic 9(5).
     03  post-amount4    pic s9(7)v99  sign is leading.
     03  post-legend4    pic x(32).
     03  vat-ac-def4     pic 99.
     03  post-vat-side4  pic xx.
     03  vat-amount4     pic s9(7)v99   sign is leading.
*>
 working-storage section.
*>----------------------
*>
 copy "wsfsrply.cob".
*>
 linkage section.
*>--------------
*>
 copy  "wspost.cob".
 copy  "wsfnctn.cob".
*> copy  "wssystem.cob".
 procedure division using posting-record file-access. *> system-record.
*>================================================================
*>
 main.
*>---
*>
     move     zero to we-error.
*>
     if       not fn-open
              go to next-1.
*>
*>   Open the file.
*>
     if       fn-input
              open input  posting-file.
     if       fn-output
              open output posting-file.
     if       fs-reply9 not = zero
              move 99 to we-error.
*>
     go       to main-exit.
*>
 next-1.
*>-----
*>
     if       fn-close
              close posting-file
              go to main-exit.
*>
     if       not fn-read-next go to next-3.
*>
 retry-2.
*>------
*>
     read     posting-file record
              at end move 3 to we-error
              go to  main-exit.
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
     move     posting-record to record-4.
     write    record-4.
     if       fs-reply9 not = zero
              display "Disk full!!! aborting." at 2401
              perform display-file-error
              stop run.
*>
     go       to main-exit.
*>
 copy "fsdispfe.cob".
 next-4.
*>-----
*>
 main-exit.   exit program.
*>********    ************
