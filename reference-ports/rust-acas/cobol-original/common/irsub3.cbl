       >>source free
*>***************************************************************
*>   A c c o u n t s   D e f a u l t  F i l e   H a n d l e r   *
*>***************************************************************
*>
 identification division.
 program-id.            irsub3.
*>
*>author.               Cobol conversion by Vincent B Coen
*>                      for Applewood Computers.
*>
*>Security.             Copyright (C) 1982-2012, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*>remarks.              Accounts Default File Handler
*>
*>version.              0.03 22/10/1982.
*>                      0.04 15/01/2009.
*>                      0.05 14/04/2009.
*>Changes.
*> 22/01/09 vbc - Migration to Open Cobol.
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of the Applewood Computers Accounting System
*>   and is copyright (c) Vincent B Coen. 1976 - 2012 and later.
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
     select default-file     assign def-file,
                             organization line sequential,
                             access sequential,
                             status fs-reply.
*>
 data division.
 file section.
*>
 fd  default-file
     label records standard.
*>
 01  record-3            pic x(256).
*>
 working-storage section.
*>
 01  def-file            pic x(12).
*>
 copy "wsfsrply.cob".
*>
 linkage section.
*>
 copy  "wsdflt.cob".
 copy  "wsfnctn.cob".
 procedure division  using  default-record file-access.
*>====================================================
*>
 main.
*>---
*>
     move     zero to we-error.
     move     file-3 to def-file.
     if       fn-write
              open  output default-file
              move  default-record to record-3
              write record-3
              close default-file
              go to main-exit.
*>
*> Read the file.
*>
 do-read.
*>------
     open     input default-file.
*>
     if       fs-reply9 not = zero
              display "Failure to Open Default File" at 2301 with foreground-color 4  *> red
              perform display-file-error
              move 1 to we-error
              go to main-exit.
*>
     read     default-file record.
     move     record-3 to default-record.
     close    default-file
     go       to main-exit.
*>
 copy "fsdispfe.cob".
*>
 main-exit.   exit program.
*>********    ************
