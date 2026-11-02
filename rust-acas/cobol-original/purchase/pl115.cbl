       >>source free
*>**************************************************
*>                                                 *
*>             Trial  Balance  Sort                *
*>                                                 *
*>**************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl115.
*>**
*>    Author.             V B Coen FBCS, 17/04/84
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Pre-Trail Balance Sort.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps99.
*>**
*>    Error messages used.
*>                        NONE
*>**
*> Changes:
*>
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 04/04/09 vbc - Remove display msg.
*> 15/12/11 vbc - .02 Error msgs to SLnnn.Support for dates other than UK
*>                    Support for path+filenames.
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
*>-----------
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
 copy "fdois.cob".
 sd  sort-file.
*>
 01  sort-record.
     03  s-customer       pic x(7).
     03  s-invoice        binary-long.
     03  s-date           binary-long.
     03  s-batch                         comp.
         05  s-b-nos      pic 9(5).
         05  s-b-item     pic 999.
     03  s-type           pic 9.
     03  filler           pic x(87).
*>
 working-storage section.
*>----------------------
 77  prog-name            pic x(15) value "PL115 (3.01.02)".
*>
 copy "wsfnctn.cob".
*>
*> 01  Error-Messages.
*> System Wide
*>       NONE
*> Module specific
*>       NONE
*>
 01  error-code          pic 999.
 01  ws-reply            pic x.
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
     if       oi-5-flag = "N"
              go to  menu-exit. *> using previous sort file
*>
     if       file-status (29) not = 1
              move "Y" to oi-5-flag
              move 25  to  error-code
              call "maps99"  using  error-code ws-calling-data
              move 15 to error-code
              call "maps99"  using  error-code ws-calling-data
              move 25 to error-code
              go to menu-exit.
*>
     perform  sorting-1.
     move     "N"  to  oi-5-flag.
*>
 menu-exit.
     exit     program.
*>
 sorting-1    section.
*>===================
*>
     sort     sort-file
               on ascending key s-customer
                                s-date
                                s-invoice
                                s-type
              input procedure input-to-sort
              giving  open-item-file-s.
*>
 main-exit.   exit.
*>
 input-to-sort  section.
     open     input open-item-file-5.
*>
 process-input.
     read     open-item-file-5 next record at end
              go to end-of-input.
*>
     release  sort-record from open-item-record-5.
     go       to process-input.
*>
 end-of-input.
     close    open-item-file-5.
*>
