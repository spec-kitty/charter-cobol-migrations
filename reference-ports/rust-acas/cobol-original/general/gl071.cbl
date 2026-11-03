       >>source free
*>*****************************************************
*>                                                    *
*>              Batch  Transaction  Sort              *
*>                                                    *
*>*****************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         gl071.
*>**
*>    author.             V.B.Coen, FBCS,
*>                        Converted For Cis January 85,
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Batch Sort.
*>**
*>   Changes:
*> 28/01/09 vbc - Migration to Open Cobol.
*> 20/12/11 vbc - .02 Support for dates other than UK & clean up msgs
*>                    Error msgs to GLnnn, Support for path+filenames.
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
     select  pre-trans  assign  pre-trans-name,
                        access  sequential
                        status  fs-reply
                        organization  line sequential.
*>
     select  post-trans assign  post-trans-name,
                        access  sequential
                        status  fs-reply
                        organization  line sequential.
*>
     select  sort-trans  assign file-21.
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 fd  pre-trans.
*>
 01  pre-trans-record.
     03  pre-batch       pic 9(5).
     03  pre-post        pic 9(5).
     03  pre-code        pic xx.
     03  pre-date        pic x(8).
     03  pre-ac          pic 9(6).
     03  pre-pc          pic 99.
     03  pre-amount      pic s9(8)v99.
     03  pre-legend      pic x(32).
*>
 fd  post-trans.
*>
 01  post-trans-record.
     03  post-batch      pic 9(5).
     03  post-post       pic 9(5).
     03  post-code       pic xx.
     03  post-date       pic x(8).
     03  post-ac         pic 9(6).
     03  post-pc         pic 99.
     03  post-amount     pic s9(8)v99.
     03  post-legend     pic x(32).
*>
 sd  sort-trans.
*>
 01  sort-trans-record.
     03  sort-batch      pic 9(5).
     03  sort-post       pic 9(5).
     03  sort-code       pic xx.
     03  sort-date       pic x(8).
     03  sort-ac         pic 9(6).
     03  sort-pc         pic 99.
     03  sort-amount     pic s9(8)v99.
     03  sort-legend     pic x(32).
*>
 working-storage section.
*>----------------------
*>
 77  prog-name           pic x(15)       value "gl071 (3.00.02)".
 77  fs-reply            pic xx.
*>
 linkage section.
*>--------------
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
 01  to-day               pic x(10).
*>
 procedure division  using ws-calling-data system-record to-day file-defs.
*>=======================================================================
*>
 main.
*>---
*>
     display  "Sorting.......Please wait            " at 0801  with foreground-color 2.
*>
     sort     sort-trans
              on ascending key sort-batch
                               sort-ac
                               sort-pc
                               sort-post
              using  pre-trans
              giving post-trans.
*>
 main-exit.   exit program.
*>********    ************
