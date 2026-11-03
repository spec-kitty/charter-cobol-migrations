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
*> copy "envdiv.cob".
 configuration section.
 source-computer.      Linux.
 object-computer.      Linux.
*> special-names.
*>     console is crt.
 input-output            section.
*>-------------------------------
*>
 file-control.
*>------------
*>
*> copy "selstock.cob".
*>
     select  Stock-File      assign               File-11
                             access               dynamic
                             organization         indexed
                             status               Fs-Reply
                             record key           Stock-Key
                             alternate record key Stock-Abrev-Key
                             alternate record key Stock-Desc with duplicates.
*> copy "selpl.cob".
*>
     select  purchase-file   assign        file-22,
                             access        dynamic,
                             organization  indexed,
                             status        fs-reply,
                             record key    purch-key.
*> copy "selanal.cob".
*>
     select  analysis-file   assign        file-15
                             access        dynamic
                             organization  indexed
                             status        fs-reply
                             record key    pa-code.
*> copy "selprint.cob".
*>
*> removed org line seq as causing double line printing in OC CE
*>
       select  print-file     assign        "prt-1".
 *>                            organization line sequential.
 data                    division.
*>================================
*>
 file section.
*>------------
*>
*> copy "fdstock.cob".
*>*******************************************
*>                                          *
*>  File Definition For The Stock Control   *
*>                                          *
*>*******************************************
*> rec size 385 bytes (with WIP) 26/05/09
*> rec size 400 bytes (with fillers) 11/12/11
*> 02/06/09 vbc - Added PA code
*> 17/03/12 vbc - Field types chgd from bin long to comp still 400
*>
 fd  Stock-File.
*>
 01  Stock-Record.
     03  Stock-Key                pic x(13).
     03  Stock-Abrev-Key          pic x(7).
     03  Stock-Suppliers-Group.
         05  Stock-Supplier-P1    pic x(7).                          *> Primary   Supplier
         05  Stock-Supplier-P2    pic x(7).                          *> Secondary Supplier
         05  Stock-Supplier-P3    pic x(7).                          *> Back Up   Supplier
     03  filler redefines Stock-Suppliers-Group.
         05  Stock-Suppliers      pic x(7)     occurs 3.  *> 41
     03  Stock-Desc               pic x(32).              *> 73
     03  Stock-Construct-Item     pic x(13).              *> 86
     03  Stock-Location           pic x(10).
     03  Stock-PA-Code.
         05  Stock-pa-System      pic x.
         05  Stock-pa-Group.
             07  Stock-pa-First   pic x.
             07  Stock-pa-Second  pic x.
     03  Stock-SA-Code.
         05  Stock-sa-System      pic x.
         05  Stock-sa-Group.
             07  Stock-sa-First   pic x.
             07  Stock-sa-Second  pic x.
     03  Stock-Services-Flag      pic x.                  *> 103        flag for services, not product (Y/N)
     03  Stock-Last-Actual-Cost   pic 9(7)v99     comp-3. *> (5)
     03  filler                   pic x(8).               *> 116
     03  Stock-Construct-Bundle   pic s9(6)       comp.
     03  Stock-Under-Construction pic s9(6)       comp.
     03  Stock-Work-in-Progress   pic s9(6)       comp.
     03  Stock-ReOrder-Pnt        pic s9(6)       comp.
     03  Stock-Std-ReOrder        pic s9(6)       comp.
     03  Stock-Back-Ordered       pic s9(6)       comp.
     03  Stock-On-Order           pic s9(6)       comp.
     03  Stock-Held               pic s9(6)       comp.
     03  Stock-Pre-Sales          pic s9(6)       comp.   *> 36 = 152
     03  Stock-Retail             pic 9(7)v99     comp-3. *> 5    *> This 3 increased by 1 leading digit
     03  Stock-Cost               pic 9(7)v9999   comp-3. *> 6          Based on last Order Only
     03  Stock-Value              pic 9(9)v99     comp-3. *> 6 = 169
     03  Stock-Order-Due          pic 9(8)    comp.  *> binary-long unsigned.
     03  Stock-Order-Date         pic 9(8)    comp.  *> binary-long unsigned.   *> 177
     03  Stock-Mthly-Running-Totals.                 *> 16:    cleared at EOY cycle
         05  Stock-Adds           pic 9(8)    comp.  *> binary-long.
         05  Stock-Deducts        pic 9(8)    comp.  *> binary-long.
         05  Stock-Wip-Adds       pic 9(8)    comp.  *> binary-long.
         05  Stock-Wip-Deds       pic 9(8)    comp.  *> binary-long.
     03  Stock-History.
         05  Stock-History-Data              occurs 12.   *> 193:       zeroed for new year
             07  Stock-TD-Adds     pic 9(8)   comp.  *> binary-long.
             07  Stock-TD-Deds     pic 9(8)   comp.  *> binary-long.
             07  Stock-TD-Wip-Adds pic 9(8)   comp.  *> binary-long.
             07  Stock-TD-Wip-Deds pic 9(8)   comp.  *> binary-long.   *> 48 (x4) = 192 == 385
     03  filler                   pic x(15).                           *> 400  expansion
*> copy "fdpl.cob".
*>**********************************************
*>                                             *
*>  File Definition For The Purchase Ledger    *
*>                                             *
*>**********************************************
*> rec size 299 bytes  26/03/09
*> rec size 300 bytes  22/12/11
*>
 fd  Purchase-File.
*>
 01  Purch-Record.
     03  Purch-Key           pic x(7).
*>     03  filler   redefines Purch-Key.
*>         05  array-k         pic x  occurs 6.
*>         05  check-digit     pic 9.
     03  purch-status        pic 9.
         88  supplier-live               value 1.
         88  supplier-dead               value 0.
     03  Purch-Notes-Tag     pic 9.
     03  purch-name          pic x(30).
     03  purch-address.
         05  purch-addr1     pic x(48).
         05  purch-addr2     pic x(48).
     03  purch-phone         pic x(13).
     03  purch-ext           pic x(4).
     03  purch-fax           pic x(13).
     03  purch-email         pic x(30).
     03  purch-discount      pic 99v99      comp.
     03  purch-credit        binary-char.
     03  purch-sortcode      binary-long.
     03  purch-accountno     binary-long.
     03  purch-limit         binary-long.
     03  purch-activety      binary-long.
     03  purch-last-inv      binary-long.
     03  purch-last-pay      binary-long.
     03  purch-average       binary-long.
     03  purch-create-date   binary-long.
     03  purch-pay-activety  binary-long.
     03  purch-pay-average   binary-long.
     03  purch-pay-worst     binary-long.
     03  purch-current       pic s9(8)v99   comp-3.
     03  purch-last          pic s9(8)v99   comp-3.
     03  quarters.
         05  turnover-q1     pic s9(8)v99   comp-3.
         05  turnover-q2     pic s9(8)v99   comp-3.
         05  turnover-q3     pic s9(8)v99   comp-3.
         05  turnover-q4     pic s9(8)v99   comp-3.
     03  filler redefines quarters.
         05  pturnover-q     pic s9(8)v99   comp-3 occurs  4.
     03  purch-unapplied     pic s9(8)v99   comp-3.
     03  filler              pic x(16).
*>
*> copy "fdanal.cob".
*>*******************************************
*>                                          *
*>  File Definition For The Analysis File   *
*>                                          *
*>*******************************************
*> 36 bytes 25/3/09
 fd  Analysis-File.
*>
 01  analysis-record.
     03  pa-code.
         05  pa-system     pic x.
         05  pa-group.
             07  pa-first  pic x.
             07  pa-second pic x.
     03  pa-gl             pic 9(6).
     03  pa-desc           pic x(24).
     03  pa-print          pic xxx.
*> copy "fdprint.cob".
*>
 fd  print-file
     report Stock-File-Report.
*>
 working-storage section.
*>-----------------------
*>
 77  prog-name           pic x(16)       value "ST010 (3.01.149)".
*>
*>  This will print 1 copy to CUPS print spool specified on line 3
*>
*> copy "print-spool-command.cob".
*>
*> Landscape
*>
 01  Print-Report.
     03  filler          pic x(117)     value
     "lpr -r -o 'orientation-requested=4 page-left=21 page-top=48 " &
     "page-right=10 sides=two-sided-long-edge cpi=12 lpi=8' -P ".
     03  PSN             pic x(48)      value "HPLJ4TCP ".  *> This is the Cups print spool, change it for yours
     03  filler          pic x(15)      value "prt-1".      *> Don't change this line
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
*>     copy "screenio.cpy".
      *>  Copyright (C) 2008,2009 Roger While
      *>
      *>  This file is part of OpenCOBOL.
      *>
      *>  The OpenCOBOL compiler is free software: you can redistribute it
      *>  and/or modify it under the terms of the GNU General Public License
      *>  as published by the Free Software Foundation, either version 3 of the
      *>  License, or (at your option) any later version.
      *>
      *>  OpenCOBOL is distributed in the hope that it will be useful,
      *>  but WITHOUT ANY WARRANTY; without even the implied warranty of
      *>  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
      *>  GNU General Public License for more details.
      *>
*>      *>  You should have received a copy of the GNU General Public License
      *>  along with OpenCOBOL.  If not, see <http://www.gnu.org/licenses/>.


      *>   Colors
       78  COB-COLOR-BLACK     VALUE 0.
       78  COB-COLOR-BLUE      VALUE 1.
       78  COB-COLOR-GREEN     VALUE 2.
       78  COB-COLOR-CYAN      VALUE 3.
       78  COB-COLOR-RED       VALUE 4.
       78  COB-COLOR-MAGENTA   VALUE 5.
       78  COB-COLOR-YELLOW    VALUE 6.
       78  COB-COLOR-WHITE     VALUE 7.

      *>
      *> Values that may be returned in CRT STATUS (or COB-CRT-STATUS)
      *> Normal return - Value 0000
       78  COB-SCR-OK          VALUE 0.

      *>  Function keys - Values 1xxx
       78  COB-SCR-F1          VALUE 1001.
       78  COB-SCR-F2          VALUE 1002.
       78  COB-SCR-F3          VALUE 1003.
       78  COB-SCR-F4          VALUE 1004.
       78  COB-SCR-F5          VALUE 1005.
       78  COB-SCR-F6          VALUE 1006.
       78  COB-SCR-F7          VALUE 1007.
       78  COB-SCR-F8          VALUE 1008.
       78  COB-SCR-F9          VALUE 1009.
       78  COB-SCR-F10         VALUE 1010.
       78  COB-SCR-F11         VALUE 1011.
       78  COB-SCR-F12         VALUE 1012.
       78  COB-SCR-F13         VALUE 1013.
       78  COB-SCR-F14         VALUE 1014.
       78  COB-SCR-F15         VALUE 1015.
       78  COB-SCR-F16         VALUE 1016.
       78  COB-SCR-F17         VALUE 1017.
       78  COB-SCR-F18         VALUE 1018.
       78  COB-SCR-F19         VALUE 1019.
       78  COB-SCR-F20         VALUE 1020.
       78  COB-SCR-F21         VALUE 1021.
       78  COB-SCR-F22         VALUE 1022.
       78  COB-SCR-F23         VALUE 1023.
       78  COB-SCR-F24         VALUE 1024.
       78  COB-SCR-F25         VALUE 1025.
       78  COB-SCR-F26         VALUE 1026.
       78  COB-SCR-F27         VALUE 1027.
       78  COB-SCR-F28         VALUE 1028.
       78  COB-SCR-F29         VALUE 1029.
       78  COB-SCR-F30         VALUE 1030.
       78  COB-SCR-F31         VALUE 1031.
       78  COB-SCR-F32         VALUE 1032.
       78  COB-SCR-F33         VALUE 1033.
       78  COB-SCR-F34         VALUE 1034.
       78  COB-SCR-F35         VALUE 1035.
       78  COB-SCR-F36         VALUE 1036.
       78  COB-SCR-F37         VALUE 1037.
       78  COB-SCR-F38         VALUE 1038.
       78  COB-SCR-F39         VALUE 1039.
       78  COB-SCR-F40         VALUE 1040.
       78  COB-SCR-F41         VALUE 1041.
       78  COB-SCR-F42         VALUE 1042.
       78  COB-SCR-F43         VALUE 1043.
       78  COB-SCR-F44         VALUE 1044.
       78  COB-SCR-F45         VALUE 1045.
       78  COB-SCR-F46         VALUE 1046.
       78  COB-SCR-F47         VALUE 1047.
       78  COB-SCR-F48         VALUE 1048.
       78  COB-SCR-F49         VALUE 1049.
       78  COB-SCR-F50         VALUE 1050.
       78  COB-SCR-F51         VALUE 1051.
       78  COB-SCR-F52         VALUE 1052.
       78  COB-SCR-F53         VALUE 1053.
       78  COB-SCR-F54         VALUE 1054.
       78  COB-SCR-F55         VALUE 1055.
       78  COB-SCR-F56         VALUE 1056.
       78  COB-SCR-F57         VALUE 1057.
       78  COB-SCR-F58         VALUE 1058.
       78  COB-SCR-F59         VALUE 1059.
       78  COB-SCR-F60         VALUE 1060.
       78  COB-SCR-F61         VALUE 1061.
       78  COB-SCR-F62         VALUE 1062.
       78  COB-SCR-F63         VALUE 1063.
       78  COB-SCR-F64         VALUE 1064.
      *>  Exception keys - Values 2xxx
       78  COB-SCR-PAGE_UP     VALUE 2001.
       78  COB-SCR-PAGE_DOWN   VALUE 2002.
       78  COB-SCR-KEY-UP      VALUE 2003.
       78  COB-SCR-KEY-DOWN    VALUE 2004.
       78  COB-SCR-ESC         VALUE 2005.
       78  COB-SCR-PRINT       VALUE 2006.
       78 COB-SCR-TAB        VALUE 2007.	*> extended accept on patched C.E
       78 COB-SCR-BACK-TAB   VALUE 2008.      	*>  ditto
*>  Input validation - Values 8xxx
       78  COB-SCR-NO-FIELD    VALUE 8000.
       78  COB-SCR-TIME-OUT    VALUE 8001.
      *>  Other errors - Values 9xxx
       78  COB-SCR-FATAL       VALUE 9000.
       78  COB-SCR-MAX-FIELD   VALUE 9001.
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
*> copy "wsfnctn.cob".
*>**********************************
*>                                 *
*>  File Access Control Functions  *
*>                                 *
*>**********************************
*>
 01  File-Access.
     03  We-Error        binary-long.
     03  Rrn             binary-long.
     03  Fs-Reply        pic 99.
     03  s1              pic x.   *> not sure this is used so lets rem it out and see
*>     05  s2              pic x.  *> rem'd out MF status
*>    03  stat-bin            redefines fs-reply pic 9(4) comp.
*>    03  disply-stat.
*>     05 s1-displ        pic x.
*>     05 filler          pic xxx.
*>     05 s2-displ        pic 9999.
*>
     03  Curs            pic 9(4).
     03  filler redefines Curs.
         05  Lin         pic 99.
         05  Cole        pic 99.
     03  Curs2           pic 9(4).
     03  filler redefines Curs2.
         05  Lin2        pic 99.
         05  Col2        pic 99.
*>
     03  Fs-Action       pic x(20)  value spaces.
*> current range 1 thru 3
*> 1 = Stock-Key (or only key), 2 = Stock-Abrev-Key, 3 = Stock-Desc
     03  File-Key-No     pic 9.
     03  File-Key        pic x(32).      *> Max size of any key  NOT USED ANY WHERE SO FAR (03/04/12)
     03  SQL-Err         pic x(5).                    *> May not be needed
     03  SQL-Msg         pic x(512) value spaces.     *> May not be needed
     03  Accept-Reply    pic x      value space.
     03  DB-Schema       pic x(12)  value spaces.
     03  DB-UName        pic x(12)  value spaces.
     03  DB-UPass        pic x(12)  value spaces.
*>
*> Block for File/table access via acas000 thru acas033 for IS files and rdbms
*> Also see RDBMS-Flat-Statuses in System-Record
*>
     03  File-Function   pic 9.
         88  fn-open            value 1.
         88  fn-close           value 2.
         88  fn-read-next       value 3.
         88  fn-read-indexed    value 4.
         88  fn-write           value 5.
         88  fn-spare           value 6.
         88  fn-re-write        value 7.
         88  fn-delete          value 8.
         88  fn-start           value 9.
*>
     03  Access-Type     pic 9.                *> For rdbms 2 should cover all !!!
         88  fn-input           value 1.
         88  fn-i-o             value 2.
         88  fn-output          value 3.
         88  fn-extend          value 4.
         88  fn-equal-to        value 5.
         88  fn-less-than       value 6.
         88  fn-greater-than    value 7.
         88  fn-not-less-than   value 8.
         88  fn-not-greater-than value 9.    *> Not currently used (06/04/2012)
*>
*> copy "wsmaps03.cob".
       >>source free
*>*********
*> maps03 *
*>*********
*> 23/04/09 vbc - Support for UK, USA, Intl formats
 01  maps03-ws.
     03  u-date          pic x(10).
     03  u-UK redefines u-date.
         05  u-days      pic 99.
         05  filler      pic x.
         05  u-month     pic 99.
         05  filler      pic x.
         05  u-year.
             07  u-cc    pic 99.
             07  u-yy    pic 99.
     03  u-USA redefines u-date.
         05  u-usa-month pic 99.
         05  filler      pic x.
         05  u-usa-days  pic 99.
         05  filler      pic x.
         05  filler      pic x(4).
     03  u-Intl redefines u-date.
         05  u-intl-year.
             07  u-intl-cc pic 99.
             07  u-intl-yy pic 99.
         05  filler        pic x.
         05  u-intl-month  pic 99.
         05  filler        pic x.
         05  u-intl-days   pic 99.
     03  u-bin           binary-long.
*> copy "wsmaps09.cob".
*>*********
*> maps09 *
*>*********
*>
 01  maps09-ws.
     03  customer-code.
         05  customer-nos   pic x(6).
         05  check-digit    pic 9.
     03  maps09-reply       pic x.
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
*> copy "wscall.cob".
 01  ws-calling-data.
     03  ws-called       pic x(8).
     03  ws-caller       pic x(8).
     03  ws-del-link     pic x(8).
     03  ws-term-code    pic 9.
*>                                 new 18/5/13
     03  ws-Process-Func pic 9.
     03  ws-Sub-Function pic 9.
     03  filler          pic x.
*>
*> copy "wssystem.cob".
*>*******************************************
*>                                          *
*>  Record Definition For The System File   *
*>                                          *
*>*******************************************
*>  file size 1024 with fillers
*> 01/02/09 vbc - Repacked 2 reduce slack
*> 05/04/09 vbc - Light clean up
*> 07/04/09 vbc - Remove op-gen to filler (general)
*> 22/04/09 vbc - Stock control data added.
*> 29/05/09 vbc - Added 'system wide' Print-Lines for all ledgers.
*>  1/06/09 vbc - Added Stock link for PL and SL.
*> 14/09/10 vbc - Added Print-Spool-Name.
*> 15/09/10 vbc - Need to increase rec size by 128 bytes in system-data and more in the others
*>                to bring it up to 1024, the other 2 rec types will also increase to same.
*>                Epos remarked out for Open source versions.
*> 07/11/10 vbc - New fields added as above including vers & sub vers for file for auto
*>                updating of changed file layouts by system
*> 16/11/11 vbc - Added extra 88 in op-system
*> 11/12/11 vbc - Added Date-Form for all of ACAS and removed stk-Date-Form
*> 04/03/12 vbc - Added File-Duplicates-In-Use & FS-Duplicate-Processing + support for MS SQL server.
*> 09/04/12 vbc - Added Needed RDB data, DB Name, User Name and password requred for connecting
*>                 to Database tables.
*> 15/05/13 vbc - Added SL-Stock-Audit to invoicing replacing a filler. Needs adding to rdbms layouts!!!
*> 19/05/13 vbc - Added 4 fields at end of SL block for company name/address headings in
*>                Inv, Stat, Pick, Letters, Vat-prints And VAT registration number in system block
*>                  - NEEDS adding to in RDBMS layouts.
*> 04/06/13 vbc - Added fields Print-Spool-Name2 & Print-Spool-Name3 in filler areas but really need to be moved
*>                to system data block AND moving around some other fields. File size NOT changed
*> 12/06/13 vbc - Added IRS fields to main system file - Starter for 10.
*>
 01  System-Record.
*>******************
*>   System Data   *
*>******************
     03  System-Data-Block.                                  *>   384 bytes
         05  System-Record-Version-Prime      binary-char.   *>  NEW
         05  System-Record-Version-Secondary  binary-char.   *>  NEW
         05  Vat-Rates                    comp.
             07 Vat-Rate-1   pic 99v99.
             07 Vat-Rate-2   pic 99v99.
             07 Vat-Rate-3   pic 99v99.
             07 Vat-Rate-4   pic 99v99.   *> 2b used for local sales tax   Not UK  {  as of 07 Nov 2010  *> NEW setup in sys002
             07 Vat-Rate-5   pic 99v99.   *> 2b used for local sales tax   Not UK  {                     *> NEW setup in sys002
         05  Vat-Rate redefines Vat-Rates pic 99v99 comp occurs 5.
         05  Cyclea          binary-char.
         05  Scycle Redefines cyclea  binary-char.
         05  Period          binary-char.
         05  Page-Lines      binary-char  unsigned.
         05  Next-Invoice    binary-long.
         05  Run-Date        binary-long.
         05  Start-Date      binary-long.
         05  End-Date        binary-long.
         05  Suser.				*> IRS
             07  Usera       pic x(32).
         05  User-Code       pic x(32).
         05  Address-1       pic x(24).
         05  Address-2       pic x(24).
         05  Address-3       pic x(24).
         05  Address-4       pic x(24).
         05  Post-Code       pic x(12).   *> or ZipCode size should cover all countries
         05  Country         pic x(24).
         05  Print-Spool-Name pic x(48).
         05  File-Statuses.
             07  File-Status pic 9          occurs 32.
         05  Pass-Value      pic 9.
         05  Level.
             07  Level-1     pic 9.
                 88  G-L                    value 1.   *> General (Nominal) ledger
             07  Level-2     pic 9.
                 88  B-L                    value 1.   *> Purchase (Payables) ledger
             07  Level-3     pic 9.
                 88  S-L                    value 1.   *> Sales (Receivables) ledger
             07  Level-4     pic 9.
                 88  Stock                  value 1.   *> Stock Control (Inventory)
             07  Level-5     pic 9.
                 88  O-E                    value 1.   *> Order Entry
             07  Level-6     pic 9.
                 88  Payroll                value 1.   *> Payroll
         05  Pass-Word       pic x(4).                 *>
         05  Host            pic 9.
             88  Multi-User                 value 1.
         05  Op-System       pic 9.
             88  Dos                        value 1.
             88  Windows                    value 2.
             88  Mac                        value 3.
             88  Os2                        value 4.
             88  Unix                       value 5.
             88  Linux                      value 6.
             88  OS-Single                  values 1 2 4.
         05  Current-Quarter pic 9.
         05  RDBMS-Flat-Statuses.
             07  File-System-Used  pic 9.
                 88  FS-Cobol-Files-Used        value zero.
                 88  FS-RDBMS-Used              value 1.
*>                 88  FS-Oracle-Used             value 1.  *> THESE NOT IN USE
*>                 88  FS-MySql-Used              value 2.  *> ditto
*>                 88  FS-Postgres-Used           value 3.  *> ditto
*>                 88  FS-DB2-Used                value 4.  *> ditto
*>                 88  FS-MS-SQL-Used             value 5.  *> ditto
                 88  FS-Valid-Options           values 0 thru 1.    *> 5. (not in use unless 1-5)
             07  File-Duplicates-In-Use pic 9.
                 88  FS-Duplicate-Processing    value 1.
         05  Maps-Ser.      *> Not needed in OpenSource version, = 9999 (No Maintainence Contract]
             07  Maps-Ser-xx pic xx.        *> Allows for 36^2 * 100 customers
             07  Maps-Ser-nn binary-short.  *>       =  129600 - 2
         05  Date-Form       pic 9.
             88  Date-UK                    value 1.  		*> dd/mm/yyyy
             88  Date-USA                   value 2.  		*> mm/dd/yyyy
             88  Date-Intl                  value 3.  		*> yyyy/mm/dd
             88  Date-Valid-Formats         values 1 2 3.
         05  Data-Capture-Used pic 9.
             88  DC-Cobol-Standard          value zero.
             88  DC-GUI                     value 1.
             88  DC-Widget                  value 2.
         05  RDBMS-DB-Name   pic x(12)      value "ACASDB".	*> change in setup
         05  RDBMS-User      pic x(12)      value "ACAS-User".	*> change in setup
         05  RDBMS-Passwd    pic x(12)      value "PaSsWoRd".	*> change in setup
         05  VAT-Reg-Number  pic x(11)      value spaces.
         05  filler          pic x(08).          		*> change for file record sizing
*>***************
*>   G/L Data   *
*>***************
     03  General-Ledger-Block.               *> 80 bytes
         05  P-C             pic x.
             88  Profit-Centres             value "P".
             88  Branches                   value "B".
         05  P-C-Grouped     pic x.
             88  Grouped                    value "Y".
         05  P-C-Level       pic x.
             88  Revenue-Only               value "R".
         05  Comps           pic x.
             88  Comparatives               value "Y".
         05  Comps-Active    pic x.
             88  Comparatives-Active        vaLUE "Y".
         05  M-V             pic x.
             88  Minimum-Validation         vaLUE "Y".
         05  Arch            pic x.
             88  Archiving                  value "Y".
         05  Trans-Print     pic x.
             88  Mandatory                  value "Y".
         05  Trans-Printed   pic x.
             88  Trans-Done                 value "Y".
         05  Header-Level    pic 9.
         05  Sales-Range     pic 9.
         05  Purchase-Range  pic 9.
         05  Vat             pic x.
             88  Auto-Vat                   value "Y".
         05  Batch-Id        pic x.
             88  Preserve-Batch             value "Y".
         05  Ledger-2nd-Index pic x.                     	*> But file uses SINGLE INDEX only ???
             88  Index-2                    value "Y".
         05  Irs-Instead     pic x.
             88  Irs-Used                   value "Y".
         05  Ledger-Sec      binary-short.
         05  Updates         binary-short.
         05  Postings        binary-short.
         05  Next-Batch      binary-short.   		*> should be unsigned used for all ledgers
         05  Extra-Charge-Ac binary-long.
         05  Vat-Ac          binary-long.
         05  Print-Spool-Name2 pic x(48).
*>******************
*>   P(B)/L Data   *
*>******************
     03  Purchase-Ledger-Block.              *> 88 bytes
         05  Next-Folio      binary-long.
         05  BL-Pay-Ac       binary-long.
         05  P-Creditors     binary-long.
         05  BL-Purch-Ac     binary-long.
         05  BL-End-Cycle-Date binary-long.
         05  BL-Next-Batch   binary-short.   *> should be unsigned - unused ?
         05  Age-To-Pay      binary-char.    *> should be unsigned
         05  Purchase-Ledger pic x.
             88  P-L-Exists                 value "Y".
         05  PL-Delim        pic x.
         05  Entry-Level     pic 9.
         05  P-Flag-A        pic 9.
         05  P-Flag-I        pic 9.
         05  P-Flag-P        pic 9.
         05  PL-Stock-Link   pic x.
         05  Print-Spool-Name3 pic x(48).
         05  filler          pic x(10).
*>***************
*>   S/L Data   *
*>***************
     03  Sales-Ledger-Block.                 *> 128 bytes
         05  Sales-Ledger    pic x.
             88  S-L-Exists                 value "Y".
         05  SL-Delim        pic x.
         05  Oi-3-Flag       pic x.		*> 'Y' used in sl060 why?
         05  Cust-Flag       pic x.
         05  Oi-5-Flag       pic x.
         05  S-Flag-Oi-3     pic x.		*> 'z' when otm3 created, used in sl060 why? NO LONGER USED
         05  Full-Invoicing  pic 9.
         05  S-Flag-A        pic 9.		*> '1' used in sl060 why?
         05  S-Flag-I        pic 9.		*> '2' used in sl060 why?
         05  S-Flag-P        pic 9.
         05  SL-Dunning      pic 9.
         05  SL-Charges      pic 9.
         05  Sl-Own-Nos      pic x.
         05  SL-Stats-Run    pic 9.
         05  Sl-Day-Book     pic 9.
         05  invoicer        pic 9.
             88  I-Level-0                  value 0.  *> show totals only (no net & vat) not used?
             88  I-Level-1                  value 1.  *> Show net, vat
             88  I-Level-2                  value 2.  *> show Details + vat etc     *> this looks wrong in sl910 ??????   totals only (no net & vat)
             88  Not-Invoicing              value 9.  *> show totals only (no net & vat) but not found yet nor level 3 (see sl900)
         05  Extra-Desc      pic x(14).
         05  Extra-Type      pic x.
             88  Discount                   value "D".
             88  Charge                     value "C".
         05  Extra-Print     pic x.
         05  SL-Stock-Link   pic x.
         05  SL-Stock-Audit  pic x.
             88  Stock-Audit-On             value "Y".   *> Invoicing will create an audit record (15/05/13)
         05  SL-Late-Per     pic 99v99    comp.
         05  SL-Disc         pic 99v99    comp.
         05  Extra-Rate      pic 99v99    comp.
         05  SL-Days-1       binary-char.
         05  SL-Days-2       binary-char.
         05  SL-Days-3       binary-char.
         05  SL-Credit       binary-char.
         05  filler          binary-short.   *> No longer used.
         05  SL-Min          binary-short.
         05  SL-Max          binary-short.
         05  PF-Retention    binary-short.
         05  First-Sl-Batch  binary-short.   *> should be unsigned - unused ?
         05  First-Sl-Inv    binary-long.
         05  SL-Limit        binary-long.
         05  SL-Pay-Ac       binary-long.
         05  S-Debtors       binary-long.
         05  SL-Sales-Ac     binary-long.
         05  S-End-Cycle-Date binary-long.
         05  SL-Comp-Head-Pick Pic x.
             88  SL-Comp-Pick               value "Y".
         05  SL-Comp-Head-Inv  pic x.
             88  SL-Comp-Inv                value "Y".
         05  SL-Comp-Head-Stat pic x.
             88  SL-Comp-Stat               value "Y".
         05  SL-Comp-Head-Lets pic x.
             88  SL-Comp-Lets               value "Y".
         05  SL-VAT-Printed  pic x.
             88  SL-VAT-Prints              value "Y".
         05  filler          pic x(45).      *>  just in case
*>***************
*> Stock Data   *
*>***************
*>
     03  Stock-Control-Block.                *> 88 bytes
         05  Stk-Abrev-Ref   pic x(6).
         05  Stk-Debug       pic 9.          *> T/F (1/0).
         05  Stk-Manu-Used   pic 9.          *> T/F (Bomp/Wip)
         05  Stk-OE-Used     pic 9.          *> T/F.
         05  Stk-Audit-Used  pic 9.          *> T/F.
         05  Stk-Mov-Audit   pic 9.          *> T/F.
         05  Stk-Period-Cur  pic x.          *> M=Monthly, Q=Quarterly, Y=Yearly
         05  Stk-Period-dat  pic x.          *>  --  ditto  --
         05  filler          pic x.    	     *> was stk-date-form
         05  Stock-Control   pic x.
             88  Stock-Control-Exists   value "Y".
         05  Stk-Averaging   pic 9.          *> T/F.
             88  Stock-Averaging        value 1.
         05  Stk-Activity-Rep-Run pic 9.     *> T/F.  =17 bytes 0=no, 1=add, 2=del, 3=both
         05  filler          pic x.          *> slack byte
         05  Stk-Page-Lines  binary-char unsigned.  *> Taken from Print-Lines
         05  Stk-Audit-No    binary-char unsigned.  *> 20
         05  filler          pic x(68).             *> 64    (just in case)
     03  Order-Entry-Block.                         *> 128 bytes
         05  filler-Dummy    pic x(128).
     03  IRS-Data-Block.
         05  filler-dummy4   pic x(128).
     03  IRS-Entry-Block redefines IRS-Data-Block.			*> NEW 12/06/13
         05  Client             pic x(24). 	*> 		24
         05  System-Files.
             07  fn-1           pic x(9).  	*> acts  	33
             07  fn-2           pic x(10). 	*> system  	43
             07  fn-3           pic x(8).  	*> dflt  	51
             07  fn-4           pic x(8).  	*> post 	59
             07  fn-5           pic x(12). 	*> prn  	71 Needed??
             07  System-Ops     pic x.     	*> 		72
         05  Next-Post          pic 9(5).  	*> 		77
         05  Vat-Rates2.
             07  vat1           pic 99v99. 	*> 		81   *> Standard  changed from vat (11/06/13)
             07  vat2           pic 99v99. 	*> 		85   *> reduced 1 [not yet used]
             07  vat3           pic 99v99. 	*> 		89   *> reduced 2 [not yet used]
         05  Vat-Group redefines Vat-Rates2.
             07  Vat-Psent      pic 99v99    occurs 3.
         05  IRS-Pass-Value     pic 9.	 	 *>		90  (Was Pass-Value in IRS system file)
         05  save-sequ          pic 9.     	 *> 		91
         05  system-work-group  pic x(18).	 *> 		109
         05  PL-App-Created     pic x.    	 *> 		110
         05  PL-Approp-AC       pic 9(5). 	 *> 		115
         05  1st-Time-Flag      pic 9.    	 *> 		116   (was First-Time-Flag in IRS system file)
         05  filler             pic x(12).	 *>             128
*>         05  filler             pic x(12).	 *> when vat rates killed
*>     03  Payroll-Data-Block.                        *> 128 bytes
*>         05  filler-dummy2   pic x(128).		*> Content Removed
*>     03  Epos-Data-Block.
*>         05  filler-dummy3   pic x(128).		*> Content Removed
*> copy "wsnames.cob".
*>
*> Stock
*>
 01  file-defs.
*> copy "file00.cob" suppress.
      03  file-0          pic x(532)      value "system.dat".
*> copy "file09.cob" suppress printing.
      03  file-9        pic x(532)      value "tmp-stock.dat".
*> copy "file10.cob".
      03  file-10         pic x(532)      value "staudit.dat".
*> copy "file11.cob".
      03  file-11         pic x(532)      value "stockctl.dat".
*> copy "file15.cob".
      03  file-15         pic x(532)       value "analysis.dat".
*> copy "file22.cob".
     03  file-22        pic x(532)      value "purchled.dat".
 01  filler         redefines file-defs.
     03  System-File-Names   pic x(532)    occurs 6.
 01  File-Defs-Count         binary-short  value 6.    *> MUST be the same as above occurs
*> 01  IRS-files.
*> copy "file08.cob".
 01  to-day             pic x(10).
*>
 report section.
*>**************
*>
 rd  Stock-File-Report
     control is final
     page limit is Page-Lines
     heading 1
     first detail 6
     last  detail  WS-Page-Lines.
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
      03  Underline-Line line plus 1              present when line-counter > 5 and < 45.
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
              go to ea230-Totals.
*>
     perform a00-Detail-Core.
*>     if       line-counter > 6 and < 45
*>              move all "-" to Underline-Line                  *> value all "-" not working
              generate Underline-Line.
     generate Stock-Detail.                                   *> changed from RD name
     generate Stock-Detail-2.                                 *> see if line 2 now printed
*>     if       ws-Print-Line-Flag = 1
     generate WIP-Data
*>     end-if
*>     if       Stock-Services-Flag = "Y"
*>              move 1 to ws-Services-Flag
              generate Service-Non-Dataname
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
