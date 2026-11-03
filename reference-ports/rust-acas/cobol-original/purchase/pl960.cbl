       >>source free
*>*****************************************************
*>                                                    *
*>                 Remittance Advices                 *
*>    Normally used for cheques only but variant used *
*>     to send via email for bank to bank payments    *
*>                                                    *
*>*****************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl960.
*>**
*>    Author.             V B Coen FBCS, 18/04/84
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Remittance Advices.
*>**
*>    Changes.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Error messages used.
*>                        NONE
*>**
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 31/03/09 vbc - Added BACS to remittances.
*> 15/09/10 vbc - .04 Mod to lpr command.
*> 16/12/11 vbc - .05 Error msgs to SLnnn.Support for dates other than UK
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
*>------------------------------
*>
 file-control.
*>------------
*>
     select  cheque-file   assign file-33
                           organization line sequential
                           status fs-reply.
*>
 copy "selprint.cob".
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 fd  cheque-file.
*>
 01  cheque-record.
     03  filler              pic x(256).
     03  filler              pic x(128).
     03  filler              pic x(128).
     03  filler              pic x(128).
     03  filler              pic x(5).
 copy "fdprint.cob".
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "PL960 (3.01.05)".
 copy "print-spool-command.cob".
*>
 copy "wsfnctn.cob".
*>
 01  ws-data.
     03  z                pic 99.
     03  a                pic 9           value zero.
*>
*> 01  Error-Messages.
*> System Wide
*>     03  PL005          pic x(18) value "PL005 Invalid Date".
*> Module specific
*>     NONE
*>
 01  cheque.
*>
*> rec size 645 bytes
*>
     03  c-account        pic x(7).
     03  filler           pic x           value ",".
     03  c-name           pic x(30).
     03  filler           pic x           value ",".
     03  filler                          occurs 5.
         05  c-address    pic x(32).
         05  c-adr-filler pic x.
     03  c-words-1        pic x(64).
     03  filler           pic x           value ",".
     03  c-words-2        pic x(64).
     03  filler           pic x           value ",".
     03  c-gross          pic x(10).
     03  filler           pic x           value ",".
     03  c-cheque         pic x(9).
     03  filler           pic x           value ",".
     03  c-date           pic x(10).
     03  filler           pic x           value ",".
     03  filler                    occurs 9.
         05  c-inv        pic x(10).
         05  c-inv-filler pic x.
         05  c-folio      pic x(8).
         05  c-folio-fil  pic x.
         05  c-value      pic x(10).
         05  c-last       pic x.
*>
 01  line-box.
     03  filler          pic x(29)       value spaces.
     03  filler          pic x(24)       value all "*".
*>
 01  line-0.
     03  filler          pic x(29)       value spaces.
     03  filler          pic x(24)       value "** Remittance  Advice **".
*>
 01  line-1.
     03  l1-to           pic xxx.
     03  l1-addr1        pic x(32).
     03  filler          pic x(6)        value spaces.
     03  l1-from         pic x(7).
     03  l1-addr2        pic x(32).
 01  line-2.
     03  filler          pic x(16)       value "   A/C Number - ".
     03  l2-ac           pic x(19).
     03  filler          pic x(5)        value "Date ".
     03  l2-date         pic x(10).
 01  line-3.
     03  filler          pic x(10)       value spaces.
     03  filler          pic x(23)       value
         "Invoice Nos       Folio".
     03  filler          pic x(17)       value spaces.
     03  filler          pic x(7)        value "Amount".
 01  line-4.
     03  filler          pic x(11)       value spaces.
     03  l4-inv          pic x(14).
     03  l4-folio        pic x(23).
     03  l4-amount       pic x(12).
 01  line-5.
     03  filler          pic x(48)       value spaces.
     03  filler          pic x(10)       value all "=".
 01  line-6.
     03  filler          pic x(11)       value spaces.
     03  filler          pic x(14)       value "Total Paid by ".
     03  l6-chq-bacs     pic x(7).
     03  l6-cheque       pic x(16).
     03  l6-total        pic x(12).
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
 init section.
*>
*> MODIFY these 3 lines to suit your requirements
*>
     string   "lpr -P "        delimited by size
              Print-Spool-Name delimited by space
              " -r prt-1"      delimited by size into Print-Report.
*>
     open     input cheque-file.
     if       fs-reply not = zero
              goback.
     open     output print-file.
*>
 loop.
     read     cheque-file  at end
              go to  main-end.
*>
     move     spaces  to  print-record.
     if       a = 1
              write print-record after page
     else
              write print-record after 1.
     move     1 to a.
     write    print-record  from  line-box after 1.
     write    print-record  from  line-0 after 1.
     write    print-record  from  line-box after 1.
*>
     move     "To "  to  l1-to.
     move     "From   "  to  l1-from.
     move     cheque-record  to  cheque.
     move     c-name  to  l1-addr1.
     move     usera   to  l1-addr2.
     write    print-record  from  line-1 after 3.
*>
     move     spaces  to  l1-to
                          l1-from.
*>
     move     c-address (1)  to  l1-addr1.
     move     address-1      to  l1-addr2.
     write    print-record  from  line-1 after 1.
*>
     move     c-address (2)  to  l1-addr1.
     move     address-2      to  l1-addr2.
     write    print-record  from  line-1 after 1.
*>
     move     c-address (3)  to  l1-addr1.
     move     address-3      to  l1-addr2.
     write    print-record  from  line-1 after 1.
*>
     move     c-address (4)  to  l1-addr1.
     move     address-4      to  l1-addr2.
     write    print-record  from  line-1 after 1.
*>
     move     c-address (5) to l1-addr1.
     move     spaces to l1-addr2.
     write    print-record from line-1 after 1.
     move     c-account  to  l2-ac.
     move     c-date     to  l2-date.
     write    print-record  from  line-2 after 4 lines.
*>
     write    print-record  from  line-3 after 3 lines.
*>
     move     spaces  to  print-record.
     write    print-record after 1.
*>
     perform  varying z from 1 by 1 until z > 9
              move  c-inv (z)    to  l4-inv
              move  c-folio (z)  to  l4-folio
              move  c-value (z)  to  l4-amount
              if    l4-amount  not equal  spaces
                    write  print-record  from  line-4 after 1
     end-perform.
*>
     write     print-record  from  line-5 after 3  lines.
*>
     if       c-cheque not = "BACS"
              move "Cheque"  to  l6-chq-bacs
              move c-cheque  to  l6-cheque
     else
              move "BACS" to l6-chq-bacs
              move "to your Bank" to l6-cheque.
     move     c-gross   to  l6-total.
*>
     write    print-record  from  line-6 after 1.
     write    print-record  from  line-5 after 1.
     go       to loop.
*>
 main-end.
     close    print-file cheque-file.
     call     "SYSTEM" using Print-Report.
     exit     program.
