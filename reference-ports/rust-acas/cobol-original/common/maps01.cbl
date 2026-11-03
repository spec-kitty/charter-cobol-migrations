       >>source free
*>****************************************************************
*>                                                               *
*> P A S S - W O R D  /  N A M E    E N C O D E R                *
*>                                                               *
*>****************************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         maps01.
*>**
*>    author.             Cis Cobol Conversion By V B Coen 31/10/82
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Pass-Word / Name Encoder, OS version.
*>**
*>    version.            1.03 of 03/02/02 21:00.
*>****
*> Changes:
*> 29/01/09 vbc - Migration to Open Cobol.
*>                Simplify password mechanism for export inc USA
*>                 & change to just four chars.
*>
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of ACAS the Applewood Computers Accounting
*> System and is copyright (c) Vincent B Coen. 1976-2012 and later.
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
 copy  "envdiv.cob".
 input-output            section.
*>------------------------------
*>
 data                    division.
*>===============================
*>
 working-storage section.
*>----------------------
*>
 01  ws-data.
     03  alpha           pic x(26)     value "CKQUAELSMWYIZJRPBXFVGNODTH".
     03  filla1  redefines  alpha.
       05  ar1           pic x         occurs  26 indexed by xx.
     03  alower          pic x(26)     value "ckquaelsmwyizjrpbxfvgnodth".
     03  filler  redefines  alower.
       05  ar1-l         pic x         occurs  26  indexed by a.
*>
     03  pass-word-input.
       05  ar2           pic x         occurs  4.
     03  pass-word-output.
       05  ar3           pic x         occurs  4.
*>
     03  pass-name-input.
       05  ar4           pic x         occurs  32.
     03  pass-name-output.
       05  ar5           pic x         occurs  32.
*>
 77  q                   pic s9(5)      computational.
 77  y                   pic s9(5)      computational.
 77  z                   pic s9(5)      computational.
 77  base                pic s9(5)      computational.
 linkage section.
*>--------------
*>
 copy  "wsmaps01.cob".
*>
 procedure division  using  maps01-ws.
*>===================================
*>
     if       not  pass
              go to  encode-name.
*>
 encode-pass.
*>----------
*>
     move     pass-word  to  pass-word-input.
     move     1  to  y.
*>
 loop.
*>---
*>
     set      xx to  1.
     search   ar1  at end  go to  test-lower
                   when  ar1 (xx) = ar2 (y)
                   set a to xx
                   go to  set-base.
*>
 test-lower.
*>
     set      a  to  1.
     search   ar1-l  at end  go to  return-to-loop
                     when  ar1-l (a) = ar2 (y)
                     go to  set-base.
*>
 set-base.
*>
     multiply y  by  y  giving  base.
     add      3  to  base.
*>
     set      z  to  a.
     add      base  to  z.
     subtract 26  from  z.
*>
     if       z  <  1
              multiply  z  by  -1  giving  z.
*>
     subtract y  from  5  giving  q.
     if       z  not = zero
              move  ar1 (z)  to  ar3 (q)
     else
              move  space    to  ar3 (q).
*>
 return-to-loop.
*>
     add      1  to  y.
     if       y  <   5    go to  loop.
*>
     move     pass-word-output  to  pass-word.
     go       to main-exit.
*>
 encode-name.
*>----------
     move     pass-name  to  pass-name-input.
     move     1  to  y.
*>
 loop-n.
*>-----
*>
     set      xx to  1.
     search   ar1  at end  go to  test-lower-n
               when  ar1 (xx) = ar4 (y)
               set a to xx
               go to  set-base-n.
*>
 test-lower-n.
*>
     set      a  to  1.
     search   ar1-l  at end  go to  return-to-loop-n
                when  ar1-l (a) = ar4 (y)
                go to  set-base-n.
*>
 set-base-n.
*>
     add      y  51  giving  base.
     divide   base  by  y  giving  base  rounded.
*>
     if       base  >  25   subtract  26  from  base.
*>
     set      z  to  a.
     add      base  to  z.
     subtract 27  from  z.
*>
     if       z  <  1
              multiply  z  by  -1  giving  z.
*>
     if       z  >  26   subtract  26  from  z.
*>
     if       z  not = zero
              move  ar1 (z)  to  ar5 (y)
     else
              move  space    to  ar5 (y).
*>
 return-to-loop-n.
*>
     add      1  to  y.
     if       y  <  32    go to  loop-n.
*>
     move     pass-name-output  to  pass-name.
*>
 main-exit.   exit program.
*>********    ************
