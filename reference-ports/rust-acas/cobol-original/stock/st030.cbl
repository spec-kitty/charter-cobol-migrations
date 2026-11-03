       >>source free
*>*************************************************************
*>                                                            *
*>                  Stock Control Reporting                   *
*>                                                            *
*>*************************************************************
*>
 identification          division.
*>================================
*>
*>**
      program-id.         st030.
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
*>
*>                        ST300.
*>                        ST301.
*>                        ST302.
*>                        ST303.
*>                        ST304.
*>                        ST305.
*>                        ST306.
*>                        ST307.
*>                        ST308.
*>                        ST313.
*>**
*> Changes:
*> 12/06/09 vbc - .00 Written in Cobol from scratch against v2 specs.
*> 18/06/09 vbc - .01 Test 1-Bugs in menus screens, report heads & added
*>                    support for alt key on desc.
*> 18/06/09 vbc - .02-5 Report layout tidy ups with more to follow, no doubt.
*> 19/06/09 vbc - .06 Wip on activity only if used & wip qty or wip history
*>                    nonzero.
*>                .08 Replace trailing spaces on Abrev-To with 'z'.
*> 25/06/09 vbc - .09-10 If range not used force start on Abrev key = 0 to make
*>                    all reads on stock file sequential by Abrev key. Clean up
*>                    positioning of subheadings ie 'All Items' etc, 1 col right.
*> 29/06/09 vbc - .11 Added Stock History report.
*> 22/07/09 vbc - .12/13 Understocked test wrong - Don't ask.
*> 07/09/10 vbc - .14/16 on opt 5 incorrect test for < 0 > 5
*>                    amended lpr to include cpi=12 & Cups printer spool.
*> 11/12/11 vbc -     Changed version from 1.00.xx to 3.01.xx, in keeping with the rest of ACAS
*>                .17 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 04/03/12 vbc - .18 Cleanup: Removed chk char from Stock-Abbrev-key and Stock-Key 4 rdbms
*> 12/05/13 vbc - .19 Changed wsnames to in common as pl010 called in st010.
*> 13/05/13 vbc - .20 Added time to reports.
*> 16/05/13 vbc - .21 Changed wsnames to in copybook see above.
*> 04/06/13 vbc - .22 Replaced Stk-Page-Lines with system Page-Lines.
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
 data                    division.
*>================================
*>
 file section.
*>------------
*>
 copy "fdstock.cob".
 copy "fdprint.cob".
*>
 working-storage section.
*>-----------------------
*>
 77  Prog-Name           pic x(15)       value "ST030 (3.01.22)".
 copy "print-spool-command.cob".
 77  Report-Name         pic x(28)       value spaces.
*>
 01  work-fields.
     03  Menu-Reply      pic 9                   value zero.
     03  ws-Reply        pic 9                   value zero.
     03  ws-Proc-Month.
         05  ws-Proc-Mth pic 99                  value zero.
             88  ws-Good-Month                   values 01 thru 12.
     03  ws-Partial      pic 9                   value zero.
     03  ws-First-Rec    pic 9                   value zero.
     03  ws-Stock-From   pic x(13)               value spaces.
     03  ws-Stock-To     pic x(13)               value spaces.
     03  ws-Abrev-From   pic x(7)                value spaces.
     03  ws-Abrev-To     pic x(7)                value spaces.
     03  ws-3            pic 999.
     03  ws-z6           pic z(6).
     03  ws-z6b          pic z(6).
     03  ws-z6c          pic z(6).
     03  ws-Rec-Total    pic zzz,zzz,zz9.
     03  ws-Current-Period  pic x(10).
     03  ws-Todate-Period   pic x(16).
     03  ws-Total-Value  pic s9(9)v99 comp-3     value zero.
     03  ws-Total-Add    binary-long             value zero.
     03  ws-Total-Ded    binary-long             value zero.
     03  ws-WIP-Total-Add binary-long            value zero.
     03  ws-WIP-Total-Ded binary-long            value zero.
     03  ws-Rec-Cnt      binary-long  unsigned   value zero.
     03  Line-Cnt        binary-char  unsigned   value 99.
     03  Page-Nos        binary-char  unsigned   value zero.
     03  a               binary-char  unsigned   value zero.
     03  b               binary-char  unsigned   value zero.
     03  c               binary-char  unsigned   value zero.
*>
     03  ws-lines        binary-char  unsigned   value zero.
     03  ws-22-lines     binary-char  unsigned   value zero.
     03  ws-23-lines     binary-char  unsigned   value zero.
     03  ws-env-lines    pic 999                 value zero.
*>
 01  accept-terminator-array pic 9(4)            value zero.
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
*>
*> Print layouts
*>
 01  Line-0a               pic x(19) value "Items ranging from ".
 01  Line-0b               pic x(9)  value " through ".
*>
 01  Line-0                pic x(100)    value spaces.
 01  Line-11.       *>  Valuation report
     03  l11-Program       pic x(16)     value spaces.
     03  filler            pic x(39)     value spaces.
     03  l11-title         pic x(42)     value "Stock Valuation Report".
     03  filler            pic x(27)     value spaces.
     03  filler            pic x(5)      value "Page ".
     03  l11-Page          pic zz9.
*>
 01  Line-12.
     03  l12-User          pic x(40).
     03  filler            pic x(76)     value spaces.
     03  l12-Date          pic x(10).
     03  filler            pic x         value space.
     03  l2-HH             pic xx        value spaces.
     03  filler            pic x         value ":".
     03  l2-MM             pic xx        value spaces.
*>
 01  Line-13.        *> Valuation Report
     03  filler            pic x(96)   value
         "<------- Stock ------>                                      Average       Replace     Stock     ".
     03  l13-Lit-Wip       pic xxx     value "WIP".
     03  filler            pic x(24)   value "     Value in    Retail".
*>
 01  Line-14.
     03  filler            pic x(96)   value
         "Abrev    Number         Description                           Cost          Cost        Qty     ".
     03  l14-Lit-WIP       pic xxx     value "Qty".
     03  filler            pic x(24)   value "     Stockroom    Price ".
*>
 01  Line-15.
     03  l15-Abrev-Number  pic x(9).
     03  l15-Stock-Number  pic x(15).          *> 24
     03  l15-Desc          pic x(33).          *> 57
     03  l15-Ave-Cost      pic zzzzz,zz9.9999. *> 71
     03  filler redefines l15-Ave-Cost.
         05  filler        pic x(12).
         05  l15-blank-0   pic xx.
     03  l15-Cost          pic zzzzz,zz9.99.   *> 83
     03  l15-Qty           pic z(7)9.          *> 91
     03  l15-Wip           pic z(7)9.          *> 99
     03  l15-Value         pic zzz,zzz,zz9.99. *> 113
     03  l15-Retail        pic zzzzz,zz9.99.   *> 125
*>
 01  Line-16-Total. *> Total
     03  filler            pic x(86)  value spaces.
     03  filler            pic x(13)  value "Total Value: ".
     03  l16-Value         pic zzz,zzz,zz9.99.
*>
 01  Line-16-Over.
     03  filler            pic x(99) value spaces.
     03  filler            pic x(14) value all "-".
*>
 01  Line-16-Under.
     03  filler            pic x(99) value spaces.
     03  filler            pic x(14) value all "=".
*>
 01  Line-23.       *> Activity Report
     03  filler            pic x(72)   value "<------ Stock ------>                                  Current  Retail  ".
     03  l23-Lit-Average   pic x(13)   value " Average".  *> or "   Unit" (cost)
     03  l23-Lit-Val       pic x(9)    value "  Stock ".
     03  l23-Lit-Cur       pic x(19)   value "<- Current Period >".
     03  l23-Lit-YTD       pic x(19)   value "<- Year to Date -->".
*>
 01  Line-24.
     03  filler            pic x(86)  value "Abrev     Number      Description                       Stock   Price      Cost".
     03  l24-Lit-Val       pic x(11)  value "Value".
     03  filler            pic x(35)  value "Add   Ded    Net   Add   Ded    Net".
*>
 01  Line-25.
     03  l25-Abrev-Number  pic x(8).
     03  l25-Stock-Number  pic x(14).           *> 22
     03  l25-Desc.
         05  filler        pic x(28).
         05  l25-Lit-Wip   pic x(5).           *> 55
     03  l25-Qty           pic zzz,zz9.        *> 62
     03  l25-Retail        pic zzz,zz9.99.     *> 72
     03  l25-Ave-Cost      pic zzz,zz9.99.     *> 82
     03  l25-ValueX.
         05  l25-Value     pic zzzzz,zz9.99.   *> 94
     03  l25-Cur-Add       pic z(5)9.          *> 100
     03  l25-Cur-Ded       pic z(5)9.          *> 106
     03  l25-Cur-Net       pic z(5)9-.         *> 113
     03  l25-YTD-Add       pic z(5)9.          *> 119
     03  l25-YTD-Ded       pic z(5)9.          *> 125
     03  l25-YTD-Net       pic z(5)9-.         *> 132
*>
 01  Line-25B redefines Line-25.
     03  filler            pic x(77).
     03  l25b-Lit-Wip      pic x(17).  *> "Work In Progress:"
     03  filler            pic x(38).
*>
 01  Line-33.           *> ReOrder Report
     03  filler            pic x(132)   value
         "<------ Stock ------>                                     Supp    Stock " &
         "< ReOrder >  Unit     On   <------- Date ------>    Bk   WIP".
*>
 01  Line-34.
     03  filler            pic x(132)  value
         "Abrev     Number     Flg Description                      Number   Qty  " &
         "  Pnt   Qty  Cost    Order  Ordered      Due       Ord   Qty".
*>
 01  Line-35.
     03  l35-Abrev-Number  pic x(8).
     03  l35-Stock-Number  pic x(14).          *> 22
     03  l35-Flag          pic x.
     03  filler            pic xx.             *> 25
     03  l35-Desc          pic x(33).          *> 58
     03  l35-Supplier      pic x(7).           *> 65
     03  l35-Qty           pic z(5)9.          *> 71
     03  l35-ReOrder-Pnt   pic z(5)9.          *> 77
     03  l35-Std-Reorder   pic z(5)9.          *> 83
     03  l35-Cost          pic z(5)9.99.       *> 92
     03  l35-On-Order      pic z(5)9b.         *> 99
     03  l35-Order-Date    pic x(11).
     03  l35-Order-Due     pic x(10).          *> 120
     03  l35-Back-Ordered  pic z(5)9.          *> 126
     03  l35-WIP           pic z(6).           *> 132
*>
 01  line-43.             *> Stock Report  (as in st010 but with range facility)
     03  filler          pic x(132)  value
         "<------ Stock ------> Supplier  Location     Unit      Unit        Value " &
         "   Number <- ReOrder -> <------- Date ------>  Quantity On".
*>
 01  line-44.
     03  filler          pic x(132)  value
         "Abrev   Number         Number               Price      Cost        in Stk" &
         "   in Stk  Point    Qty   Ordered     Due      Order  B/Ord".
*>
 01  line-45.
     03  l45-Abrev-Stock pic x(8).
     03  l45-Stock-Number pic x(14).
     03  l45-Supplier-No  pic x(8).         *> 30
     03  l45-Location     pic x(11).        *> 41
     03  l45-Retail       pic z(6)9.99.     *> 51
     03  l45-Cost         pic z(6)9.9999.   *> 63
     03  l45-Costx redefines l45-Cost.  *> helps to clear fraction of a penny/cent when zero
         05  filler       pic x(10).
         05  l45-Costz    pic xx.
     03  l45-Value        pic zzzzz,zz9.99. *> 75
     03  l45-Held         pic z(6)9.        *> 82
     03  l45-Reord-Pnt    pic z(6)9.        *> 89
     03  l45-Reord-Qty    pic z(6)9b.       *> 97
     03  l45-Date-Ordered pic x(11).        *> 108
     03  l45-Date-Due     pic x(10).        *> 118
     03  l45-Qty-Ordered  pic z(6)9.        *> 125
     03  l45-Qty-Back-Ord pic z(6)9.        *> 132
*>
 01  line-46.
     03  filler           pic x(5)   value spaces.
     03  filler           pic x(13)  value "Description: ".
     03  l46-Desc         pic x(32)  value spaces.
     03  filler           pic x(5)   value spaces.
     03  l46-vars         pic x(77).
*>
 01  line-53.             *> History Report
     03  filler          pic x(132)  value "<------ Stock ------>" &
         " Description          This <----------------------------- History for the" &
         " Year ------------------------------->".
*>
 01  line-54.
     03  filler          pic x(41)  value "Abrev   Number        ".
     03  l54-Lit-Period  pic x(07)  value "Quarter".  *> | " Month " | " Week  "
*>
 01  line-55.
     03  l55-Abrev-Stock  pic x(8).
     03  l55-Stock-Number pic x(14).              *>          22
     03  l55-Desc.
         05  filler       pic x(14).
         05  l55-Lit-Wip  pic x(4).
     03  filler           pic x.                  *>          41
     03  l55-This-Period  pic -(6)9.              *> (7)      48
     03  l55-This-Year    pic -(6)9   occurs 12.  *> (84)     132
*>
 copy "wsfnctn.cob".
 copy "wsmaps03.cob".
 copy "wsmaps09.cob".
*>
 01  Error-Messages.
*> Module specific
     03  ST300          pic x(32) value "ST300 Stock File not yet created".
     03  ST301          pic x(26) value "ST301 Stock File not found".
     03  ST302          pic x(60) value "ST302 There were no Stock numbers within the specified range".
     03  ST303          pic x(66) value "ST303 There were no Abrev Stock numbers within the specified range".
     03  ST304          pic x(53) value "ST304 You cannot specify both Stock AND Abrev numbers".
     03  ST305          pic x(42) value "ST305 Abbreviated Stock number not present".
     03  ST306          pic x(28) value "ST306 Stock Number not found".
     03  ST307          pic x(43) value "ST307 Stock From MUST be less than Stock To".
     03  ST308          pic x(43) value "ST308 Abrev From MUST be less than Abrev To".
     03  ST313          pic x(23) value "ST313 Bad month in date".
*>
 01  Error-Code         pic 999    value zero.
*>
 linkage section.
*>***************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
 01  To-Day             pic x(10).
*>
 Screen Section.
*>*************
*>
 01  display-01                  background-color cob-color-black  *> ReOrder Rep
                                 foreground-color cob-color-green.
     03  from Prog-Name        pic x(15)            line  1 col  1 blank screen.
     03  from Report-Name      pic x(28)                    col 26.
     03  from ws-Conv-Date     pic x(10)                    col 71.
     03  value "Report Attributes"                  line  3 col 32.
     03  value "Select an Report Option Number : [" line  5 col  1.
     03  using ws-Reply        pic 9                        col 35.
     03  value "]"                                          col 36.
     03  value "(1)   All Stock Items"              line  7 col 10.
     03  value "(2)   A Range of Items"             line  8 col 10.
     03  value "(3)   Items that are Understocked"  line  9 col 10.
     03  value "(4)   Range of Understocked Items"  line 10 col 10.
     03  value "(5)   Items, Not in Stock"          line 11 col 10.
     03  value "(6)   Range of Items, Not in Stock " line 12 col 10.
     03  value "(7)   Items on Order"               line 13 col 10.
     03  value "(8)   Range of Items on Order"      line 14 col 10.
     03  value "(9)   Return to Main Menu"          line 16 col 10.
*>
 01  display-02                  background-color cob-color-black  *> Activity Rep
                                 foreground-color cob-color-green.
     03  from Prog-Name        pic x(15)            line  1 col  1 blank screen.
     03  from Report-Name      pic x(28)                    col 26.
     03  from ws-Conv-Date     pic x(10)                    col 71.
     03  value "Report Attributes"                  line  3 col 32.
     03  value "Select an Report Option Number : [" line  5 col  1.
     03  using ws-Reply        pic 9                        col 35.
     03  value "]"                                          col 36.
     03  value "(1)   All Stock Items"              line  7 col 10.
     03  value "(2)   Range of Items"               line  8 col 10.
     03  value "(3)   Items Active in current "     line  9 col 10.
     03  from ws-Current-Period pic x(10)                   col 40.
     03  value "(4)   Items Active in "             line 10 col 10.
     03  from ws-Todate-Period  pic x(16)                   col 32.
     03  value "(5)   Range of active Items in Current " line 11 col 10.
     03  from ws-Current-Period pic x(10)                   col 49.
     03  value "(6)   Range of active Items in "    line 12 col 10.
     03  from ws-Todate-Period pic x(16)                    col 41.
     03  value "(9)   Return to Main Menu"          line 14 col 10.
*>
 01  display-03                  background-color cob-color-black  *> Valuation Rep
                                 foreground-color cob-color-green.
     03  from Prog-Name        pic x(15)            line  1 col  1 blank screen.
     03  from Report-Name      pic x(28)                    col 26.
     03  from ws-Conv-Date     pic x(10)                    col 71.
     03  value "Report Attributes"                  line  3 col 32.
     03  value "Leave fields blank to select All"   line  5 col 24 highlight.
     03  value "Select Stock no. or Abrev Stock no. but NOT both"
                                                    line  6 col 17 highlight.
     03  value "From Stock Number - ["              line  8 col  4.
     03  using ws-Stock-From   pic x(13)                    col 25.
     03  value "]"                                          col 38.
     03  value "Enter characters in positions to match"     col 41.
     03  value "  To Stock Number - ["              line  9 col  4.
     03  using ws-Stock-To     pic x(13)                    col 25.
     03  value "]"                                          col 38.
     03  value "Enter characters in positions to match"     col 41.
     03  value "OR"                                 line 10 col 14 highlight.
     03  value "From Abrev Number - ["              line 11 col  4.
     03  using ws-Abrev-From   pic x(7)                     col 25.
     03  value "]"                                          col 32.
     03  value "Enter characters in positions to match"     col 41.
     03  value "  To Abrev Number - ["              line 12 col  4.
     03  using ws-Abrev-To     pic x(7)                     col 25.
     03  value "]"                                          col 32.
     03  value "Enter characters in positions to match"     col 41.
*>
 procedure  division using ws-calling-data system-record to-day file-defs.
*>***********************************************************************
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
*> Get current date into locale format for display and printing
*>
     perform  zz070-Convert-Date.
     move     ws-Date to ws-Conv-Date.
     accept   hdtime from time.
     if       hdtime not = "00000000"
              move hd-hh to l2-HH
              move hd-mm to l2-MM.
*>
*> Set up period descriptives for screen and reports
*>
     move     spaces to ws-Current-Period
                        ws-Todate-Period.
*>
     if       Stk-Period-Cur = "Q"
              move "Quarter" to ws-Current-Period
                                l54-Lit-Period
     else
      if      Stk-Period-Cur = "W"
              move "Week" to ws-Current-Period
              move "   Week" to l54-Lit-Period
      else
              move "  Month" to l54-Lit-Period
              move "Month" to ws-Current-Period.
*>
     if       Stk-Period-dat = "M"
              move "Month To Date" to ws-Todate-Period
     else
      if      Stk-Period-dat = "Q"
              move "Quarter To Date" to ws-Todate-Period
      else
              move "Year To Date" to ws-Todate-Period.
*>
     if       file-status (11) not = 1
              display ST300 at line ws-23-lines col 1 with foreground-color 4 highlight
              move 45 to Error-Code
              perform maps99
              go to aa999-Exit.
*>
     open     input Stock-File.
     if       fs-reply not = zero
              display ST301 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 28 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              go to aa999-Exit.
     move     zero to Menu-Reply.
     close    Stock-File.   *> open and close prior to each proc incase Start not used)
*>
*> Good, we now know the stock file exists
*>
 aa010-Display-Headings.
     move     zero to Page-Nos.
     move     99 to Line-Cnt.
     if       Menu-Reply = 1
              move "Stock Valuation Report"       to Report-Name
     else
      if      Menu-Reply = 2
              move "Stock Activity Report "       to Report-Name
      else
       if     Menu-Reply = 3
              move "Stock Re-Order Report "       to Report-Name
       else
        if    Menu-Reply = 4
              move " Stock History Report "       to Report-Name
        else
         if   Menu-Reply = 5
              move "     Stock Report     "       to Report-Name
         else
              move "Stock Control - Reports Menu" to Report-Name.
*>
 aa020-Display-Heads.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     if       Menu-Reply = zero
              display  Report-Name at 0127 with foreground-color 2
     else
              display  Report-Name at 0130 with foreground-color 2.
     display  ws-Conv-Date at 0171 with foreground-color 2.
*>
 aa030-DH-End.
     move     to-day to ws-Date.
     move     ws-Month to ws-Proc-Month.
     if       ws-Proc-Month not numeric or not ws-Good-Month
              display ST313 at line ws-23-lines col 1 with foreground-color 4 highlight
              display ws-Proc-Month at line ws-23-lines col 25 with foreground-color 2 highlight
              display ws-Date at line ws-23-lines col 28 with foreground-color 2 highlight
              move 45 to error-code
              perform maps99
              go to aa999-Exit.
*>
 aa100-Main-Menu.
     display  "Select one of the following by number :- [ ]" at 0401 with foreground-color 2
                                                                          erase eos.
*>
     display  "(1)  Valuation Report"            at 0604 with foreground-color 2.
     display  "(2)  Activity Report"             at 0704 with foreground-color 2.
     display  "(3)  Re-Order Report"             at 0804 with foreground-color 2.
     display  "(4)  Stock History Report"        at 0904 with foreground-color 2.
     display  "(5)  Stock Report"                at 1004 with foreground-color 2.
     display  "(9)  Return to System Menu"       at 1204 with foreground-color 2.
*>
 aa110-Accept-Loop.
     move     zero to Menu-Reply.
     accept   Menu-Reply at 0443  with foreground-color 6 auto update.
     if       Menu-Reply = 9
              go to aa999-Exit.
     perform  aa010-Display-Headings.
     perform  zz050-Report-Selection.
*> check if quit at level 1
     if       ws-Reply = 9
              go to aa020-Display-Heads.
     if       Menu-Reply = zero or > 5
              go to aa110-Accept-Loop.
*>
     display  " " at line ws-23-lines col 1 with erase eol.
     open     input Stock-File.
     if       Menu-Reply = 1
              open output Print-File
              perform  ba000-Process-Valuations
              close Print-File Stock-File
              if  Page-Nos not = zero
                  call  "SYSTEM" using Print-Report
              end-if
     else
      if      Menu-Reply = 2
              open output Print-File
              perform  ca000-Process-Activity
              close Print-File Stock-File
              if  Page-Nos not = zero
                  call  "SYSTEM" using Print-Report
              end-if
      else
       if     Menu-Reply = 3
              open output Print-File
              perform  da000-Process-ReOrder
              close Print-File Stock-File
              if  Page-Nos not = zero
                  call  "SYSTEM" using Print-Report
              end-if
       else
        if    Menu-Reply = 4
              open output Print-File
              perform  fa000-Process-History
              close Print-File Stock-File
              if  Page-Nos not = zero
                  call  "SYSTEM" using Print-Report
              end-if
        else
         if   Menu-Reply = 5
              open output Print-File
              perform  ea000-Process-Stock-Lists
              close Print-File Stock-File
              if  Page-Nos not = zero
                      call  "SYSTEM" using Print-Report
              end-if
     end-if
*>
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
*>***********************************************
*>                  Routines                    *
*>***********************************************
*>
 ba000-Process-Valuations section.
*>*******************************
*>
     if       ws-Abrev-To not = spaces
              perform varying a from 7 by -1 until a < 2 or ws-Abrev-To (a:1) not = space
                      move "z" to ws-Abrev-To (a:1)
              end-perform
     end-if
     if       ws-Stock-From not = spaces
              move ws-Stock-From to Stock-Key
              start Stock-File key not < Stock-Key invalid key
                  display ST306 at line ws-23-lines col 1 with foreground-color 4 highlight
                  move 15 to Error-Code
                  perform maps99
                  go to ba999-Exit
              end-start
     end-if
*>
     if       ws-Abrev-From not = spaces
              move ws-Abrev-From to Stock-Abrev-Key
              if   Stock-Abrev-Key (7:1) = space
                   move 0 to Stock-Abrev-Key (7:1)
              end-if
              start Stock-File key not < Stock-Abrev-Key invalid key
                  display ST305 at line ws-23-lines col 1 with foreground-color 4 highlight
                  move 15 to Error-Code
                  perform maps99
                  go to ba999-Exit
              end-start
     end-if
     if       ws-Partial = zero
              move  zeros to Stock-Abrev-Key
              start Stock-File key not < Stock-Abrev-Key
     end-if
     move     zero to ws-Total-Value.
     move     spaces to line-15.
*>
 ba010-Read-Rec.
     Read     Stock-File next record at end
              go to ba030-Finish-Report.
*>
*> next 2 in case start does not work and its a partial list and before from keys
*>
     if       ws-Stock-From not = spaces
         and  ws-Stock-From > Stock-Key
              go to ba010-Read-Rec.
     if       ws-Abrev-From not = spaces
         and  ws-Abrev-From > Stock-Abrev-Key
              go to ba010-Read-Rec.
*>
*> next 2 if partial list and past the to keys
*>
     if       ws-Stock-To not = spaces
         and  Stock-Key > ws-Stock-To
              go to ba030-Finish-Report.
*>
     if       ws-Abrev-To not = spaces
         and  Stock-Abrev-Key > ws-Abrev-To
              go to ba030-Finish-Report.
*>
*> Now we can deal with printing the record
*>
 ba020-Print-Rec.
     perform  zz010-Print-Heads.
     move     Stock-Abrev-Key to l15-Abrev-Number.
     move     Stock-Key       to l15-Stock-Number.
     move     Stock-Desc      to l15-Desc.
     move     Stock-Last-Actual-Cost to l15-Cost.
     move     Stock-Cost      to l15-Ave-Cost.
     move     Stock-Held      to l15-Qty.
     move     Stock-Value     to l15-Value.
     move     Stock-Retail    to l15-Retail.
     if       l15-Blank-0 = "00"
              move spaces to l15-Blank-0
     end-if
     if       Stk-Manu-Used = 1
              move Stock-Work-in-Progress to l15-Wip
     end-if
     write    Print-Record from Line-15 after 1.
     add      Stock-Value to ws-Total-Value.
     add      1 to Line-Cnt.
     go       to ba010-Read-Rec.
*>
 ba030-Finish-Report.
*>
*> On current page. Enough extra lines for total and if Partial report,
*>      extra 2 lines for from/to line
*>
     if       Page-Nos = zero
        and   (spaces not = ws-Stock-From or not = ws-Stock-To)
              display ST302 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ba999-Exit.
     if       Page-Nos = zero
        and   (spaces not = ws-Abrev-From or not = ws-Abrev-To)
              display ST303 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ba999-Exit.
*>
     if       Line-Cnt > Page-Lines - 4
              move 99 to Line-Cnt
              perform zz010-Print-Heads.
*>
     move     ws-Total-Value to l16-Value.
     write    Print-Record from Line-16-Over after 2.
     write    Print-Record from Line-16-Total after 1.
     write    Print-Record from Line-16-Under after 1.
*>
 ba999-Exit.
     exit     section.
*>
 ca000-Process-Activity section.
*>*****************************
*>
     if       ws-Abrev-To not = spaces
              perform varying a from 7 by -1 until a < 2 or ws-Abrev-To (a:1) not = space
                      move "z" to ws-Abrev-To (a:1)
              end-perform
     end-if
     move     spaces to line-25.
     if       ws-Stock-From not = spaces
              move ws-Stock-From to Stock-Key
              start Stock-File key not < Stock-Key invalid key
                  display ST306 at line ws-23-lines col 1 with foreground-color 4 highlight
                  move 15 to Error-Code
                  perform maps99
                  go to ca999-Exit
              end-start
     end-if
*>
     if       ws-Abrev-From not = spaces
              move ws-Abrev-From to Stock-Abrev-Key
              if   Stock-Abrev-Key (7:1) = space
                   move 0 to Stock-Abrev-Key (7:1)
              end-if
              start Stock-File key not < Stock-Abrev-Key invalid key
                  display ST305 at line ws-23-lines col 1 with foreground-color 4 highlight
                  move 15 to Error-Code
                  perform maps99
                  go to ca999-Exit
              end-start
     end-if
     if       ws-Partial = zero
              move  zeros to Stock-Abrev-Key
              start Stock-File key not < Stock-Abrev-Key
     end-if.
*>
 ca010-Read-Rec.
     Read     Stock-File next record at end
              go to ca030-Finish-Report.
*>
     if       ws-reply = 1
              go to ca020-Print-Rec.
*>
*> next 2 in case start does not work and its a partial list and before from keys
*>
     if       ws-Stock-From not = spaces
         and  ws-Stock-From > Stock-Key
              go to ca010-Read-Rec.
     if       ws-Abrev-From not = spaces
         and  ws-Abrev-From > Stock-Abrev-Key
              go to ca010-Read-Rec.
*>
*> now for other report variations
*>
     if       ws-Reply = 3 or 5  *> Activity in current period
         and  zero = Stock-Adds and Stock-Deducts and Stock-Wip-Adds and Stock-Wip-Deds
              go to ca010-Read-Rec.
*>
     move     zero to ws-Total-Add ws-Total-Ded.
     move     zero to ws-WIP-Total-Add ws-WIP-Total-Ded.
     perform  varying a from 1 by 1 until a > 12
              add  Stock-TD-Adds (a)      to ws-Total-Add
              add  Stock-TD-Deds (a)      to ws-Total-Ded
              add  Stock-TD-Wip-Adds (a)  to ws-WIP-Total-Add
              add  Stock-TD-Wip-Deds (a)  to ws-WIP-Total-Ded
     end-perform
*>
     if       ws-Reply = 4 or 6  *> Activity in period to date
         and  zero = ws-Total-Add and ws-Total-Ded and ws-WIP-Total-Add and ws-WIP-Total-Ded
              go to ca010-Read-Rec.
*>
*> next 2 if partial list and past the to keys
*>
     if       ws-Stock-To not = spaces
         and  Stock-Key > ws-Stock-To
              go to ca030-Finish-Report.
*>
     if       ws-Abrev-To not = spaces
         and  Stock-Abrev-Key > ws-Abrev-To
              go to ca030-Finish-Report.
*>
 ca020-Print-Rec.
*>
*> Now we can deal with printing the record
*>
     perform  zz020-Print-Heads.
     move     Stock-Abrev-Key              to l25-Abrev-Number.
     move     Stock-Key                    to l25-Stock-Number.
     move     Stock-Desc                   to l25-Desc.
     if       Stock-Averaging
              move  Stock-Cost             to l25-Ave-Cost
              move  Stock-Value            to l25-Value
     else
              move  spaces                 to l25-ValueX
              move  Stock-Last-Actual-Cost to l25-Ave-Cost
     end-if
     move     Stock-Held                   to l25-Qty.
     move     Stock-Retail                 to l25-Retail.
     move     Stock-Adds                   to l25-Cur-Add.
     move     Stock-Deducts                to l25-Cur-Ded.
     subtract Stock-Deducts from Stock-Adds giving l25-Cur-Net.
*>
     move     ws-Total-Add                 to l25-YTD-Add.
     move     ws-Total-Ded                 to l25-YTD-Ded.
     subtract ws-Total-Ded from ws-Total-Add giving l25-YTD-Net.
     write    Print-Record from Line-25 after 1.
     add      1 to Line-Cnt.
     if       Stk-Manu-Used = 1
         and  (Stock-Work-in-Progress not = zero
          or  Stock-Wip-Adds not = zero or Stock-Wip-Deds not = zero
          or  ws-WIP-Total-Add not = zero or ws-WIP-Total-Ded not = zero)
              move spaces to line-25
              move "Work in Progress:"    to l25b-Lit-Wip
              move Stock-Work-in-Progress to l25-Qty
              move "WIP:"                 to l25-Lit-Wip
              move Stock-Wip-Adds         to l25-Cur-Add
              move Stock-Wip-Deds         to l25-Cur-Ded
              subtract Stock-Wip-Deds from Stock-Wip-Adds giving l25-Cur-Net
              move ws-WIP-Total-Add       to l25-YTD-Add
              move ws-WIP-Total-Ded       to l25-YTD-Ded
              subtract ws-WIP-Total-Ded from ws-WIP-Total-Add giving l25-YTD-Net
              write Print-Record from Line-25 after 1
              add  1 to Line-Cnt
     end-if
     go       to ca010-Read-Rec.
*>
 ca030-Finish-Report.
     if       Page-Nos = zero
        and   (spaces not = ws-Stock-From or not = ws-Stock-To)
              display ST302 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ca999-Exit.
     if       Page-Nos = zero
        and   (spaces not = ws-Abrev-From or not = ws-Abrev-To)
              display ST303 at line ws-23-lines col 1 with foreground-color 4 highlight.
*>
 ca999-Exit.
     exit     section.
*>
 da000-Process-ReOrder section.
*>****************************
*>
     if       ws-Abrev-To not = spaces
              perform varying a from 7 by -1 until a < 2 or ws-Abrev-To (a:1) not = space
                      move "z" to ws-Abrev-To (a:1)
              end-perform
     end-if
     move     spaces to line-35.
     if       ws-Stock-From not = spaces
              move ws-Stock-From to Stock-Key
              start Stock-File key not < Stock-Key invalid key
                  display ST306 at line ws-23-lines col 1 with foreground-color 4 highlight
                  move 15 to Error-Code
                  perform maps99
                  go to da999-Exit
              end-start
     end-if
*>
     if       ws-Abrev-From not = spaces
              move ws-Abrev-From to Stock-Abrev-Key
              if   Stock-Abrev-Key (7:1) = space
                   move 0 to Stock-Abrev-Key (7:1)
              end-if
              start Stock-File key not < Stock-Abrev-Key invalid key
                  display ST305 at line ws-23-lines col 1 with foreground-color 4 highlight
                  move 15 to Error-Code
                  perform maps99
                  go to da999-Exit
              end-start
     end-if
     if       ws-Partial = zero
              move  zeros to Stock-Abrev-Key
              start Stock-File key not < Stock-Abrev-Key
     end-if.
*>
 da010-Read-Rec.
     Read     Stock-File next record at end
              go to da030-Finish-Report.
*>
     if       ws-reply = 1        *>  All items
              go to da020-Print-Rec.
     if       Stock-Services-Flag = "Y"     *> ignore 'services' records
              go to da010-Read-Rec.
*>
*> next 2 in case start does not work and its a partial list and before from keys
*>
     if       ws-Stock-From not = spaces
         and  ws-Stock-From > Stock-Key
              go to da010-Read-Rec.
     if       ws-Abrev-From not = spaces
         and  ws-Abrev-From > Stock-Abrev-Key
              go to da010-Read-Rec.
*>
*> now for other report variations
*>
     if       ws-Reply = 2          *> all items in range
              go to da013-End-Range-Test.
*>
     if       (ws-Reply = 3 or 4)  *> Understocked
         and  (Stock-ReOrder-Pnt < Stock-Held)
              go to da010-Read-Rec.
*>
     if       (ws-Reply = 5 or 6)  *> no Stock
         and  (Stock-Held not = zero)
              go to da010-Read-Rec.
*>
     if       (ws-Reply = 7 or 8)  *> On Order
         and  (Stock-On-Order = zero
         and  Stock-Back-Ordered = zero
         and  Stock-Order-Date = zero
         and  Stock-Order-Due  = zero)
              go to da010-Read-Rec.
*>
*> Record passed specific tests, so can be included in report subject to next one
*>
 da013-End-Range-Test.
*>
*> next 2 if partial list and past the to keys
*>
     if       ws-Stock-To not = spaces
         and  Stock-Key > ws-Stock-To
              go to da030-Finish-Report.
*>
     if       ws-Abrev-To not = spaces
         and  Stock-Abrev-Key > ws-Abrev-To
              go to da030-Finish-Report.
*>
 da020-Print-Rec.
*>
*> Now we can deal with printing the record for all within scope
*>
     perform  zz030-Print-Heads.
     move     Stock-Abrev-Key              to l35-Abrev-Number.
     move     Stock-Key                    to l35-Stock-Number.
     move     Stock-Desc                   to l35-Desc.
     if       Stock-Held < Stock-ReOrder-Pnt
              move "U" to l35-Flag
     else
      if      Stock-Held = zero
              move "0" to l35-Flag
      else
              move space to l35-Flag.
*>
     if       Stock-Services-Flag = "Y"
              move space to l35-Flag.
*>
     if       Stock-Averaging
              move  Stock-Cost             to l35-Cost
     else
              move  Stock-Last-Actual-Cost to l35-Cost
     end-if
     move     Stock-Held                   to l35-Qty.
     move     Stock-Supplier-P1            to l35-Supplier.
     move     Stock-ReOrder-Pnt            to l35-ReOrder-Pnt.
     move     Stock-Std-ReOrder            to l35-Std-ReOrder.
     move     Stock-On-Order               to l35-On-Order.
     move     Stock-Back-Ordered           to l35-Back-Ordered.
     if       Stk-Manu-Used = 1
              move Stock-Work-in-Progress  to l35-WIP
     end-if
     if       Stock-Order-Date not = zero
              move Stock-Order-Date to u-bin
              perform zz060-Convert-Date
              move ws-date to l35-Order-Date
     else
              move spaces to l35-Order-Date
     end-if
     if       Stock-Order-Due not = zero
              move Stock-Order-Due to u-bin
              perform zz060-Convert-Date
              move ws-date to l35-Order-Due
     else
              move spaces to l35-Order-Due
     end-if
     write    Print-Record from Line-35 after 1.
     add      1 to Line-Cnt.
     go       to da010-Read-Rec.
*>
 da030-Finish-Report.
     if       Page-Nos = zero
        and   (spaces not = ws-Stock-From or not = ws-Stock-To)
              display ST302 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to da999-Exit.
     if       Page-Nos = zero
        and   (spaces not = ws-Abrev-From or not = ws-Abrev-To)
              display ST303 at line ws-23-lines col 1 with foreground-color 4 highlight.
*>
 da999-Exit.
     exit     section.
*>
 ea000-Process-Stock-Lists section.
*>********************************
*>
     if       ws-Abrev-To not = spaces
              perform varying a from 7 by -1 until a < 2 or ws-Abrev-To (a:1) not = space
                      move "z" to ws-Abrev-To (a:1)
              end-perform
     end-if
     if       ws-Stock-From not = spaces
              move ws-Stock-From to Stock-Key
              start Stock-File key not < Stock-Key invalid key
                  display ST306 at line ws-23-lines col 1 with foreground-color 4 highlight
                  move 15 to Error-Code
                  perform maps99
                  go to ea999-Exit
              end-start
     end-if
*>
     if       ws-Abrev-From not = spaces
              move ws-Abrev-From to Stock-Abrev-Key
              if   Stock-Abrev-Key (7:1) = space
                   move 0 to Stock-Abrev-Key (7:1)
              end-if
              start Stock-File key not < Stock-Abrev-Key invalid key
                  display ST305 at line ws-23-lines col 1 with foreground-color 4 highlight
                  move 15 to Error-Code
                  perform maps99
                  go to ea999-Exit
              end-start
     end-if
     if       ws-Partial = zero
              move  zeros to Stock-Abrev-Key
              start Stock-File key not < Stock-Abrev-Key
     end-if
     move     spaces to line-45.
     move     zero to ws-Rec-Cnt.
*>
 ea010-Read-Rec.
     Read     Stock-File next record at end
              go to ea030-Totals.
*>
*> next 2 in case start does not work and its a partial list and before from keys
*>
     if       ws-Stock-From not = spaces
         and  ws-Stock-From > Stock-Key
              go to ea010-Read-Rec.
     if       ws-Abrev-From not = spaces
         and  ws-Abrev-From > Stock-Abrev-Key
              go to ea010-Read-Rec.
*>
*> next 2 if partial list and past the to keys
*>
     if       ws-Stock-To not = spaces
         and  Stock-Key > ws-Stock-To
              go to ea030-Totals.
*>
     if       ws-Abrev-To not = spaces
         and  Stock-Abrev-Key > ws-Abrev-To
              go to ea030-Totals.
*>
*> Now we can deal with printing the record
*>
 ea020-Print-Rec.
     perform  zz040-Print-Heads.
     add      1 to ws-Rec-Cnt.
     move     spaces to line-45.
     move     Stock-Key          to l45-Stock-Number.
     move     Stock-Abrev-Key    to l45-Abrev-Stock.
     move     Stock-Supplier-P1  to l45-Supplier-No.
     move     Stock-Retail       to l45-Retail.
     move     Stock-Cost         to l45-Cost.
     if       l45-Costz = "00"
              move spaces to l45-Costz
     end-if
     if       Stock-Services-Flag not = "Y"
              move  Stock-Value        to l45-Value
              move  Stock-Held         to l45-Held
              move  Stock-ReOrder-Pnt  to l45-Reord-Pnt
              move  Stock-Std-ReOrder  to l45-Reord-Qty
              move  Stock-On-Order     to l45-Qty-Ordered
              move  Stock-Back-Ordered to l45-Qty-Back-Ord
     end-if
     move     Stock-Location     to l45-Location.
     if       Stock-Order-Date not = zero
              move Stock-Order-Date to u-bin
              perform zz060-Convert-Date
              move ws-date to l45-Date-Ordered
     else
              move spaces to l45-Date-Ordered
     end-if
     if       Stock-Order-Due not = zero
              move Stock-Order-Due to u-bin
              perform zz060-Convert-Date
              move ws-date to l45-Date-Due
     else
              move spaces to l45-Date-Due
     end-if
     move     Stock-Desc to l46-Desc.
     move     1 to a.
     move     spaces to l46-vars.
     if       Stock-Supplier-P2 not = spaces
           or Stock-Supplier-P3 not = spaces
              string "Secondary Suppliers" delimited by size into l46-vars pointer a
              if Stock-Supplier-P2 not = spaces
                  string " 1: "            delimited by size
                         Stock-Supplier-P2 delimited by size into l46-vars pointer a
              end-if
              if Stock-Supplier-P3 not = spaces
                  string " 2: "            delimited by size
                         Stock-Supplier-P3 delimited by size into l46-vars pointer a
              end-if
              add 2 to a
     end-if
     if       Stock-SA-Code not = spaces
              string "SA Code: "           delimited by size
                     Stock-SA-Group        delimited by size into l46-vars pointer a
              add 2 to a
     end-if
     if       Stock-PA-Code not = spaces
              string "PA Code: "           delimited by size
                     Stock-PA-Group        delimited by size into l46-vars pointer a
     end-if
*>
     if       Stock-Pre-Sales not = zero
              move Stock-Pre-Sales to ws-z6
              string "  Pre Sales :"       delimited by size
                     ws-z6                 delimited by size into l46-vars pointer a
     end-if
     if       Line-Cnt > 6
              move all "-" to print-record
              write print-record after 1
              write print-record from line-45 after 1
     else
              write print-record from line-45 after 1
     end-if
     write    print-record from line-46 after 1.
     add      2 to Line-Cnt.
     move     spaces to print-record.
     if       Stock-Services-Flag not = "Y"
          and (zero not = Stock-Construct-Bundle or not = Stock-Under-Construction
           or not = Stock-Work-in-Progress or Stock-Construct-Item not = spaces)
              move Stock-Construct-Bundle    to ws-z6
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
                                into print-record
              end-string
              write  print-record after 1
              add 1 to Line-Cnt
     end-if
     if       Stock-Services-Flag = "Y"
              move "Services only Product" to print-record
              write  print-record after 1
              add 1 to Line-Cnt
     end-if
     go       to ea010-Read-Rec.
*>
 ea030-Totals.
     if       Page-Nos = zero
        and   (spaces not = ws-Stock-From or not = ws-Stock-To)
              display ST302 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ea999-Exit.
     if       Page-Nos = zero
        and   (spaces not = ws-Abrev-From or not = ws-Abrev-To)
              display ST303 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to ea999-Exit.
*>
     if       Line-Cnt > Page-Lines - 3
              add 60 to Line-Cnt
              perform zz040-Print-Heads.
     move     spaces to Print-Record.
     move     ws-Rec-Cnt to ws-Rec-Total.
     string   " Total stock records Printed " delimited by size
              function trim (ws-Rec-Total leading) delimited by size into Print-Record.
     write    Print-Record after 3.
*>
 ea999-Exit.
     exit     section.
*>
 fa000-Process-History section.
*>****************************
*>
     if       ws-Abrev-To not = spaces
              perform varying a from 7 by -1 until a < 2 or ws-Abrev-To (a:1) not = space
                      move "z" to ws-Abrev-To (a:1)
              end-perform
     end-if
     if       ws-Stock-From not = spaces
              move ws-Stock-From to Stock-Key
              start Stock-File key not < Stock-Key invalid key
                  display ST306 at line ws-23-lines col 1 with foreground-color 4 highlight
                  move 15 to Error-Code
                  perform maps99
                  go to fa999-Exit
              end-start
     end-if
*>
     if       ws-Abrev-From not = spaces
              move ws-Abrev-From to Stock-Abrev-Key
              if   Stock-Abrev-Key (7:1) = space
                   move 0 to Stock-Abrev-Key (7:1)
              end-if
              start Stock-File key not < Stock-Abrev-Key invalid key
                  display ST305 at line ws-23-lines col 1 with foreground-color 4 highlight
                  move 15 to Error-Code
                  perform maps99
                  go to fa999-Exit
              end-start
     end-if
     if       ws-Partial = zero
              move  zeros to Stock-Abrev-Key
              start Stock-File key not < Stock-Abrev-Key
     end-if
     move     zero to ws-Rec-Cnt c.
     move     spaces to line-55.
*>
 fa010-Read-Rec.
     Read     Stock-File next record at end
              go to fa030-Finish-Report.
*>
*> next 2 in case start does not work and its a partial list and before from keys
*>
     if       ws-Stock-From not = spaces
         and  ws-Stock-From > Stock-Key
              go to fa010-Read-Rec.
     if       ws-Abrev-From not = spaces
         and  ws-Abrev-From > Stock-Abrev-Key
              go to fa010-Read-Rec.
*>
*> next 2 if partial list and past the to keys
*>
     if       ws-Stock-To not = spaces
         and  Stock-Key > ws-Stock-To
              go to fa030-Finish-Report.
*>
     if       ws-Abrev-To not = spaces
         and  Stock-Abrev-Key > ws-Abrev-To
              go to fa030-Finish-Report.
*>
*> Now we can deal with printing the record
*>
 fa020-Print-Rec.
     add      1 to ws-Rec-Cnt.
     perform  zz045-Print-Heads.
     move     Stock-Abrev-Key to l55-Abrev-Stock.
     move     Stock-Key       to l55-Stock-Number.
     move     Stock-Desc      to l55-Desc.
     add      Stock-Adds Stock-Deducts giving l55-This-Period.
     perform  varying a from 1 by 1 until a > 12
              add Stock-TD-Adds (a) Stock-TD-Deds (a) giving l55-This-Year (a)
     end-perform
     write    Print-Record from Line-55 after 1.
     add      1 to Line-Cnt.
*>
     if       Stk-Manu-Used = 1
              move spaces to line-55
              move zero to b                     *> dont bother printing WIPs if all zero
              if   Stock-Wip-Adds not = zero
                or Stock-Wip-Deds not = zero
                   move 1 to b
              end-if
              perform  varying a from 1 by 1 until a > 12
                       if   Stock-TD-WIP-Adds (a) not = zero
                         or Stock-TD-WIP-Deds (a) not = zero
                            move 1 to b
                       end-if
              end-perform
              if   b not = zero
                   add  Stock-Wip-Adds Stock-Wip-Deds giving l55-This-Period
                   perform  varying a from 1 by 1 until a > 12
                            add Stock-TD-WIP-Adds (a) Stock-TD-WIP-Deds (a)
                                                      giving l55-This-Year (a)
                   end-perform
                   move "WIP:" to l55-Lit-Wip
                   write Print-Record from Line-55 after 1
                   add 1 to Line-Cnt
                   move 1 to c
              end-if
     end-if
     go       to fa010-Read-Rec.
*>
 fa030-Finish-Report.
*>
*> On current page. Enough extra lines for total and if Partial report,
*>      extra 2 lines for from/to line
*>
     if       Page-Nos = zero
        and   (spaces not = ws-Stock-From or not = ws-Stock-To)
              display ST302 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to fa999-Exit.
     if       Page-Nos = zero
        and   (spaces not = ws-Abrev-From or not = ws-Abrev-To)
              display ST303 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to fa999-Exit.
*>
     if       Line-Cnt > Page-Lines - 5
              add 60 to Line-Cnt
              perform zz045-Print-Heads.
     move     spaces to Print-Record.
     move     ws-Rec-Cnt to ws-Rec-Total.
     string   " Total stock records Printed " delimited by size
              function trim (ws-Rec-Total leading) delimited by size into Print-Record.
     write    Print-Record after 3.
*>
     if       Stk-Manu-Used = 1
         and  c = zero
              move "WIP records were present but none had data" to Print-Record
              write Print-Record after 2.
*>
 fa999-Exit.
     exit     section.
*>
*>***********************************************
*>           Common Routines                    *
*>***********************************************
*>
 zz002-Print-Head-Top      section.
*>********************************
*>
     add      1            to Page-Nos.
     move     Prog-Name    to l11-Program.
     move     Page-Nos     to l11-Page.
     move     Usera        to l12-User.
     move     ws-Conv-Date to l12-Date.
     move     Report-Name  to l11-Title.
     if       Page-Nos not = 1
              write print-record from Line-11 after page
              move Line-12 to Print-Record
              if    b > 1
                    move Line-0 (1:b) to Print-Record (a:b)
              end-if
              write print-record after 1
              move  spaces to print-record
              write print-record after 1
     else
              write print-record from Line-11 before 1
              move Line-12 to Print-Record
              if    b > 1
                    move Line-0 (1:b) to Print-Record (a:b)
              end-if
              write print-record before 1
     end-if
     move     6 to Line-Cnt.
*>
     move     spaces to Print-Record
                        line-0.
 zz002-Exit.
     exit     section.
*>
 zz004-String-Range        section.
*>********************************
*>
*>      b is set prior to call
*> Insert 'Items ranging from '
*>
     string   Line-0a            delimited by size into Line-0 pointer b.
*> Insert stock-from or 'Start'
     if       spaces not = ws-Stock-From or not = ws-Stock-To
              if  ws-Stock-From = spaces
                  string "Start"       delimited by size into Line-0 pointer b
              else
                  string ws-Stock-From delimited by size into Line-0 pointer b
              end-if
*> Insert 'through'
              string Line-0b           delimited by size into Line-0 pointer b
*> Insert stock-to or 'End'
              if  ws-Stock-To = spaces
                  string "End"         delimited by size into Line-0 pointer b
              else
                  string ws-Stock-To   delimited by size into Line-0 pointer b
              end-if
     else
*>
*>  Must be Abrev so do similar as above but abrev may be missing trailing chars
*>
              if ws-Abrev-From = spaces
                  string "Start"       delimited by size into Line-0 pointer b
              else
                  string function trim (ws-Abrev-From trailing)
                                       delimited by size into Line-0 pointer b
              end-if
              string Line-0b           delimited by size into Line-0 pointer b
              if  ws-Abrev-To = spaces
                  string "End"         delimited by size into Line-0 pointer b
              else
                  string ws-Abrev-To   delimited by size into Line-0 pointer b
              end-if
     end-if
     compute a = (132 - b + 2) / 2.
*>
 zz004-Exit.
     exit     section.
*>
 zz010-Print-Heads         section.
*>********************************
*>      Valuation
*>
     if       Line-Cnt not > Page-Lines
              go to zz010-Exit.
     move     1 to b.
     if       ws-Partial = 1
              perform zz004-String-Range
     else
              string "All Items"       delimited by size into Line-0 pointer b
              compute a = (132 - b + 2) / 2.
     perform  zz002-Print-Head-Top.
*>
     if       Stk-Manu-Used = zero
              move spaces to l13-Lit-WIP l14-Lit-WIP
     else
              move "WIP"  to l13-Lit-WIP
              move "Qty"  to l14-Lit-WIP
     end-if
     write    print-record from Line-13 after 1.
     write    print-record from Line-14 after 1.
*>
     move     spaces to print-record.
     write    print-record after 1.
*>
 zz010-Exit.
     exit     section.
*>
 zz020-Print-Heads         section.
*>********************************
*>    Activity
*>
     if       Line-Cnt not > Page-Lines
              go to zz020-Exit.
*>
*> Build report Sub title based on sub menu selection and print it + field heads
*>
     move     1 to b.
     if       ws-Reply = 1 or 2
              string "All" delimited by size into Line-0 pointer b
     end-if
     if       ws-Reply = 3 or 5
              string "Active in Current "   delimited by size
                     ws-Current-Period      delimited by " " into Line-0 pointer b
     end-if
     if       ws-Reply = 4 or 6
              string "Active in "           delimited by size
                     ws-Todate-Period       delimited by "  "
                     " To Date"             delimited by size into Line-0 pointer b
     end-if
     add      1 to b.
     if       ws-Partial = 1
              perform zz004-String-Range
     else
              string "Items" delimited by size into Line-0 pointer b
              compute  a = (132 - b + 2) / 2
     end-if  *>  Next bit should work with any compiler (unless you know better)
     perform  zz002-Print-Head-Top.
*>
     if       Stock-Averaging
              move " Average" to l23-Lit-Average
              move " Stock"   to l23-Lit-Val
              move "Value"    to l24-Lit-Val
     else
              move "   Unit"  to l23-Lit-Average
              move spaces     to l23-Lit-Val l24-Lit-Val
     end-if
*>
*>  Set up period and to date heads
*>
     if       Stk-Period-Cur = "Q"
              move "< Current Quarter >" to l23-Lit-Cur
     else
      if      Stk-Period-Cur = "W"
              move "<- Current Week -->" to l23-Lit-Cur
      else
              move "<- Current Month ->" to l23-Lit-Cur.

     if       Stk-Period-Dat = "Q"
              move "< Quarter to Date >" to l23-Lit-YTD
     else
              move "<- Year to Date -->" to l23-Lit-YTD.
*>
     write    print-record from Line-23 after 1.
     write    print-record from Line-24 after 1.
     move     spaces to print-record.
     write    print-record after 1.
*>
 zz020-Exit.
     exit     section.
*>
 zz030-Print-Heads         section.
*>********************************
*>     Reorder
*>
     if       Line-Cnt not > Page-Lines
              go to zz030-Exit.
*>
*> Build report Sub title based on sub menu selection and print it + field heads
*>
     move     1 to b.
     if       ws-Reply = 1 or 2
              string "All " delimited by size into Line-0 pointer b
     end-if
     if       ws-Reply = 3 or 4
              string "Understocked " delimited by size into Line-0 pointer b
     end-if
     if       ws-Reply = 5 or 6
              string "Not in Stock " delimited by size into Line-0 pointer b
     end-if
     if       ws-Reply = 7 or 8
              string "On Order " delimited by size into Line-0 pointer b
     end-if
     if       ws-Partial = 1
              perform zz004-String-Range
     else
              string "Items" delimited by size into Line-0 pointer b
              compute  a = (132 - b + 2) / 2
     end-if
     perform  zz002-Print-Head-Top.
*>
     write    print-record from Line-33 after 1.
     write    print-record from Line-34 after 1.
     move     spaces to print-record.
     write    print-record after 1.
*>
 zz030-Exit.
     Exit     section.
*>
 zz040-Print-Heads         section.
*>********************************
*>
*>  Stock Lists
*>
     if       Line-Cnt not > Page-Lines
              go to zz040-Exit.
*>
     move     1 to b.
     if       ws-Partial = 1
              perform zz004-String-Range
     else
              string "All Items"       delimited by size into Line-0 pointer b
              compute a = (132 - b + 2) / 2.
     perform  zz002-Print-Head-Top.
*>
     write    print-record from Line-43 after 1.
     write    print-record from Line-44 after 1.
     move     spaces to print-record.
     write    print-record after 1.
*>
 zz040-Exit.
     exit     section.
*>
 zz045-Print-Heads         section.
*>********************************
*>
*> Stock History
*>
     if       Line-Cnt not > Page-Lines
              go to zz045-Exit.
*>
     move     1 to b.
     if       ws-Partial = 1
              perform zz004-String-Range
     else
              string "All Items"       delimited by size into Line-0 pointer b
              compute a = (132 - b + 2) / 2.
     perform  zz002-Print-Head-Top.
*>
     write    print-record from Line-53 after 1.
     write    print-record from Line-54 after 1.
     move     spaces to print-record.
     write    print-record after 1.
*>
 zz045-Exit.
     exit     section.
*>
 zz050-Report-Selection  section.
*>******************************
*>
*>  Common for all reports
*>
     move     spaces to ws-Stock-From ws-Stock-To
                        ws-Abrev-From ws-Abrev-To.
     move     zeroes to ws-Partial ws-First-Rec ws-Reply.
*>
     if       Menu-Reply = 1    *> Valuation report, only get stk no. range
              go to zz050-Get-Disp-03.
     if       Menu-Reply = 3    *> ReOrder reports
              go to zz050-Get-Disp-01.
     if       Menu-Reply = 4 or = 5    *> Stock item or History report
              go to zz050-Get-Disp-03.
*>
*> If here, it's a Activity report  (2)
*>
     accept   display-02.
     if       ws-Reply = 9
              go to zz050-Exit.
     if       ws-Reply < 1 or > 6
              go to zz050-Report-Selection.
     if       ws-Reply = 2 or 5 or 6   *>  2(range), 5(Range current period), 6(range todate)
              go to zz050-Get-Disp-03.
*>
*> now left with 1 (All), 3 All current period) & 4 (All, Period to date)
*>
     go       to zz050-Exit.
*>
 zz050-Get-Disp-01.
*>
*>  Setup for Reorder
*>
     accept   display-01.
     if       ws-Reply = 9
              go to zz050-Exit.
     if       ws-Reply < 1
              go to zz050-Get-Disp-01.
     if       ws-Reply = 2 or 4 or 6 or 8  *> 2(range), 4(Range understock), 6(range unstock)
                                           *> 8 (Range on Order)
              go to zz050-Get-Disp-03.
*>
*> now left with 1 (All), 3 All understocked), 5 (All, unstocked) & 7 (all on order)
*>
     go       to zz050-Exit.
*>
 zz050-Get-Disp-03.
     accept   display-03.
     move     function upper-case (ws-Stock-From) to ws-Stock-From.
     move     function upper-case (ws-Stock-To)   to ws-Stock-To.
     move     function upper-case (ws-Abrev-From) to ws-Abrev-From.
     move     function upper-case (ws-Abrev-To)   to ws-Abrev-To.
*>
*> Can't have both Stock and Abrev in any combination
*>
     if       (ws-Stock-From not = spaces and ws-Abrev-From not = spaces)
          or  (ws-Stock-To   not = spaces and ws-Abrev-To   not = spaces)
          or  (ws-Stock-From not = spaces and ws-Abrev-To   not = spaces)
          or  (ws-Stock-To   not = spaces and ws-Abrev-From not = spaces)
              display ST304 at line ws-23-lines col 1 with foreground-color 4 highlight
              move 15 to Error-Code
              perform maps99
              go to zz050-Get-Disp-03.
*>
     if       ws-Stock-From not = spaces and ws-Stock-To not = spaces
         and  ws-Stock-From > ws-Stock-To
              display ST307 at line ws-23-lines col 1 with foreground-color 4 highlight
              move 15 to Error-Code
              perform maps99
              go to zz050-Get-Disp-03.
*>
     if       ws-Abrev-From not = spaces and ws-Abrev-To not = spaces
         and  ws-Abrev-From > ws-Abrev-To
              display ST308 at line ws-23-lines col 1 with foreground-color 4 highlight
              move 15 to Error-Code
              perform maps99
              go to zz050-Get-Disp-03.
*>
     if       ws-Stock-From not = spaces or ws-Stock-To not = spaces
           or ws-Abrev-From not = spaces or ws-Abrev-To not = spaces
              move 1    to ws-Partial
     else
              move zero to ws-Partial.
*>
 zz050-Exit.
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
