       >>source free
*>*************************************************************
*>                                                            *
*>              Stock Item File Maintenance                   *
*>                                                            *
*>*************************************************************
*>
 identification          division.
*>================================
*>
*>**
      program-id.         st010.
*>**
*>    author.             V.B.Coen, FBCS
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Stock Item File Maintenance.
*>**
*>    Version.            See prog-name in Ws.
*>**
*>    Called modules.
*>                        maps04 - Date testing and conversion.
*>                        maps09 - Check Digit verify and creation, used for supplier.
*>                        maps99 - Error Message (ACAS wide only) production.
*>                        SL070  - Analysis codes set up - Defaults only.
*>**
*>    Error messages used.
*>                        ST000.
*>                        ST003.
*>                        ST005.
*>
*>                        ST101.
*>                        ST102.
*>                        ST103.
*>                        ST104.
*>                        ST105.
*>                        ST106.
*>                        ST107.
*>                        ST108.
*>                        ST109.
*>                        ST110.
*>                        ST111.
*>                        ST112.
*>                        ST113.
*>                        ST114.
*>                        ST115.
*>                        ST116.
*>                        ST117.
*>                        ST118.
*>                        ST119.
*>**
*>    Changes:
*> 25/04/09 vbc - Rewritten in Cobol from scratch.
*> 04/05/09 vbc - WIP changes in layout in screen and file.
*> 26/05/09 vbc - Added Stock location so no need to imbed into stock number.
*> 28/05/09 vbc - .16 Added Function Renumber Stock Item.
*> 02/06/09 vbc - .18 Added PA & SA Anal codes and anal file for sales/Purchase support.
*> 03/06/09 vbc - .20 Added Services only flag ie for Consultancy etc
*>                 so item does not require Qty ordered/backordered, cost etc
*>                 nor WIP values so WIPs are not printed.
*> 05/06/09 vbc - .21 Include total record count on report.
*> 06/06/09 vbc - .22 Added WIP stock to stock-value if in use.
*> 18/06/09 vbc - .24 reversed PA and SA code in report to match input screen
*>                 Swap Stk Abrev and no. around.2 match st030.
*> 16/07/09 vbc - .25 Using ST104 instead of 105, if purchase ledger not setup.
*> 17/07/09 vbc - .26 Abbrev code does not need to pass maps09 as no check digit.
*> 24/07/09 vbc - .27 Force record entry (1) if stockfile not setup
*>                    (file-status (11) not = 1) as per spec/manual.
*> 11/12/11 vbc -     Changed version from 1.00.xx to 3.01.xx, in keeping with the rest of ACAS
*>                .28 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 28/04/13 vbc - .29 Force services flag to N on new record entry screen
*> 10/05/13 vbc - .30 Added new function of display all records in Display Records and new msg ST119.
*>                    Changed set up and amend procedures to correctly accept amounts as screen section
*>                    doesn't using Display-01B / 01C (display only).
*> 12/05/13 vbc - .31 Detect F1 on accept during stock setup (or amend)
*>                    and call pl010 to set up one or more supplier's.
*> 12/05/13 vbc - .32 Changed wsnames to in common as pl010 called in st010.
*>                .33 Bug in .31 display cleared some data.
*> 13/05/13 vbc - .34 Added time to reports so that later reports on same day can be seen.
*> 16/05/13 vbc - .35 Changed wsnames to in copybook see above.
*> 25/05/13 vbc - .36 Force call to SL070 if analysis file not set up & clean up error recovery on opening same.
*> 04/06/13 vbc - .37 Replaced Stk-Page-Lines with system Page-Lines.
*> 03/12/13 vbc - .137 Rewritten for GNU Cobol Report Writer functions.
*>                     Versions with RW added have builds with 100 added.
*>                     My first attempt at using in almost 50 years of Cobol programming !
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
 copy "selpl.cob".
 copy "selanal.cob".
 copy "selprint.cob".
 data                    division.
*>================================
*>
 file section.
*>------------
*>
 copy "fdstock.cob".
 copy "fdpl.cob".
 copy "fdanal.cob".
*> copy "fdprint.cob".
*>
 fd  print-file
     report Stock-File-Report.
*>
 working-storage section.
*>-----------------------
*>
 77  prog-name           pic x(16)       value "ST010 (3.01.151)".
*>
*>  This will print 1 copy to CUPS print spool specified on line 3
*>
 copy "print-spool-command.cob".
 01  ws-saved-stock-record
                         pic x(400).
 01  ws-vars             pic x(77).
 01  ws-Print-Total      pic x(35) value spaces.
*>
*> Amount workfields
*>
 01  ws-amount-screen-display7.
     03  ws-poundsd7     pic 9(7).
     03  ws-period7      pic x     value ".".
     03  ws-penced7      pic v99.
 01  ws-amount-screen-accept7 redefines ws-amount-screen-display7.
     03  ws-pound7       pic 9(7).
     03  filler          pic x.
     03  ws-pence7       pic v99.
*>
 01  ws-amount-work7.
     03  amt-wk-pds7     pic 9(7).
     03  amt-wk-pence7   pic v99.
 01  ws-amount-ok7 redefines ws-amount-work7.
     03  amt-ok7         pic 9(7)v99.
*>
 01  ws-amount-screen-display7b.
     03  ws-poundsd7b    pic 9(7).
     03  ws-period7b     pic x     value ".".
     03  ws-penced7b     pic v9999.
 01  ws-amount-screen-accept7b redefines ws-amount-screen-display7b.
     03  ws-pound7b      pic 9(7).
     03  filler          pic x.
     03  ws-pence7b      pic v9999.
*>
 01  ws-amount-work7b.
     03  amt-wk-pds7b    pic 9(7).
     03  amt-wk-pence7b  pic v9999.
 01  ws-amount-ok7b redefines ws-amount-work7b.
     03  amt-ok7b        pic 9(7)v9999.
*>
 01  ws-amount-screen-display9.
     03  ws-poundsd9     pic 9(9).
     03  ws-period9      pic x     value ".".
     03  ws-penced9      pic v99.
 01  ws-amount-screen-accept9 redefines ws-amount-screen-display9.
     03  ws-pound9       pic 9(9).
     03  filler          pic x.
     03  ws-pence9       pic v99.
*>
 01  ws-amount-work9.
     03  amt-wk-pds9     pic 9(9).
     03  amt-wk-pence9   pic v99.
 01  ws-amount-ok9 redefines ws-amount-work9.
     03  amt-ok9         pic 9(9)v99.
*>
 01  work-fields.
     03  Menu-Reply      pic 9.
     03  ws-reply        pic x.
     03  ws-menu         pic 9.
     03  ws-EOF          pic x     value "N".
     03  Escape-Code     pic x.
     03  a               binary-char unsigned value zero.
     03  b               pic 9.
     03  c               pic 9.
*>
     03  ws-stock-dates.
         05  ws-Stock-Order-Date pic x(10).
         05  ws-Stock-Order-Due  pic x(10).
     03  ws-Test-Date    pic x(10).
     03  ws-contruct-key pic x(13).
     03  ws-Stock-Key    pic x(13).
     03  ws-Save-Stock-Key   pic x(13).
     03  ws-Save-Abrev-Key   pic x(7).
     03  ws-Abrev-Key.
         05  ws-Abrev-K2     pic x(6).
         05  ws-Abrev-Chk2   pic 9.
     03  ws-Stock-Supplier.
         05  filler          pic x(6).
         05  ws-Stock-Supp-7 pic x.
     03  ws-Cost         pic z(6)9.9999.
     03  ws-Costx redefines ws-Cost.       *> helps to clear fraction of a penny/cent when zero
         05  filler      pic x(10).
         05  ws-Costz    pic xx.
     03  ws-Date-Ordered pic x(11).
     03  ws-Date-Due     pic x(10).
     03  ws-ToDate       pic x(10).
     03  ws-z6           pic z(6).
     03  ws-z6b          pic z(6).
     03  ws-z6c          pic z(6).
     03  ws-Rec-Total    pic zzz,zzz,zz9.
     03  ws-Services-Flag pic 9     value zero.
     03  ws-Print-Line-Flag pic 9   value zero.
*>
     03  ws-env-lines    pic 999              value zero.
     03  ws-Page-Lines   binary-char unsigned value zero.
     03  ws-lines        binary-char unsigned value zero.
     03  ws-22-lines     binary-char unsigned value zero.
     03  ws-23-lines     binary-char unsigned value zero.
     03  ws-Rec-Cnt      binary-long unsigned value zero.
*>
 01  ws-COB-CRT-Status   pic 9(4)             value zero.
 01  accept-terminator-array pic 9(4)         value zero.
     copy "screenio.cpy".
*>
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
 01  hdtime                            value spaces.
     03  hd-hh           pic xx.
     03  hd-mm           pic xx.
     03  hd-ss           pic xx.
     03  hd-uu           pic xx.
 01  WS-Time.
     03  ws-hh           pic xx.
     03  ws-col          pic x        value ":".
     03  ws-mm           pic xx.
*>
 copy "wsfnctn.cob".
 copy "wsmaps03.cob".
 copy "wsmaps09.cob".
*>
 01  Error-Messages.
*> System Wide
     03  ST000          pic x(36) value "ST000 Error on Writing to Stock File".
     03  ST003          pic x(25) value "ST003 Hit return for Menu".
     03  ST005          pic x(18) value "ST005 Invalid Date".
*> Module Specific
     03  ST101          pic x(24) value "ST101 Supplier not found".
     03  ST102          pic x(46) value "ST102 Abbreviated Stock number Must be present".
     03  ST103          pic x(38) value "ST103 Abbreviated Stock number Invalid".
     03  ST104          pic x(46) value "ST104 Purchase Ledger not yet set up, Aborting".
     03  ST105          pic x(46) value "ST105 Purchase Ledger File not found, Aborting".
     03  ST106          pic x(41) value "ST106 Stock File not found, nothing to do".
     03  ST107          pic x(51) value "ST107 Cannot Delete record as non zero values exist".
     03  ST108          pic x(36) value "ST108 Delete failed on Stock File = ".
     03  ST109          pic x(50) value "ST109 Cannot Renumber record as Order values exist".
     03  ST110          pic x(44) value "ST110 Cannot find Sales Ledger Analysis Code".
     03  ST111          pic x(47) value "ST111 Cannot find Purchase Ledger Analysis Code".
     03  ST112          pic x(39) value "ST112 Analysis File not found, Aborting".
     03  ST113          pic x(49) value "ST113 Abbreviated Stock Number is already on file".
     03  ST114          pic x(28) value "ST114 Stock Number not found".
     03  ST115          pic x(38) value "ST115 Construct Stock Number not found".
     03  ST116          pic x(37) value "ST116 Stock Number is already on file".
     03  ST117          pic x(47) value "ST117 Stock Number/Abrev No. is already on file".
     03  ST118          pic x(51) value "ST118 Service Flag is set, so unused values cleared".
     03  ST119          pic x(32) value "ST119 No more records to display".
*>
 01  error-code         pic 999    value zero.
*>
 linkage section.
*>***************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
 01  to-day             pic x(10).
*>
 report section.
*>**************
*>
 rd  Stock-File-Report
     control is final
     page limit is Page-Lines
     heading 1
     first detail 7
     last  detail WS-Page-Lines.
*>
 01  Report-Head-Group type page heading.
*> Print layouts to 132 cols
*>
     03  Line 1.
         05  col   1     pic x(17)   source Prog-Name.
         05  col  58     pic x(17)    value "Stock File Report".
         05  col 125     pic x(5)     value "Page ".
         05  col 130     pic zz9     source Page-Counter.
*>
     03  line 2.
         05  col   1     pic x(40)   source Usera.
         05  col 117     pic x(10)   source ws-ToDate.
         05  col 128     pic x(5)    source ws-Time.
*>
     03  line 4.
         05  col   1     pic x(21)    value "<------ Stock ------>".
         05  col  23     pic x(18)    value "Supplier  Location".
         05  col  46     pic x(4)     value "Unit".
         05  col  56     pic x(4)     value "Unit".
         05  col  68     pic x(5)     value "Value".
         05  col  77     pic x(6)     value "Number".
         05  col  84     pic x(13)    value "<- ReOrder ->".
         05  col  98     pic x(21)    value "<------- Date ------>".
         05  col 122     pic x(11)    value "Quantity On".
*>
     03  line 5.
         05  col   1     pic x(14)    value "Abrev   Number".
         05  col  24     pic x(6)     value "Number".
         05  col  45     pic x(5)     value "Price".
         05  col  56     pic x(4)     value "Cost".
         05  col  68     pic x(6)     value "in Stk".
         05  col  77     pic x(6)     value "in Stk".
         05  col  85     pic x(5)     value "Point".
         05  col  94     pic x(3)     value "Qty".
         05  col 100     pic x(7)     value "Ordered".
         05  col 112     pic x(3)     value "Due".
         05  col 121     pic x(5)     value "Order".
         05  col 128     pic x(5)     value "B/Ord".
*>
 01  Stock-Detail type detail.
     03  line plus 1.
         05      col   1 pic x(7)    source Stock-Abrev-Key.
         05      col   9 pic x(13)   source Stock-Key.
         05      col  23 pic x(7)    source Stock-Supplier-P1.
         05      col  31 pic x(10)   source Stock-Location.
         05      col  42 pic z(6)9.99 source Stock-Retail.
         05      col  52 pic x(12)   source ws-Costx.        *> taken from Stock-Cost
         05      col  64 pic zzzzz,zz9.99 source Stock-Value   present when Stock-Services-Flag not = "Y".
         05      col  76 pic z(6)9   source Stock-Held         present when Stock-Services-Flag not = "Y".
         05      col  83 pic z(6)9   source Stock-ReOrder-Pnt  present when Stock-Services-Flag not = "Y".
         05      col  90 pic z(6)9   source Stock-Std-ReOrder  present when Stock-Services-Flag not = "Y".
         05      col  98 pic x(10)   source ws-Stock-Order-Date.
         05      col 109 pic x(10)   source ws-Stock-Order-Due.
         05      col 119 pic z(6)9   source Stock-On-Order     present when Stock-Services-Flag not = "Y".
         05      col 126 pic z(6)9   source Stock-Back-Ordered present when Stock-Services-Flag not = "Y".
*>
     03  Stock-Detail-2 line plus 1.   *> 2nd-Detail
         05      col   6 pic x(12)  value "Description:".
         05      col  19 pic x(32)  value spaces source Stock-Desc.
         05      col  56 pic x(77)  value spaces source ws-vars.
*>
     03  WIP-Data    line plus 1     present when Stock-Services-Flag not = "Y"
                                             and (Stock-Construct-Bundle not = zero
                                               or Stock-Under-Construction not = zero
                                               or Stock-Work-in-Progress not = zero
                                               or Stock-Construct-Item not = spaces).
         05  rd-Wip-Data col   1     pic x(132)  value spaces.
*>
     03  Service-Non-Dataname line plus 1         present when Stock-Services-Flag = "Y".
         05  col  1  pic x(21)       value "Services only Product".
*>         05  col 22  pic x(111)      value spaces.
*>
*>  Underline previous printed record on a page
*>
     03  Underline-Line line plus 1              present when line-counter > 7 and line-counter < 45
                                                         and ws-EOF not = "Y".
          05      col   1 pic x(132) value all "-".
*>
 01  type control footing final line plus 3.
     03  col 1           pic x(35)  source ws-Print-Total.
     03  col 36          pic x(97)  value spaces.
*>
 screen section.
*>**************
*>
 01  display-01                  background-color cob-color-black
                                 foreground-color cob-color-green erase eos.
     03  value "Stock Number     - [" line  4 col  1.
*>      using stock-key pic x(13) col 21. has an accept verb to get info
     03  value "]"                            col 34.
     03  value "PL Fast key  - ["             col 41.
*>      using Stock-Abrev-key pic x(7) col 57. has an accept verb to get info
     03  value "]"                            col 64.
     03  value "Desc ["               line  5 col  1.
     03  using Stock-Desc pic x(32)           col  7 foreground-color 3.
     03  value "]"                            col 39.
     03  value "Stock Location ["             col 41.
     03  using Stock-Location  pic x(10)      col 57 foreground-color 3.
     03  value "]"                            col 67.
     03  value "Supplier: 1 - ["      line  6 col  1.
     03  using Stock-Supplier-P1 pic x(7)     col 16 foreground-color 3.
     03  value "] : 2 - ["                    col 23.
     03  using Stock-Supplier-P2 pic x(7)     col 32 foreground-color 3.
     03  value "]"                            col 39.
     03  value ": 3 - ["                      col 50.
     03  using Stock-Supplier-P3 pic x(7)     col 57 foreground-color 3.
     03  value "]"                            col 64.
     03  value "Stock Qty        - [" line  7 col  1.
     03  using Stock-Held     pic 9(6)        col 21 foreground-color 3.
     03  value "]"                            col 27.
     03  value "Qty Ordered      - ["         col 41.
     03  using Stock-On-Order pic 9(6)        col 61 foreground-color 3.
     03  value "]"                            col 67.
     03  value "Re-Order Point   - [" line  8 col  1.
     03  using Stock-ReOrder-Pnt pic 9(6)     col 21 foreground-color 3.
     03  value "]"                            col 27.
     03  value "Back Ordered     - ["         col 41.
     03  using Stock-Back-Ordered pic 9(6)    col 61 foreground-color 3.
     03  value "]"                            col 67.
     03  value "Re-Order Qty     - [" line  9 col  1.
     03  using Stock-Std-ReOrder pic 9(6)     col 21 foreground-color 3.
     03  value "]"                            col 27.
     03  value "Sales Orders O/S - ["         col 41.
     03  using Stock-Pre-Sales pic 9(6)       col 61 foreground-color 3.
     03  value "]"                            col 67.
     03  value "Sales Anal. Code - [" line 10 col  1.
     03  using Stock-SA-Group pic xx          col 21 foreground-color 3.
     03  value "]"                            col 23.
     03  value "Purch Anal.Code["             col 41.
     03  using Stock-PA-Group pic xx          col 57 foreground-color 3.
     03  value "]"                            col 59.
     03  value "Services only Flag [" line 11 col  1.
     03  using Stock-Services-Flag pic x      col 21 foreground-color 3.
     03  value "] (Y/N)"                      col 22.
     03  value "Date Ordered - ["     line 12 col  1.
     03  using ws-Stock-Order-Date pic x(10)  col 17 foreground-color 3.
     03  value "]"                            col 27.
     03  value "Date Due     - ["             col 41.
     03  using ws-Stock-Order-Due pic x(10)   col 57 foreground-color 3.
     03  value "]"                            col 67.
*>
*>
*> Escape function box
     03  value "*******************"  line 18 col 61 erase eol.
     03  value "* Escape Code [ ] *"  line 19 col 61 erase eol.
     03  value "* <B> = Back      *"  line 20 col 61 erase eol.
     03  value "* <S> = Save      *"  line 21 col 61 erase eol.
     03  value "* <Q> = Quit      *"  line 22 col 61 erase eol.
     03  value "*******************"  line 23 col 61 erase eol.
*>
 01  Display-01B                  background-color cob-color-black
                                 foreground-color cob-color-green.   *> Display for accepting money amounts
*> these values from accepts
     03  value "Retail Price - ["     line 13 col  1.
*>     03  using Stock-Retail pic 9(7).99       col 17 foreground-color 3.
     03  value "]"                            col 27.
     03  value "Cost   Price - ["             col 41.
*>     03  using Stock-Cost pic 9(7).9999       col 57 foreground-color 3.
     03  value "]"                            col 69.
     03  value "Stock Value  - ["     line 14 col  1.
*>     03  using Stock-Value pic 9(9).99        col 17 foreground-color 3.
     03  value "]"                            col 29.
*>
 01  Display-01C                  background-color cob-color-black
                                 foreground-color cob-color-green.   *> Display for money amounts (Display Only)
*> these values from accepts
     03  value "Retail Price - ["     line 13 col  1.
     03  using Stock-Retail pic 9(7).99       col 17 foreground-color 3.
     03  value "]"                            col 27.
     03  value "Cost   Price - ["             col 41.
     03  using Stock-Cost pic 9(7).9999       col 57 foreground-color 3.
     03  value "]"                            col 69.
     03  value "Stock Value  - ["     line 14 col  1.
     03  using Stock-Value pic 9(9).99        col 17 foreground-color 3.
     03  value "]"                            col 29.
*>
*> used only if Stk-Manu-Used = 1
*>
 01  display-02                  background-color cob-color-black
                                 foreground-color cob-color-green.
     03  value "Optional - Work In Progress (BOMP) Data"
                                      line 15 col 21 highlight.
     03  value "Construct Bundle - [" line 16 col  1.
     03  using Stock-Construct-Bundle pic 9(6) col 21 foreground-color 3.
     03  value "]"                            col 27.
     03  value "Construction   - ["           col 41.
     03  using Stock-Under-Construction pic 9(6)
                                              col 59 foreground-color 3.
     03  value "]"                            col 65.
     03  value "Work In Progress - [" line 17 col  1.
     03  using Stock-Work-in-Progress  pic 9(6)
                                              col 21 foreground-color 3.
     03  value "]"                            col 27.
     03  value "Construct Item - ["           col 41.
     03  using Stock-Construct-Item pic x(13) col 59 foreground-color 3.
     03  value "]"                            col 72.
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>**********************************************************************
*>
*> Declaratives.
*> Detail-Core-Reporting section.
*>     use before reporting Stock-Detail.
*>
*> end declaratives.
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
 aa010-Menu-Return.
     move     zero to Menu-Reply.
     perform  zz010-Display-Heading.
*>
 aa020-Menu-Input.
     if       file-status (11) not = 1
              perform ba000-Setup-Stock
              go to aa010-Menu-Return.

     display  "Select one of the following by number :- [ ]" at 0701 with foreground-color 2.
*>
     display  "(1)  Set-up Stock records"   at 0904 with foreground-color 2.
     display  "(2)  Amend Stock records"    at 1104 with foreground-color 2.
     display  "(3)  Delete Stock records"   at 1304 with foreground-color 2.
     display  "(4)  Renumber Stock records" at 1504 with foreground-color 2.
     display  "(5)  Display Stock records"  at 1704 with foreground-color 2.
     display  "(6)  Print Stock records"    at 1904 with foreground-color 2.
     display  "(9)  Return to system menu"  at 2104 with foreground-color 2.
*>
     accept   Menu-Reply at 0743 with foreground-color 6 auto.
*>
     if       menu-reply = 9
              go to  aa999-Exit.
*>
     if       menu-reply < 1 or > 6
              go to  aa020-Menu-Input.
*>
     if       menu-reply = 1
              perform ba000-Setup-Stock
     else
      if      menu-reply = 2
              perform ca000-Amend-Stock
      else
       if     menu-reply = 3
              perform da000-Delete-Stock
       else
        if    Menu-Reply = 4
              perform ga000-Renumber-Stock
        else
         if   menu-reply = 6
              perform ea000-Report-Stock
         else
          if  menu-reply = 5
              perform fa000-Display-Stock.
*>
     go       to aa010-Menu-Return.
*>
 maps04.
     call     "maps04" using maps03-ws.
*>
 maps09.
     call     "maps09" using customer-code.
*>
 maps99.
     call     "maps99" using error-code ws-calling-data.
*>
 Clear-Error-Line.
     display  " " at line ws-23-lines col 01 with erase eol.
*>
 aa999-Exit.
     exit     program.
*>
 ba000-Setup-Stock      section.
*>*****************************
*>
     open     input Purchase-File.
     if       fs-reply not = zero
              display ST104 at line ws-23-lines col 1 with foreground-color 4 highlight
              move 45 to error-code
              perform  maps99
              exit program.
*>
     open     i-o Stock-File.
     if       fs-reply not = zero
              close       Stock-File
              open output Stock-File           *> OC doesnt create in i-o - possible bug
              close       Stock-File
              open i-o    Stock-File
              move "Y" to Stock-Control
              move 1 to file-status (11).
*>
     if       file-status (15) not = 1			*> Analysis file
              move 1 to ws-Process-Func ws-Sub-Function
              call "sl070" using ws-Calling-Data
                                 System-Record
                                 To-Day
                                 File-Defs
              end-call
              if    File-Status (15) not = 1		*> Only if the call failed for some unknown reason
                    display ST112 at line ws-23-lines col 1 with foreground-color 4 highlight
                    move 45 to error-code
                    close Stock-File Purchase-File
                    perform  maps99
                    go to ba999-exit
              end-if
     end-if
     open     input Analysis-File.
*>
 ba010-Display-Stock-Headings.
     perform  zz020-Display-Outline.
*>
     initialize Stock-Record.
     move     spaces to Stock-Key (13:1)
                        Stock-Abrev-Key (7:1)
                        Customer-Code ws-stock-dates.
     move     "N" to Stock-Services-Flag.
 ba020-Stock-Item-Accept.
     display  " " at 0467.
     accept   Stock-Key at 0421 with foreground-color 3.
     if       Stock-Key = spaces
          or  Cob-Crt-Status = Cob-Scr-Esc
              go to  ba998-Main-End.
     move     function upper-case (Stock-Key) to Stock-Key
                                                 ws-Stock-Key.
     display  Stock-Key at 0421 with foreground-color 3.
*>
 ba030-Stock-Abrev-Item-Accept.
     accept   Stock-Abrev-Key at 0457 with foreground-color 3.
     if       Cob-Crt-Status = Cob-Scr-Esc
          or  Cob-Crt-Status = Cob-Scr-Page_Up
          or  Cob-Crt-Status = Cob-Scr-Key-Up
              go to ba020-Stock-Item-Accept
     end-if
     if       Stock-Abrev-Key not = spaces
              move  function upper-case (Stock-Abrev-Key) to Stock-Abrev-Key
                                                             Customer-Code
              display Stock-Abrev-Key at 0457 with foreground-color 3
              perform  clear-error-line
     else
              display ST102 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ba030-Stock-Abrev-Item-Accept
     end-if
*>
*>  Check that keys do NOT exist
*>
     read     Stock-File key is Stock-Key not invalid key
              display ST113 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ba020-Stock-Item-Accept.
*>
     move     Customer-Code to Stock-Abrev-Key.
     if       Stock-Abrev-Key not = spaces
              read   Stock-File key is Stock-Abrev-Key not invalid key
                     display ST116 at line ws-23-lines col 1 with foreground-color 4 highlight
                     go to ba020-Stock-Item-Accept.
*>
*>  Now, we have unused Stock keys
*>
     perform  clear-error-line.
     move     customer-code to Stock-Abrev-Key.
     move     ws-Stock-Key  to Stock-Key.
*>
 ba040-Accept-Block.
     accept   Display-01.      *> get all data but not money fields
     If       Cob-Crt-Status = Cob-Scr-Esc
              go to ba020-Stock-Item-Accept.
*>
*> If F3 allow set up of a supplier then redisplay heads and data be re-accepting data.
*>   question is, will f1 be detected?
*>
     if       Cob-Crt-Status = COB-SCR-F3
              move     zero to ws-term-code
              call     "pl010" using ws-calling-data system-record to-day file-defs
              perform  zz010-Display-Heading
              display  Display-01
              display  Stock-Key at 0421 with foreground-color 3
              display  Stock-Abrev-Key at 0457 with foreground-color 3
              go       to ba040-Accept-Block.
*>
*>  If Suppliers included, they are now checked for presence on Purchase Ledger
*>
     move     zero to c.
     perform  varying b from 1 by 1 until b > 3
              if       Stock-Suppliers (b) not = spaces
                       move     function upper-case (Stock-Suppliers (b)) to Stock-Suppliers (b)
                                                                             ws-Stock-Supplier
                       perform  zz040-Check-for-Supplier
                       if       Error-Code not = zero
                                multiply b by 2 giving a
                                add      20 to a
                                if       c = zero    *> display only once
                                         move 1 to c
                                         display "Supplier not found : "
                                          at line ws-23-lines col 1 with foreground-color 4 highlight
                                end-if
                                display b at line ws-23-lines col a with foreground-color 4 highlight
                       end-if
                       move     ws-Stock-Supplier to Stock-Suppliers (b)
              end-if
     end-perform
     if       c not = zero
              go to ba040-Accept-Block.
*>
     perform  Clear-Error-Line.
*>
*> If PA or SA anal codes present they are checked for on analysis file.
*>
     move     function lower-case (Stock-pa-Group) to Stock-pa-Group.
     display  Stock-pa-Group at 1057 with foreground-color 3.
     if       Stock-pa-Group not = spaces
              move "P" to Stock-PA-System
              move Stock-PA-Code to PA-Code
              start Analysis-File key = PA-Code invalid key
                    display ST111 at line ws-23-lines col 1 with foreground-color 4 highlight
                    go to ba040-Accept-Block
              end-start
     end-if
*>
     move     function lower-case (Stock-sa-Group) to Stock-sa-Group.
     display  Stock-sa-Group at 1021 with foreground-color 3.
     if       Stock-sa-Group not = spaces
              move "S" to Stock-SA-System
              move Stock-SA-Code to PA-Code
              start Analysis-File key = PA-Code invalid key
                    display ST110 at line ws-23-lines col 1 with foreground-color 4 highlight
                    go to ba040-Accept-Block
              end-start
     end-if
*>
*>   Display and get money fields then WIPs
*>
     display Display-01C.
*>
 ba042-Get-Stock-Retail.
     move     13 to lin.
     move     17 to cole.
     move     Stock-Retail to amt-ok7.
     perform  zz030-accept-money7.
     move     amt-ok7 to Stock-Retail.  *> 9(7).99
 ba044-Get-Stock-Cost.
     move     57 to cole.
     move     Stock-Cost to amt-ok7b.
     perform  zz030-accept-money7b.
     move     amt-ok7b to Stock-Cost.   *> 9(7).9999
 ba046-Get-Stock-Value.
     move     14 to lin.
     move     17 to cole.
     move     Stock-Value to amt-ok9.
     perform  zz030-accept-money9c.
     move     amt-ok9 to Stock-Value.   *> 9(9).99
*>
     if       Stk-Manu-Used = 1
              accept Display-02.
*>
*>  Calc Stock-Value only if Stock-Averaging is set
*>
     if       Stock-Averaging
         and  Stock-Value = zero
         and  Stock-Cost not = zero
         and  Stock-Held not = zero
              multiply Stock-Held by Stock-Cost giving Stock-Value
              if Stk-Manu-Used = 1
                 compute Stock-Value = Stock-Value + (Stock-Cost * Stock-Work-in-Progress).
*>
     if       ws-Stock-Order-Date not = spaces
              move ws-Stock-Order-Date to ws-Test-Date
              perform zz050-Validate-Date
              if u-bin not = zero
                 move u-bin to Stock-Order-Date
                 display " " at 1228
              else
                 display ST005 at line ws-23-lines col 1 with foreground-color 4 highlight
                 display "*" at 1228 with foreground-color 4 highlight
                 go to ba040-Accept-Block.
*>
     if       ws-Stock-Order-Due not = spaces
              move ws-Stock-Order-Due to ws-Test-Date
              perform zz050-Validate-Date
              if u-bin not = zero
                 move u-bin to Stock-Order-Due
                 display " " at 1268
              else
                 display ST005 at line ws-23-lines col 1 with foreground-color 4 highlight
                 display "*" at 1268 with foreground-color 4 highlight
                 go to ba040-Accept-Block.
*>
     display  " " at 1228.  *> incase 1st was entered then spaces 2nd.
     display  " " at 1268.
     perform  Clear-Error-Line.
*>
     if       Stock-Construct-Item not = spaces
              move    function upper-case (Stock-Construct-Item) to Stock-Construct-Item
                                                                    ws-contruct-key
              display Stock-Construct-Item at 1659 with foreground-color 3
              move    Stock-Record to ws-saved-stock-record
              move    ws-contruct-key to Stock-Key
              start   Stock-File key = Stock-key invalid key
                      display ST115 at line ws-23-lines col 1 with foreground-color 4 highlight
                      move  ws-saved-stock-record to Stock-Record
                      go    to ba040-Accept-Block
              end-start
              move     ws-saved-stock-record to Stock-Record
     end-if
*>
*> if stock-services-flag set clear down unneeded values inc. WIP & redisplay
*>
     if       Stock-Services-Flag not = space
              move function upper-case (Stock-Services-Flag) to Stock-Services-Flag.
     if       Stock-Services-Flag = "Y"
              move spaces to Stock-Construct-Item ws-Stock-Order-Due ws-Stock-Order-Date
              move zero to Stock-Construct-Bundle  Stock-Under-Construction
                           Stock-Work-in-Progress  Stock-ReOrder-Pnt
                           Stock-Std-ReOrder       Stock-Back-Ordered
                           Stock-On-Order          Stock-Pre-Sales
                           Stock-Value
                           Stock-Order-Due         Stock-Order-Date
              display  display-01
              display  display-01C
              if       Stk-Manu-Used = 1
                       display Display-02
              end-if
              display ST118 at line ws-23-lines col 1 with foreground-color 2 highlight
     end-if
     move     "S" to Escape-Code.
     perform  zz100-Test-Escape.
*>
 ba050-Main-Output.
     if       escape-code = "Q"
         or   Cob-Crt-Status = Cob-Scr-Esc
              go to  ba998-Main-End.
*>
     if       escape-code = "B"
         or   Cob-Crt-Status = Cob-Scr-Page_Up
          or  Cob-Crt-Status = Cob-Scr-Key-Up
              go to ba020-Stock-Item-Accept.
*>
     write    stock-record.
     if       fs-reply not = zero
              display ST000 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 38 with foreground-color 4 highlight
              move 45 to Error-Code
              perform maps99
              go to ba998-Main-End.
*>
     initialize Stock-Record.
     move     spaces to ws-stock-dates.
     go       to ba010-Display-Stock-Headings.
*>
 ba998-Main-End.
     close    Stock-File Analysis-File Purchase-File.
*>
 ba999-Exit.
     exit     section.
*>
 ca000-Amend-Stock          section.
*>*********************************
*>  can any of this be removed ???????
     open     input Purchase-File.
     if       fs-reply not = zero
              display ST105 at line ws-23-lines col 1 with foreground-color 4 highlight
              move 45 to error-code
              perform  maps99
              go to ca999-exit.
*>
     open     i-o Stock-File.
     if       fs-reply not = zero
              close       Stock-File
              open output Stock-File    *> OC doesnt create in i-o
              close       Stock-File
              open i-o    Stock-File
              move "Y" to Stock-Control
              move 1 to File-Status (11)
              display ST106 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ca998-Main-End.
*>
     open     input Analysis-File.
     if       fs-reply not = zero
              display ST112 at line ws-23-lines col 1 with foreground-color 4 highlight
              move 45 to error-code
              close Stock-File Purchase-File
              perform  maps99
              go to ca999-exit.
*>
 ca010-Display-Stock-Headings.
     perform  zz020-Display-Outline.
*>
 ca020-Stock-Item-Accept.
     initialize Stock-Record.
     move     spaces to Stock-Key (13:1)
                        Stock-Abrev-Key (7:1)
                        Customer-Code ws-stock-dates.
     display  " " at 0467.
     accept   Stock-Key at 0421 with foreground-color 3.
     if       Stock-Key = spaces
          or  Cob-Crt-Status = Cob-Scr-Esc
              go to  ca998-Main-End.
     move     function upper-case (Stock-Key) to Stock-Key
                                                 ws-Stock-Key.
*>
 ca030-Get-Record.
     read     Stock-File record key Stock-Key invalid key
              display ST114 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ca020-Stock-Item-Accept.
     display  Stock-Key at 0421 with foreground-color 3.
     display  Stock-Abrev-Key at 0457 with foreground-color 3.
     perform  Clear-Error-Line.
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
     end-if
*>
*> redisplay now dates are converted
*>
     display  display-01.
     display  Stock-Key at 0421 with foreground-color 3.
     display  Stock-Abrev-Key at 0457 with foreground-color 3.
*>
 ca040-Accept-Block.
     accept   display-01.      *> get all data but not money fields
     If       Cob-Crt-Status = Cob-Scr-Esc
              go to ca020-Stock-Item-Accept.
*>
*> If F3 allow set up of a supplier then redisplay heads and data be re-accepting data.
*>   question is, will f1 be detected?
*>
     if       Cob-Crt-Status = COB-SCR-F3
              move     zero to ws-term-code
              call     "pl010" using ws-calling-data system-record to-day file-defs
              perform  zz010-Display-Heading
              display  Display-01
              display  Stock-Key at 0421 with foreground-color 3
              display  Stock-Abrev-Key at 0457 with foreground-color 3
              go       to ca040-Accept-Block.
*>
*>  If Suppliers included, they are now checked for presence on Purchase Ledger
*>
     move     zero to c.
     perform  varying b from 1 by 1 until b > 3
              if       Stock-Suppliers (b) not = spaces
                       move     function upper-case (Stock-Suppliers (b)) to Stock-Suppliers (b)
                                                                             ws-Stock-Supplier
                       perform  zz040-Check-for-Supplier
                       if       Error-Code not = zero
                                multiply b by 2 giving a
                                add      20 to a
                                if       c = zero    *> display only once
                                         move 1 to c
                                         display "Supplier not found : "
                                                    at line ws-23-lines col 1 with foreground-color 4 highlight
                                end-if
                                display b at line ws-23-lines col a with foreground-color 4 highlight
                       end-if
                       move     ws-Stock-Supplier to Stock-Suppliers (b)
              end-if
     end-perform
     if       c not = zero
              go to ca040-Accept-Block.
*>
     perform  Clear-Error-Line.
*>
*> If PA or SA anal codes present they are checked for on analysis file.
*>
     move     function lower-case (Stock-pa-Group) to Stock-pa-Group.
     display  Stock-pa-Group at 1057 with foreground-color 3.
     if       Stock-pa-Group not = spaces
              move "P" to Stock-PA-System
              move Stock-PA-Code to PA-Code
              start Analysis-File key = PA-Code invalid key
                   display ST111 at line ws-23-lines col 1 with foreground-color 4 highlight
                   go to ca040-Accept-Block
              end-start
     end-if
*>
     move     function lower-case (Stock-sa-Group) to Stock-sa-Group.
     display  Stock-sa-Group at 1021 with foreground-color 3.
     if       Stock-sa-Group not = spaces
              move "S" to Stock-SA-System
              move Stock-SA-Code to PA-Code
              start Analysis-File key = PA-Code invalid key
                   display ST110 at line ws-23-lines col 1 with foreground-color 4 highlight
                   go to ca040-Accept-Block
              end-start
     end-if
*>
*>   Display and get money fields then WIPs
*>
     display Display-01C.
*>
 ca042-Get-Stock-Retail.
     move     13 to lin.
     move     17 to cole.
     move     Stock-Retail to amt-ok7.
     perform  zz030-accept-money7.
     move     amt-ok7 to Stock-Retail.  *> 9(7).99
 ca044-Get-Stock-Cost.
     move     57 to cole.
     move     Stock-Cost to amt-ok7b.
     perform  zz030-accept-money7b.
     move     amt-ok7b to Stock-Cost.   *> 9(7).9999
 ca046-Get-Stock-Value.
     move     14 to lin.
     move     17 to cole.
     move     Stock-Value to amt-ok9.
     perform  zz030-accept-money9c.
     move     amt-ok9 to Stock-Value.   *> 9(9).99
*>
     if       Stk-Manu-Used = 1
              accept Display-02.
*>
*>  Calc Stock-Value only if Stock-Averaging is set
*>
     if       Stock-Averaging
         and  Stock-Value = zero
         and  Stock-Cost not = zero
         and  Stock-Held not = zero
              multiply Stock-Held by Stock-Cost giving Stock-Value.
              if Stk-Manu-Used = 1
                 compute Stock-Value = Stock-Value + (Stock-Cost * Stock-Work-in-Progress).
*>
     if       ws-Stock-Order-Date not = spaces
              move ws-Stock-Order-Date to ws-Test-Date
              perform zz050-Validate-Date
              if u-bin not = zero
                 move u-bin to Stock-Order-Date
                 display " " at 1228
              else
                 display ST005 at line ws-23-lines col 1 with foreground-color 4 highlight
                 display "*" at 1228 with foreground-color 4 highlight
                 go to ca040-Accept-Block.
*>
     if       ws-Stock-Order-Due not = spaces
              move ws-Stock-Order-Due to ws-Test-Date
              perform zz050-Validate-Date
              if u-bin not = zero
                 move u-bin to Stock-Order-Due
                 display " " at 1268
              else
                 display ST005 at line ws-23-lines col 1 with foreground-color 4 highlight
                 display "*" at 1268 with foreground-color 4 highlight
                 go to ca040-Accept-Block.
*>
     display  " " at 1228.  *> incase 1st was entered then spaces 2nd.
     display  " " at 1268.
     perform  Clear-Error-Line.
*>
     if       Stock-Construct-Item not = spaces
              move    function upper-case (Stock-Construct-Item) to Stock-Construct-Item
                                                                    ws-contruct-key
              display Stock-Construct-Item at 1659 with foreground-color 3
              move    Stock-Record to ws-saved-stock-record
              move    ws-contruct-key to Stock-Key
              start   Stock-File key = Stock-key invalid key
                      display ST115 at line ws-23-lines col 1 with foreground-color 4 highlight
                      move   ws-saved-stock-record to Stock-Record
                      go to ca040-Accept-Block
              end-start
              move     ws-saved-stock-record to Stock-Record
     end-if
*>
*> if stock-services-flag set clear down unneeded values inc. WIP & redisplay
*>
     if       Stock-Services-Flag not = space
              move function upper-case (Stock-Services-Flag) to Stock-Services-Flag.
     if       Stock-Services-Flag = "Y"
              move spaces to Stock-Construct-Item ws-Stock-Order-Due ws-Stock-Order-Date
              move zero to Stock-Construct-Bundle  Stock-Under-Construction
                           Stock-Work-in-Progress Stock-ReOrder-Pnt
                           Stock-Std-ReOrder      Stock-Back-Ordered
                           Stock-On-Order         Stock-Pre-Sales
                           Stock-Value
                           Stock-Order-Due        Stock-Order-Date
              display  display-01
              display  display-01C
              if       Stk-Manu-Used = 1
                       display Display-02
              end-if
              display ST118 at line ws-23-lines col 1 with foreground-color 2 highlight
     end-if
     move     "S" to escape-code.
     perform  zz100-test-escape.
*>
 ca050-Main-Output.
     if       escape-code = "Q"
         or   Cob-Crt-Status = Cob-Scr-Esc
              go to  ca998-main-end.
*>
     if       escape-code = "B"
         or   Cob-Crt-Status = Cob-Scr-Page_Up
          or  Cob-Crt-Status = Cob-Scr-Key-Up
              go to ca020-Stock-Item-Accept.
*>
     rewrite  stock-record.
     if       fs-reply not = zero
              display ST000 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 38 with foreground-color 4 highlight
              move 45 to error-code
              perform maps99
              go to ca998-main-end.
*>
     initialize Stock-record.
     move     spaces to ws-stock-dates.
     go       to ca010-Display-Stock-Headings.
*>
 ca998-Main-End.
     close    Stock-File Analysis-File Purchase-File.
*>
 ca999-Exit.
     exit     section.
*>
 da000-Delete-Stock         section.
*>*********************************
*>
     open     i-o stock-file.
     if       fs-reply not = zero
              close Stock-File
              display ST106 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to da999-Exit.
*>
 da010-Display-Stock-Headings.
     perform  zz020-Display-Outline.
*>
 da020-Stock-Item-Accept.
     move     spaces to Stock-Key
                        Stock-Abrev-Key
                        Customer-Code.
     display  " " at 2361 with erase eol.
     display  display-01.
     if       Stk-Manu-Used = 1
              display Display-02.
     accept   Stock-Key at 0421 with foreground-color 3.
     if       Stock-Key = spaces
          or  Cob-Crt-Status = Cob-Scr-Esc
              close Stock-File
              go to da999-Exit.
     move     function upper-case (Stock-Key) to Stock-Key
                                                 ws-Stock-Key.
     display  " " at line ws-23-lines col 1 with erase eos.
*>
 da030-Get-Record.
     read     Stock-File record key Stock-Key invalid key
              display ST114 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to da020-Stock-Item-Accept.
     display  Stock-Key at 0421 with foreground-color 3.
     display  Stock-Abrev-Key at 0457 with foreground-color 3.
     perform  Clear-Error-Line.
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
     end-if
*>
*> redisplay now dates are converted
*>
     display  display-01.
     if       Stk-Manu-Used = 1
              display Display-02.
     display  "* <D> = Delete    *" at 2261 with foreground-color 2.
     display  "*******************" at 2361 with foreground-color 2.
     display  Stock-Key at 0421 with foreground-color 3.
     display  Stock-Abrev-Key at 0457 with foreground-color 3.
*>
     if       Stock-On-Order not = zero
           or Stock-Held not = zero
           or Stock-Back-Ordered not = zero
              display ST107 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to da020-Stock-Item-Accept.
*>
     move     "D" to escape-code.
     perform  zz100-test-escape.
*>
     if       escape-code = "Q"
         or   Cob-Crt-Status = Cob-Scr-Esc
              go to  da999-Exit.
*>
     if       escape-code = "B" or = "S"
         or   Cob-Crt-Status = Cob-Scr-Page_Up
          or  Cob-Crt-Status = Cob-Scr-Key-Up
              go to da020-Stock-Item-Accept.
*>
     if       escape-code not = "D"
              go to  da010-Display-Stock-Headings.

 da040-Accept-Delete.
     display  "Deleting Stock Item record, are you sure? [ ]"
                at line ws-22-lines col 1 with foreground-color 2 highlight.
     accept   ws-reply at line ws-22-lines col 44 with foreground-color 6.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply not = "Y" and not = "N"
              go to da040-Accept-Delete.
*>
     if       ws-reply = "N"
              go to da010-Display-Stock-Headings.
     display  " " at line ws-22-lines col 1 with erase eol.
*>
     delete   Stock-File Record.
     if       fs-reply not = zero
              display ST108 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 37 with foreground-color 4 highlight
              move 15 to error-code
              perform maps99.
*>
     go       to  da010-Display-Stock-Headings.
*>
 da999-Exit.
     exit     section.
*>
 ea000-Report-Stock         section.
*>*********************************
*>
*> Used here as a full print. For other options see st030 (Stock Reports)
*>
     open     input Stock-File.
     if       fs-reply not = zero
              close Stock-File
              display ST106 at line ws-23-lines col 1 with foreground-color 4 highlight
              exit section
     end-if
     open     output Print-File.
*>
*> Set up the variables & constants for heads
*>
     move     zero to ws-Rec-Cnt.
     subtract 1 from Page-Lines giving ws-Page-Lines.
     move     spaces to ws-Print-Total.  *> incase prog print more than once in same run.
     move     To-Day to u-Date.
     perform  zz020-convert-date.
     move     u-Date to ws-ToDate.
     accept   hdtime from time.
     if       hdtime not = "00000000"
              move hd-hh to WS-HH
              move hd-mm to WS-MM
     else
              move spaces to WS-Time
     end-if
*>
     initiate Stock-File-Report.
     perform  ea200-Produce-Report.
     terminate Stock-File-Report.
     close    Stock-File Print-File.
     call     "SYSTEM" using Print-Report.
*>
 ea999-exit.
     exit     section.
*>
 ea200-Produce-Report       section.
*>*********************************
*>
*>
 ea210-Read-Stock.
     read     Stock-File next record at end
              move "Y" to ws-Eof
              move     ws-Rec-Cnt to ws-Rec-Total
              string   " Total Stock Records " delimited by size
                       function trim (ws-Rec-Total leading) delimited by size into ws-Print-Total
              end-string
              exit     section.
*>              go to ea230-Totals.
*>
     perform a00-Detail-Core.
     if       line-counter > 7 and < 45 and ws-Eof not = "Y"
              generate Underline-Line
     end-if
     generate Stock-Detail.                                   *> changed from RD name
     generate Stock-Detail-2.                                 *> see if line 2 now printed
*>     if       ws-Print-Line-Flag = 1
     generate WIP-Data.
*>     end-if
*>     if       Stock-Services-Flag = "Y"
*>              move 1 to ws-Services-Flag
              generate Service-Non-Dataname.
*>     else
*>              move zero to ws-Services-Flag
*>     end-if
*>
     go       to ea210-Read-Stock.
*>
 ea230-Totals.
*>
*>  Total, setup as final
*>
     move     ws-Rec-Cnt to ws-Rec-Total.
     string   " Total Stock Records " delimited by size
              function trim (ws-Rec-Total leading) delimited by size into ws-Print-Total.
*>
 ea299-Exit.
     exit     section.
*>
 a00-Detail-Core section.
     add      1 to ws-Rec-Cnt.
*>
     if       Stock-Order-Date not = zero
              move Stock-Order-Date to u-bin
              perform a01-Reform-Date
              move ws-date to ws-Stock-Order-Date
     else
              move spaces to ws-Stock-Order-Date
     end-if
     if       Stock-Order-Due not = zero
              move Stock-Order-Due to u-bin
              perform a01-Reform-Date
              move ws-date to ws-Stock-Order-Due
     else
              move spaces to ws-Stock-Order-Due
     end-if
     move     Stock-Cost to ws-Cost.
     if       ws-Costz = "00"
              move spaces to ws-Costz
     end-if
*>
     move     1 to a.
     move     spaces to ws-vars.
     if       Stock-Supplier-P2 not = spaces
           or Stock-Supplier-P3 not = spaces
              string "Secondary Suppliers" delimited by size into ws-vars pointer a
              if  Stock-Supplier-P2 not = spaces
                  string " 1: "            delimited by size
                         Stock-Supplier-P2 delimited by size into ws-vars pointer a
              end-if
              if  Stock-Supplier-P3 not = spaces
                  string " 2: "            delimited by size
                         Stock-Supplier-P3 delimited by size into ws-vars pointer a
              end-if
              add 2 to a
     end-if
     if       Stock-SA-Code not = spaces
              string "SA Code: "           delimited by size
                     Stock-SA-Group        delimited by size into ws-vars pointer a
              add 2 to a
     end-if
     if       Stock-PA-Code not = spaces
              string "PA Code: "           delimited by size
                     Stock-PA-Group        delimited by size into ws-vars pointer a
     end-if
*>
     if       Stock-Pre-Sales not = zero
              move Stock-Pre-Sales to ws-z6
              string "  Pre Sales :"       delimited by size
                     ws-z6                 delimited by size into ws-vars pointer a
     end-if.
*>
*> Should we do WIP here or somewhere else ??? WELL lets try here
*>
*>  Now need to program this block into RW somehow so that the line ONLY print if
*>     data present e.g., WIP data exists or we have a services only item
*>
     move     spaces to rd-Wip-Data.
     if       Stock-Services-Flag not = "Y"
          and (Stock-Construct-Bundle not = zero or Stock-Under-Construction not = zero
           or Stock-Work-in-Progress not = zero or Stock-Construct-Item not = spaces)
              move Stock-Construct-Bundle   to ws-z6
              move Stock-Under-Construction to ws-z6b
              move Stock-Work-in-Progress   to ws-z6c
              string "Construction Bundle :"    delimited by size
                     ws-z6                      delimited by size
                     "  WIP :"                  delimited by size
                     ws-z6c                     delimited by size
                     "  Under Construction :"   delimited by size
                     ws-z6b                     delimited by size
                     " For Constructed Item : " delimited by size
                     Stock-Construct-Item       delimited by size
                                into rd-Wip-Data
              end-string
              move 1 to ws-Print-Line-Flag
     else
              move zero to ws-Print-Line-Flag
     end-if .
*>
 a00-Exit.    Exit section.
*>
 a01-Reform-Date        section.
*>*****************************
*>
*>  Converts date in binary to UK/USA/Intl date format (Same as zz060)
*>********************************************************************
*> Input:   u-bin
*> output:  ws-date as uk/US/Inlt date format
*>          u-date & ws-Date = spaces if invalid date
*>
     call     "maps04" using maps03-ws.
     if       u-date = spaces
              move spaces to ws-Date
              go to a01-Exit.
     move     u-date to ws-date.
*>
     if       Date-Form = zero
              move 1 to Date-Form.
     if       Date-UK
              go to a01-Exit.
     if       Date-USA                *> swap month and days
              move ws-days to ws-swap
              move ws-month to ws-days
              move ws-swap to ws-month
              go to a01-Exit.
*>
*> So its International date format
*>
     move     "ccyy/mm/dd" to ws-date.  *> swap Intl to UK form
     move     u-date (7:4) to ws-Intl-Year.
     move     u-date (4:2) to ws-Intl-Month.
     move     u-date (1:2) to ws-Intl-Days.
*>
 a01-Exit.
     exit     section.
 fa000-Display-Stock        section.
*>*********************************
*>
     open     input stock-file.
     if       fs-reply not = zero
              close stock-file
              display ST106 at line ws-23-lines col 1 with foreground-color 4 highlight
              display ST003 at line ws-lines col 1 with foreground-color 4 highlight
              go to fa999-Exit.
*>
 fa010-Display-Stock-Headings.
     perform  zz020-Display-Outline.
*>
 fa020-Stock-Item-Accept.
     move     spaces to Stock-Key
                        Stock-Abrev-Key
                        Customer-Code.
     display  display-01.
     display  display-01C.
     if       Stk-Manu-Used = 1
              display Display-02.
     accept   Stock-Key at 0421 with foreground-color 3.
*>
*> test to see if can save function key values!!!
*>
     if       Stock-Key = spaces
          or  Cob-Crt-Status = Cob-Scr-Esc
              close Stock-File
              go to fa999-Exit.
     if       ws-Cob-Crt-Status = Cob-Scr-F1
              move "*" to Stock-Key.
     move function upper-case (Stock-Key) to Stock-Key
                                             ws-Stock-Key.
*>
 fa030-Get-Record.
*>
*>  if a * entered then we will go though all stock records sequentially
*>
     if       ws-Stock-Key (1:1) = "*"
              read     Stock-File next record at end
                       display ST119 at line ws-23-lines col 1 with foreground-color 4 highlight
                       display ST003 at line ws-lines col 1 with foreground-color 4 highlight
                       go to fa020-Stock-Item-Accept
              end-read
     else
              read     Stock-File record key Stock-Key invalid key
                       display ST114 at line ws-23-lines col 1 with foreground-color 4 highlight
                       display ST003 at line ws-lines col 1 with foreground-color 4 highlight
                       go to fa020-Stock-Item-Accept
              end-read
     end-if
     display  Stock-Key at 0421 with foreground-color 3.
     display  Stock-Abrev-Key at 0457 with foreground-color 3.
     perform  Clear-Error-Line.
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
     end-if
*>
*> redisplay now dates are converted
*>
     display  display-01.
     display  display-01C.
     if       Stk-Manu-Used = 1
              display Display-02.
     display  Stock-Key at 0421 with foreground-color 3.
     display  Stock-Abrev-Key at 0457 with foreground-color 3.
*>
     if       ws-Stock-Key = "*"
              move "N" to Escape-Code
              display "N> = Next  " at line 20 col 64 with foreground-color cob-color-green
     else
              move "S" to Escape-Code.
     perform  zz100-test-escape.
*>
     if       Escape-Code = "N"                  *> Get next record
         or   Cob-Crt-Status = Cob-Scr-F1
              go to fa030-Get-Record.
     if       escape-code = "Q"
         or   Cob-Crt-Status = Cob-Scr-Esc
              close Stock-File
              go to  fa999-Exit.
*>
     go       to  fa010-Display-Stock-Headings.  *> S will redisplay heads etc
*>
 fa999-Exit.
     exit     section.
*>
 ga000-Renumber-Stock        section.
*>**********************************
*>
     open     i-o stock-file.
     if       fs-reply not = zero
              close Stock-File
              display ST106 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ga999-Exit.
*>
 ga010-Display-Stock-Headings.
     perform  zz020-Display-Outline.
*>
 ga020-Stock-Item-Accept.
     move     spaces to Stock-Key
                        Stock-Abrev-Key
                        Customer-Code.
     display  " " at 2361 with erase eol.
     display  display-01.
     display  Display-01C.
     if       Stk-Manu-Used = 1
              display Display-02.
     accept   Stock-Key at 0421 with foreground-color 3.
     if       Stock-Key = spaces
          or  Cob-Crt-Status = Cob-Scr-Esc
              close Stock-File
              go to ga999-Exit.
     move     function upper-case (Stock-Key) to Stock-Key
                                                 ws-Stock-Key.
     display  " " at line ws-23-lines col 1 with erase eos.
*>
 ga030-Get-Record.
     read     Stock-File record key Stock-Key invalid key
              display ST114 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ga020-Stock-Item-Accept.
     display  Stock-Key at 0421 with foreground-color 3.
     display  Stock-Abrev-Key at 0457 with foreground-color 3.
     perform  Clear-Error-Line.
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
     end-if
*>
*> redisplay now dates are converted
*>
     display  display-01.
     display  Display-01C.
     if       Stk-Manu-Used = 1
              display Display-02.
*>
*> Get and process new Stock and Abrev keys
*>
     display  "Stock Number     - [" at 1601 with foreground-color 2 erase eol.
     display  "]" at 1634 with foreground-color 2.
     display  "PL Fast key  - [" at 1641 with foreground-color 2.
     display  "]" at 1664 with foreground-color 2.
*>
     display  "* <R> = Renumber  *" at 2261 with foreground-color 2.
     display  "*******************" at 2361 with foreground-color 2.
     display  Stock-Key at 0421 with foreground-color 3.
     display  Stock-Abrev-Key at 0457 with foreground-color 3.
*>
     if       Stock-On-Order not = zero
           or Stock-Back-Ordered not = zero
              display ST109 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ga020-Stock-Item-Accept.
*>
     move     Stock-Key to ws-Stock-Key ws-Save-Stock-Key.
     move     Stock-Abrev-Key to ws-Abrev-Key ws-Save-Abrev-Key.

 ga040-Accept-New-Stock-No.
     accept   ws-Stock-Key at 1621 with foreground-color 3 update.
     if       ws-Stock-Key = spaces
           or Cob-Crt-Status = Cob-Scr-Esc
              go to ga010-Display-Stock-Headings.
*>
     move     function upper-case (ws-Stock-Key) to ws-Stock-Key.
     display  Stock-Key at 1621 with foreground-color 3.
*>
     accept   ws-Abrev-Key at 1657 with foreground-color 3.
     if       Cob-Crt-Status = Cob-Scr-Esc
          or  Cob-Crt-Status = Cob-Scr-Page_Up
          or  Cob-Crt-Status = Cob-Scr-Key-Up
              go to ga040-Accept-New-Stock-No.
*>
     if       ws-Abrev-Key not = spaces
              move    function upper-case (ws-Abrev-Key) to ws-Abrev-Key
              perform clear-error-line
     else
              display ST102 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ga040-Accept-New-Stock-No.
*>
     move     "R" to escape-code.
     perform  zz100-test-escape.
     if       escape-code = "Q"
         or   Cob-Crt-Status = Cob-Scr-Esc
              go to  ga999-Exit.
*>
     if       escape-code = "B" or = "S"
         or   Cob-Crt-Status = Cob-Scr-Page_Up
          or  Cob-Crt-Status = Cob-Scr-Key-Up
              go to ga020-Stock-Item-Accept.
*>
     if       escape-code not = "R"
              go to  ga010-Display-Stock-Headings.
*>
 ga050-Accept-Renumber.
     display  "Renumbering Stock Item record, are you sure? [ ]"
                at line ws-22-lines col 1 with foreground-color 2 highlight.
     accept   ws-reply at line ws-22-lines col 47 with foreground-color 6.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply not = "Y" and not = "N"
              go to ga050-Accept-Renumber.
*>
     if       ws-reply = "N"
              go to ga010-Display-Stock-Headings.
     display  " " at line ws-22-lines col 1 with erase eol.
*>
     move     ws-Stock-Key to Stock-Key.
     move     ws-Abrev-Key to Stock-Abrev-Key.
     write    stock-record.
     if       fs-reply = 22
              display ST117 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ga040-Accept-New-Stock-No.
     if       fs-reply not = zero
              display ST000 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 38 with foreground-color 4 highlight
              move 45 to Error-Code
              perform maps99
              close Stock-File
              go to ga999-Exit.
*>
*>  Created record with new stock number so can delete old one
*>
     move     ws-Save-Stock-Key to Stock-Key.
     move     ws-Save-Abrev-key to Stock-Abrev-Key.
     delete   Stock-File Record.
     if       fs-reply not = zero
              display ST108 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 37 with foreground-color 4 highlight
              move 15 to error-code
              perform maps99.
*>
     go       to  ga010-Display-Stock-Headings.
*>
 ga999-Exit.
     exit     section.
*>
*>****************************************************
*>               Common Routines Block               *
*>****************************************************
*>
 zz010-Display-Heading      section.
*>*********************************
*>
     if       menu-reply not = 4
              display prog-name at 0101 with foreground-color 2 erase eos
              display  usera at 0301 with foreground-color 3
              perform zz020-convert-date
              display u-date at 0171 with foreground-color 2.
*>
     if       menu-reply = zero
              display "Stock File Set-Up & Maintenance" at 0124 with foreground-color 2
              display "Function  Menu"         at 0434 with foreground-color 2
     else
       if     menu-reply = 1
              display "Stock Record Creation"  at 0129 with foreground-color 2
       else
        if    menu-reply = 2
              display "Stock Record Amendment" at 0129 with foreground-color 2
        else
         if   menu-reply = 3
              display "Stock Record Deletion"  at 0129 with foreground-color 2
         else
          if  menu-reply = 5
              display "Stock Record Display"   at 0129 with foreground-color 2.
*>
     go       to zz010-Exit.
*>
 zz020-convert-date.
*>
*> Convert from UK to selected form
*>
     move     to-day to u-date.
     if       Date-USA
              move u-date to ws-date
              move ws-days to ws-swap
              move ws-month to ws-days
              move ws-swap to ws-month
              move ws-date to u-date
     end-if
     if       Date-Intl
              move "ccyy/mm/dd" to ws-date   *> swap Intl to UK form
              move u-date (7:4) to ws-Intl-Year
              move u-date (4:2) to ws-Intl-Month
              move u-date (1:2) to ws-Intl-Days
              move ws-date to u-date
     end-if.
*>
 zz010-exit.
     exit     section.
*>
 zz020-Display-Outline      section.
*>*********************************
*>
     perform  zz010-Display-Heading.
     initialize Stock-Record.
     move     spaces to Stock-Key Stock-Abrev-key ws-stock-dates.
     display  Display-01.
*>     if       Stk-Manu-Used = 1
*>              display Display-02.
*>
 zz020-exit.
     exit     section.
*>
 zz030-common-routines      section.
*>*********************************
*>
 zz030-accept-money7.  *> USED
     move     amt-wk-pence7 to ws-pence7.
     move     amt-wk-pds7 to ws-pound7.
     display  ws-amount-screen-display7 at curs with foreground-color 3.
     accept   ws-amount-screen-accept7  at curs with foreground-color 3 update.
     move     ws-pound7 to amt-wk-pds7.
     move     ws-pence7 to amt-wk-pence7.
*>
 zz030-accept-money7b.  *> USED
     move     amt-wk-pence7b to ws-pence7b.
     move     amt-wk-pds7b to ws-pound7b.
     display  ws-amount-screen-display7b at curs with foreground-color 3.
     accept   ws-amount-screen-accept7b  at curs with foreground-color 3 update.
     move     ws-pound7b to amt-wk-pds7b.
     move     ws-pence7b to amt-wk-pence7b.
*>
 zz030-accept-money9a.	*> Not used
     move     zero to ws-poundsd9 ws-penced9 amt-ok9.
*>
 zz030-accept-money9b.	*> Not used
     display  ws-amount-screen-display9 at curs with foreground-color 3.
     accept   ws-amount-screen-accept9  at curs with foreground-color 3 update.
     move     ws-pound9 to amt-wk-pds9.
     move     ws-pence9 to amt-wk-pence9.
*>
 zz030-accept-money9c.  *> USED
     move     amt-wk-pence9 to ws-pence9.
     move     amt-wk-pds9 to ws-pound9.
     display  ws-amount-screen-display9 at curs with foreground-color 3.
     accept   ws-amount-screen-accept9  at curs with foreground-color 3 update.
     move     ws-pound9 to amt-wk-pds9.
     move     ws-pence9 to amt-wk-pence9.
*>
 zz030-exit.
     exit     section.
*>
 zz040-Check-for-Supplier   section.
*>*********************************
*>
     move     zero to Error-Code.
     if       ws-Stock-Supplier = spaces
              go to zz040-Exit.
     if       ws-Stock-Supp-7 = space
              move ws-Stock-Supplier to customer-code
              move "C" to maps09-reply
              perform maps09
              if  maps09-reply not = "Y"
                  move 2 to Error-Code
                  display ST103 at line ws-23-lines col 1 with foreground-color 4 highlight
                  go to zz040-Exit
              else
                  move Customer-Code to ws-Stock-Supplier.
*>
     move     ws-Stock-Supplier to Purch-Key.
     read     purchase-file  not invalid key
              go to  zz040-Exit.
     move     1 to Error-Code.
     display  ST101 at line ws-23-lines col 1 with foreground-color 4 highlight.
*>
 zz040-Exit.
     exit     section.
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
 zz100-test-escape          section.
*>*********************************
*>
     display  escape-code at 1976 with foreground-color 6.
*>
 zz100-get-escape.
     accept   escape-code at 1976 with foreground-color 6 update.
     move     function upper-case (escape-code) to escape-code.
*>
     if       escape-code not = "B" and not = "S" and not = "Q"
                      and not = "K" and not = "D" and not = "R"
                      and not = "C" and not = "N"
              go to zz100-get-escape.
*>
 zz100-exit.
     exit     section.
*>
