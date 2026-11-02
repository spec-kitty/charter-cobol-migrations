       >>source free
*>*************************************************************
*>                                                            *
*>              Stock Item Additions & Deletions              *
*>                                                            *
*>*************************************************************
*>
 identification          division.
*>================================
*>
*>**
      program-id.         st020.
*>**
*>    author.             V.B.Coen, FBCS
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Called modules.
*>                        maps04.
*>                        maps99.
*>**
*>    Error messages used.
*>                        ST000.
*>                        ST002.
*>                        ST005.
*>
*>                        ST201.
*>                        ST202.
*>                        ST203.
*>                        ST204.
*>                        ST205.
*>                        ST206.
*>                        ST207.
*>                        ST208.
*>                        ST209.
*>                        ST210.
*>                        ST211.
*>                        ST212.
*>                        ST213.
*>                        ST214.
*>                        ST215.
*>                        ST216.
*>                        ST217.
*>                        ST218.
*>                        ST219.
*>
*>                        ST250.
*>                        ST251.
*>**
*> Changes:
*> 07/05/09 vbc - Rewritten in Cobol from scratch against v2 specs.
*> 10/05/09 vbc - Added in support for Barcode reader module & tested.
*> 27/05/09 vbc - Remove barcode module in OpenSource version so that
*>                support can be offered for the different versions
*>                  of Hardware but provide a dummy for menu.
*> 03/06/09 vbc - .07 Added support for Service only Flag.
*> 04/06/09 vbc - .08 Added Audit No in reports.
*> 05/06/09 vbc - .12 Added Report stock change totals for each print.
*> 06/06/09 vbc - .13 Reposition change totals.
*> 09/06/09 vbc - .14 Added missing WIP Quantity if any, to stock value.
*> 28/06/09 vbc - .15 Set Stk-Activity-Rep-Run (1) after running reports
*>                    Also increment batch no when clearing down Audit file.
*>                    Reset Stk-Audit-No to 1 on size error (max val = 255).
*> 15/07/09 vbc - .16 Modify menu option 4 subject to value of Stk-Period-Cur.
*>                    Batch no (Stk-Audit-No) used on proof rep and updated after
*>                    running end of period rep and clearing down audit file.
*>                    Amend manuals to reflect s/w changes.
*> 20/07/09 vbc - .17 Added function 5 to replace existing optional data, ie
*>                .18 dates ordered & due, quantities on order and backordered.
*> 19/08/09 vbc - .19 Added Standard and simple barcode processing based on a
*>                    WASP WLR8900 CCD LR via USB port. should work for any using
*>                    same port and protocol see code at da000 for more info.
*> 07/09/10 vbc - .20 Added extra functions for Cups print spool lpr as well as 2 copies etc.
*> 11/12/11 vbc -     Changed version from 1.00.xx to 3.01.xx, in keeping with the rest of ACAS
*>                .21 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 12/05/13 vbc - .22 Changed wsnames to in common as pl010 called in st010.
*> 13/05/13 vbc - .23 Added time to reports.
*> 14/05/13 vbc - .24 Commented out ws-month processing at aa020-DH-End in error along with the test!
*> 15/05/13 vbc - .25 Added processing in audit report for 'source' from invoicing and purchasing
*>                    in reports.
*> 16/05/13 vbc - .26 Changed wsnames using copybook and added msg ST219 to replace 201 if SF not created.
*> 25/05/13 vbc - .27 Added invoice / PO nos to add/ded audit reports with a change of heading & forced
*>                    Stock Value literal in adds & deducts report in case another report was run 1st
*>                    restored test for proc-month as YTD looks odd & changed the add statement (misused?)
*>                    for yearly figures.
*> 28/05/13 vbc - .28 (see .27) added credit note reporting see ea000.
*> 04/06/13 vbc - .29 Replaced Stk-Page-Lines with system Page-Lines.
*>
*>  << TODO >>
*>                 1. Need to add wip qty * bundle to co-joined stock no.
*>                    having updated wip qty et al.
*>                 2. Validate code to ensure conformance with updated spec
*>                    for order and procedure when calc. & updating stock values.
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of the Applewood Computers Accounting System
*> and is copyright (c) Vincent B Coen. 1976-2013 and later.
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
 copy "selstock.cob".
 copy "selprint.cob".
 copy "selaud.cob".
 data                    division.
*>================================
*>
 file section.
*>------------
*>
 copy "fdstock.cob".
 copy "fdprint.cob".
 copy "fdaudit.cob".
*>
 working-storage section.
*>-----------------------
*>
 77  Prog-Name           pic x(15)       value "ST020 (3.01.29)".
 copy "print-spool-command.cob".
 01  ws-qty-screen-display6.
     03  ws-unit6        pic 9(6).
     03  ws-sign6        pic x.
*>
 01  ws-amount-screen-display6.
     03  ws-poundsd6     pic 9(6).
     03  ws-period6      pic x     value ".".
     03  ws-penced6      pic v99.
 01  ws-amount-screen-accept6 redefines ws-amount-screen-display6.
     03  ws-pound6       pic 9(6).
     03  filler          pic x.
     03  ws-pence6       pic v99.
*>
 01  ws-amount-work6.
     03  amt-wk-pds6     pic 9(6).
     03  amt-wk-pence6   pic v99.
 01  ws-amount-ok6 redefines ws-amount-work6.
     03  amt-ok6         pic 9(6)v99.
*>
 01  ws-amount-screen-display8.
     03  ws-poundsd8     pic 9(8).
     03  ws-period8      pic x     value ".".
     03  ws-penced8      pic v99.
 01  ws-amount-screen-accept8 redefines ws-amount-screen-display8.
     03  ws-pound8       pic 9(8).
     03  filler          pic x.
     03  ws-pence8       pic v99.
*>
 01  ws-amount-work8.
     03  amt-wk-pds8     pic 9(8).
     03  amt-wk-pence8   pic v99.
 01  ws-amount-ok8 redefines ws-amount-work8.
     03  amt-ok8         pic 9(8)v99.
*>
 01  work-fields.
     03  Menu-Reply      pic 9                   value zero.
     03  ws-Reply        pic x                   value space.
     03  Escape-Code     pic x                   value space.
     03  ws-Proc-Month.
         05  ws-Proc-Mth pic 99                  value zero.
             88  ws-Good-Month                   values 01 thru 12.
     03  ws-Proc-Date    pic x(10).
     03  ws-Current-Period pic x(8).         *> Week, Month Quarter
     03  ws-Test-Date    pic x(10).
     03  ws-stock-dates.
         05  ws-Stock-Order-Date pic x(10).
         05  ws-Stock-Order-Due  pic x(10).
     03  ws-Audit-Report-Lit pic x(33)           value spaces.
     03  ws-Days-Late    pic s999                value zero.
     03  Line-Cnt        binary-char unsigned    value 99.
     03  Page-Nos        binary-char unsigned    value zero.
     03  a               binary-char unsigned    value zero.
     03  i               binary-char unsigned    value zero.
     03  b               pic s9(7).
     03  ws-Audit-Count  binary-short unsigned   value zero.
*>
     03  ws-Stock-Key                            value spaces.
         05  ws-Abrev-Stock   pic x(7).
         05  ws-Stock-No-Long pic x(6).
*>
     03  ws-z6           pic z(6).
     03  ws-z3           pic zz9.
     03  ws-Qty          pic s9(6)               value zero.
     03  ws-New-Qty      pic s9(6)               value zero.
     03  ws-Price        pic 9(6)v99     comp-3  value zero.
     03  ws-Value        pic s9(8)v99    comp-3  value zero.
     03  ws-Old-Value    pic s9(8)v99    comp-3  value zero.
     03  ws-New-Value    pic s9(8)v99    comp-3  value zero.
     03  ws-New-Cost     pic s9(6)v9999  comp-3  value zero.
     03  ws-Add-Total    pic s9(9)v99    comp-3  value zero.
     03  ws-Ded-Total    pic s9(9)v99    comp-3  value zero.
     03  ws-Total        pic zzz,zzz,zz9.99.
*>
     03  ws-Spaces-20    pic x(20)               value spaces.
     03  ws-Env-Lines    pic 999                 value zero.
     03  ws-Lines        binary-char  unsigned   value zero.
     03  ws-22-Lines     binary-char  unsigned   value zero.
     03  ws-23-Lines     binary-char  unsigned   value zero.
*>
 01  accept-terminator-array pic 9(4)            value zero.
     copy "screenio.cpy".
*>
 01  ws-Date-Formats.
     03  ws-Swap             pic xx.
     03  ws-Date             pic x(10).
     03  ws-UK redefines ws-Date.
         05  ws-days         pic xx.
         05  filler          pic x.
         05  ws-month        pic xx.
         05  filler          pic x.
         05  ws-year         pic x(4).
     03  ws-USA redefines ws-Date.
         05  ws-usa-month    pic xx.
         05  filler          pic x.
         05  ws-usa-days     pic xx.
         05  filler          pic x.
         05  filler          pic x(4).
     03  ws-Intl redefines ws-Date.
         05  ws-intl-year    pic x(4).
         05  filler          pic x.
         05  ws-intl-month   pic xx.
         05  filler          pic x.
         05  ws-intl-days    pic xx.
*>
 01  hdtime                            value spaces.
     03  hd-hh           pic xx.
     03  hd-mm           pic xx.
     03  hd-ss           pic xx.
     03  hd-uu           pic xx.
*>
*> Print layouts
*>
 01  Line-1.
     03  l1-Program      pic x(16)     value spaces.
     03  filler          pic x(39)     value spaces.
     03  l1-title        pic x(42)     value "Stock Addition Report".
     03  filler          pic x(27)     value spaces.
     03  filler          pic x(5)      value "Page ".
     03  l1-Page         pic zz9.
*>
 01  Line-2.
     03  l2-User         pic x(61).
     03  l2-Batch        pic x(55)     value spaces.
     03  l2-Date         pic x(10).
     03  filler          pic x         value space.
     03  l2-HH           pic xx        value spaces.
     03  filler          pic x         value ":".
     03  l2-MM           pic xx        value spaces.
*>
 01  Line-3.
     03  filler          pic x(78)   value spaces.
     03  filler          pic x(9)    value "Change in".
*>
 01  Line-3b.
     03  l3-Proc-Lit     pic x(11)  value "Proc. Date".
     03  filler          pic x(57)  value
         "Stock Number  Description                         Qty    ".
     03  l3-Price-Lit    pic x(5)   value "Price".
     03  l3-Stock-Lit    pic x(19)  value "    Stock Value    ".
     03  l3-Dates-Lit    pic x(39)  value "Order Date    Date Due     Order Status".
*>
 01  Line-4.
     03  l4-Proc-Date    pic x(11).
     03  l4-Stock-Number pic x(14).        *> 25
     03  l4-Desc         pic x(32).        *> 57
     03  l4-Qty          pic z(6)9-.       *> 65
     03  l4-Cost         pic z(6)9.99-.    *> 76
     03  l4-Qty-B-ord redefines l4-Cost
                         pic bbz(5)9bbb.
     03  l4-New-Value    pic z(5),zz9.99-. *> 89
     03  filler          pic xxx          value spaces.
     03  l4-Source.
         05  l4-Date-Ordered pic x(13).
         05  l4-Date-Due     pic x(13).        *> 118
         05  l4-Days-Late    pic zz9          blank when zero.
         05  l4-Lit-Late     pic x(10).        *> Days Late  131
*>
 copy "wsfnctn.cob".
 copy "wsmaps03.cob".
 copy "wsmaps09.cob".
*>
 01  Error-Messages.
*> System Wide
     03  ST000          pic x(36) value "ST000 Error on Writing to Stock File".
     03  ST002          pic x(36) value "ST002 Error on Writing to Audit File".
     03  ST005          pic x(18) value "ST005 Invalid Date".
*> Module specific
     03  ST201          pic x(26) value "ST201 Stock File not found".
     03  ST202          pic x(26) value "ST202 Audit File not found".
     03  ST203          pic x(42) value "ST203 Abbreviated Stock number not present".
     03  ST204          pic x(45) value "ST204 Quantity cannot equal or exceed 999,999".
     03  ST205          pic x(45) value "ST205 Quantity in Stock cannot exceed 999,999".
     03  ST206          pic x(48) value "ST206 Quantity in Stock cannot be less than zero".
     03  ST207          pic x(43) value "ST207 Quantity can only end with space or -".
     03  ST208          pic x(42) value "ST208 CAUTION: Stock quantity will be zero".
     03  ST209          pic x(40) value "ST209 Stock Value set to Minimum. (Zero)".
     03  ST210          pic x(39) value "ST210 Current Deductions at Zero or < 0".
     03  ST211          pic x(39) value "ST211 To Date Deductions at Zero or < 0".
     03  ST212          pic x(49) value "ST212 Stock Value set to Maximum. (99,999,999.99)".
     03  ST213          pic x(23) value "ST213 Bad month in date".
     03  ST214          pic x(28) value "ST214 Stock Number not found".
     03  ST215          pic x(39) value "ST215 Current Additions at Zero or < 0".
     03  ST216          pic x(39) value "ST216 To Date Additions at Zero or < 0".
     03  ST217          pic x(27) value "ST217 Services only Product".
     03  ST218          pic x(53) value "ST218 Services only product so only quantity accepted".
     03  ST219          pic x(32) value "ST219 Stock File not yet created".
*>
     03  ST250          pic x(13) value " (Order Date)".
     03  ST251          pic X(11) value " (Due Date)".
*>
 01  Error-Code         pic 999    value zero.
*>
 linkage section.
*>***************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
 01  to-day             pic x(10).
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>**********************************************************************
*>
 aa000-Core                 section.
*>*********************************
     accept   ws-env-lines from lines.
     if       ws-env-lines < 24
              move  24 to ws-env-lines ws-lines
     else
              move  ws-env-lines to ws-lines
     end-if
     subtract 1 from ws-lines giving ws-23-lines.
     subtract 2 from ws-lines giving ws-22-lines.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name to PSN.
*>
     if       file-status (11) not = 1
              display ST219 at line ws-23-lines col 1 with foreground-color 4 highlight
              move 45 to Error-Code
              perform maps99
              go to aa999-Exit.
*>
     open     i-o Stock-File.
     if       fs-reply not = zero
              close Stock-File
              display ST201 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 28 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              go to aa999-Exit.
     move     zero to Menu-Reply.
     perform  zz070-Convert-Date.
     move     ws-Date to ws-Proc-Date.
*>
*> Set variable menu item (4)
*>
     if       Stk-Period-Cur = "Q"
              move "Quarter" to ws-Current-Period
     else
      if      Stk-Period-Cur = "W"
              move "Week" to ws-Current-Period
      else
              move "Month" to ws-Current-Period.
*>
     string   "(5)  End of "    delimited by size
              ws-Current-Period delimited by space
              " Audit Reports"  delimited by size  into ws-Audit-Report-Lit.
*>
 aa010-Display-Headings.
     move     zero to ws-Audit-Count Page-Nos.
     move     99 to Line-Cnt.
     if       Menu-Reply = 1
              perform aa030-Display-Head-Add
     else
      if      Menu-Reply = 2
              perform aa040-Display-Head-Del
      else
       if     Menu-Reply = 3
              perform aa050-Display-Head-Barcode-Add
       else
        if    Menu-Reply = 4
              perform aa060-Display-Head-EOM
        else
         if   Menu-Reply = 5
              perform aa080-Display-Head-Order
         else
              perform aa070-Display-Head-Menu.
*>
 aa020-DH-End.
     move     ws-Month to ws-Proc-Month.
     if       ws-Proc-Month not numeric or not ws-Good-Month
              display ST213 at line ws-23-lines col 1 with foreground-color 4 highlight
              display ws-Proc-Month at line ws-23-lines col 25 with foreground-color 2 highlight
              display ws-Date at line ws-23-lines col 28 with foreground-color 2 highlight
              move 45 to error-code
              perform maps99
              go to aa999-Exit.
     go       to aa100-Main-Menu.
*>
 aa030-Display-Head-Add.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Stock Additions Entry" at 0130 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
 aa040-Display-Head-Del.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Stock Deductions Entry" at 0130 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
 aa050-Display-Head-Barcode-Add.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Stock Barcode Additions Entry" at 0123 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
 aa060-Display-Head-EOM.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Stock End of Month Processing" at 0126 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
 aa070-Display-Head-Menu.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Stock Movements Menu" at 0131 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
 aa080-Display-Head-Order.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Stock Order Entry" at 0132 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
 aa100-Main-Menu.
     display  "Select one of the following by number :- [ ]" at 0401 with foreground-color 2.
*>
     display  "(1)  Stock Additions Entry"       at 0604 with foreground-color 2.
     display  "(2)  Stock Deductons Entry"       at 0704 with foreground-color 2.
     display  "(3)  Stock Additions from Barcode Readers" at 0804 with foreground-color 2.
     display  "(4)  Stock Order Entry"           at 0904 with foreground-color 2.
     if       Stk-Audit-Used = 1
              display  ws-Audit-Report-Lit at 1104 with foreground-color 2. *> (5)
     display  "(9)  Return to System Menu"       at 1404 with foreground-color 2.
*>
 aa110-Accept-Loop.
     accept   Menu-Reply at 0443  with foreground-color 6 auto update.
     if       Menu-Reply = 9
              close Stock-File
              go to aa999-Exit.
     if       Menu-Reply = zero or > 5
              go to aa110-Accept-Loop.
*>
     if       File-Status (10) not = 1
         and  Stk-Audit-Used = 1
              open output Stock-Audit
              close Stock-Audit
              move 1 to File-Status (10).
*>
     if       Stk-Audit-Used = 1
      if      (Menu-Reply > zero and < 5)
              open  extend Stock-Audit
      else
              open  input Stock-Audit.
*>
     if       fs-reply not = zero
              display ST202 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 28 with foreground-color 2 highlight
              move  45 to error-code
              perform maps99
              close Stock-File
              go to aa999-Exit.
*>
     if       Menu-Reply = 1
              move  "Stock Addition Report" to l1-Title
              move  "Order Date    Date Due     Order Status" to l3-Dates-Lit
              move  "Proc. Date" to l3-Proc-Lit
              move  "Price" to l3-Price-Lit
              move  "    Stock Value    " to l3-Stock-Lit
              move spaces to l2-Batch
              open output Print-File
              perform  ba000-Process-Manual-Additions
              close Print-File
              if  Page-Nos not = zero
                  call  "SYSTEM" using Print-Report
              end-if
     else
      if      Menu-Reply = 2
              move  "Stock Deduction Report" to l1-Title
              move  spaces                   to l3-Dates-Lit  l3-Price-Lit l2-Batch
              move  "Proc. Date" to l3-Proc-Lit
              move  "    Stock Value    " to l3-Stock-Lit
              open output Print-File
              perform  ca000-Process-Manual-Deductions
              close Print-File
              if  Page-Nos not = zero
                  call  "SYSTEM" using Print-Report
              end-if
      else
       if     Menu-Reply = 3    *> use Barcode reader data to update stock & audit
              move spaces to l2-Batch
              open output Print-File
              perform  da000-Process-Barcode-Additions *> this process need to be mod'd to suit
              close Print-File
              if  Page-Nos not = zero
                  call  "SYSTEM" using Print-Report
              end-if
       else
        if  Menu-Reply = 4
              move  "Stock Orders Update" to l1-Title
              move  "Order Date    Date Due" to l3-Dates-Lit
              move  "B'Qty" to l3-Price-Lit
              move  spaces to l3-Stock-Lit l3-Proc-Lit
              move  spaces to l2-Batch line-4
              open output Print-File
              perform fa000-Process-Orders
              close Print-File
              if  Page-Nos not = zero
                  call  "SYSTEM" using Print-Report
              end-if
        else
         if   Menu-Reply = 5
          and Stk-Audit-Used = 1        *> zero = no audit, so report not avail
              move Stk-Audit-No to ws-z3
              string  "Batch "   delimited by size
                      ws-z3      delimited by size
                      into l2-Batch
              perform  ea000-Process-End-of-Month.

*>
     if       Stk-Audit-Used = 1
              close  Stock-Audit.
     move     zero to Menu-Reply.
     go       to aa010-Display-Headings.
*>
 maps04.
     call     "maps04" using maps03-ws.
 maps99.
     call     "maps99" using error-code ws-calling-data.
*>
 aa999-Exit.
     exit     program.
*>
*>******************************************
*>                  Routines               *
*>******************************************
*>
 ba000-Process-Manual-Additions   section.
*>***************************************
*>
     perform  aa010-Display-Headings.
     display  " Stock Number    Description         Quantity    Price   Stk Qty   Stk Value"
                                                  at 0301 with foreground-color 2.
     perform  varying lin from 5 by 1 until lin > ws-22-lines
              move    1 to cole
              display "[             ]" at curs with erase eol foreground-color 2
              move    16 to cole
              display "{                    }" at curs with foreground-color 2
              move    38 to cole
              display "[       ]"     at curs with foreground-color 2
              move    47 to cole
              display "[         ]"   at curs with foreground-color 2
              move    58 to cole
              display "{      }"      at curs with foreground-color 2
              move    67 to cole
              display "[           ]" at curs with foreground-color 2
     end-perform
     move     4 to i.
*>
 ba010-Accept-Data1.
     add      1 to i.
     if       i > ws-22-lines
              perform ba000-Process-Manual-Additions.     *> check for end of screen & reset
     move     spaces to ws-Stock-Key.
     initialize Stock-Audit-Record.
     move     2 to cole.
     move     i to lin.
     accept   ws-Stock-Key at curs with foreground-color 3 update.
     if       ws-Stock-Key = spaces
           or Cob-Crt-Status = Cob-Scr-Esc
              go to ba999-Exit.
*>
     move     function upper-case (ws-Stock-Key) to ws-Stock-Key.
*>
*>   Redisplay as uppercase then get the stock record but might have abbrev. no.
*>
     display  ws-Stock-Key at curs with foreground-color 3.
     if       ws-Stock-No-Long = spaces
              move ws-Abrev-Stock to Stock-Abrev-Key
              read Stock-File key Stock-Abrev-Key invalid key
                   display ST203 at line ws-23-lines col 1 with foreground-color 4 highlight
                   subtract 1 from i
                   go to ba010-Accept-Data1
              end-read
     else
              move ws-Stock-Key to Stock-Key
              read Stock-File invalid key
                   display ST214 at line ws-23-lines col 1 with foreground-color 4 highlight
                   subtract 1 from i
                   go to ba010-Accept-Data1
              end-read
     end-if
*>
*>  Have the required Stock record so get and show the desc
*>
     move     17 to cole.
     display  Stock-Desc (1:20) at curs with foreground-color 3.
*>
*> Check for Services only flag so ignore
*>
     if       Stock-Services-Flag = "Y"
              display ST217 at line ws-23-lines col 1 with foreground-color 2 highlight
              display ws-spaces-20 at curs
              subtract 1 from i
              go to ba010-Accept-Data1.
     display  " " at line ws-23-lines col 1 with erase eol.  *> clear any prior errors
*>
*>  Quantity to add to stock next but use whats on order as guide
*>
 ba020-Accept-Qty.
     move     Stock-On-Order to ws-unit6.
     move     space to ws-sign6.
     move     39 to cole.
     accept   ws-qty-screen-display6 at curs with foreground-color 3 update.
     if       ws-unit6 = zero
           or Cob-Crt-Status = Cob-Scr-Esc
           or Cob-Crt-Status = Cob-Scr-key-up
           or Cob-Crt-Status = Cob-Scr-page_up
              subtract 1 from i
              move 17 to cole
              display ws-spaces-20 at curs
              go to ba010-Accept-Data1.
*>
     if       ws-unit6 > 999998
              display ST204 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ba020-Accept-Qty.
     if       (ws-unit6 + Stock-Held) > 999999
              display ST205 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ba020-Accept-Qty.
     if       ws-sign6 not = "-" and not = space
              display ST207 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ba020-Accept-Qty.
*>
*> clear error line
*>
     display  " " at line ws-23-lines col 1 with erase eol.
     move     ws-unit6 to ws-qty.
     if       ws-sign6 = "-"
              move 1 to Audit-Reverse-Transaction
              multiply -1 by ws-qty.
*>
     if       ws-qty + Stock-Held < zero
              display ST206 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ba020-Accept-Qty.
*>
*> if zero, issue caution and continue so it stays displayed until next line processed
*>
     if       ws-qty + Stock-Held = zero
              display ST208 at line ws-23-lines col 1 with foreground-color 4 highlight
              move 15 to Error-Code
              perform maps99.
*>
 ba030-Accept-Price.
     move     48 to cole.
     perform  zz200-accept-money6a thru zz200-accept-money6b.
     if       amt-ok6 = zero
              go to ba020-Accept-Qty.
     move     amt-ok6 to ws-price.
*>
*>  Got it all now so process it.
*>
     if       Stk-Audit-Used = 1
              move     1 to Audit-Type         *> Additions
              move     Stock-Key to Audit-Stock-Key
              move     Stock-Desc to Audit-Desc
              move     ws-qty to Audit-Transaction-Qty
              move     ws-price to Audit-Unit-Cost
     end-if
     move     ws-price to Stock-Last-Actual-Cost.
     if       Stock-Held not = zero
          or  Stock-Work-in-Progress not = zero
              compute ws-Old-Value = (Stock-Held + Stock-Work-in-Progress) * Stock-Cost
     else
              move zero to ws-Old-Value.
*>
     multiply ws-Qty by ws-Price giving ws-Value.
     if       Stk-Audit-Used = 1
              move     ws-Value to Audit-Stock-Value-Change.
     add      ws-Value ws-Old-Value giving ws-New-Value   on size error
              display ST212 at line ws-23-lines col 1 with foreground-color 4 highlight
              move 99999999.99 to ws-New-Value.
*>
*> display updated quantity
*>
     add      ws-Qty Stock-Held giving ws-New-Qty.
     move     ws-New-Qty to ws-z6.
     move     59 to cole.
     display  ws-z6 at curs with foreground-color 3.
*>
*> Now for updating stock value
*>
     if       not Stock-Averaging
              move 68 to cole
              move ws-new-value to amt-ok8
              perform zz200-accept-money8c
              if    amt-ok8 not = zero
                    move amt-ok8 to ws-new-value.
*>
     divide   ws-New-Qty into ws-New-Value giving ws-New-Cost rounded.
*>
     if       Stock-Averaging
              move 67 to cole
              display "{           }" at curs with foreground-color 2
              add 1 to cole
              move ws-new-value to amt-ok8
              move amt-wk-pds8   to ws-pound8
              move amt-wk-pence8 to ws-pence8
              display ws-amount-screen-display8 at curs with foreground-color 3.
*>
     if       Stk-Audit-Used = 1
              move Stk-Audit-No to Audit-No
              move zero to Stk-Activity-Rep-Run
              move ws-Proc-Date to Audit-Process-Date
              write Stock-Audit-Record
              if    fs-reply not = zero
                    display ST002 at line ws-23-lines col 1 with foreground-color 4 highlight
                    display fs-reply at line ws-23-lines col 38 with foreground-color 2 highlight
                    move 45 to Error-Code
                    perform maps99
                    go to ba999-Exit.
*>
*> ws-Qty can be negative
*>
     if       ws-Qty > zero
              subtract ws-Qty from Stock-On-Order
     else
              add ws-Qty to Stock-On-Order.
*>
     if       Stock-On-Order not = zero
              add Stock-On-Order to Stock-Back-Ordered
              move zero to Stock-On-Order.
*>
     if       Stock-Back-Ordered < zero
              move zero to Stock-Back-Ordered.
*>
*>  Accumulate Month and Year to Date (TD) quantities.
*>
     add      ws-Qty to Stock-Adds.
     add      ws-Qty to Stock-TD-Adds (ws-Proc-Mth).
     if       Stock-Adds < 1
              display ST215 at line ws-23-lines col 1 with foreground-color 4 highlight.
     if       Stock-TD-Adds (ws-Proc-Mth) < 1
              display ST216 at line ws-23-lines col 41 with foreground-color 4 highlight.
*>
 ba040-Setup-Print-Transaction.
*>
*>  print report line
*>
     move     spaces to line-4.
     move     ws-Proc-Date to l4-Proc-Date.
     move     Stock-Key    to l4-Stock-Number.
     move     Stock-Desc   to l4-Desc.
     move     ws-Qty       to l4-Qty.
     move     ws-Price     to l4-Cost.
     move     ws-Value     to l4-New-Value.
*>
     move     spaces to u-date.
     move     Stock-Order-Date to u-bin.
     perform  zz060-Convert-Date.
     move     ws-date to l4-Date-Ordered.
*>
     move     spaces to u-date.
     move     Stock-Order-Due to u-bin.
     perform  zz060-Convert-Date.
     move     ws-date to l4-Date-Due.
*>
*> Work out days from order to today (assuming goods arrived today)
*>
     move     to-day to u-date.
     move     zero to u-bin.
     perform  maps04.
*>
*> this test should never happen
*>
     if       u-bin = zero
              display ST005 at line ws-23-lines col 1 with foreground-color 4 highlight
              display u-date at line ws-23-lines col 20 with foreground-color 2 highlight.
*>
     if       Stock-Order-Due = zero
              move spaces to l4-Lit-Late.
     if       Stock-Order-Due not = zero
              subtract Stock-Order-Due from u-bin giving ws-Days-Late
              if  ws-Days-Late > zero
                  move ws-Days-Late to l4-Days-Late
                  move " Days Late" to l4-Lit-Late
              else
               if ws-Days-Late < zero
                  move ws-Days-Late to l4-Days-Late
                  move " Days Early" to l4-Lit-Late.
*>
*> Clear due and ordered dates if ordered stock zero and print transaction
*>
     if       Stock-On-Order = zero
          and Stock-Back-Ordered = zero
              move zero to Stock-Order-Date Stock-Order-Due.
*>
     if       Line-Cnt > Page-Lines
              perform zz010-Print-Heads.
     write    print-record from line-4 after 1.
     add      1 to Line-Cnt.
*>
*>  Update Stock Record
*>
     move     ws-New-Value to Stock-Value.
     move     ws-New-Qty   to Stock-Held.
     move     ws-New-Cost  to Stock-Cost.
     rewrite  Stock-Record.
     if       fs-reply not = zero
              display ST000 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 38 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              go to ba999-Exit.
*>
     go       to ba010-Accept-Data1.
*>
 ba999-Exit.
     exit     section.
*>
 ca000-Process-Manual-Deductions  section.
*>***************************************
*>
     perform  aa010-Display-Headings.
     display  " Stock Number    Description         Quantity    Stk Qty"
                                                  at 0301 with foreground-color 2.
     perform  varying lin from 5 by 1 until lin > ws-22-lines
              move    1 to cole
              display "[             ]" at curs with erase eol foreground-color 2
              move    16 to cole
              display "{                    }" at curs with foreground-color 2
              move    38 to cole
              display "[       ]"     at curs with foreground-color 2
              move    47 to cole
              display "{      }"      at curs with foreground-color 2
     end-perform
     move     4 to i.
*>
 ca010-Accept-Data1.
     add      1 to i.
     if       i > ws-22-lines
              perform ca000-Process-Manual-Deductions.  *> check for end of screen & reset
     move     spaces to ws-Stock-Key.
     initialize Stock-Audit-Record.
     move     2 to cole.
     move     i to lin.
     accept   ws-Stock-Key at curs with foreground-color 3 update.
     if       ws-Stock-Key = spaces
           or Cob-Crt-Status = Cob-Scr-Esc
              go to ca999-Exit.
*>
     move     function upper-case (ws-Stock-Key) to ws-Stock-Key.
*>
*>   Redisplay as uppercase then get the stock record but might have abbrev. no.
*>
     display  ws-Stock-Key at curs with foreground-color 3.
     if       ws-Stock-No-Long = spaces
              move ws-Abrev-Stock to Stock-Abrev-Key
              read Stock-File key Stock-Abrev-Key invalid key
                   display ST203 at line ws-23-lines col 1 with foreground-color 4 highlight
                   subtract 1 from i
                   go to ca010-Accept-Data1
              end-read
     else
              move ws-Stock-Key to Stock-Key
              read Stock-File invalid key
                   display ST214 at line ws-23-lines col 1 with foreground-color 4 highlight
                   subtract 1 from i
                   go to ca010-Accept-Data1
              end-read
     end-if
*>
*>  Have the required Stock record so get and show the desc
*>
     move     17 to cole.
     display  Stock-Desc (1:20) at curs with foreground-color 3.
     move     48 to cole.
     add      Stock-Work-in-Progress Stock-Held giving ws-Z6.
     display  ws-Z6 at curs with foreground-color 3.
     display  " " at line ws-23-lines col 1 with erase eol.  *> clear any prior errors
*>
*>  Quantity to subtract from stock next
*>
 ca020-Accept-Qty.
     move     zero  to ws-unit6.
     move     space to ws-sign6
     move     39 to cole.
     accept   ws-qty-screen-display6 at curs with foreground-color 3 update.
     if       ws-unit6 = zero
           or Cob-Crt-Status = Cob-Scr-Esc
           or Cob-Crt-Status = Cob-Scr-key-up
           or Cob-Crt-Status = Cob-Scr-page_up
              subtract 1 from i
              move 17 to cole
              display ws-spaces-20 at curs
              go to ca010-Accept-Data1.
*>
     if       ws-unit6 > 999998
              display ST204 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ca020-Accept-Qty.
     if       ws-sign6 not = "-" and not = space
              display ST207 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ca020-Accept-Qty.
*>
*> clear error line
*>
     display  " " at line ws-23-lines col 1 with erase eol.
     move     ws-unit6 to ws-qty.
     if       ws-sign6 = "-"
              move 1 to Audit-Reverse-Transaction
              multiply -1 by ws-qty
              if  (ws-unit6 + Stock-Held) > 999999
                  display ST205 at line ws-23-lines col 1 with foreground-color 4 highlight
                  go to ca020-Accept-Qty.
*>
     if       Stock-Held - ws-qty < zero
              display ST206 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ca020-Accept-Qty
     else
              display  " " at line ws-23-lines col 1 with erase eol.
*>
*> Check for Services only flag so ignore
*>
     if       Stock-Services-Flag = "Y"
              display ST217 at line ws-23-lines col 1 with foreground-color 2 highlight
              subtract 1 from i
              go to ca010-Accept-Data1.
*>
*> if zero, issue caution and continue
*>
     if       Stock-Held - ws-Qty = zero
              display ST208 at line ws-23-lines col 1 with foreground-color 4 highlight
              move 15 to Error-Code
              perform maps99
              display " " at line ws-23-lines col 1 with erase eos.
*>
     move     48 to cole.
     subtract ws-Qty from Stock-Held giving ws-New-Qty.   *> neg values should add
     move     ws-New-Qty to ws-Z6.
     display  ws-Z6 at curs with foreground-color 3.
*>
*>  Got it all now so process it.
*>
     move     2 to Audit-Type.         *> Deductions
     move     Stock-Key to Audit-Stock-Key.
     move     Stock-Desc to Audit-Desc.
     move     ws-qty to Audit-Transaction-Qty.
     move     Stock-Cost to Audit-Unit-Cost.              *> IS THIS NEEDED else set to zero
     compute  Audit-Stock-Value-Change = ws-Qty * Stock-Cost * -1.
*>
     move     Stk-Audit-No to Audit-No.
     if       Stk-Audit-Used = 1
              move zero to Stk-Activity-Rep-Run
              move ws-Proc-Date to Audit-Process-Date
              write Stock-Audit-Record
              if    fs-reply not = zero
                    display ST002 at line ws-23-lines col 1 with foreground-color 4 highlight
                    display fs-reply at line ws-23-lines col 38 with foreground-color 2 highlight
                    move 45 to Error-Code
                    perform maps99
                    go to ca999-Exit.
*>
*>  Accumulate Month and Year to Date (TD) quantities.
*>
     add      ws-Qty to Stock-Deducts.
     add      ws-Qty to Stock-TD-Deds (ws-Proc-Mth).
     if       Stock-Deducts < 1
              display ST210 at line ws-23-lines col 1 with foreground-color 4 highlight.
     if       Stock-TD-Deds (ws-Proc-Mth) < 1
              display ST211 at line ws-23-lines col 41 with foreground-color 4 highlight.
*>
 ca040-Setup-Print-Transaction.
*>
*>  print report line
*>
     move     spaces to line-4.
     move     ws-Proc-Date to l4-Proc-Date.
     move     Stock-Key    to l4-Stock-Number.
     move     Stock-Desc   to l4-Desc.
     move     ws-Qty       to l4-Qty.
     move     Audit-Stock-Value-Change  to l4-New-Value.
*>
     if       Line-Cnt > Page-Lines
              perform zz010-Print-Heads.
     write    print-record from line-4 after 1.
     add      1 to Line-Cnt.
*>
*>  Update Stock Record
*>
     subtract ws-Qty from Stock-Held.
*>                                             needed even for NO stock-averaging
     compute Stock-Value = (Stock-Held + Stock-Work-in-Progress) * Stock-Cost on size error
               display ST212 at line ws-23-lines col 1 with foreground-color 4 highlight
               move 99999999.99 to Stock-Value.
*>
     rewrite  Stock-Record.
     if       fs-reply not = zero
              display ST000 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 38 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              go to ca999-Exit.
*>
     go       to ca010-Accept-Data1.
*>
 ca999-Exit.
     exit     section.
*>
 da000-Process-Barcode-Additions   section.
*>****************************************
*>
*>  check this AFTER RE-CODING <<<<<<<<<<<<<<<<<<<<<***<<<<<<<<<<<<<<<<<<<<<<<<<<
*>-----------------------------------------------------------------------------------
*>
*>   Coding taken from the additions routine ba000 with most of the code still present
*>    in case you need to modify it.
*>
*> This element just reads the bar code and adds 1 to qty & increases stock value
*>  by the last unit price paid or if zero then the unit average stock price assuming
*>    averaging is in use otherwise
*> stock value is not changed.
*>  that said code for accept quantity & unit price has been left in but is bypassed
*>  and the bar codes are read in showing the normal manual display screen.
*>
*> It is assumed that the code reader is connected to the USB or keyboard PS/2 port
*>  and the scanned barcode is read as coming from a keyboard with a CR (carriage return)
*> as tested using a WASP WLR8900 CCD LR (long range) USB scanner available from Wasp
*> Technologies Inc which are available in the UK and Europe. See SC manual for
*> additional information. While this specific reader reads one code at a time and passes
*> the resulting code to the program along with CR some versions can hold in their memory
*> many hundreds of such codes each again, ending with a CR. The code as supplied still
*> supports that.
*>
*> Note that the scanners may need to be programmed to end each scanned barcode with a CR.
*> See the specific scanner manual for the method,
*> Another point: Some scanners also have a numeric keypad on them so the user can input a
*> product quantity. This module would need changing to support this.
*>
*> For all support to program or for programming a module/program to process bar code data,
*>  or for that matter any other changes or additions, a request should be made
*>  to Applewood Computers with details of hardware used, i.e., make, model & specs of
*>  bar code readers in use and data produced. This is a chargeable service.
*> For contact details please see supplied manuals inside front page.
*>-----------------------------------------------------------------------------------
*>
     perform  aa010-Display-Headings.
     display  " Stock Number    Description         Quantity    Price   Stk Qty   Stk Value"
                                                  at 0301 with foreground-color 2.
     perform  varying lin from 5 by 1 until lin > ws-22-lines
              move    1 to cole
              display "[             ]" at curs with erase eol foreground-color 2
              move    16 to cole
              display "{                    }" at curs with foreground-color 2
              move    38 to cole
              display "[       ]"     at curs with foreground-color 2
              move    47 to cole
              display "[         ]"   at curs with foreground-color 2
              move    58 to cole
              display "{      }"      at curs with foreground-color 2
              move    67 to cole
              display "[           ]" at curs with foreground-color 2
     end-perform
     move     4 to i.
*>
 da010-Accept-Data1.
     add      1 to i.
     if       i > ws-22-lines
              perform da000-Process-Barcode-Additions.     *> check for end of screen & reset
     move     spaces to ws-Stock-Key.
     initialize Stock-Audit-Record.
     move     2 to cole.
     move     i to lin.
     accept   ws-Stock-Key at curs with foreground-color 3 update.
     if       ws-Stock-Key = spaces
           or Cob-Crt-Status = Cob-Scr-Esc
              go to da999-Exit.
*>
     move     function upper-case (ws-Stock-Key) to ws-Stock-Key.
*>
*>   Redisplay as uppercase then get the stock record but redundant as using barcodes.
*>
     display  ws-Stock-Key at curs with foreground-color 3.
     move     ws-Stock-Key to Stock-Key
     read     Stock-File invalid key
              display ST214 at line ws-23-lines col 1 with foreground-color 4 highlight
              display "Missing Stock Record" at curs with foreground-color 3 highlight blink
              go to da010-Accept-Data1.
*>
*>  Have the required Stock record so get and show the desc
*>
     move     17 to cole.
     display  Stock-Desc (1:20) at curs with foreground-color 3.
*>
*> Check for Services only flag so ignore
*>
     if       Stock-Services-Flag = "Y"
              display ST217 at line ws-23-lines col 1 with foreground-color 2 highlight
              display ws-spaces-20 at curs
              go to da010-Accept-Data1.
     display  " " at line ws-23-lines col 1 with erase eol.  *> clear any prior errors
*>
*> Bypass accept quantity but set as 1 and use filed last price paid for unit price
*>
     move     1 to ws-qty
                   ws-unit6.
     if       Stock-Last-Actual-Cost not = zero
              move  Stock-Last-Actual-Cost to Amt-ok6
                                              ws-price
     else
              move  Stock-Cost  to Amt-ok6
                                   ws-price.
*>
     move     39 to cole.
     display  ws-qty-screen-display6 at curs with foreground-color 3.
     go       to da030-Accept-Price.
*>
*> da020 is bypassed as quantity 1 is 'assumed' for basic barcode readers.
*>
*>  Quantity to add to stock next but use whats on order as guide
*>
 da020-Accept-Qty.
     move     Stock-On-Order to ws-unit6.
     move     space to ws-sign6.
     move     39 to cole.
     accept   ws-qty-screen-display6 at curs with foreground-color 3 update.
     if       ws-unit6 = zero
           or Cob-Crt-Status = Cob-Scr-Esc
           or Cob-Crt-Status = Cob-Scr-key-up
           or Cob-Crt-Status = Cob-Scr-page_up
              subtract 1 from i
              move 17 to cole
              display ws-spaces-20 at curs
              go to da010-Accept-Data1.
*>
     if       ws-unit6 > 999998
              display ST204 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to da020-Accept-Qty.
     if       (ws-unit6 + Stock-Held) > 999999
              display ST205 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to da020-Accept-Qty.
     if       ws-sign6 not = "-" and not = space
              display ST207 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to da020-Accept-Qty.
*>
*> clear error line
*>
     display  " " at line ws-23-lines col 1 with erase eol.
     move     ws-unit6 to ws-qty.
     if       ws-sign6 = "-"
              move 1 to Audit-Reverse-Transaction
              multiply -1 by ws-qty.
*>
     if       ws-qty + Stock-Held < zero
              display ST206 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to da020-Accept-Qty.
*>
*> if zero, issue caution and continue so it stays displayed until next line processed
*>
     if       ws-qty + Stock-Held = zero
              display ST208 at line ws-23-lines col 1 with foreground-color 4 highlight
              move 15 to Error-Code
              perform maps99.
*>
 da030-Accept-Price.
*>
*> code bypassed but using Stock-Last-Actual-Cost & update stock value if used otherwise zero
*>   with no stock value update
*>
*>??     if       not Stock-Averaging
*>??              move zero to ws-Price
*>??                           ws-Value
*>??     go       to
*>
     move     48 to cole.
     move     amt-wk-pence6 to ws-pence6.
     move     amt-wk-pds6 to ws-pound6.
     display  ws-amount-screen-display6 at curs with foreground-color 3.



*>     perform  zz200-accept-money6c.
*>     if       amt-ok6 = zero
*>              go to da020-Accept-Qty.
*>     move     amt-ok6 to ws-price.
*>
*>  Got it all now so process it.
*>
     if       Stk-Audit-Used = 1
              move     1 to Audit-Type         *> Additions
              move     Stock-Key to Audit-Stock-Key
              move     Stock-Desc to Audit-Desc
              move     ws-qty to Audit-Transaction-Qty
              move     ws-price to Audit-Unit-Cost
     end-if
     move     ws-price to Stock-Last-Actual-Cost.
     if       Stock-Held not = zero
          or  Stock-Work-in-Progress not = zero
              compute ws-Old-Value = (Stock-Held + Stock-Work-in-Progress) * Stock-Cost
     else
              move zero to ws-Old-Value.
*>
     multiply ws-Qty by ws-Price giving ws-Value.
     if       Stk-Audit-Used = 1
              move     ws-Value to Audit-Stock-Value-Change.
     add      ws-Value ws-Old-Value giving ws-New-Value   on size error
              display ST212 at line ws-23-lines col 1 with foreground-color 4 highlight
              move 99999999.99 to ws-New-Value.
*>
*> display updated quantity
*>
     add      ws-Qty Stock-Held giving ws-New-Qty.
     move     ws-New-Qty to ws-z6.
     move     59 to cole.
     display  ws-z6 at curs with foreground-color 3.
*>
*> Now for updating stock value
*>
     if       not Stock-Averaging
              move 68 to cole
              move ws-new-value to amt-ok8
              perform zz200-accept-money8c
              if    amt-ok8 not = zero
                    move amt-ok8 to ws-new-value.
*>
     divide   ws-New-Qty into ws-New-Value giving ws-New-Cost rounded.
*>
     if       Stock-Averaging
              move 67 to cole
              display "{           }" at curs with foreground-color 2
              add 1 to cole
              move ws-new-value to amt-ok8
              move amt-wk-pds8   to ws-pound8
              move amt-wk-pence8 to ws-pence8
              display ws-amount-screen-display8 at curs with foreground-color 3.
*>
     if       Stk-Audit-Used = 1
              move Stk-Audit-No to Audit-No
              move zero to Stk-Activity-Rep-Run
              move ws-Proc-Date to Audit-Process-Date
              write Stock-Audit-Record
              if    fs-reply not = zero
                    display ST002 at line ws-23-lines col 1 with foreground-color 4 highlight
                    display fs-reply at line ws-23-lines col 38 with foreground-color 2 highlight
                    move 45 to Error-Code
                    perform maps99
                    go to da999-Exit.
*>
*> ws-Qty can be negative
*>
     if       ws-Qty > zero
              subtract ws-Qty from Stock-On-Order
     else
              add ws-Qty to Stock-On-Order.
*>
     if       Stock-On-Order not = zero
              add Stock-On-Order to Stock-Back-Ordered
              move zero to Stock-On-Order.
*>
     if       Stock-Back-Ordered < zero
              move zero to Stock-Back-Ordered.
*>
*>  Accumulate Month and Year to Date (TD) quantities.
*>
     add      ws-Qty to Stock-Adds.
     add      ws-Qty to Stock-TD-Adds (ws-Proc-Mth).
     if       Stock-Adds < 1
              display ST215 at line ws-23-lines col 1 with foreground-color 4 highlight.
     if       Stock-TD-Adds (ws-Proc-Mth) < 1
              display ST216 at line ws-23-lines col 41 with foreground-color 4 highlight.
*>
 da040-Setup-Print-Transaction.
*>
*>  print report line
*>
     move     spaces to line-4.
     move     ws-Proc-Date to l4-Proc-Date.
     move     Stock-Key    to l4-Stock-Number.
     move     Stock-Desc   to l4-Desc.
     move     ws-Qty       to l4-Qty.
     move     ws-Price     to l4-Cost.
     move     ws-Value     to l4-New-Value.
*>
     move     spaces to u-date.
     move     Stock-Order-Date to u-bin.
     perform  zz060-Convert-Date.
     move     ws-date to l4-Date-Ordered.
*>
     move     spaces to u-date.
     move     Stock-Order-Due to u-bin.
     perform  zz060-Convert-Date.
     move     ws-date to l4-Date-Due.
*>
*> Work out days from order to today (assuming goods arrived today)
*>
     move     to-day to u-date.
     move     zero to u-bin.
     perform  maps04.
*>
*> this test should never happen
*>
     if       u-bin = zero
              display ST005 at line ws-23-lines col 1 with foreground-color 4 highlight
              display u-date at line ws-23-lines col 20 with foreground-color 2 highlight.
*>
     if       Stock-Order-Due = zero
              move spaces to l4-Lit-Late.
     if       Stock-Order-Due not = zero
              subtract Stock-Order-Due from u-bin giving ws-Days-Late
              if  ws-Days-Late > zero
                  move ws-Days-Late to l4-Days-Late
                  move " Days Late" to l4-Lit-Late
              else
               if ws-Days-Late < zero
                  move ws-Days-Late to l4-Days-Late
                  move " Days Early" to l4-Lit-Late.
*>
*> Clear due and ordered dates if ordered stock zero and print transaction
*>
     if       Stock-On-Order = zero
          and Stock-Back-Ordered = zero
              move zero to Stock-Order-Date Stock-Order-Due.
*>
     if       Line-Cnt > Page-Lines
              perform zz010-Print-Heads.
     write    print-record from line-4 after 1.
     add      1 to Line-Cnt.
*>
*>  Update Stock Record
*>
     move     ws-New-Value to Stock-Value.
     move     ws-New-Qty   to Stock-Held.
     move     ws-New-Cost  to Stock-Cost.
     rewrite  Stock-Record.
     if       fs-reply not = zero
              display ST000 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 38 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              go to da999-Exit.
*>
     go       to da010-Accept-Data1.
*>
 da999-Exit.
     exit     section.
*>
 ea000-Process-End-of-Month  section.
*>**********************************
*>
*> New code for processing records from invoicing in Sales & if present update stock values in stock file.
*> and purchase order receipts if and when implemented.
*>
     display  "Printing" at 1337 with erase eos.
     open     output Print-File.
     perform  ea100-Print-Additions.
     close    Print-File.               *> force seperate reports in case of double sided printing
     if       Page-Nos not = zero
              call  "SYSTEM" using Print-Report.
     open     output Print-File.
     perform  ea200-Print-Deductions.
     close    Print-File.
     if       Page-Nos not = zero
              call  "SYSTEM" using Print-Report.
     move     1 to Stk-Activity-Rep-Run.
*>
 ea010-Accept-Delete.
     move     "N" to ws-Reply.
     display  "Can I Delete the Audit File Now? [ ]" at 0401 with foreground-color 2.
     display  " Making sure that Sales Invoicing and Purchase Ledger are NOT running"
                                                     at 0601 with foreground-color 4 highlight.
     display  "Check that Reports are complete first, before responding"
                                                     at 0802 with foreground-color 4 highlight blink.
     accept   ws-Reply at 0435 with foreground-color 3 update.
     move     function upper-case (ws-Reply) to ws-Reply.
     if       ws-Reply = "N"
              go to ea999-Exit.
     if       ws-Reply not = "Y"
              go to ea010-Accept-Delete.
     close    Stock-Audit.
     open     output Stock-Audit.
     add      1 to Stk-Audit-No on size error
              move 1 to Stk-Audit-No.
*>
 ea999-Exit.
     exit     section.
*>
 ea100-Print-Additions     section.
*>********************************
*>
     close    Stock-Audit.
     open     input Stock-Audit.
     move     zero to Page-Nos ws-add-total ws-ded-total.
     move     99 to Line-Cnt.
     move     "Additions Stock Audit Report" to l1-Title.
     move     "Proc. Date" to l3-Proc-Lit.
     move     "Price"      to l3-Price-Lit.
     move     "    Stock Value    " to l3-Stock-Lit.
*>     move     spaces to l3-Dates-Lit.
     move    "Source/PO.no."  to l3-Dates-Lit.
     move     spaces to line-4.
*>
 ea110-Read-Record.
     read     Stock-Audit at end
              go to ea120-Totals.
*>
*> Could have batch headers but not in use at this time
*>
     if       Del-Record or SL-Del-Record or SL-Credit-Record
              add  Audit-Stock-Value-Change to ws-Ded-Total.
*>
     if       not Add-Record and not PL-Add-Record
              go to ea110-Read-Record.
     move     Audit-Stock-Key          to l4-Stock-Number.
     move     Audit-Desc               to l4-Desc.
     move     Audit-Transaction-Qty    to l4-Qty.
     move     Audit-Unit-Cost          to l4-Cost.
     move     Audit-Stock-Value-Change to l4-New-Value.
     move     Audit-Process-Date       to l4-Proc-Date.
     add      Audit-Stock-Value-Change to ws-Add-Total.
     move     spaces                   to l4-Source.
     if       PL-Add-Record
              string "Purchasing/"     delimited by size
                     Audit-Invoice-PO  delimited by size
                                          into l4-Source.
*>
     if       Line-Cnt > Page-Lines
              perform zz010-Print-Heads.
     write    Print-Record from line-4 after 1.
     add      1 to Line-Cnt.
     go       to ea110-Read-Record.
*>
 ea120-Totals.
     if       Line-Cnt > Page-Lines - 7
              perform zz010-Print-Heads.
     move     spaces to Print-Record.
     move     ws-Add-Total to ws-Total.
     move     56 to a.
     string   " Total Additions   " delimited by size
              ws-Total              delimited by size into Print-Record pointer a.
     write    Print-Record after 3.
     move     spaces to Print-Record.
     move     ws-Ded-Total to ws-Total.
     move     56 to a.
     string   " Total Deductions  " delimited by size
              ws-Total              delimited by size into Print-Record pointer a.
     write    Print-Record after 1.
     move     spaces to Print-Record (56:35).
     move     75 to a.
     string   "-------------- " delimited by size into Print-Record pointer a.
     write    Print-Record after 1.
     add      ws-Add-Total ws-Ded-Total giving ws-Total.
     move     56 to a.
     string   " Total Changes     " delimited by size
              ws-Total              delimited by size into Print-Record pointer a.
     write    Print-Record after 1.
     move     spaces to Print-Record (56:35).
     move     75 to a.
     string   "============== "  delimited by size into Print-Record pointer a.
     write    Print-Record after 1.
*>
 ea199-Exit.
     exit     section.
*>
 ea200-Print-Deductions    section.
*>********************************
*>
     close    Stock-Audit.
     open     input Stock-Audit.
     move     zero to Page-Nos.
     move     99 to Line-Cnt.
     move     "Deductions Stock Audit Report" to l1-Title.
     move     "Proc. Date"          to l3-Proc-Lit.
     move     "    Stock Value    " to l3-Stock-Lit.
     move     spaces to l3-Dates-Lit.
*>     move     spaces to l3-Price-Lit.
     move    "Source/Inv.no."  to l3-Dates-Lit.
     move     spaces to line-4.
*>
 ea210-Read-Record.
     read     Stock-Audit at end
              go to ea220-Totals.
*>
     if       not Del-record
          and not SL-Del-Record
          and not SL-Credit-Record
              go to ea210-Read-Record.
     move     Audit-Stock-Key          to l4-Stock-Number.
     move     Audit-Desc               to l4-Desc.
     move     Audit-Transaction-Qty    to l4-Qty.
     move     Audit-Stock-Value-Change to l4-New-Value.
     move     Audit-Process-Date       to l4-Proc-Date.
     move     spaces to l4-Source.
     if       SL-Del-Record
              string "Invoicing/"     delimited by size
                     Audit-Invoice-PO delimited by size
                                       into l4-Source.
     if       SL-Credit-Record
              string "Credit note/"       delimited by size
                     Audit-Invoice-PO     delimited by size
                     " for "              delimited by size
                     Audit-Cr-for-Invoice delimited by size
                                       into l4-Source.
*>
     if       Line-Cnt > Page-Lines
              perform zz010-Print-Heads.
     write    print-record from line-4 after 1.
     add      1 to Line-Cnt.
     go       to ea210-Read-Record.
*>
 ea220-Totals.
     if       Line-Cnt > Page-Lines - 7
              perform zz010-Print-Heads.
     move     spaces to Print-Record.
     move     ws-Add-Total to ws-Total.
     move     56 to a.
     string   " Total Additions   " delimited by size
              ws-Total              delimited by size into Print-Record pointer a.
     write    Print-Record after 3.
     move     spaces to Print-Record.
     move     ws-Ded-Total to ws-Total.
     move     56 to a.
     string   " Total Deductions  " delimited by size
              ws-Total              delimited by size into Print-Record pointer a.
     write    Print-Record after 1.
     move     spaces to Print-Record (56:35).
     move     75 to a.
     string   "-------------- " delimited by size into Print-Record pointer a.
     write    Print-Record after 1.
     add      ws-Add-Total ws-Ded-Total giving ws-Total.
     move     56 to a.
     string   " Total Changes     " delimited by size
              ws-Total              delimited by size into Print-Record pointer a.
     write    Print-Record after 1.
     move     75 to a.
     move     spaces to Print-Record (56:35).
     string   "============== "  delimited by size into Print-Record pointer a.
     write    Print-Record after 1.
*>
 ea299-Exit.
     exit     section.
*>
 fa000-Process-Orders   section.
*>*****************************
*>
*> Note that audit file is NOT updated only the stock file and that this process
*> replaces data, ie, quantities are REPLACED not added to
*>------------------------------------------------------------------------------
*>  So it is only used when Purchase Ledger is NOT passing this information on
*>   to Stock Control (or is not used).
*>
     perform  aa010-Display-Headings.
     display  " Stock Number   Description          Qty Ord Date Ordered  Date Due  " &
              "Back Qty"                at 0301 with foreground-color 2.
     perform  varying lin from 5 by 1 until lin > ws-22-lines
              move    1 to cole
              display "[             ]" at curs with erase eol foreground-color 2 *> stock no.
              move    16 to cole
              display "{                    }" at curs with foreground-color 2 *> desc (disp)
              move    38 to cole
              display "[      ]"       at curs with foreground-color 2  *> qty ordered
              move    46 to cole
              display "[          ]"   at curs with foreground-color 2  *> date ordered
              move    58 to cole
              display "[          ]"   at curs with foreground-color 2  *> date Due
              move    70 to cole
              display "[      ]"       at curs with foreground-color 2  *> qty B'ord
     end-perform
     move     4 to i.
*>
 fa010-Accept-Data1.
     add      1 to i.
     if       i > ws-22-lines                        *> check for end of screen & redraw
              perform fa000-Process-Orders.
     move     spaces to ws-Stock-Key.
     move     2 to cole.
     move     i to lin.
     accept   ws-Stock-Key at curs with foreground-color 3 update.
     if       ws-Stock-Key = spaces
           or Cob-Crt-Status = Cob-Scr-Esc
              go to fa999-Exit.
*>
     move     function upper-case (ws-Stock-Key) to ws-Stock-Key.
*>
*>   Redisplay as uppercase then get the stock record but might have abbrev. no.
*>
     display  ws-Stock-Key at curs with foreground-color 3.
     if       ws-Stock-No-Long = spaces
              move ws-Abrev-Stock to Stock-Abrev-Key
              read Stock-File key Stock-Abrev-Key invalid key
                   display ST203 at line ws-23-lines col 1 with foreground-color 4 highlight
                   subtract 1 from i
                   go to fa010-Accept-Data1
              end-read
     else
              move ws-Stock-Key to Stock-Key
              read Stock-File invalid key
                   display ST214 at line ws-23-lines col 1 with foreground-color 4 highlight
                   subtract 1 from i
                   go to fa010-Accept-Data1
              end-read
     end-if
*>
*>  Have the required Stock record so get and show the desc
*>
     move     17 to cole.
     display  Stock-Desc (1:20) at curs with foreground-color 3.
*>
*> Check for Services only flag so ignore
*>
     if       Stock-Services-Flag = "Y"
              display ST217 at line ws-23-lines col 1 with foreground-color 2 highlight
              display ws-spaces-20 at curs
              subtract 1 from i
              go to fa010-Accept-Data1.
     display  " " at line ws-23-lines col 1 with erase eol.  *> clear any prior errors
     move     space to ws-sign6.
*>
*>  Quantity on order
*>
 fa020-Accept-Qty.
     move     Stock-On-Order to ws-unit6.
     move     39 to cole.
     accept   ws-unit6 at curs with foreground-color 3 update.
     if       Cob-Crt-Status = Cob-Scr-Esc
           or Cob-Crt-Status = Cob-Scr-key-up
           or Cob-Crt-Status = Cob-Scr-page_up
              subtract 1 from i
              move 17 to cole
              display ws-spaces-20 at curs
              go to fa010-Accept-Data1.
*>
     if       ws-unit6 > 999998
              display ST204 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to fa020-Accept-Qty.
*>
*> clear error line
*>
     display  " " at line ws-23-lines col 1 with erase eol.
     move     ws-unit6 to Stock-On-Order.
*>
*> convert dates pre display and accept
*>
     if       Stock-Order-Date not = zero
              move Stock-Order-Date to u-bin
              perform zz060-Convert-Date
              move ws-date to ws-Stock-Order-Date
     else
              move spaces to ws-Stock-Order-Date
     end-if
     if       Stock-Order-Due not = zero
              move Stock-Order-Due to u-bin
              perform zz060-Convert-Date
              move ws-date to ws-Stock-Order-Due
     else
              move spaces to ws-Stock-Order-Due
     end-if.
*>
 fa030-Accept-Date-Ord.
     move     47 to Cole.
     accept   ws-Stock-Order-Date at curs with foreground-color 3 update.
     if       ws-Stock-Order-Date not = spaces
              move ws-Stock-Order-Date to ws-Test-Date
              perform zz050-Validate-Date
              if u-bin not = zero
                 move u-bin to Stock-Order-Date
              else
                 display ST005 at line ws-23-lines col 1  with foreground-color 4 highlight
                 display ST250 at line ws-23-lines col 19 with foreground-color 4 highlight
                 go to fa030-Accept-Date-Ord
     else
              move zero to Stock-Order-Date.
*>
 fa040-Accept-Date-Due.
     move     59 to Cole.
     accept   ws-Stock-Order-Due at curs with foreground-color 3 update.
     if       ws-Stock-Order-Due not = spaces
              move ws-Stock-Order-Due to ws-Test-Date
              perform zz050-Validate-Date
              if u-bin not = zero
                 move u-bin to Stock-Order-Due
              else
                 display ST005 at line ws-23-lines col 1  with foreground-color 4 highlight
                 display ST251 at line ws-23-lines col 19 with foreground-color 4 highlight
                 go to fa040-Accept-Date-Due
     else
              move zero to Stock-Order-Due.
*>
     display  " " at line ws-23-lines col 1 with erase eol.
*>
 fa050-Accept-B-ord.
     move     Stock-Back-Ordered to ws-unit6.
     move     71 to cole.
     accept   ws-unit6 at curs with foreground-color 3 update.
*>
     if       ws-unit6 > 999998
              display ST204 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to fa050-Accept-B-ord.
*>
*> clear error line
*>
     display  " " at line ws-23-lines col 1 with erase eol.
     move     ws-unit6 to Stock-Back-Ordered.
*>
 fa060-Setup-Print-Transaction.
*>
*>  print report line
*>
     move     spaces to line-4.
     move     Stock-Key          to l4-Stock-Number.
     move     Stock-Desc         to l4-Desc.
     move     Stock-On-Order     to l4-Qty.
     move     Stock-Back-Ordered to l4-Qty-B-ord.
*>
     move     spaces to u-date.
     move     Stock-Order-Date to u-bin.
     perform  zz060-Convert-Date.
     move     ws-date to l4-Date-Ordered.
*>
     move     spaces to u-date.
     move     Stock-Order-Due to u-bin.
     perform  zz060-Convert-Date.
     move     ws-date to l4-Date-Due.
*>
     if       Line-Cnt > Page-Lines
              perform zz010-Print-Heads.
     write    print-record from line-4 after 1.
     add      1 to Line-Cnt.
*>
*>  Update Stock Record
*>
     rewrite  Stock-Record.
     if       fs-reply not = zero
              display ST000 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 38 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              go to fa999-Exit.
*>
     go       to fa010-Accept-Data1.
*>
 fa999-Exit.
     exit     section.
*>
 zz010-Print-Heads         section.
*>********************************
*>
     if       Line-Cnt not > Page-Lines
              go to zz010-Exit.
     move     prog-name to l1-Program.
     add      1 to Page-Nos.
     move     Page-Nos to l1-Page.
     move     Usera to l2-User.
     perform  zz070-Convert-Date.
     move     ws-date to l2-Date.
     accept   hdtime from time.
     if       hdtime not = "00000000"
              move hd-hh to l2-HH
              move hd-mm to l2-MM.
     if       Page-Nos not = 1
              write print-record from Line-1 after page
              write print-record from Line-2 after 1
              move  spaces to print-record
              write print-record after 1
     else
              write print-record from Line-1 before 1
              write print-record from Line-2 before 1
     end-if
     move     6 to Line-Cnt.
     if       Menu-Reply not = 5
              write print-record from Line-3 after 1
     else
              subtract 1 from Line-Cnt.
     write    print-record from Line-3b after 1.
     move     spaces to print-record.
     write    print-record after 1.
*>
 zz010-Exit.
     Exit     section.
*>
 zz050-Validate-Date        section.
*>*********************************
*>
*>  Converts USA/Intl to UK date format for processing.
*>*******************************
*> Input:   ws-test-date
*> output:  u-date/ws-date as uk date format
*>          u-bin not zero if valid date
*>
     move     ws-test-date to ws-date.
     if       Date-Form = zero
              move 1 to Date-Form.
     if       Date-UK
              go to zz050-test-date.
     if       Date-USA                *> swap month and days
              move ws-days to ws-swap
              move ws-month to ws-days
              move ws-swap to ws-month
              go to zz050-test-date.
*>
*> So its International date format
*>
     move     "dd/mm/ccyy" to ws-date.  *> swap Intl to UK form
     move     ws-test-date (1:4) to ws-Year.
     move     ws-test-date (6:2) to ws-Month.
     move     ws-test-date (9:2) to ws-Days.
*>
 zz050-test-date.
     move     ws-date to u-date.
     move     zero to u-bin.
     perform  maps04.
*>
 zz050-exit.
     exit     section.
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
 zz100-test-escape          section.
*>*********************************
*>
     display  escape-code at 1876 with foreground-color 6.
*>
 zz100-get-escape.
     accept   escape-code at 1876 with foreground-color 6 update.
     move     function upper-case (escape-code) to escape-code.
*>
     if       escape-code not = "B" and not = "S" and not = "Q"
                      and not = "K"  and not = "D"
              go to zz100-get-escape.
*>
 zz100-exit.
     exit     section.
*>
 zz200-comm-routines section.
*>**************************
*>
 zz200-accept-money6a.
     move     zero to ws-poundsd6 ws-penced6 amt-ok6.
*>
 zz200-accept-money6b.
     display  ws-amount-screen-display6 at curs with foreground-color 3.
     accept   ws-amount-screen-accept6  at curs with foreground-color 3 update.
     move     ws-pound6 to amt-wk-pds6.
     move     ws-pence6 to amt-wk-pence6.
*>
*> this updates existing value in amt-ok6
*>
 zz200-accept-money6c.
     move     amt-wk-pence6 to ws-pence6.
     move     amt-wk-pds6 to ws-pound6.
     display  ws-amount-screen-display6 at curs with foreground-color 3.
     accept   ws-amount-screen-accept6  at curs with foreground-color 3 update.
     move     ws-pound6 to amt-wk-pds6.
     move     ws-pence6 to amt-wk-pence6.
*>
 zz200-accept-money8a.
     move     zero to ws-poundsd8 ws-penced8 amt-ok8.
*>
 zz200-accept-money8b.
     display  ws-amount-screen-display8 at curs with foreground-color 3.
     accept   ws-amount-screen-accept8  at curs with foreground-color 3 update.
     move     ws-pound8 to amt-wk-pds8.
     move     ws-pence8 to amt-wk-pence8.
*>
*> this updates existing value in amt-ok8
*>
 zz200-accept-money8c.
     move     amt-wk-pence8 to ws-pence8.
     move     amt-wk-pds8 to ws-pound8.
     display  ws-amount-screen-display8 at curs with foreground-color 3.
     accept   ws-amount-screen-accept8  at curs with foreground-color 3 update.
     move     ws-pound8 to amt-wk-pds8.
     move     ws-pence8 to amt-wk-pence8.
*>
 zz200-comm-exit.
     exit     section.
