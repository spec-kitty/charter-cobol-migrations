       >>source free
*>*************************************************************
*>                                                            *
*>            Stock Control File Compression                  *
*>                                                            *
*> This recreates the indexed Stock file ignoring deleted     *
*>      records and is not normally used except for           *
*>   maybe yearly or if a large number of items are deleted   *
*>    from the system which has a lot of items.               *
*>############################################################*
*>  Note that the program tests that the file record lengths  *
*>     are the same for both temp file and the stock file and *
*>     will produce a fatal error msg if not the same.        *
*>                                                            *
*>*************************************************************
*>
 identification          division.
*>================================
*>
*>**
      program-id.         st050.
*>**
*>    author.             V.B.Coen, FBCS
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2013 and later, Vincent Bryan Coen.
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
*>                        ST501.
*>                        ST502.
*>                        ST503.
*>                        ST504.
*>                        ST505.
*>                        ST506
*>**
*> Changes:
*> 29/06/09 vbc - .00 Written in Cobol from scratch against v2 specs.
*> 07/09/10 vbc - .00 Added notes with prog description above.
*> 27/11/11 vbc - .01 Added extra tests and display if errors found during
*>                    file processing, also added open/close on temp file
*>                    BUT rem'd out until testing complete <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*> 11/12/11 vbc -     Changed version from 1.00.xx to 3.01.xx, in keeping with the rest of ACAS
*>                .02 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 12/05/13 vbc - .03 Changed wsnames to in common as pl010 called in st010.
*> 14/05/13 vbc - .04 Support for File recovery from existing temp file.
*> 16/05/13 vbc - .05 Changed wsnames to in copybook see above.
*> 22/05/13 vbc - .06 Added a stock value comp during process.
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
     select   Temp-Stock-File      assign  file-9
                                   access  sequential
                                   status  fs-reply.

 data                    division.
*>================================
*>
 file section.
*>------------
*>
 copy "fdstock.cob".
 fd  Temp-Stock-File.
 01  Temp-Stock-Record.
     03  filler          pic x(400).
*>
 working-storage section.
*>-----------------------
*>
 77  Prog-Name           pic x(15)       value "ST050 (3.01.06)".
 77  Eval-Msg            pic x(25)       value spaces.
*>
 01  work-fields.
     03  ws-Reply        pic x                   value space.
     03  ws-Recovery     pic x                   value "N".
     03  a               pic 9999.
     03  b               pic 9999.
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
*> copy "wsmaps03.cob".
*> copy "wsmaps09.cob".
*>
 01  Error-Messages.
     03  ST000          pic x(36) value "ST000 Error on Writing to Stock File".
*> Module specific
     03  ST501          pic x(26) value "ST501 Stock File not found".
     03  ST502          pic x(17) value "ST502 Y or N only".
     03  ST503          pic x(29) value "ST503 Error opening temp file".
     03  ST504          pic x(32) value "ST504 Error writing to temp file".
     03  ST505          pic x(55) value "ST505 Error: Length of Stock File not same as Temp File".
     03  ST506          pic x(30) value "ST506 Error opening Stock File".
*>
 01  Error-Code         pic 999    value zero.
*>
 linkage section.
*>**************
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
*>  Check that Stock file record length is same as Temp file layout
*>      if not program, MUST be changed to fix and recompiled
*>
     move     function length (Stock-Record) to a.
     move     function length (Temp-Stock-Record) to b.
     if       a not = b
              display " " at 0401 with erase eos
              display ST505 at 0401 with foreground-color 4 highlight
              display "Stock File = " at 0601 with foreground-color 2
              display a at 0614 with foreground-color 2 highlight
              display "Temp  File = " at 0701 with foreground-color 2
              display b at 0714 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              go to aa999-Exit.
*>
 aa010-Questions.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Stock Compression Utility" at 0128 with foreground-color 2.
     display  ws-Conv-Date at 0171 with foreground-color 2.
     display  "This process will clean up the Stock File of deleted records"       at 0410 with foreground-color 2.
     display  "Is this a recovery from a previous run of this process - [ ] (N/Y)" at 0610 with foreground-color 2.
*>
 aa020-Recovery.
     move     "N" to ws-Recovery.
     accept   ws-Recovery at 0668 with foreground-color 6 update.
     move     function upper-case (ws-Recovery) to ws-Recovery.
     if       ws-Recovery not = "N" and not = "Y"
              display ST502 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to aa020-Recovery.
*>
 aa030-U-Sure.
     display  "Confirm you wish this to happen & that you have a backup [ ] (N/Y)" at 0810 with foreground-color 2.
     move     "N" to ws-Reply.
     accept   ws-Reply at 0868 with foreground-color 6 update.
     move     function upper-case (ws-Reply) to ws-Reply.
     if       ws-Reply not = "N" and not = "Y"
              display ST502 at line ws-23-lines col 1 with foreground-color 4 highlight
              go to aa030-U-Sure.
     if       ws-Reply = "N"
              go to aa999-Exit.
     display  " " at line ws-23-lines col 1 with erase eol.
*>
     if       ws-Recovery = "Y"
              display  "recreating Stock file from temp file as requested" at 1210
                                                with foreground-color 2 highlight erase eol
              perform  ba000-Process-Stock-Comp.
              go       to aa999-Exit.
*>
     open     input Stock-File.
     if       fs-reply not = zero
              display ST501 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 28 with foreground-color 2 highlight
              perform  ba030-Eval-Status
              display Eval-Msg at line ws-23-lines col 31 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              go to aa999-Exit.
*>
     open     output Temp-Stock-File.
     if       fs-reply not = zero
              display ST503 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 31 with foreground-color 2 highlight
              perform  ba030-Eval-Status
              display Eval-Msg at line ws-23-lines col 34 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              go to aa999-Exit.
*>
     display  "Updating your Stock file as requested" at 1210 with foreground-color 2 highlight erase eol.
*>
     perform  ba000-Process-Stock-Comp.
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
 ba000-Process-Stock-Comp    section.
*>**********************************
*>
     if       ws-Recovery = "Y"
              go to ba010-Build-Stock
     end-if
     read     Stock-File next record at end
              close Stock-File
                    Temp-Stock-File
              go to ba010-Build-Stock.
*>
*> Here any record clean ups if needed
*>
     compute  Stock-Value = Stock-Held * Stock-Cost.
     write    Temp-Stock-Record from Stock-Record.
     if       fs-Reply not = zero
              display ST504 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 34 with foreground-color 2 highlight
              perform  ba030-Eval-Status
              display Eval-Msg at line ws-23-lines col 37 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              close Stock-File
                    Temp-Stock-File
              go to ba999-Exit.
     go       to ba000-Process-Stock-Comp.
*>
 ba010-Build-Stock.
     open     input Temp-Stock-File.
     if       fs-reply not = zero
              display ST503 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 31 with foreground-color 2 highlight
              perform  ba030-Eval-Status
              display Eval-Msg at line ws-23-lines col 34 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              go to ba999-Exit.
*>
     open     output Stock-File.
     if       fs-reply not = zero
              display ST506 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 32 with foreground-color 2 highlight
              perform  ba030-Eval-Status
              display Eval-Msg at line ws-23-lines col 35 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              close Temp-Stock-File
              go to ba999-Exit.
*>
 ba020-Read-Temp.
     read     Temp-Stock-File at end
              close Temp-Stock-File
                    Stock-File
*>
*>   These two lines to put back in after testing so that temp file made zero length
*>
*>              open output Temp-Stock-File
*>              close Temp-Stock-File
*>
              go to ba999-Exit.
*>
*>  This error should never happen unless HDD error as new file will be = or smaller than original
*>
     write    Stock-Record from Temp-Stock-Record invalid key
              display ST000 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 38 with foreground-color 2 highlight
              perform  ba030-Eval-Status
              display Eval-Msg at line ws-23-lines col 41 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              close Stock-File
                    Temp-Stock-File
              go to ba999-Exit.
*>
     if       fs-Reply not = zero
              display ST000 at line ws-23-lines col 1 with foreground-color 4 highlight
              display fs-reply at line ws-23-lines col 38 with foreground-color 2 highlight
              perform  ba030-Eval-Status
              display Eval-Msg at line ws-23-lines col 41 with foreground-color 2 highlight
              move 45 to Error-Code
              perform maps99
              close Stock-File
                    Temp-Stock-File
              go to ba999-Exit.
     go       to ba020-Read-Temp.
*>
 ba030-Eval-Status.
 copy "FileStat-Msgs.cpy"   replacing STATUS by fs-Reply
                                      MSG by Eval-Msg.
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
