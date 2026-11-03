       >>source free
*>*************************************************************
*>                                                            *
*>               Stock Item File Importer                     *
*>                TEMPLATE program ONLY                       *
*>                                                            *
*>*************************************************************
*>
 identification          division.
*>================================
*>
*>**
      program-id.         st060.
*>**
*>    Author.             V.B.Coen, FBCS
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Stock Item File Importer.
*>                        This program can be used to import records stock from another system.
*>                        HOWEVER it will need to be modified to reflect the format and
*>                        layout of the old system. We can undertake this service on
*>                        receipt of the first five records both as a file dump and a
*>                        full listing/s (containing as many of the data fields that is
*>                        used as possible as well as the full file to be imported.
*>                        If you have it, the record layout of the file from the
*>                        documentation of the old system or from their technical support
*>                        department if they are still in business.
*>                        Otherwise:
*>
*>                        It is recommended to create the five records using the lowest
*>                        values for the stock number eg, 0000000test1 though 000000test5
*>                        and all numeric fields 1234567 etc and likewise money fields with
*>                        say 123456.78 or 987654.32 etc. Also alphabetic fields eg, item
*>                        descriptions with 'abcdefghijklmnop' or 'mlkjihgfedcba' etc.
*>                        This will help in examining the file for the correct layout for
*>                        each field.
*>                        This is a chargeable service and is charged at the rate of
*>                        25 pounds sterling per hour with a maximum of eight hours but
*>                        the average is five. Contact via email to vbcoen@btconnect.com.
*>                        --------------------------------------------------------------
*>
*>                        This program assumes that the supplier information is NOT
*>                        available on the old system and will use the value in
*>                        ws-Default-Supplier and you will need to manually add/change
*>                        them via Stock Record Amend having loaded up all suppliers in
*>                        Sales Ledger including the default one as set up in this program
*>                        as well as the analysis code for each record however
*>                        here you can leave it as the default code 'a1' for both sales
*>                        and purchase (see ws-Default-PA for Purchase and ws-Default-SA
*>                        for Sales. You can modify the source to different values prior
*>                        to compiling and running this program.
*>                        Also the default operation regarding stock item numbers and the
*>                        abbreviated number is for the Stock Item, use from old file,
*>                        abbreviated, Generate new starting with 0000001.
*>                        Here you should change to your requirements.
*>
*>                        WARNING, WARNING: This program must NOT be used as is.
*>                        ^^^^^^^^^^^^^^^^* ************************************
*>                        It needs to be changed according the the data file to be imported
*>                        as well as the field order in the imported file.
*>                        You then need to test it to make sure that it is working correctly
*>                        before used in a live environment. IT does not have any code in to
*>                        support duplicate records or rewrite on write error as a safe guard
*>                        to existing data.
*>**
*>    Version.            See prog-name in Ws.
*>**
*>    Called modules.
*>                        maps04 - Date testing and conversion.
*>                        SL070  - Analysis codes set up - Defaults only.
*>**
*>    Error messages used.
*>                        ST000.
*>
*>                        ST601.
*>                        ST602.
*>                        ST603.
*>                        ST604.
*>**
*>    Changes:
*> 08/06/13 vbc - Rewritten in Cobol from scratch via st010 & updated to v3.01.37.
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
     select import-file             assign File-101
                                    organization sequential
                                    status fs-reply.
*>
 data                    division.
*>================================
*>
 file section.
*>------------
*>
 copy "fdstock.cob".
*>
 fd  Import-file.			*> Assumes that this file is a comma delimited file
 01  Import-Record.             	*> eg, field-1,field2,field3 etc where alphanemerics are in quotes
     03  filler          pic x(512).	*> This needs changing to reflect actual + 2 (if needed)
 copy "wsstock.cob".     		*>  replacing WS-Stock-Desc by Stock-Desc.
*>
 working-storage section.
*>-----------------------
*>
 77  prog-name           pic x(15)       value "ST060 (3.01.00)".
 77  Evaluation-Msg      pic x(25)       value spaces.
 77  File-101            pic x(64)       value spaces.
 77  ws-Import-Date-Format pic 9         value 1.		*> UK date format, but change to one data uses
     88  ws-Date-UK                      value 1.  *> dd/mm/yyyy
     88  ws-Date-USA                     value 2.  *> mm/dd/yyyy
     88  ws-Date-Intl                    value 3.  *> yyyy/mm/dd
 77  ws-Default-PA       pic xxx         value "Pa1".     	*> Default anal code for PL.
 77  ws-Default-SA       pic xxx         value "Sa1".     	*> Default anal code for SL.
 77  ws-Default-Supplier pic x(7)        value "A000011". 	*> Default Supplier code.
 77  ws-Abrev-Value      pic 9(7)        value zero.      	*> Default Abrev code.
 77  ws-Test-Desc        pic x(36)       value spaces.		*> Used to clear quotes from alphanumeric fields
 77  ws-Delimiter-Found  pic x           value space.
 77  Import-Mode         pic 9           value 1.		*> change to 2 if needed.
     88  Process-Comma                   value 1.
     88  Process-Reg                     value 2.
 77  ws-Hist-Reset-Flag  pic 9           value 1.		*> CHANGE to zero if importing these
     88  ws-Reset-Hist                   value 1.
 77  ws-Record-Count     pic 9(7)        value zero.		*> read count
 77  ws-Write-Count      pic 9(7)        value zero.
 77  ws-Disp-Count       pic z(6)9.
*>
 01  ws-Number-X-8       pic x(8).
 01  ws-Number-X.
     03  ws-Number       pic 9(6)        value zero.
 01  ws-Amount-X-14      pic x(14).
 01  ws-Amount-X.
     03  ws-Amount       pic 9(13)       value zero.		*> In pence of 4 places eg 9(9)[v]9999
 01  ws-Chk-Number       pic 9(6).
 01  ws-Chk-Amount       pic 9(13).
 01  ws-Chk-Amount-V     redefines ws-Chk-Amount pic 9(9)v9(4).
 01  ws-Amount-Length    binary-char     value zero.
 01  ws-Pence-Length     binary-char     value zero.
 01  ws-Pounds-Length    binary-char     value zero.
*>
 01  work-fields.
     03  ws-reply        pic x.
     03  a               binary-char unsigned value zero.
     03  b               pic 9(4)   comp     value zero.
     03  c               pic 9(4)   comp     value zero.
     03  c2              pic 9(4)   comp     value zero.
     03  d               pic 9               value zero.     *> flag for decimal point
     03  e               pic 9               value zero.
     03  f               pic 99.
     03  ws-stock-dates.
         05  ws-Stock-Order-Date pic x(12).
         05  ws-Stock-Order-Due  pic x(12).
     03  ws-Test-Date    pic x(10).
*>
 01  ws-date-formats.			*> not yet used
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
 copy "wsmaps03.cob".
*>
 01  Error-Messages.
*> System Wide
     03  ST000          pic x(36) value "ST000 Error on Writing to Stock File".
*> Module Specific
     03  ST601          pic x(42) value "ST601 Error on Open/Reading Import File - ".
     03  ST602          pic x(31) value "ST602 Note error and hit return".
     03  ST603          pic x(31) value "ST603 Note total and hit return".
     03  ST604          pic x(39) value "ST604 Note error and hit return to quit".
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
 procedure division using ws-calling-data system-record to-day file-defs.
*>**********************************************************************
*>
 Declaratives.
*>
 File-Error-On-IF section.
*>
     use after error procedure on Import-File.
 a00-IF-Error-1.
     if       fs-reply not = zero
              perform  Eval-Status
              display  ST601          at 2301
              display  fs-reply       at 2337
              display  Evaluation-Msg at 2340
              display  ST602          at 2401
              accept   ws-reply       at 2433
              close Stock-File Import-File
     end-if
     exit    program.
*>
 Eval-Status.
*>==========
*>
     move     spaces to Evaluation-Msg.
 copy "FileStat-Msgs.cpy"  replacing STATUS by fs-reply
                                     msg    by Evaluation-Msg.
*>
 File-Error-On-Stock section.
*>
     use after error procedure on Stock-File.
 a10-Stock-Error-1.
     if       fs-reply not = zero
              perform  Eval-Status
              display ST000    at 2301 with foreground-color 4 highlight
              display fs-reply at 2338 with foreground-color 4 highlight
              display  Evaluation-Msg at 2340
              display  ST602          at 2401
              accept   ws-reply       at 2433
              close Stock-File Import-File
     end-if
     exit program.
*>
 main-exit.   exit.
*>
 end declaratives.
*>
 aa000-Core              section.
*>******************************
*>
 aa010-Get-File-for-Import.
     perform  zz010-Display-Heading.
     display  "Provide full path and file name of file to be imported" at 0701 with foreground-color 2.
     accept   File-101 at 0902 with foreground-color 6 update.
     perform  ba000-Import-Stock.
     go       to aa999-exit.
*>
 maps04.
     call     "maps04" using maps03-ws.
*>
 aa999-Exit.
     goback.
*>
 ba000-Import-Stock      section.
*>******************************
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
     end-if
     open     input Import-File.
*>
 ba010-Get-A-Record.
*>
*>  If stock item is =< 7 make both stock & Abrev the same otherwse create new Abrev key
*>  inclemented by 1 from ws-Abrev-Value
*>
     initialize Import-Record.			*> Needed ? can't do any harm !
     move     spaces to ws-stock-dates.			*> NEEDED
*>
     read     Import-File record at end
              go to  ba998-Main-End.
     add      1 to ws-Record-Count.
     initialize Stock-Record.
     if       Process-Comma
              go to ba030-Process-Comma.
*>
 ba020-Process-Regular.
*>
     move     corresponding WS-Stock-Record to Stock-Record.
*>
     move     WS-Stock-Key to Stock-Key.
     perform  varying a from 13 by -1 until ws-Stock-Key (a:1) not = space
                                         OR a = 1
     end-perform
*> 							Now have size of stock key
     if       a < 8
              move ws-Stock-Key to Stock-Abrev-Key
     else
              add   1              to ws-Abrev-Value
              move  ws-Abrev-Value to Stock-Abrev-Key
     end-if
*>
*>  Instead of prev. if, when abrev key exists in imported record :
*>
*>     move     ws-Abrev-Key to Stock-Abrev-Key.
*>
     move     ws-Stock-Desc to Stock-Desc.
     if       ws-Reset-Hist
              initialize Stock-Mthly-Running-Totals
                         Stock-History in Stock-Record
     end-if
*>
*>						Any more moves needed then here ??
*>
     write    stock-record.
     add      1 to ws-Write-Count.
     go       to ba010-Get-A-Record.
*>
 ba030-Process-Comma.
*>
*>  ************************************************************
*>  *  THIS NEEDS TO BE CHANGED TO REFLECT import file LAYOUT  *
*>  ************************************************************
*>
     move     1 to b.
*>
*> Used if not abrev-key available in imput file so increment by 1 for each record
*>   No not the best. NOTE that both keys MUST NOT have duplicate keys
*>
     unstring Import-Record  delimited by "," into Stock-Key count c pointer b.
     if       c not > 7
              move Stock-Key to Stock-Abrev-Key
     else
              add 1 to ws-Abrev-Value
              move ws-Abrev-Value to Stock-Abrev-Key
    end-if
*>
*>  Here we are using a default supplier but if used on old file use rem'd unstring instead
*>
     move     ws-Default-Supplier to Stock-Supplier-P1 in Stock-Record.
*>     unstring Import-Record  delimited by "," into Stock-Supplier-P1 pointer b.
*>
     unstring Import-Record  delimited by "," into ws-Test-Desc pointer b.
     if       ws-Test-Desc (1:1) = quote or "'" or "`"
              move ws-Test-Desc (1:1) to ws-Delimiter-Found
              perform varying c from 36 by -1 until c < 4
                                                 or ws-Test-Desc (c:1) = ws-Delimiter-Found
              end-perform
              move ws-Test-Desc (2:c - 2) to Stock-Desc
     else
              move ws-Test-Desc to Stock-Desc
     end-if
     move     ws-Default-PA to Stock-PA-Code in Stock-Record.
     move     ws-Default-SA to Stock-SA-Code in Stock-Record.
     move     "N"           to Stock-Services-Flag in Stock-Record.
*>
     move     zero to ws-Number ws-Number-X-8.
     unstring Import-Record  delimited by "," into ws-Number-X-8 count c pointer b.
     perform  zz025-Format-Number.
     move     ws-Chk-Number to Stock-ReOrder-Pnt in Stock-Record.
*>
     move     zero to ws-Number ws-Number-X-8.
     unstring Import-Record  delimited by "," into ws-Number-X-8 count c pointer b.
     perform  zz025-Format-Number.
     move     ws-Chk-Number to Stock-Std-ReOrder in Stock-Record.
*>
     move     zero to ws-Number ws-Number-X-8.
     unstring Import-Record  delimited by "," into ws-Number-X-8 count c pointer b.
     perform  zz025-Format-Number.
     move     ws-Chk-Number to Stock-Back-Ordered in Stock-Record.
*>
     move     zero to ws-Number ws-Number-X-8.
     unstring Import-Record  delimited by "," into ws-Number-X-8 count c pointer b.
     perform  zz025-Format-Number.
     move     ws-Chk-Number to Stock-On-Order in Stock-Record.
*>
     move     zero to ws-Number ws-Number-X-8.
     unstring Import-Record  delimited by "," into ws-Number-X-8 count c pointer b.
     perform  zz025-Format-Number.
     move     ws-Chk-Number to Stock-Held in Stock-Record.
*>
     move     zero to ws-Number ws-Number-X-8.
     unstring Import-Record  delimited by "," into ws-Number-X-8 count c pointer b.
     perform  zz025-Format-Number.
     move     ws-Chk-Number to Stock-Pre-Sales in Stock-Record.
*>
*> Formats of import amounts need to be examined and these changed to reflect it
*>  including ws- field sizes
*>  The move will truncate the source field as its a 9(9)v9999 moving to smaller fields
*>    but that is ok as digits trancated are zero but still check it after running
*>
     move     zero to ws-Amount ws-Amount-X-14.
     unstring Import-Record  delimited by "," into ws-Amount-X-14 count c pointer b.
     perform  zz030-Format-Amount.
     move     ws-Chk-Amount-V to Stock-Retail in Stock-Record.
*>
     move     zero to ws-Amount ws-Amount-X-14.
     unstring Import-Record  delimited by "," into ws-Amount-X-14 count c pointer b.
     perform  zz030-Format-Amount.
     move     ws-Chk-Amount-V to Stock-Cost in Stock-Record.
*>
*>  Note that LAST field in record must also be delimited by space
*>
     move     zero to ws-Amount ws-Amount-X-14.
     unstring Import-Record  delimited by "," or space into ws-Amount-X-14 count c pointer b.
     perform  zz030-Format-Amount.
     move     ws-Chk-Amount-V to Stock-Value in Stock-Record.
*>
*>  Here for Due and order dates if present and they will be in quotes and dates are ASSUMED as 8 chars long
*>    So we will ingnore the first and last chars (")
*>
     unstring Import-Record  delimited by "," or space into ws-Stock-Order-Date pointer b.
     move     ws-Stock-Order-Date (2:10) to ws-Test-Date.
     perform  zz050-Validate-Date.
     if       u-Bin not zero
              move u-bin to Stock-Order-Date in Stock-Record
     end-if
*>
*> IF this is the LAST field in the record add 'or space' but if not can remove 'or space '
*>     Same applies above field
*>
     unstring Import-Record  delimited by "," or space into ws-Stock-Order-Due pointer b.
     move     ws-Stock-Order-Due (2:10) to ws-Test-Date.
     perform  zz050-Validate-Date.
     if       u-Bin not zero
              move u-bin to Stock-Order-Due in Stock-Record
     end-if.
*>
 ba040-Write-Stock.
     write    stock-record.
     add      1 to ws-Write-Count.
     go       to ba010-Get-A-Record.
*>
 ba998-Main-End.
     close    Stock-File Import-File.
     move     ws-Record-Count to ws-Disp-Count.
     display  "Records Imported - " at 0601 with foreground-color 2 erase eos.
     display  ws-Disp-Count         at 0620 with foreground-color 2.
     move     ws-Write-Count  to ws-Disp-Count.
     display  "Records Written  - " at 0601 with foreground-color 2.
     display  ws-Disp-Count         at 0620 with foreground-color 2.
     display  ST603                 at 0801 with foreground-color 2.
     accept   ws-reply              at 0835.
*>
 ba999-Exit.
     exit     section.
*>
*>****************************************************
*>               Common Routines Block               *
*>****************************************************
*>
 zz010-Display-Heading      section.
*>*********************************
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  usera at 0301 with foreground-color 3.
     perform  zz010-convert-date.
     display  u-date at 0171 with foreground-color 2.
*>
     display  "Stock File Importer" at 0124 with foreground-color 2.
     go       to zz010-Exit.
*>
 zz010-convert-date.
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
 zz025-Format-Number       section.
*>********************************
*>
*> C has char count
*>
     perform  zz027-Clean-Number.		*> remove any quotes if present
     move     zero to ws-Chk-Number.
     if       ws-Number-X not numeric
              go to zz025-Exit.
*>
     perform  varying d from 6 by -1 until c < 1
              move ws-Number (c:1) to ws-Chk-Number (d:1)
              subtract 1 from c
     end-perform.
*>
*>  Now have number right justified in ws-chk-number
*>
 zz025-Exit.
     exit     section.
*>
 zz027-Clean-Number        section.
*>********************************
*>
*> Check of number is in quotes and clear them otherwise move number
*>
     move     zeros to ws-Number.
     move     c to c2.
     if       ws-Number-X-8 (1:1) = quote or "'" or "`"
              move ws-Number-X-8 (1:1) to ws-Delimiter-Found
              perform varying c from 8 by -1 until c < 3
                                                 or ws-Number-X-8 (c:1) = ws-Delimiter-Found
              end-perform
              move ws-Number-X-8 (2:c - 2) to ws-Number
     else
              move ws-Number-X-8 (1:c2) to ws-Number-X		*> now have unjustified number but not number?
     end-if
     if       ws-Number not numeric
              move zero to ws-Number
     end-if.
*>
 zz027-Exit.
     exit     section.
*>
 zz030-Format-Amount       section.
*>
*> A reminder of what we can get: 0.n 0.nn nnnn nn.n nn.nn
*> Source = ws-amount-X-14
*> target = ws-chk-amount
*>
     move     zeros to ws-Amount.
     move     c  to c2.
     if       ws-Amount-X-14 (1:1) = quote or "'" or "`"
              move ws-Amount-X-14 (1:1) to ws-Delimiter-Found
              perform varying c from c2 by -1 until c < 3		*> Should happen on 1st pass
                                                 or ws-Amount-X-14 (c:1) = ws-Delimiter-Found
              end-perform
              move ws-Amount-X-14 (2:c2 - 2) to ws-Amount-X	*> got 9(9).9999 LEFT justified
              if   c = c2
                   subtract 2 from c2				*> including the '.'
              else						*> We have problems with the data so quit
                 display "Problem with amount - "       at 1601 with foreground-color 3 highlight
                 display ws-Amount-X-14                 at 1623 with foreground-color 3
                 display "Has invalid quotes or other!" at 1638 with foreground-color 3 highlight
                 display ST604                          at 1701 with foreground-color 3
                 accept  ws-reply                       at 1741
                 close import-File Stock-File
                 stop run
              end-if
     else
              move ws-Amount-X-14 (1:c2) to ws-Amount-X		*> now have left justified number
     end-if
     move     c2 to ws-Amount-Length				*> including the '.'
     move     zero to e.					*> test if we have a period
     inspect  ws-Amount-X tallying e for all ".".
     if       e not = zero					*> We do, so find it
              perform  varying c from c2 by -1 until ws-Amount-X (c:1) = "."
                                                  or c < 2	*> can't be 1st char so this test should not happen !
              end-perform
     end-if							*> if c = 1 then no pounds & all is pence
*>
*>  Now we know where the period is within ws-amount-X as c
*>  AND If e = zero we have whole number only
*>
     move     zeros to ws-Chk-Amount.
     if       e not zero
       and    c > 1
              compute f = c + 1					*> 1st pence position
              compute ws-Pence-length = c2 - c			*> pence length
              compute ws-Pounds-Length = c - 1
              move ws-Amount (f:ws-Pence-Length)  to ws-Chk-Amount (10:ws-Pence-Length)
              move ws-Amount (1:ws-Pounds-Length) to ws-Chk-Amount (10 - ws-Pounds-Length:ws-Pounds-Length)
     end-if
     if       e = zero								*> Only pounds and no pence or '.'
              move ws-Amount-Length to f
              move ws-Amount (1:f) to ws-Chk-Amount (10 - f:f)			*> got the pounds
     end-if
*>
*>  Test the data and if this appears its a possible program bug or a data problem
*>
     if     ws-Chk-Amount not numeric						*> We have problems with the data so quit
            display "Problem with amount - " at 1601 with foreground-color 3 highlight
            display ws-Amount-X-14           at 1623 with foreground-color 3
            display "Has become - "          at 1638 with foreground-color 3 highlight
            display ws-Chk-Amount            at 1651 with foreground-color 3
            display ST604                    at 1701 with foreground-color 3
            accept  ws-reply                 at 1741
            close import-File Stock-File
            stop run
     end-if.

 zz030-Exit.
     exit     section.
*>
 zz050-Validate-Date       section.
*>********************************
*>
*>  Converts USA/Intl to UK date format for processing and modified for Import data ws field.
*>*******************************===========================================================
*> Input:   ws-test-date
*> output:  u-date/ws-date as uk date format
*>          u-bin not zero if valid date
*>
     move     ws-test-date to ws-date.
     if       ws-Import-Date-Format = zero
              move 1 to ws-Import-Date-Format.
     if       ws-Date-UK
              go to zz050-test-date.
     if       ws-Date-USA                *> swap month and days
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
