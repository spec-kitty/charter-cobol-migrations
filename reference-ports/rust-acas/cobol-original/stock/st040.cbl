       >>source free
*>*************************************************************
*>                                                            *
*>        Stock Control Reset Period and Year Totals          *
*>                                                            *
*>*************************************************************
*>
 identification          division.
*>================================
*>
*>**
      program-id.         st040.
*>**
*>    author.             V.B.Coen, FBCS
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Called modules.
*>                        maps99.
*>**
*>    Error messages used.
*>
*>                        ST000.
*>
*>                        ST401.
*>                        ST402.
*>**
*> Changes:
*> 28/06/09 vbc - .00 Written in Cobol from scratch against v2 specs.
*> 21/07/09 vbc - .02 Program title change.
*> 11/12/11 vbc -     Changed version from 1.00.xx to 3.01.xx, in keeping with the rest of ACAS
*>                .03 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 12/05/13 vbc - .04 Changed wsnames to in common as pl010 called in st010.
*> 16/05/13 vbc - .05 Changed wsnames to in copybook see above.
*> 25/05/13 vbc - .06 Test for Activity-Rep-Run wrong shoud be for zero.
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
 data                    division.
*>================================
*>
 file section.
*>------------
*>
 copy "fdstock.cob".
*>
 working-storage section.
*>-----------------------
*>
 77  Prog-Name           pic x(15)       value "ST040 (3.01.06)".
*>
 01  work-fields.
     03  ws-Reply-Year    pic x                   value space.
         88 Clear-Year                            value "Y".
     03  ws-Reply-Period  pic x                   value space.
         88 Clear-Period                          value "Y".
     03  ws-Reply         pic x                   value space.

     03  ws-lines        binary-char  unsigned   value zero.
     03  ws-22-lines     binary-char  unsigned   value zero.
     03  ws-23-lines     binary-char  unsigned   value zero.
     03  ws-env-lines    pic 999                 value zero.
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
 copy "wsfnctn.cob".
*>
 01  Error-Messages.
     03  ST000          pic x(36) value "ST000 Error on Writing to Stock File".
*> Module specific
     03  ST401          pic x(26) value "ST401 Stock File not found".
     03  ST402          pic x(17) value "ST402 Y or N only".
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
 procedure division using ws-calling-data system-record to-day file-defs.
*>**********************************************************************
*>
 aa000-Core                 section.
*>*********************************
*>
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
*>
*> Get current date into locale format for display
*>
     perform  zz070-Convert-Date.
     move     ws-Date to ws-Conv-Date.
*>
 aa010-Questions.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Stock Activity Reset" at 0131 with foreground-color 2.
     display  ws-Conv-Date at 0171 with foreground-color 2.
*>
     display  "Can I clear this " at 0410 with foreground-color 2.
     if       Stk-Period-Cur = "Q"
              display "Quarter" at 0427 with foreground-color 2
     else
      if      Stk-Period-Cur = "W"
              display "   Week" at 0427 with foreground-color 2
      else
              display "  Month" at 0427 with foreground-color 2.
*>
     display  " Totals? [ ] (N/Y)" at 0434 with foreground-color 2.
     display  "Can I clear End of Year Totals on Stock records [ ] (N/Y)" at 0610 with foreground-color 2.
*>
 aa020-Accept-Loop.
     move     "N" to ws-Reply-Year ws-Reply-Period.
     accept   ws-Reply-Period at 0444  with foreground-color 6 update.
     move     function upper-case (ws-Reply-Period) to ws-Reply-Period.
     if       ws-Reply-Period not = "Y" and not = "N"
              display ST402 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to aa020-Accept-Loop.
     accept   ws-Reply-Year at 0659  with foreground-color 6 update.
     move     function upper-case (ws-Reply-Year) to ws-Reply-Year.
     if       ws-Reply-Year not = "Y" and not = "N"
              display ST402 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to aa020-Accept-Loop.
     display  " " at line ws-23-lines col 1 with erase eol.
     if       not Clear-Year and not Clear-Period
              go to aa999-Exit.
*>
     if       Clear-Period
              display "Will Clear Period totals" at 0801 with foreground-color 3 highlight.
     if       Clear-Year
              display "Will Clear Year totals"   at 0901 with foreground-color 3 highlight.
*>
 aa030-U-Sure.
     if       Stk-Activity-Rep-Run = zero
              display "You have NOT run audit reports" at line ws-23-lines col 1 with foreground-color 6 highlight
              move 45 to Error-Code
              perform maps99
              go to aa999-Exit.
*>
     display  "Have you made backups of your data and are you sure?  [ ] (N/Y)"
                                       at 1210 with foreground-color 2 highlight.
     move     "N" to ws-Reply.
     accept   ws-Reply at 1265 with foreground-color 6 update.
     move     function upper-case (ws-Reply) to ws-Reply.
     if       ws-Reply not = "N" and not = "Y"
              display ST402 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to aa030-U-Sure.
     if       ws-Reply = "N"
              go to aa999-Exit.
     display  " " at line ws-23-lines col 1 with erase eol.
*>
     open     i-o Stock-File.
     if       fs-reply not = zero
              display ST401 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 28 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              go to aa999-Exit.
*>
     display  "Updating your Stock file as requested" at 1210 with foreground-color 2 highlight erase eol.
*>
     perform  ba000-Clear-Totals.
     go       to aa999-Exit.
*>
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
 ba000-Clear-Totals    section.
*>****************************
*>
     read     Stock-File next record at end
              close Stock-File
              go to ba999-Exit.
     if       Clear-Period
              initialize Stock-Mthly-Running-Totals.
     if       Clear-Year
              initialize Stock-History.
     rewrite  Stock-Record invalid key
              display ST000 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 38 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              close Stock-File
              go to ba999-Exit.
     go       to ba000-Clear-Totals.
*>
 ba999-Exit.
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
