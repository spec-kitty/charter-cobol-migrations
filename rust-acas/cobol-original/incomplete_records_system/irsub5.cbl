       >>source free
*>*****************************************************************
*>     F i n a l   A c c o u n t s   F i l e   H a n d l e r      *
*>*****************************************************************
*>
 identification division.
*>======================
*>
*>
 program-id.            irsub5.
*>
*>author.               Cobol conversion by Vincent B Coen
*>                      for Applewood Computers.
*>
*>Security.             Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*>
*>  remarks.            Final A/Cs File Handler.
*>
*>  version.            0.02 22/10/1982.
*>                      0.03 15/01/2009.
*> Changes.
*> 22/01/09 vbc - Migration to Open Cobol.
*>
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
*>
 copy  "envdiv.cob".
 input-output section.
 file-control.
*>
     select  final-file      assign "final.dat"
                             organization line sequential
                             access sequential
                             status fs-reply.
*>
 data division.
 file section.
*>
 fd  final-file.
*>
 01  record-5            pic x(655).
*>
 working-storage section.
*>
 copy "wsfsrply.cob".
*>
 linkage section.
*>
 copy  "wsfinal.cob".
 copy  "wsfnctn.cob".
*>
 procedure division  using  final-record file-access.
*>==================================================
*>
 main.
*>----
*>
     move     zero to we-error.
*>
     if       fn-write
              open output final-file
              if fs-reply9 not zero
                  display "Failure to open O/P Final File" at 2301 with foreground-color 4
                  perform display-file-error
                  move fs-reply9 to we-error
                  go to main-exit
              end-if
              move  final-record to record-5
              write record-5
              close final-file
              go to main-exit
     end-if
*>
     open     input final-file.
     if       fs-reply not zero

*>              display "Failure to open I/P Final File !" at 2301 with foreground-color 4
*>              perform display-file-error
*>              move 1 to we-error
*>              go to main-exit

              close   final-file
              open    output final-file
              initialize final-record
              move    final-record to record-5
              write   record-5
              close   final-file
              go      to main-exit
     end-if
*>
     read     final-file record.
     if       fs-reply not zero
              display "Failure to read Final File rec. !" at 2301 with foreground-color 4
              perform display-file-error
              move fs-reply9 to we-error
     end-if
*>

     if       fs-reply = zero
              move record-5 to final-record.
     close    final-file.
*>
     go       to main-exit.
*>
 copy "fsdispfe.cob".
*>
 main-exit.   exit program.
*>********    ************
