       >>source free
*>********************************
*>                               *
*>     System File Handler       *
*>                               *
*>********************************
 identification division.
 program-id.            irsub2.
*>
*>author.               Cobol conversion by Vincent B Coen
*>                      Applewood Computers.
*>
*>Security.             Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*>remarks.              System File Handler.
*>
*>version.              0.04 17/06/1984.
*>                      0.05 15/01/2009.
*>                      0.06 14/04/2009
*>                      0.07 21/09/2010
*>                      0.08 21/11/2011
*>Changes.
*> 22/01/09 vbc - Migration to Open Cobol.
*> 21/09/10 vbc -.07  Update fd system size to 288 byte for print spool name.
*> 21/11/11 vbc -.08  increased size system record to 312.
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
 copy "envdiv.cob".
*>
 input-output section.
 file-control.
*>
     select  system-file     assign "system.dat"
                             organization line sequential
                             access sequential
                             status fs-reply.
*>
 data division.
 file section.
*>
 fd  system-file.
*>
 01  record-2            pic x(312).
*>
 working-storage section.
*>
 01  fs-reply            pic 99.
*>
 linkage section.
*>
 copy "wssystem.cob".
 copy "wsfnctn.cob".
*>
 procedure division  using  system-record file-access.
*>***************************************************
*>
 main.
*>----
*>
     move     zero to we-error.
     if       fn-write go to do-write.
*>
 do-read.
*>------
*>
     open     input system-file.
     if       fs-reply not zeros
              move 1 to we-error
              go to main-exit.
*>
     read     system-file record at end
              move 1 to we-error
              go to main-exit.
     move     record-2 to system-record.
     move     system-files to file-names.
     close    system-file.
     go       to main-exit.
*>
 do-write.
*>-------
*>
     open     output system-file.
     if       fs-reply not zeros
              display "System File Open OU Failure" at 2301 with foreground-color 4
              perform display-file-error
              move 1 to we-error
              go to main-exit.
     move     system-record to record-2.
     write    record-2.
     if       fs-reply not zeros
              display "System File Write Failure" at 2301 with foreground-color 4
              perform display-file-error
              move 1 to we-error
              go to main-exit.
     close    system-file.
*>
 main-exit.
     exit     program.
*>
     copy "fsdispfe.cob".
