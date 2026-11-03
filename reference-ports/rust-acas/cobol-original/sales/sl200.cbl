       >>source free
*>****************************************************************
*>                                                               *
*>       I N V O I C E   D E L E T I O N   R E P O R T           *
*>                                                               *
*>****************************************************************
*>
 identification          division.
*>================================
*>
      program-id.         sl200.
*>**
*>    author.             V.B.Coen   AIDPM, FBCS
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Invoice Deletion Report.
*>
*>**
*>    Called Modules.     Maps04.
*>**
*>    Error messages used.
*>                        NONE
*>**
*> Changes:
*>  unknown vbc - Program added at customers request
*> 03/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 19/03/09 vbc - .01 Added 'None to report' when needed.
*> 25/11/11 vbc - .02 Error msgs to SLnnn.Support for dates other than UK
*> 08/12/11 vbc - .03 Support for path+filenames.
*> 09/12/11 vbc -     Updated version to 3.01.nn
*> 11/12/11 vbc - .04 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
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
*>================================
*>
 copy "envdiv.cob".
 input-output            section.
*>-------------------------------
*>
 file-control.
*>------------
*>
 copy "selprint.cob".
 copy "seldnos.cob".
 data                    division.
*>================================
*>
 file section.
*>------------
*>
 copy "fdprint.cob".
*>
 01 line-1.
     03  filler        pic xxx.
     03  pinv-nos      pic z(9)9.
     03  filler        pic x(5).
     03  pinv-date     pic x(10).
     03  filler        pic x(3).
     03  pinv-cus      pic x(7).
*>
 01  head-line.
     03  p1-version    pic x(15).
     03  filler        pic x(14).
     03  p1-title      pic x(23).
     03  filler        pic x(9).
     03  p1-date       pic x(12).
     03  p1-tit-page   pic x(5).
     03  p1-page       pic z9.
*>
 copy "fddnos.cob".
*>
 working-storage section.
*>-----------------------
 77  prog-name           pic x(15)    value "SL200 (3.01.04)".
 copy "print-spool-command-p.cob".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
*>
 01  ws-data.
     03  ws-reply        pic x.
     03  line-cnt        pic 99  comp value zero.
     03  page-cnt        pic 99  comp value zero.
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
*>     NONE
*> Module specific
*>     NONE
*>
 linkage section.
*>***************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
 01  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 start-program.
*>*************
*>
     open     output print-file.
     move     spaces to print-record.
     perform  headings-1.
     open     input del-inv-nos-file.
     if       fs-reply not = zero
              move "       None to report" to print-record
              write print-record after 2
              go to end-program.
*>
 main-read.
*>*********
*>
     read     del-inv-nos-file at end
              go to end-program.
     move     del-inv-dat to u-bin.
     perform  zz060-Convert-Date.
     move     ws-date to pinv-date.
*>
     move     del-inv-nos to pinv-nos.
     move     del-inv-cus to pinv-cus.
*>
     write    print-record after 1.
     add      1 to line-cnt.
     if       line-cnt > 70
              perform headings-1.
     go       to main-read.
*>
 headings-1.
*>
     move     spaces to head-line.
     add      1 to page-cnt.
     move     page-cnt to p1-page.
     move     "Page" to p1-tit-page.
     perform  zz070-Convert-Date.
     move     ws-date to p1-date.
     move     "Invoice Deletion Report" to p1-title.
     move     prog-name to p1-version.
     move     4 to line-cnt.
     if       page-cnt not = 1
              write print-record after page
     else
              write print-record after 1.
     move     "   Invoice No       Date         Cust No" to print-record.
     write    print-record after 2.
     move     spaces to print-record.
     write    print-record after 1.
*>
 end-program.
*>***********
*>
     if       fs-reply = zero
       and    page-cnt = 1 and line-cnt = 4
              move "       None to report" to print-record
              write print-record after 1.
     close    del-inv-nos-file print-file.
     move     Print-Spool-Name to PSN.
     call     "SYSTEM" using Print-Report.
*>
 main-term.
     exit program.
*>
 zz060-Convert-Date        section.
*>********************************
*>
*>  Converts date in binary to UK/USA/Intl date format
*>****************************************************
*> Input:   u-bin
*> output:  ws-date as uk/US/Inlt date format
*>          u-date & ws-Date = spaces if invalid date
*>
     perform  maps04.
     if       u-date = spaces
              move spaces to ws-Date
              go to zz060-Exit.
     move     u-date to ws-date.
*>
     if       Date-Form = zero
              move 1 to Date-Form.
     if       Date-UK
              go to zz060-Exit.
     if       Date-USA                *> swap month and days
              move ws-days to ws-swap
              move ws-month to ws-days
              move ws-swap to ws-month
              go to zz060-Exit.
*>
*> So its International date format
*>
     move     "ccyy/mm/dd" to ws-date.  *> swap Intl to UK form
     move     u-date (7:4) to ws-Intl-Year.
     move     u-date (4:2) to ws-Intl-Month.
     move     u-date (1:2) to ws-Intl-Days.
*>
 zz060-Exit.
     exit     section.
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
