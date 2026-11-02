       >>source free
*>***************************************************
*>                                                  *
*>           Statement & Trial Balance Sort         *
*>                                                  *
*>***************************************************
*>
 identification          division.
*>===============================
*>
      program-id.         sl115.
*>**
*>    author.             Cis Cobol Conversion By V B Coen FBCS, 24/10/83
*>                        For Applewood Computers.
*>**
*>    Security            Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    remarks.            Pre Statement & Trail Balance Sort.
*>
*>**
*>    version.            See Prog-Name In Ws.
*>**
*>
*>    Called Modules.     maps99.
*>**
*>    Error messages used.
*>                        NONE
*>**
*> Changes:
*> 03/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 25/11/11 vbc - .01 Error msgs to SLnnn.Support for dates other than UK
*> 08/12/11 vbc - .02 Support for path+filenames.
*> 09/12/11 vbc - .03 Updated version to 3.01.nn
*> 02/06/13 vbc - .04 Added Sort file layout and size to 114 bytes.
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
 environment             division.
*>===============================
*>
 copy "envdiv.cob".
 input-output            section.
*>------------------------------
 file-control.
*>-----------
 copy "seloi3.cob".
 copy "selois.cob".
     select       sort-file   assign  file-21.
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
 copy "fdoi3.cob".
 copy "fdois.cob".
 sd  sort-file.
*>
 01  sort-record.			*> 114 bytes (02/06/13)
     03  s-customer       pic x(7).
     03  s-invoice        binary-long.
     03  s-date           binary-long.
     03  s-batch                         comp.
         05  s-b-nos      pic 9(5).
         05  s-b-item     pic 999.
     03  s-type           pic 9.
     03  filler           pic x(92).
*>
 working-storage section.
*>----------------------
 77  prog-name            pic x(15) value "SL115 (3.01.04)".
 77  ws-reply             pic x     value space.
*>
 copy "wsfnctn.cob".
*>
*> 01  Error-Messages.
*> System Wide
*>       NONE
*> Module specific
*>       NONE
*>
 01  error-code           pic 999.
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
 01  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 init01 section.
     if       oi-3-flag = "N"
              go to  menu-exit. *> using previous sort file
*>
     if       file-status (19) not =  1		*> OTM3 does not exist should not happen see above test
              move     "Y" to oi-3-flag
              move     19  to  error-code
              call     "maps99"  using  error-code ws-calling-data
              move     15 to error-code
              call     "maps99" using error-code ws-calling-data
              move     19  to  error-code
              go       to menu-exit.
*>
     perform  sorting-1.
     move     "N"  to  oi-3-flag.
*>
 menu-exit.
     exit     program.
*>
 sorting-1    section.
*>===================
*>
     sort     sort-file
              on  ascending key  s-customer
                                 s-date
                                 s-invoice
                                 s-type
              input procedure input-to-sort
              giving  open-item-file-s.
*>
 main-exit.   exit section.
*>********    ************
*>
 input-to-sort  section.
     open     input open-item-file-3.
*>
 process-input.
     read     open-item-file-3 next record at end
              go to end-of-input.
*>
     release  sort-record from open-item-record-3.
     go       to process-input.
*>
 end-of-input.
     close    open-item-file-3.
