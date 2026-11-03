       >>source free
*>****************************************************************
*>                                                               *
*>             A C A S   E R R O R - H A N D L E R               *
*>                                                               *
*>****************************************************************
*>
 identification          division.
*>================================
*>
*>**
      program-id.         maps99.
*>**
*>    author.             Cis Cobol Conversion By V B Coen FBCS, 1/11/82
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2010, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    remarks.            Maps Error Handler.
*>**
*>    version.            1.07 of 12/03/09.
*>**
*> Changes:
*> 29/01/09 vbc - Migration to Open Cobol.
*> 03/03/09 vbc - Support for env lines eg Large screens
*>****
*>
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of ACAS the Applewood Computers Accounting
*> System and is copyright (c) Vincent B Coen. 1976-2010 and later.
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
*>================================
*>
 copy  "envdiv.cob".
 input-output            section.
*>-------------------------------
*>
 file-control.
*>------------
*>
     select  error-file      assign        "error.txt"
                             access        sequential
                             organization  line sequential
                             status        fs-reply.
*>
 data                    division.
*>================================
*>
 file section.
*>------------
*>
*>*******************************************
*>                                          *
*>   File Definition For The Error File     *
*>                                          *
*>*******************************************
*>
 fd  error-file.
*>
 01  error-record.
     03  error-nos       pic 999.
     03  severity        pic x.
     03  response        pic x.
     03  error-line      pic 99.
     03  e-message       pic x(50).
*>
 working-storage section.
*>-----------------------
 77  fs-reply            pic 99.
*>
 01  ws-area.
     03  ws-reply        pic x         value space.
     03  curs            pic 9(4).
     03  filler redefines curs.
         05  lin         pic 99.
         05  cole        pic 99.
     03  ws-env-lines    pic 999       value zero.
     03  ws-lines        binary-char unsigned value zero.
     03  ws-23-lines     binary-char unsigned value zero.
*>
 01  wsmess-1.
     03  ws-serv         pic x  value "T".
     03  ws-f1           pic x  value "-".
     03  ws-errno        pic 999.
     03  ws-f2           pic x  value space.
     03  ws-mess         pic x(50) value "Error not in error.txt. Hit return to close".
*>
 linkage section.
*>---------------
*>
 01  error-pass          pic 999.
*>
 copy "wscall.cob".
*>
 procedure division  using  error-pass ws-calling-data.
*>=====================================================
*>
 main.
*>----
     accept   ws-env-lines   from lines.
     if       ws-env-lines < 24
              move  24 to ws-env-lines ws-lines
     else
              move  ws-env-lines   to ws-lines
     end-if
     subtract 1 from ws-lines giving ws-23-lines.
     move     ws-23-lines to lin.
     move     1           to cole.
     move     zero to ws-term-code.
     open     input  error-file.
     if       fs-reply not = zero
              close  error-file
              go to error-close.
*>
 search-loop.
*>-----------
*>
     read     error-file  at end
              close  error-file
              go to error-close.
*>
     if       error-nos not =  error-pass
              go to  search-loop.
*>
     close    error-file.
*>
     move     error-nos to ws-errno.
     move     severity to ws-serv.
     move     e-message to ws-mess.
*>
     if       error-line  not =  zero
              if  error-line > 19
                  compute lin =  ws-lines - (24 - error-line)
              else
                  move error-line to lin.
*>
     if       response = "T"
              go to display-loop.
     if       "S" = severity and = response
              go to display-loop.
     display  wsmess-1 at curs with foreground-color 4.
*>
     if       severity = "T"
              move 9 to ws-term-code.
     go       to main-exit.
*>
 display-loop.
*>------------
*>
     display  wsmess-1 at curs with foreground-color 4.
     accept   ws-reply at line ws-lines col 79.
     go       to main-exit.
*>
 error-close.
*>
     move     error-pass to ws-errno
     go       to display-loop.
*>
 main-exit.   exit program.
