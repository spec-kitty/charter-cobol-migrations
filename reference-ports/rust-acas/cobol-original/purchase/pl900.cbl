       >>source free
*>*******************************************************
*>                                                      *
*>                   Cheque  Menu                       *
*>                                                      *
*>*******************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl900.
*>**
*>    Author.             V B Coen FBCS, 18/04/84
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012 Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Invoice Menu & Fixed Data.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Pl910 Pl920 Pl930 Pl940 Pl945 Pl950 Pl955
*>                        Pl960.
*>**
*>    Error messages used.
*>                        SL005
*>**
*>  Changes.
*>
*> 22/06/84 Vbc - Support Indexed Openitm File By Scrapping Sorts
*>                Pl945, Pl955; Not Using Pl115 Pre Pl910.
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00
*> 16/12/11 vbc - .02 Mod lpr.
*>                    Error msgs to SLnnn.Support for dates other than UK
*>                    Support for path+filenames.
*>                    Updated version to 3.01.nn
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
 file-control.
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 working-storage section.
*>----------------------
 77  prog-name          pic x(15) value "PL900 (3.01.02)".
 77  menu-reply         pic 9     value zero.
 copy "wsmaps03.cob".
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
 01  Error-Messages.
*> System Wide
     03  SL005          pic x(18) value "SL005 Invalid Date".
*> Module specific
*>     NONE
*>
 linkage section.
*>==============
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
*>
 01  to-day              pic x(10).
*>
 procedure  division using ws-calling-data system-record to-day file-defs.
*>=======================================================================
*>
 main.
     move     ws-caller to ws-del-link.
     move     ws-called to ws-caller.
*>
 menu-start.
     move     zero  to  menu-reply.
     display  prog-name     at 0101 with foreground-color 2 erase eos.
     display  "Cheque Menu" at 0136 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date       at 0171 with foreground-color 2.
*>
     display  "Select one of the following by number :- [ ]" at 0501 with foreground-color 2.
*>
     display  "(1)  Generate payments to be made" at 0811            with foreground-color 2.
     display  "(2)  Amend payments" at 1011                          with foreground-color 2.
     display  "(3)  Proof payments" at 1211                          with foreground-color 2.
     display  "(4)  Generate cheques" at 1411                        with foreground-color 2.
     display  "(5)  Print cheque register" at 1611                   with foreground-color 2.
     display  "(6)  Print remittance advices" at 1811                with foreground-color 2.
     display  "(9)  Return to system menu" at 2111                   with foreground-color 2.
*>
 menu-input.
     accept   menu-reply at 0543      with foreground-color 6 auto update.
*>
     if       menu-reply  equal  9
              go to  menu-exit.
     if       menu-reply  equal  1
              move "pl910" to ws-called
              go to loadit.
     if       menu-reply  equal  2
              move "pl920" to ws-called
              go to loadit.
     if       menu-reply  equal  3
              move "pl930" to ws-called
              go to loadit.
     if       menu-reply  equal  4
              move "pl940" to ws-called
              go to loadit.
     if       menu-reply  equal  5
              move "pl950" to ws-called
              go to loadit.
     if       menu-reply  equal  6
              move "pl960" to ws-called
              go to loadit.
*>
     go       to menu-input.
*>
 loadit.
*>
     call     ws-called using ws-calling-data system-record
                              to-day          file-defs.
     go       to menu-start.
*>
 menu-exit.
     move     ws-caller to ws-called.
     move     ws-del-link to ws-caller.
     exit     program.
*>
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
*>
 maps04       section.
*>*******************
*>
     call     "maps04"  using  maps03-ws.
*>
 maps04-exit.
     exit     section.
*>
