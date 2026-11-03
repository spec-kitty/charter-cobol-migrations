       >>source free
*>***************************************************
*>                                                  *
*>                Trial  Balance                    *
*>                                                  *
*>***************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         gl090.
*>**
*>    author.             V.B.Coen, FBCS,
*>                        Converted For Cis January 1985,
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Trial Balance Menu.
*>**
*>    Version.            See Prog-Name in Ws.
*>**
*>    Called Modules.     gl090b.
*>                        gl090a.
*>**
*>    Error messages used.
*>                        NONE
*>****
*> Changes:
*> 28/01/09 vbc - Migration to open Cobol.
*> 20/12/11 vbc - .03 Support for dates other than UK & clean up msgs
*>                    Error msgs to GLnnn,
*>                    Support for path+filenames.
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
 data                    division.
*>===============================
*>
 working-storage section.
*>----------------------
*>
 77  prog-name           pic x(15) value "gl090 (3.00.03)".
*>
 01  ws-data.
     03  menu-reply      pic 9.
*>
 01  ws-Test-Date            pic x(10).
 01  ws-date-formats.
     03  ws-swap             pic xx.
     03  ws-Conv-Date        pic x(10).
     03  ws-date             pic x(10).
     03  ws-UK redefines ws-date.
         05  ws-days         pic xx.
         05  filler          pic x.
         05  ws-month        pic xx.
         05  filler          pic x.
         05  ws-year         pic x(4).
     03  ws-USA redefines ws-date.
         05  ws-usa-month    pic xx.
         05  filler          pic x.
         05  ws-usa-days     pic xx.
         05  filler          pic x.
         05  filler          pic x(4).
     03  ws-Intl redefines ws-date.
         05  ws-intl-year    pic x(4).
         05  filler          pic x.
         05  ws-intl-month   pic xx.
         05  filler          pic x.
         05  ws-intl-days    pic xx.
*>
*> 01  Error-Messages.
*> System Wide
*>     03  GL010          pic x(16) value "GL010 Hit Return".
*>     03  GL011           pic x(25) value "GL011 Note and hit Return".
*> Module specific
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
*>
 01  to-day             pic x(10).
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 menu-input.
*>*********
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Trial Balance" at 0135 with foreground-color 2.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
     display  usera at 0301 with foreground-color 3.
*>
     display  "Select Option By Number :- [ ]" at 0801 with foreground-color 2.
     display  "(1)  Detailed Trial Balance" at 1001 with foreground-color 2.
*>
     if       profit-centres
              display "(2)  Profit Centre Trial Balance" at 1201 with foreground-color 2
     else
      if      branches
              display "(2)  Branch Trial Balance" at 1201 with foreground-color 2.
*>
     display  "(9)  Exit to system menu" at 1701 with foreground-color 2.
*>
     move     9 to menu-reply.
     accept   menu-reply at 0829 with foreground-color 7 update.
*>
     if       menu-reply = 1
              call "gl090b" using ws-calling-data system-record to-day file-defs.
*>
     if       menu-reply = 2
              call "gl090a" using ws-calling-data system-record to-day file-defs.
*>
     if       menu-reply not = 9
              go to  menu-input.
*>
 main-exit.
     exit     program.
*>
 zz070-Convert-Date        section.
*>********************************
*>
*>  Converts date in to-day to UK/USA/Intl date format
*>****************************************************
*> Input:   to-day
*> output:  ws-date as uk/US/Inlt date format
*>
     move     to-day to ws-date.
*>
     if       Date-Form = zero
              move 1 to Date-Form.
     if       Date-UK
              go to zz070-Exit.
     if       Date-USA                *> swap month and days
              move ws-days to ws-swap
              move ws-month to ws-days
              move ws-swap to ws-month
              go to zz070-Exit.
*>
*> So its International date format
*>
     move     "ccyy/mm/dd" to ws-date.  *> swap Intl to UK form
     move     to-day (7:4) to ws-Intl-Year.
     move     to-day (4:2) to ws-Intl-Month.
     move     to-day (1:2) to ws-Intl-Days.
*>
 zz070-Exit.
     exit     section.
