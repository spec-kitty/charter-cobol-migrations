       >>source free
*>**********************************************************
*>                                                         *
*>            Product  Analysis  File  Maintenance         *
*>                                                         *
*>**********************************************************
*>
 identification          division.
*>===============================
*>
      program-id.         sl070.
*>**
*>    Author.             Cis Cobol Conversion By V B Coen FBCS 16/04/84
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Product Analysis File Maintenance
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps99.
*>**
*>    Error messages used.
*>                        SL008
*>                        SL009
*>                        SL010
*>                        SL011
*>**
*>
*>    Changes.
*> 31/03/84 Vbc - On Pa Setup Create Standard Va-Codes.
*> 03/05/84 Vbc - On Pa Setup Create Value File.
*> 31/05/84 Vbc - Support Graphic Screen.
*> 03/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 03/03/09 vbc - Support long screens.
*> 02/06/09 vbc - A warning if any PA codes contain zero as a GL number.
*> 25/11/11 vbc - .07 Error msgs to SLnnn.Support for dates other than UK
*> 08/12/11 vbc - .08 Support for path+filenames.
*> 09/12/11 vbc -     Updated version to 3.01.nn
*> 11/12/11 vbc - .09 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 12/05/13 vbc - .10 Force setup of Default group a, a1 for sales and purchases
*>                    as std codes.
*> 18/05/13 vbc - .11 Support for direct call from Stock to create default PA codes.
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
 environment             division.
*>===============================
*>
 copy "envdiv.cob".
 input-output            section.
*>------------------------------
*>
 file-control.
*>-----------
*>
 copy "selanal.cob".
 copy "selval.cob".
 copy "selprint.cob".
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdanal.cob".
 copy "fdval.cob".
 copy "fdprint.cob".
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "SL070 (3.01.11)".
 copy "print-spool-command-p.cob".
 copy "wsfnctn.cob".
*>
 01  ws-data.
     03  menu-reply      pic 9.
     03  ws-reply        pic x.
     03  a               pic 99.
     03  ws-err-flag     pic 9           value zero.
     03  escape-code     pic x.
     03  Print-Mode      pic x           value space.
         88  Print-All                   value "A".
     03  save-code       pic xxx.
     03  line-cnt        pic 99   comp  value zero.
*>
     03  ws-env-lines    pic 999       value zero.
     03  ws-lines        binary-char unsigned value zero.
     03  ws-23-lines     binary-char unsigned value zero.
     03  ws-22-lines     binary-char unsigned value zero.
     03  ws-21-lines     binary-char unsigned value zero.
     03  ws-20-lines     binary-char unsigned value zero.
     03  ws-19-lines     binary-char unsigned value zero.
     03  ws-18-lines     binary-char unsigned value zero.
     03  ws-17-lines     binary-char unsigned value zero.
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
     03  SL008          pic x(32) value "SL008 P.A. Code Already Exists!!".
     03  SL009          pic x(38) value "SL009 P.A. Group Code Does Not Exist!!".
     03  SL010          pic x(45) value "SL010 P.A. Group Code Used As Analysis Code!!".
     03  SL011          pic x(32) value "SL011 P.A. Code Does Not Exist!!".
*> Module specific
*>       NONE
*>
 01  error-code          pic 999.
*>
 01  line-1.
     03  l1-version      pic x(33)       value spaces.
     03  filler          pic x(39)       value "Product Analysis Codes".
     03  filler          pic x(5)        value "Page ".
     03  l1-page         pic zz9.
*>
 01  line-2.
     03  l2-user         pic x(30)       value spaces.
     03  filler          pic x(40)       value spaces.
     03  l2-date         pic x(10).
*>
 01  line-4.
     03  l5-led-lit      pic x(4)        value "Lgr".
     03  filler          pic x(59)       value  "Code    Gl.Nos.      <-----Description------>   Print".
     03  filler          pic x(6)        value  "-Type-".
*>
 01  line-6.
     03  filler          pic x           value space.
     03  l6-ledger       pic x           value spaces.
     03  filler          pic xxx         value space.
     03  l6-code         pic x(7).
     03  l6-gl           pic 9(6)        blank when zero.
     03  filler          pic x(7)        value spaces.
     03  l6-desc         pic x(24)       value spaces.
     03  filler          pic x(4)        value spaces.
     03  l6-print        pic xxx.
     03  filler          pic x(7)        value spaces.
     03  l6-type         pic x(6).
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
*>
 01  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 init01 section.
     accept   ws-env-lines   from lines.
     if       ws-env-lines < 24
              move  24 to ws-env-lines ws-lines
     else
              move  ws-env-lines   to ws-lines
     end-if
     subtract 1 from ws-lines giving ws-23-lines.
     subtract 2 from ws-lines giving ws-22-lines.
     subtract 3 from ws-lines giving ws-21-lines.
     subtract 4 from ws-lines giving ws-20-lines.
     subtract 5 from ws-lines giving ws-19-lines.
     subtract 6 from ws-lines giving ws-18-lines.
     subtract 7 from ws-lines giving ws-17-lines.
     move     prog-name to l1-version.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name to PSN.
*>
     if       ws-Process-Func not = 1   *> Called by Stock
              display  " " at 0101 with erase eos.
     if       file-status (15) = zero
              perform  p-a-setup.
     if       ws-Process-Func = 1       *> Called by Stock so we are done
              go to Menu-Exit.
*>
 menu-return.
     move     zero  to  menu-reply.
     perform  display-heading.
*>
 menu-input.
     display  "Select one of the following by number :- [ ]" at 0701 with foreground-color 2.
     display  "(1)  Set-up P/A records" at 1004       with foreground-color 2.
     display  "(2)  Amend/Delete P/A records" at 1204 with foreground-color 2.
     display  "(3)  Print P/A records" at 1404        with foreground-color 2.
     display  "(4)  Print All P/A records" at 1604    with foreground-color 2.
     display  "(5)  Display P/A records" at 1804      with foreground-color 2.
     display  "(9)  Return to system menu" at 2004    with foreground-color 2.
*>
     accept   menu-reply at 0743 with foreground-color 6 update auto.
*>
     if       menu-reply = 9
              go to  menu-exit.
     if       menu-reply  <  1  or  >  5
              go to  menu-input.
     perform  display-heading.
     if       menu-reply = 1
              perform  create.
     if       menu-reply = 2
              perform  amend.
     if       menu-reply = 3
              move spaces to l5-led-lit
              perform  report1.
     if       menu-reply = 4
              move "Lgr" to l5-led-lit
              move "A" to Print-Mode
              perform  report1.
     if       menu-reply = 5
              perform  show.
     go       to menu-return.
*>
 menu-exit.
     exit     program.
*>
*>****************************************************************
*>      P R O C E D U R E S                                      *
*>****************************************************************
*>
 create       section.
*>===================
*>
     open     i-o  analysis-file.
*>
 product-input.
     perform  display-outline.
     move     6  to  lin.
*>
 product-loop.
     move     spaces  to  pa-group.
     move     2 to cole.
     accept   pa-group at curs with foreground-color 3 update.
     if       pa-group = spaces
              go to  main-end.
*>
     move     "S" to pa-system.
     read     analysis-file not invalid key
              perform  product-display  of  show
              display  SL008 at line ws-23-lines col 01 with foreground-color 3
              go       to product-loop.
*>
     move     pa-code  to  save-code.
     if       pa-second = space
              go to  get-details.
*>
     move     space    to  pa-second.
*>
     read     analysis-file  invalid key
              display  SL009 at line ws-23-lines col 01 with foreground-color 3
              go to  product-loop.
*>
     if       pa-gl not = zero
              display  SL010 at line ws-23-lines col 01 with foreground-color 3
              go to  product-loop.
     display  " " at line ws-23-lines col 01 with erase eol.
*>
 get-details.
*>**********
*>
     move     save-code  to  pa-code.
     move     zero       to  pa-gl.
     move     spaces     to  pa-desc.
*>
     perform  analysis-data.
*>
     move     "S"  to   escape-code.
     display  escape-code at line ws-18-lines col 77  with foreground-color 6.
     accept   escape-code at line ws-18-lines col 77  with foreground-color 6 update.
     move     function upper-case (escape-code) to escape-code.
*>
 main-output.
*>**********
*>
     if       escape-code = "B"
              perform  get-pa-desc of analysis-data through  main-exit of analysis-data.
*>
     if       escape-code = "Q" or "K"
              go to  main-end.
*>
     write    analysis-record.
     add      1  to  lin.
*>
     if       lin  >  ws-22-lines
              perform  display-outline
              move  6  to  lin.
     go       to product-loop.
*>
 main-end.
*>*******
*>
     close    analysis-file.
*>
 main-exit.   exit section.
*>
 amend        section.
*>===================
*>
     open     i-o  analysis-file.
*>
 product-input.
     perform  display-outline.
     move     6  to  lin.
*>
 product-loop.
     move     2 to cole.
     move     spaces to pa-group.
     accept   pa-group at curs with foreground-color 3 update.
     if       pa-group = spaces
              go to  main-end.
*>
     move     "S" to pa-system.
     read     analysis-file  invalid key
              display  SL009 at line ws-23-lines col 01 with foreground-color 3
              go to  product-loop.
*>
     display  " " at line ws-23-lines col 1 with erase eol.
     perform  product-display  of  show.
*>
 get-details.
     perform  analysis-data.
*>
     move     "S"  to   escape-code.
     display  escape-code at line ws-18-lines col 77  with foreground-color 6.
     accept   escape-code at line ws-18-lines col 77  with foreground-color 6 update.
     move     function upper-case (escape-code) to escape-code.
*>
 main-output.
     if       escape-code = "B"
              perform  get-pa-desc of analysis-data  through  main-exit of analysis-data.
*>
     if       escape-code = "Q"
              go to  main-end.
*>
     if       escape-code = "K"
              delete  analysis-file
     else
              rewrite analysis-record.
*>
     add      1  to  lin.
     if       lin  >  ws-21-lines
              perform  display-outline
              move  6  to  lin.
     go to    product-loop.
*>
 main-end.
*>*******
*>
     close    analysis-file.
*>
 main-exit.   exit section.
*>
 report1      section.
*>===================
*>
     open     input  analysis-file.
     open     output  print-file.
     move     zero  to  a.
     perform  headings.
*>
 read-loop.
*>********
*>
     read     analysis-file  next record  at end
              go to  end-report.
*>
     if       pa-system not = "S"
        and   not Print-All
              go to read-loop.
*>
     if       pa-second = space
       and    pa-gl = zero
              move  spaces  to  print-record
              write print-record after 1
              add 1 to line-cnt
              move  "Group"  to  l6-type
              if  Print-All
                  move pa-system to l6-ledger
              end-if
     else
              move  "Detail" to  l6-type
              move space to l6-ledger
     end-if
     if       line-cnt > 70
              perform headings.
*>
     if       pa-second not = spaces
         and  pa-gl = zero
              move 1 to ws-err-flag.
     move     pa-group to  l6-code.
     if       not Irs-Used
              divide   pa-gl by 100 giving l6-gl
     else     move pa-gl to l6-gl.
     move     pa-desc  to  l6-desc.
     move     pa-print  to  l6-print.
*>
     write    print-record  from  line-6 after 1.
     add      1 to line-cnt.
     if       line-cnt > 70
              perform  headings.
*>
     go       to read-loop.
*>
 headings.
*>*******
*>
     add      1  to  a.
     move     a  to  l1-page.
     perform  zz070-Convert-Date.
     move     ws-date to l2-date.
     move     usera to  l2-user.
*>
     if       a not = 1
              write print-record from line-1 after page
              move spaces to print-record
              write print-record after 1
     else
              write print-record from line-1 before 1.
     write    print-record  from  line-2 after 1.
     write    print-record  from  line-4 after 2.
     move     5 to line-cnt.
*>
 end-report.
*>*********
*>
     if       ws-err-flag not = zero
              move "Warning: One or more P.A. codes contain a zero value for General Ledger numbers"
                              to print-record
              write print-record after 2.
*>
 main-end.
*>*******
*>
     close    print-file.
     close    analysis-file.
     call     "SYSTEM" using Print-Report.
*>
 main-exit.   exit section.
*>
 show         section.
*>===================
*>
     open     input  analysis-file.
     move     6  to  lin.
     perform  display-outline.
     move     6  to  lin.
     display  "Enter <X> to exit or <Return> to continue...[ ]"  at line ws-23-lines col 31 with foreground-color 2.
*>
 show-read.
*>********
*>
     if       lin > ws-21-lines
              go to main-end.
*>
 sread.
*>
     read     analysis-file  next record at end
              move ws-lines  to  lin
              go to  accept-of-show.
*>
     if       pa-system not = "S"
              go to sread.
*>
 product-display.
*>**************
     move     2 to cole.
     display  pa-group at curs with foreground-color 3.
     move     8 to cole.
     display  pa-gl at curs with foreground-color 3.
     move     20 to cole.
     display  pa-desc at curs with foreground-color 3.
*>
     if       pa-second = space
       and    pa-gl = zero
              move "Group"  to l6-type
     else
              move "Detail" to l6-type.
     move     48 to cole.
     display  pa-print at curs with foreground-color 3.
     move     55 to cole.
     display  l6-type at curs with foreground-color 3.
*>
 accept-of-show.
*>*************
*>
     add      1  to  lin.
     if       lin  <  ws-22-lines
              go to  show-read.
*>
     accept   ws-reply at line ws-23-lines col 76  with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       lin > ws-23-lines
              go to main-end.
     if       ws-reply not = "X"
              perform display-outline
              move 6 to lin
              go to show-read.
*>
 main-end.
*>*******
*>
     close    analysis-file.
*>
 main-exit.   exit section.
*>
*>****************************************************************
*>       S E R V I C E    R O U T I N E S                        *
*>****************************************************************
*>
 display-heading         section.
*>==============================
*>
     display  " " at 0101 with erase eos.
*>
     display  prog-name at 0101 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
     if       menu-reply =  0
              display "Product Analysis File Set-Up & Maintenance" at 0120 with foreground-color 2
              display "Function  Menu" at 0434         with foreground-color 2.
*>
     if       menu-reply =  1
              display "Set-Up P/A Records" at 0132     with foreground-color 2.
*>
     if       menu-reply =  2
              display "Amend/Delete P/A Records" at 0129 with foreground-color 2.
*>
     if       menu-reply =  3
              display "Print P/A Records" at 0132  with foreground-color 2.
*>
     if       menu-reply = 4
              display "Print All P/A Records" at 0132 with foreground-color 2.
*>
     if       menu-reply =  5
              display "Display P/A Records" at 0131 with foreground-color 2.
*>
 main-exit.   exit section.
*>********    ****
*>
 display-outline         section.
*>==============================
*>
     display  "Code   G/L Nos          Description" at 0401  with foreground-color 2.
     display  "Ref" at 0448 with foreground-color 2.
     display  "Type" at 0456 with foreground-color 2.
     move     6 to lin.
     move     1 to cole.
*>
 main-loop.
     display  "[  ]  [      ]    [                        ]  [   ]          " at curs with foreground-color 2.
*>
     add      1  to  lin.
     if       lin < ws-23-lines
              go to  main-loop.
*>
     if       menu-reply not = 5
              display "*******************" at line ws-17-lines col 62 with foreground-color 2
              display "*" at line ws-18-lines col 62  with foreground-color 2
              display "*" at line ws-18-lines col 80  with foreground-color 2
              display "*" at line ws-19-lines col 62  with foreground-color 2
              display "*" at line ws-19-lines col 80  with foreground-color 2
              display "*" at line ws-20-lines col 62  with foreground-color 2
              display "*" at line ws-20-lines col 80  with foreground-color 2
              display "*" at line ws-21-lines col 62  with foreground-color 2
              display "*" at line ws-21-lines col 80  with foreground-color 2
              display "*" at line ws-22-lines col 62  with foreground-color 2
              display "*" at line ws-22-lines col 80  with foreground-color 2
              display "*******************"  at line ws-23-lines col 62 with foreground-color 2.
*>
     if       menu-reply not = 5
              display "Escape Code [ ]" at line ws-18-lines col 64 with foreground-color 2
              display "<B> = Back" at line ws-19-lines col 64      with foreground-color 2
              display "<S> = Save" at line ws-20-lines col 64      with foreground-color 2
              display "<Q> = Quit" at line ws-21-lines col 64      with foreground-color 2
              display "<K> = Deleted" at line ws-22-lines col 64   with foreground-color 2.
*>
 main-exit.   exit section.
*>********    ****
*>
 analysis-data           section.
*>==============================
*>
     move     8 to cole.
     accept   pa-gl at curs with foreground-color 3 update.
*>
 get-pa-desc.
*>**********
*>
     move     20 to cole.
     accept   pa-desc  at curs with foreground-color 3 update.
*>
 get-pa-print.
*>***********
*>
     if       menu-reply = 1
              move  pa-group to  pa-print.
     move     48 to cole.
     accept   pa-print at curs with foreground-color 3 update.
*>
 main-exit.   exit section.
*>********    ****
*>
 p-a-setup               section.
*>==============================
*>
     open     input value-file.
     if       fs-reply not = zero
              close value-file
              move 1 to file-status (13)
              open output value-file
     end-if
     close    value-file.
     open     i-o value-file.
     open     output  analysis-file.
     move     "S" to pa-system.
     move     "v " to pa-group.
     move     zeros to pa-gl.
     move     spaces to pa-print.
     move     "VAT Control" to pa-desc.
     perform  create-value.
     move     "P" to pa-system.
     perform  create-value.
     move     "vi" to pa-group.
     move     "VAT Input Invoices/CN's" to pa-desc.
     perform  create-value.
     move     "vj" to pa-group.
     move     "VAT Input Receipts" to pa-desc.
     perform  create-value.
     move     "S" to pa-system.
     move     "z " to pa-group.
     move     "Computer Control" to pa-desc.
     perform  create-value.
     move     "P" to pa-system.
     perform  create-value.
     move     "za" to pa-group.
     move     "Purchase Carriage Charges" to pa-desc.
     move     "P&P" to pa-print.
     perform  create-value.
     move     "zb" to pa-group.
     move     "Purchase Late Charges" to pa-desc.
     move     "LCG" to pa-print.
     perform  create-value.
     move     "S" to pa-system.
     move     "zc" to pa-group.
     move     "Sales Carriage Charges" to pa-desc.
     move     "P&P" to pa-print.
     perform  create-value.
     move     "zd" to pa-group.
     move     "Sales Late Charges" to pa-desc.
     move     "LCG" to pa-print.
     perform  create-value.
     move     "vo" to pa-group.
     move     spaces to pa-print.
     move     "VAT Output Invoices/CN's" to pa-desc.
     perform  create-value.
     move     "vp" to pa-group.
     move     "VAT Output Receipts" to pa-desc.
     perform  create-value.
     move     "P" to pa-system.
     move     "a " to pa-group.
     move     "Default Group" to pa-desc.
     perform  create-value.
     move     "a1" to pa-group.
     move     "Default Purchases" to pa-desc.
     perform  create-value.
     move     "S" to pa-system.
     move     "a " to pa-group.
     move     "Default Group" to pa-desc.
     perform  create-value.
     move     "a1" to pa-group.
     move     "Default Sales" to pa-desc.
     perform  create-value.
     close    analysis-file value-file.
*>
     move     1 to file-status (15).
     if       ws-Process-Func not = 1
              display  " " at line ws-23-lines col 01 with erase eol.
     go       to main-exit.
*>
 create-value.
*>
     move     pa-code to va-code.
     read     value-file invalid key
              move analysis-record to value-record
              move zero to va-v-this va-v-last va-v-year
                           va-t-this va-t-last va-t-year
              write value-record.
*>
     write    analysis-record.
*>
 main-exit.   exit section.
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
