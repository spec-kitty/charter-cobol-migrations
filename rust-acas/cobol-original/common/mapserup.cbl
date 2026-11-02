       >>source free
*>*****************************************************************
*>                                                                *
*>    S Y S T E M   U P D A T E  &  N A M E    E N C O D E R      *
*>                                                                *
*>*****************************************************************
*>
 identification          division.
*>================================
*>
*>**
     Program-Id.         mapserup.
*>**
     Author.             V.B.Coen FBCS For Applewood Computers.
*>**
*>   Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                       Distributed under the GNU General Public License
*>                       v2.0. Only. See the file COPYING for details.
*>**
*>   Remarks.            System Update & Name Encoder.
*>**
*>   Version.            see prog-name in ws.
*>**
*>
*>   Called Modules.     Maps01.
*> Changes:
*> 29/01/09 vbc - .01 Migration to Open Cobol - Remove strong encryption code.
*> 28/04/09 vbc - .02 Added support for Stock, EPOS, OE, Payroll and Projects X & Z
*>                    so that all setups are in one module.
*>                 02A  Remove code for sub systems not yet included in Open Source.
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
 file-control.
*>------------
*>
 copy "selsys.cob".
*>
 data                    division.
*>===============================
*>
 file section.
*>------------
*>
 copy "fdsys.cob".
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(18) value "Mapserup (3.00.02)".
*>
 copy "wsmaps01.cob".
 COPY "wsdflt.cob".
 COPY "wsfinal.cob".
 COPY "wsfnctn.cob".
 copy "wsnames.cob".
 *>
 01  ws-data.
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
     03  ws-reply        pic x.
     03  ws-reply2       pic x.
     03  ws-reply3       pic x.
     03  ws-reply4       pic x.
     03  ws-reply5       pic x.
     03  ws-reply6       pic x.
     03  ws-reply7       pic x.
     03  ws-reply8       pic x.
     03  ws-reply9       pic x.
     03  a               pic 99        computational.
     03  option-list     pic x(60).
     03  old-invoicing   pic 9.
     03  old-stock       pic 9.
     03  old-OE          pic 9.
     03  old-EPOS        pic 9.
     03  old-Payroll     pic 9.
     03  old-Project-Z   pic 9.
     03  wsmaps-ser.
       05  wsmaps-ser-xx pic xx.
       05  wsmaps-ser-nn pic 9(4).
*>
 procedure               division.
*>===============================
*>
 bgn   section.
*>************
     display  prog-name                                   at 0101  with foreground-color 2 erase eos.
     display  "ACAS System Update Routine"                at 0128  with foreground-color 2.
*>
     display  "*****************************************" at 0420  with foreground-color 2.
     display  "* This Program is for internal use only *" at 0520  with foreground-color 2.
     display  "*" at 0620 with foreground-color 2.
     display  "*" at 0660 with foreground-color 2.
     display  "*              DO NOT ISSUE             *" at 0720  with foreground-color 4 blink.
     display  "*" at 0720 with foreground-color 2
     display  "*" at 0760 with foreground-color 2
     display  "*" at 0820 with foreground-color 2.
     display  "*" at 0860 with foreground-color 2.
     display  "*****************************************" at 0920  with foreground-color 2.
*>
*> Now Open System File for Output (overwriting existing contents)
*>
     open     i-o system-file.
     move     spaces to system-record.
     move     1 to rrn.
     read     system-file.
     if       fs-reply not = zero
              display "No system file found to update" at 1001 with foreground-color 2
              display "Hit return to exit" at 1101    with foreground-color 2
              accept ws-reply at 1120
              close system-file
              stop run.
*>
     display  "Customer's name :-           [" at 1101  with foreground-color 2.
     display  "]" at 1163 with foreground-color 2.
     display  usera at 1131 with foreground-color 3.
     accept  usera at 1131 with update,
*>
     move     "Y"  to  encode.
     move     usera to  pass-name.
     call     "maps01"  using  maps01-ws.
*>
  *>   if       pass-name not = user-code
  *>            display "Customer name mismatch, Hit return to close" at 1501  with foreground-color 4
  *>            accept ws-reply at 1545
  *>            close system-file
  *>            stop run.
     move     full-invoicing to old-invoicing.
     move     level-4 to old-stock.
     move     level-5 to old-OE.
*>
     perform  level-setup.
*>
     if       s-l
        and   old-invoicing = zero
              perform  sl-setup.
     if       Stock
        and   old-stock = zero
              initialize Stock-Control-Block.
*>     if       O-E
*>        and   old-OE = zero
*>              initialize Order-Entry-Block.
*>     if       EPOS
*>        and   old-EPOS = zero
*>              initialize EPOS-Block.
*>     if       Payroll
*>        and   old-Payroll = zero
*>              initialize Payroll-Block.
*>     if       Project-Z
*>        and   old-Project-Z = zero
*>              initialize Project-Z-Block.
*>
*> Now set record nos for actual System Record to 1.
*>
     move     1  to  rrn.
     rewrite  system-record.
*>
     close    system-file.
     stop     run.
*>
*>*******************************************************
*>                  Procedures                          *
*>*******************************************************
 level-setup  section.
*>*******************
*>
     perform  serialise.
*>
     display  "General  Ledger (Y/N) ? :- [ ]" at 1901 with foreground-color 2.
     display  "Purchase Ledger (Y/N) ? :- [ ]" at 2001 with foreground-color 2.
     display  "Sales    Ledger (Y/N) ? :- [ ]" at 2101 with foreground-color 2.
     display  "Invoicing       (Y/N) ? :- [ ]" at 1941 with foreground-color 2.
     display  "Stock Control   (Y/N) ? :- [ ]" at 2041 with foreground-color 2.
*>     display  "Order Entry     (Y/N) ? :- [ ]" at 2141 with foreground-color 2.
*>     display  "Payroll         (Y/N) ? :- [ ]" at 2201 with foreground-color 2.
*>     display  "Project Z       (Y/N) ? :- [ ]" at 2241 with foreground-color 2.
*>     display  "EPOS            (Y/N) ? :- [ ]" at 2301 with foreground-color 2.
*>
     if       level-1 = zero                 *> G/L
              move "N" to ws-reply  else
              move "Y" to ws-reply.
     display  ws-reply at 1929 with foreground-color 6.
     if       level-2 = zero                 *> P/L
              move "N" to ws-reply2  else
              move "Y" to ws-reply2.
     display  ws-reply2 at 2029 with foreground-color 6.
     if       level-3 = zero                 *> S/L
              move "N" to ws-reply3  else
              move "Y" to ws-reply3.
     display  ws-reply3 at 2129 with foreground-color 6.
     if       full-invoicing = zero           *> Invoicing in S/L
              move "N" to ws-reply4  else
              move "Y" to ws-reply4.
     display  ws-reply4 at 1969 with foreground-color 6.
     if       level-4 not = 1                  *> Stock
              move "N" to ws-reply5 else
              move "Y" to ws-reply5.
     display  ws-reply5 at 2069 with foreground-color 6.
*>     if       level-5 not = 1         *>  O/E
*>              move "N" to ws-reply6 else
*>              move "Y" to ws-reply6.
*>     display  ws-reply6 at 2169 with foreground-color 6.
*>     if       level-6 not = 1         *> Payroll
*>              move "N" to ws-reply7 else
*>              move "Y" to ws-reply7.
*>     display  ws-reply7 at 2229 with foreground-color 6.
*>     if       level-7 not = 1         *> Project-Z
*>              move "N" to ws-reply8 else
*>              move "Y" to ws-reply8.
*>     display  ws-reply8 at 2269 with foreground-color 6.
*>     if       level-8 not = 1         *> EPOS
*>              move "N" to ws-reply9 else
*>              move "Y" to ws-reply9.
*>     display  ws-reply9 at 2329 with foreground-color 6.
*>
     accept   ws-reply at 1929 with foreground-color 6 update.
     if       ws-reply  equal  "Y"  or  "y"
              move  1  to  level-1
       else
              move  0  to  level-1.
*>
     accept   ws-reply2 at 2029 with foreground-color 6 update.
     if       ws-reply2  equal  "Y"  or  "y"
              move  1  to  level-2
       else
              move  0  to  level-2.
*>
     accept   ws-reply3 at 2129 with foreground-color 6 update.
     if       ws-reply3  equal  "Y"  or  "y"
              move  1  to  level-3
       else
              move  0  to  level-3.
*>
     accept   ws-reply4 at 1969 with foreground-color 6 update.
     if       ws-reply4  equal  "Y"  OR  "y"
              move  1  to  full-invoicing
       else
              move  0  to  full-invoicing.
*>
     accept   ws-reply5 at 2069 with foreground-color 6 update.
     if       ws-reply5 = "Y" or "y"
              move  1  to  Level-4
     else
              move zero to Level-4.
*>
*>     accept   ws-reply6 at 2169 with foreground-color 6 update.
*>     if       ws-reply6 = "Y" or "y"
*>              move  1  to  Level-5
*>     else
*>              move zero to Level-5.
*>
*>     accept   ws-reply7 at 2129 with foreground-color 6 update.
*>     if       ws-reply7 = "Y" or "y"
*>              move  1  to  Level-6
*>     else
*>              move zero to Level-6.
*>
*>     accept   ws-reply8 at 2169 with foreground-color 6 update.
*>     if       ws-reply8 = "Y" or "y"
*>              move  1  to  Level-7
*>     else
*>              move zero to Level-7.
*>
*>     accept   ws-reply9 at 2169 with foreground-color 6 update.
*>     if       ws-reply9 = "Y" or "y"
*>              move  1  to  Level-8
*>     else
*>              move zero to Level-8.
*>
     display  "Please confirm (Y/N) :- [ ] " at 2341 with foreground-color 2.
*>
     move     spaces  to  option-list.
     move     1  to  a.
*>
     if       g-l
              string "General "      delimited by size into option-list pointer a.
*>
     if       b-l  and  g-l
              string "/ "            delimited by size into option-list pointer a.
*>
     if       b-l
             string "Purchase "      delimited by size into option-list pointer a.
*>
     if       s-l  and  g-l
       or     s-l  and  b-l
              string  "/ "           delimited by size into option-list pointer a.
*>
     if       s-l
              string "Sales "        delimited by size into option-list pointer a.
*>
     if       s-l  and  full-invoicing = 1
              string "/ Invoicing"   delimited by size into option-list pointer a.
*>
     if       Stock
              string "/ Stock "      delimited by size into option-list pointer a.
*>
*>     if       O-E
*>              string "/ Order Entry" delimited by size into option-list pointer a.
*>
*>     if       Payroll
*>              string "/ Payroll"     delimited by size into option-list pointer a.
*>
*>     if       Project-Z
*>              string "/ Project-Z"   delimited by size into option-list pointer a.
     display  option-list at 2401 with foreground-color 2.
     accept   ws-reply at 2366 with foreground-color 6 update.
*>
     if       ws-reply not = "Y" and not = "y"
              go to  level-setup.
*>
 main-exit.   exit section.
*>
 sl-setup     section.
*>*******************
*>
     move     1     to  sl-dunning sl-charges.
     move     30    to  sl-credit.
*>
     move     zero to sl-disc sl-min sl-max sl-limit sl-day-book
                      sl-stats-run sl-late-per extra-rate
                      pf-retention s-flag-a s-flag-i s-flag-p
                      sl-pay-ac sl-sales-ac s-debtors
                      s-end-cycle-date.
     move     spaces to extra-desc extra-type.
     move     "\"   to  sl-delim.
*>
 main-exit.   exit section.
*>
 serialise section.
*>================
*>
     move     maps-ser-xx to wsmaps-ser-xx.
     move     maps-ser-nn to wsmaps-ser-nn.
*>
     display  "          Serial number   :- [" at 1501  with foreground-color 2.
     display  "]" at 1537 with foreground-color 2.
     display  wsmaps-ser at 1531 with foreground-color 3.
     accept   wsmaps-ser at 1531 with update.
     move     wsmaps-ser-xx to maps-ser-xx,
     move     wsmaps-ser-nn to maps-ser-nn.
*>
 main-exit.   exit section.
