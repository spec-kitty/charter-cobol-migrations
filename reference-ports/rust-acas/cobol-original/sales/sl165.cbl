       >>source free
*>***************************************************
*>                                                  *
*>          Sales Ledger Alpha List - Sort          *
*>                                                  *
*>***************************************************
*>
 identification          division.
*>===============================
*>
      program-id.         sl165.
*>**
*>    Author.             Cis Cobol Conversion By V B Coen FBCS, 25/10/83
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Sales Ledger Customer File Alpha Sort.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Error messages used.
*>                        NONE
*>**
*> Changes:
*> 03/03/09 vbc - Migration to Open Cobol v3.00.0.
*> 08/12/11 vbc - .01 Support for path+filenames.
*> 09/12/11 vbc -     Updated version to 3.01.nn
*>**
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
     select  sort-file       assign        file-21,
                             status        ss-reply.
*>
     select  sales-sort      assign        fn-sales,
                             access        sequential,
                             status        fs-reply.
*>
 copy "selsl.cob".
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 sd  sort-file.
*>
 01  sort-record.
     03  sort-key        pic x(7).
     03  sort-name       pic x(30).

 fd  sales-sort.
*>
 01  sales-sort-record.
     03  sales-sort-key       pic x(7).
*>
 copy "fdsl.cob".
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "SL165 (3.01.01)".
*>
 copy "wsfnctn.cob".
 01  fn-sales        pic x(12)       value "custsort.tmp".
*>
 01  ws-data.
     03  ss-reply        pic xx.
     03  ws-reply        pic x.
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
     open     input  sales-file.
     open     output sales-sort.
*>
     sort     sort-file
               on  ascending key  sort-name
*> sort-key     *> DONT THINK THIS IS NEEDED
               input procedure input-to-sort
               output procedure output-from-sort.
*>
     close    sales-file sales-sort.
*>
 end-program.
     exit     program.
*>
 input-to-sort section.
     read     sales-file  next record
              at end  go to  its-exit.
*>
     move     sales-key   to  sort-key.
     move     sales-name  to  sort-name.
     release  sort-record.
     go       to input-to-sort.
*>
 its-exit.
     exit     section.
*>
 output-from-sort section.
     return   sort-file at end
              go to ofs-exit.
     move     sort-key to sales-sort-key.
     write    sales-sort-record.
     go       to output-from-sort.
*>
 ofs-exit.
     exit     section.
