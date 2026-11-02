       >>source free
*>*****************************************************************
*>                                                                *
*>      N O M I N A L   L E D G E R   F I L E   S O R T           *
*>                                                                *
*>*****************************************************************
 identification division.
 program-id.            irs065.
*>
*>author.               V.B. COEN
*>                      Cobol conversion by V B COEN. FBCS 23.10.82
*>                      for APPLEWOOD COMPUTERS.
*>
*>Security.             Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*>
*>remarks.              Nominal ledger file sort to work file
*>                      prior to irs060.
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
     select  nominal-ledger  assign  nl-file
                             organization indexed
                             access  dynamic
                             record  key-1
                             status  fs-reply.
     select  output-file     assign  "worksort.tmp"
                             organization sequential.
     select  sort-file       assign  "work.tmp".
*>
 data division.
 file section.
*>
 fd  nominal-ledger.
 copy "fdwsnl.cob".
*>
 fd  output-file.
*>
 01  output-record.
     03  output-key        pic 9(10).
     03  output-type       pic a.
     03  output-data.
      05  output-name      pic x(24).
      05 output-dr         pic 9(8)v99  comp.
      05 output-cr         pic 9(8)v99  comp.
      05 output-dr-last    pic 9(8)v99  comp  occurs 4.
      05 output-cr-last    pic 9(8)v99  comp  occurs 4.
      05 output-ac         pic a.
    03  filler  redefines output-data.
      05 output-pointer    pic 9(5).
*>
 sd  sort-file.
*>
 01  sort-record.
     03  sort-key        pic 9(10).
     03  sort-type       pic a.
     03  sort-data.
       05  sort-name     pic x(24).
       05  sort-amounts  pic 9(8)v99  comp  occurs 10.
       05  sort-ac       pic x.
*>
 working-storage section.
*>-----------------------
 77  prog-name           pic x(16) value "irs065 (3.01.02)".
 77  fs-reply            pic 99.
 77  nl-file             pic x(11).
 77  a                   pic x      value space.
*>
 copy  "wsfnctn.cob".
*>
 linkage section.
*>---------------
*>
 copy "wssystem.cob".
*>
 procedure division using system-record.
*>======================================
*>
 init01 section.
*>**************
     move     system-files to file-names.
     move     file-1 to nl-file.
*>
     sort     sort-file on  ascending  key  sort-ac
              input procedure is  input-to-sort
              giving output-file.
*>
 main-exit.   exit program.
*>
 input-to-sort section.
*>*********************
     open     input  nominal-ledger.
     if       fs-reply not = zero
              display "Failure to open Nominal Ledger!!!" at 2401
              accept a  at 2441
              open output output-file
              close output-file
              stop run.
*>
 process-input-record.
*>
     read     nominal-ledger next record
              at end  go to  end-of-input.
*>
     if       nl-sub-ac
              go to process-input-record.
*>
     release  sort-record  from  record-1.
     go to    process-input-record.
*>
 end-of-input.
*>
     close    nominal-ledger.
*>
