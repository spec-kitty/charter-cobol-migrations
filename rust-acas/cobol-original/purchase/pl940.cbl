       >>source free
*>*******************************************************
*>                                                      *
*>                Cheque  File  Writer                  *
*>                                                      *
*>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*
*>                                                      *
*>   You MUST modify this module to suit your cheque    *
*>  format/layout.  This module produces a text file    *
*>    that can be sent to a specific print spool but    *
*> usually pass to a program eg, MS word, Libreoffice   *
*> writer etc, to print it using mail/merge with a      *
*>  macro and/or create a file suitable to be input     *
*>    into your online bill payment sub-system.         *
*> Because of the wide range of possiblities no module  *
*>    is supplied, however we can help in creating one  *
*> for your specific requirements.                      *
*> As most users no longer use cheques they use a       *
*> modified version to produce only payment data for    *
*> their bankers to a given bank format.                *
*> See manual for additional information                *
*>*******************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl940.
*>**
*>    Author.             V B Coen FBCS, 18/04/84
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Cheque File Writer.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Error messages used.
*>                        PL902
*>                        PL903
*>**
*>    Called Modules.     Maps04.
*>**
*> Changes:
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00
*> 15/09/10 vbc - Changed to free src format.
*> 16/12/11 vbc - .04 Error msgs to SLnnn.Support for dates other than UK
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
*>-----------
*>
 copy "selpl.cob".
*>
     select  cheque-file   assign file-33
                           organization  line sequential.
*>
 copy "selpay.cob".
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdpl.cob".
 fd  cheque-file.
*>
 01  cheque-record       pic x(645).
*>
 copy "fdpay.cob".
 working-storage section.
*>----------------------
 77  prog-name           pic x(15)       value "PL940 (3.01.04)".
 77  test-amount         pic 9(7)v99.
 77  asterix-fill        pic x(64)       value all "*".
*>
 copy "wsfnctn.cob".
 copy "wsoi.cob".
*>
 01  ws-data.
     03  y               pic 99.
     03  z               pic 99.
     03  cheque-nos      pic 9(8).
     03  pound-flag      pic 9           value zero.
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
 copy "wsmaps03.cob".
*>
 01  Error-Messages.
*> System Wide
*>     03  PL005          pic x(18) value "PL005 Invalid Date".
*> Module specific
     03  PL902          pic x(18) value "PL902 Missing data".
     03  PL903          pic x(36) value "PL903 No data to process. Hit return".
*>
 01  cheque.
*>
*>  rec size 645 bytes
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
     03  c-gross          pic z(6)9.99.
     03  filler           pic x           value ",".
     03  c-cheque-x.
         05  c-cheque     pic z(8)9.
     03  filler           pic x           value ",".
     03  c-date           pic x(10).
     03  filler           pic x           value ",".
     03  filler                          occurs 9.
         05  c-inv        pic x(10).
         05  c-inv-filler pic x.
         05  c-folio      pic z(7)9       blank when zero.
         05  c-folio-fil  pic x.
         05  c-value      pic z(6)9.99    blank when zero.
         05  c-last       pic x.
*>
 01  word-filler.
     03  filler          pic x(15) value "One*".
     03  filler          pic x(15) value "Two*".
     03  filler          pic x(15) value "Three*".
     03  filler          pic x(15) value "Four*".
     03  filler          pic x(15) value "Five*".
     03  filler          pic x(15) value "Six*".
     03  filler          pic x(15) value "Seven*".
     03  filler          pic x(15) value "Eight*".
     03  filler          pic x(15) value "Nine*".
     03  filler          pic x(15) value "Ten*".
     03  filler          pic x(15) value "Eleven*".
     03  filler          pic x(15) value "Twelve*".
     03  filler          pic x(15) value "Thirteen*".
     03  filler          pic x(15) value "Fourteen*".
     03  filler          pic x(15) value "Fifteen*".
     03  filler          pic x(15) value "Sixteen*".
     03  filler          pic x(15) value "Seventeen*".
     03  filler          pic x(15) value "Eighteen*".
     03  filler          pic x(15) value "Nineteen*".
     03  filler          pic x(15) value "Twenty*".
     03  filler          pic x(15) value "Twenty-One*".
     03  filler          pic x(15) value "Twenty-Two*".
     03  filler          pic x(15) value "Twenty-Three*".
     03  filler          pic x(15) value "Twenty-Four*".
     03  filler          pic x(15) value "Twenty-Five*".
     03  filler          pic x(15) value "Twenty-Six*".
     03  filler          pic x(15) value "Twenty-Seven*".
     03  filler          pic x(15) value "Twenty-Eight*".
     03  filler          pic x(15) value "Twenty-Nine*".
     03  filler          pic x(15) value "Thirty*".
     03  filler          pic x(15) value "Thirty-One*".
     03  filler          pic x(15) value "Thirty-Two*".
     03  filler          pic x(15) value "Thirty-Three*".
     03  filler          pic x(15) value "Thirty-Four*".
     03  filler          pic x(15) value "Thirty-Five*".
     03  filler          pic x(15) value "Thirty-Six*".
     03  filler          pic x(15) value "Thirty-Seven*".
     03  filler          pic x(15) value "Thirty-Eight*".
     03  filler          pic x(15) value "Thirty-Nine*".
     03  filler          pic x(15) value "Forty*".
     03  filler          pic x(15) value "Forty-One*".
     03  filler          pic x(15) value "Forty-Two*".
     03  filler          pic x(15) value "Forty-Three*".
     03  filler          pic x(15) value "Forty-Four*".
     03  filler          pic x(15) value "Forty-Five*".
     03  filler          pic x(15) value "Forty-Six*".
     03  filler          pic x(15) value "Forty-Seven*".
     03  filler          pic x(15) value "Forty-Eight*".
     03  filler          pic x(15) value "Forty-Nine*".
     03  filler          pic x(15) value "Fifty*".
     03  filler          pic x(15) value "Fifty-One*".
     03  filler          pic x(15) value "Fifty-Two*".
     03  filler          pic x(15) value "Fifty-Three*".
     03  filler          pic x(15) value "Fifty-Four*".
     03  filler          pic x(15) value "Fifty-Five*".
     03  filler          pic x(15) value "Fifty-Six*".
     03  filler          pic x(15) value "Fifty-Seven*".
     03  filler          pic x(15) value "Fifty-Eight*".
     03  filler          pic x(15) value "Fifty-Nine*".
     03  filler          pic x(15) value "Sixty*".
     03  filler          pic x(15) value "Sixty-One*".
     03  filler          pic x(15) value "Sixty-Two*".
     03  filler          pic x(15) value "Sixty-Three*".
     03  filler          pic x(15) value "Sixty-Four*".
     03  filler          pic x(15) value "Sixty-Five*".
     03  filler          pic x(15) value "Sixty-Six*".
     03  filler          pic x(15) value "Sixty-Seven*".
     03  filler          pic x(15) value "Sixty-Eight*".
     03  filler          pic x(15) value "Sixty-Nine*".
     03  filler          pic x(15) value "Seventy*".
     03  filler          pic x(15) value "Seventy-One*".
     03  filler          pic x(15) value "Seventy-Two*".
     03  filler          pic x(15) value "Seventy-Three*".
     03  filler          pic x(15) value "Seventy-Four*".
     03  filler          pic x(15) value "Seventy-Five*".
     03  filler          pic x(15) value "Seventy-Six*".
     03  filler          pic x(15) value "Seventy-Seven*".
     03  filler          pic x(15) value "Seventy-Eight*".
     03  filler          pic x(15) value "Seventy-Nine*".
     03  filler          pic x(15) value "Eighty*".
     03  filler          pic x(15) value "Eighty-One*".
     03  filler          pic x(15) value "Eighty-Two*".
     03  filler          pic x(15) value "Eighty-Three*".
     03  filler          pic x(15) value "Eighty-Four*".
     03  filler          pic x(15) value "Eighty-Five*".
     03  filler          pic x(15) value "Eighty-Six*".
     03  filler          pic x(15) value "Eighty-Seven*".
     03  filler          pic x(15) value "Eighty-Eight*".
     03  filler          pic x(15) value "Eighty-Nine*".
     03  filler          pic x(15) value "Ninety*".
     03  filler          pic x(15) value "Ninety-One*".
     03  filler          pic x(15) value "Ninety-Two*".
     03  filler          pic x(15) value "Ninety-Three*".
     03  filler          pic x(15) value "Ninety-Four*".
     03  filler          pic x(15) value "Ninety-Five*".
     03  filler          pic x(15) value "Ninety-Six*".
     03  filler          pic x(15) value "Ninety-Seven*".
     03  filler          pic x(15) value "Ninety-Eight*".
     03  filler          pic x(15) value "Ninety-Nine*".
 01  filler  redefines  word-filler.
     03  wordn           pic x(15)       occurs  99.
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
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "Cheque Print File Generation" at 0128 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
     open     input purchase-file.
     open     i-o   pay-file.
     if       fs-reply not = zero
              display PL903 at 0401 with foreground-color 2
              accept s1 at 0438
              close purchase-file pay-file
              goback.
     open     output cheque-file.
     perform  varying z from 1 by 1 until z > 9
              move "," to c-inv-filler (z) c-folio-fil (z)
              if  z < 6
                  move "," to c-adr-filler (z)
              end-if
     end-perform
*>
     display  "First Cheque number - [        ]" at 0611   with foreground-color 2.
     accept   cheque-nos at 0634 with foreground-color 3.
     display  "Payment date        - [          ]" at 0811 with foreground-color 2.
     move     ws-date to ws-test-date.
*>
 get-date.
     display  ws-test-date at 0834 with foreground-color 3.
     accept   ws-test-date at 0834 with foreground-color 3 update.
     move     zero  to  u-bin.
     perform  zz050-Validate-Date.
     if       u-bin = zero
              go to  get-date.
     move     ws-test-date to c-date.
*>
 read-purchase.
     read     pay-file  next  record
              at end  go to  main-end.
*>
     if       pay-gross  <  .01
              go to  read-purchase.
*>
     move     pay-supl-key  to  purch-key  c-account.
     read     purchase-file invalid key
              move PL902 to purch-name purch-address.
*>
     move     purch-name to  c-name.
     move     spaces to c-address (1) c-address (2)
                        c-address (3) c-address (4) c-address (5).
     move     1  to  z.
     perform  varying y from 1 by 1 until y > 5
              unstring purch-address delimited by pl-delim into c-address (y)  pointer  z
              end-unstring
     end-perform
*>
*> get words.
*>
     move     pay-gross  to  c-gross  test-amount.
     move     spaces  to  c-words-1  c-words-2.
     move     1  to  z.
     move     zero to pound-flag.
*>
     divide   test-amount  by  1000000  giving  y.
     compute  test-amount  =  test-amount - (1000000 * y).
*>
     if       y  >  0
              string  wordn (y)  delimited  by  "*"   into  c-words-1  with  pointer  z.
     if       y  >  0
              string  " Million "  delimited  by  "*" into  c-words-1  with  pointer  z.
*>
     divide   test-amount  by  100000  giving  y.
     compute  test-amount  =  test-amount - (100000 * y).
*>
     if       y  >  0
              string  wordn (y)  delimited  by  "*"   into  c-words-1 with  pointer  z.
     if       y  >  0
              string  " Hundred and " delimited by "*" into c-words-1 with  pointer  z.
*>
     divide   test-amount  by  1000  giving  y.
     compute  test-amount  =  test-amount - (1000 * y).
*>
     if       y  >  0
              string  wordn (y)  delimited  by  "*"   into  c-words-1 with  pointer  z.
     if       y  >  0
              string  " Thousand " delimited by "*"   into  c-words-1 with  pointer  z.
     if       z > 1
              move 1 to pound-flag.
*>
     string   asterix-fill  delimited  by  size into  c-words-1 with  pointer  z.
*>
     divide   test-amount  by  100  giving  y.
     compute  test-amount  =  test-amount - (100 * y).
*>
     move     1  to  z.
*>
     if       y  >  0
              string  wordn (y)  delimited  by  "*" into  c-words-2  with  pointer  z.
     if       y  >  0
              string  " Hundred and "  delimited  by  "*" into  c-words-2  with  pointer  z.
*>
     divide   test-amount  by  1  giving  y.
     compute  test-amount  =  test-amount - y.
*>
     if       y  >  0
              string  wordn (y)  delimited  by  "*" into  c-words-2  with  pointer  z.
     if       z > 1
              move 1 to pound-flag.
     if       y  >  0
       or     pound-flag = 1
              string  " Pounds "  delimited  by  "*" into  c-words-2  with  pointer  z.
*>
     multiply 100  by  test-amount  giving  y.
*>
     if       y  >  0
              string  wordn (y)  delimited  by  "*"  into  c-words-2 with  pointer  z.
     if       y  >  0
              string  " Pence "  delimited  by  "*"  into  c-words-2 with  pointer  z.
*>
     if       y  =  0
              string  "ONLY"   delimited  by  size   into  c-words-2  with  pointer  z.
*>
     perform  varying z from 1 by 1 until z > 9
              move pay-folio (z)   to  c-folio (z)
              move pay-invoice (z) to  c-inv (z)
              move pay-value (z)   to  c-value (z)
              if   z  <  9
                   move  "," to c-last (z)
              else
                   move  " " to c-last (z)
              end-if
     end-perform
*>
     if       pay-sortcode = zero
              move cheque-nos to c-cheque pay-cheque
              add 1 to cheque-nos
     else
              move zero     to pay-cheque
              move "BACS"   to c-cheque-x
     end-if
     write    cheque-record from cheque.
*>
     move     u-bin  to  pay-date.
     rewrite  pay-record.
*>
*> now loop back for next item....
*>
     go       to read-purchase.
*>
 main-end.
*>********
*>
     close    cheque-file purchase-file pay-file.
     exit     program.
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
 maps04       section.
*>*******************
*>
     call     "maps04"  using  maps03-ws.
*>
 maps04-exit.
     exit     section.
*>
