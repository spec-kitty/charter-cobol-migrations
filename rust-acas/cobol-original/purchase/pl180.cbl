       >>source free
*>****************************************************************
*>                                                               *
*>           Invoice  Menu  &  Fixed  Data  Maintenance          *
*>                                                               *
*>****************************************************************
*>
 identification          division.
*>================================
*>
*>**
      program-id.         pl180.
*>**
*>    Author.             S.J.Whine  Aidpm
*>                        Cis Conversion By V B Coen FBCS, FIDPM, 18/04/84
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2010, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Invoice Menu & Fixed Data.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     None.
*>****
*>    Changes:
*>
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of the Applewood Computers Accounting System
*> and is copyright (c) Vincent B Coen. 1976 - 2010 and later.
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
 copy "envdiv.cob".
 input-output            section.
*>-------------------------------
*>
 file-control.
*>------------
*>
 i-o-control.
*>-----------
*>
 data                    division.
*>================================
*>
 file section.
*>------------
 working-storage section.
*>-----------------------
 77  prog-name          pic x(15) value "PL180 (3.00.02)".
*>
 copy "wsfnctn.cob".
*>
 01  ws-data.
     03  menu-reply      pic 9.
     03  ws-reply        pic x.
     03  ws-next-folio   pic 9(8).
     03  ws-vat-ac       pic 9(6).
*>
 01  error-code          pic 999.
*>
 linkage section.
*>***************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
*>
 01  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record to-day.
*>=============================================================
*>
 init01 section.
     move     ws-caller to ws-del-link.
     move     ws-called to ws-caller.
     if       next-folio = zero
              perform  fixed-data.
*>
 menu-return.
*>***********
*>
     move     zero  to  menu-reply.
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "Invoicing Menu" at 0134 with foreground-color 2.
     display  to-day at 0171 with foreground-color 2.
*>
     display  "Select one of the following by number :- [ ]" at 0501 with foreground-color 2.
*>
     display  "(1)  Amend Invoicing Fixed Data" at 0811    with foreground-color 2.
     display  "(2)  Enter Invoices" at 1011                with foreground-color 2.
     display  "(3)  Amend Invoices" at 1211                with foreground-color 2.
     display  "(4)  Delete Invoices" at 1411               with foreground-color 2.
     display  "(5)  Invoice Proof Report" at 1611          with foreground-color 2.
     display  "(9)  Return to System Menu" at 2011         with foreground-color 2.
*>
 menu-input.
*>**********
*>
     accept   menu-reply at 0543 with foreground-color 6 auto.
     if       menu-reply = 9
              go to  menu-exit.
     if       menu-reply  =  1
              perform  fixed-data.
     if       menu-reply  = 2
              move "pl020" to ws-called
              go to loadit.
     if       menu-reply  = 3
              move "pl030" to ws-called
              go to loadit.
     if       menu-reply  =  4
              move "pl040" to ws-called
              go to loadit.
     if       menu-reply  =  5
              move "pl050" to ws-called
              go to loadit.
     go       to menu-return.
*>
 loadit.
*>******
*>
     call     ws-called using ws-calling-data system-record to-day.
     go       to menu-return.
*>
 menu-exit.
*>*********
*>
     move     ws-caller to ws-called.
     move     ws-del-link to ws-caller.
*>
 menu-ex.
     exit     program.
*>******************************************
*>                  Procedures             *
*>******************************************
*>
 fixed-data              section.
*>===============================
*>
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2
     display  "Invoicing Fixed Data" at 0131  with foreground-color 2.
     display  to-day at 0171 with foreground-color 2.
*>
     display  "Next Folio" at 0511 with foreground-color 2.
     display  "- [        ]" at 0545 with foreground-color 2.
*>
     if       g-l
              display "Vat Account" at 0711 with foreground-color 2
              display "- [      ]" at 0745  with foreground-color 2.
*>
     display  "Details ok to file (Y/N) ...........[Y]" at 1011 with foreground-color 2.
*>
 data-entry.
*>**********
*>
     move     next-folio to ws-next-folio.
     display  ws-next-folio at 0548 with foreground-color 3.
     accept   ws-next-folio at 0548 with foreground-color 3 update
     move     ws-next-folio to next-folio.
     if       next-folio = zero
              go to  data-entry.
*>
     if       not  g-l
              go to  confirmation.
*>
     move     vat-ac to ws-vat-ac.
     display  ws-vat-ac at 0748 with foreground-color 3.
     accept   ws-vat-ac at 0748 with foreground-color 3 update.
     move     ws-vat-ac to vat-ac.
*>
 confirmation.
*>************
*>
     move     "Y"  to  ws-reply.
     accept   ws-reply at 1048 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "N"
              go to  data-entry.
     if       ws-reply not = "Y"
              go to  confirmation.
*>
 main-exit.   exit.
