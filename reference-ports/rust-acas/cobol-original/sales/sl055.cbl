       >>source free
*>*****************************************************************
*>                                                                *
*>             INVOICE   POST - EXTRACT  ANALYSIS                 *
*>                                                                *
*>        passes o/p ITM2 to sl060 in a 2 step process            *
*>                                                                *
*>*****************************************************************
*>
 identification          division.
*>===============================
*>
      program-id.         sl055.
*>**
*>    Author.             Cis Cobol Conversion By V B Coen FBCS, 18/10/83
*>                        For Applewood Computers.
*>
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Invoice Proof Report Extract & Analysis.
*>                        Updates analysis values, invoice and outputs to itm2 that goes into sl060
*>                         must look at getting rid of itm2 for itm3
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps99.
*>
*>**
*>    File Used.	  OTM2.	Open Item File 2 - Preposting.
*>                        Invoice.
*>                        analysis.
*>                        Analysis Values.
*>**
*>    Error messages used.
*>                        SL002.
*>                        SL121.
*>                        SL122.
*>
*>    Changes:
*> 15/01/83 Sjw - 400420
*> 13/02/83 Vbc - 400432.
*> 21/02/83 Vbc - Check For Invoices Not Yet Printed.
*> 18/04/83 Vbc - On Credit Notes;Change Mult -1 From Ih To Io.
*> 26/04/83 Vbc - Zeroise Oi-Line After Writing Out Record.
*> 23/10/83 Vbc - Conversion To Cis Cobol.
*> 19/12/83 Vbc - Allow For System Record 4.
*> 01/01/84 Vbc - Support Oi-Hold-Flag.
*> 28/03/84 Vbc - Tidy Up Display Sign-On Message.
*> 31/03/84 Vbc - Only Inv Header Recs Are Copied To Openitm File.
*> 01/04/84 Vbc - Put Wsinv2 Into Fdinv=Fdinv2, & Dont Copy Into
*>                Ws On Reading, Writing ;Speed Prog.
*> 09/05/84 Vbc - Support For Indexed Openitm File
*> 09/10/84 Vbc - Insert Analysis Code From Sl130.
*> 13/11/84 Vbc - Extract:Applied Test Go To Main-Ex,(Exit).
*> 03/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 24/11/11 vbc - .03 Error msgs to SLnnn.Support for dates other than UK
*> 08/12/11 vbc - .04 Support for path+filenames.
*> 09/12/11 vbc -     Updated version to 3.01.nn
*> 11/12/11 vbc - .05 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 21/03/12 vbc - .06 Cosmetic, killed move/test on il-product/il-comment to just test product(1:1)
*>                    got rid of calls to maps99 except for a fail-fix-fail scenario !
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
*>
 input-output            section.
 file-control.
*>
 copy "seloi2.cob".
 copy "selanal.cob".
 copy "selinv.cob".
 copy "selval.cob".
*>
 data                    division.
*>===============================
*>
 file section.
*>
 copy "fdanal.cob".
 copy "fdinv2.cob".
 copy "fdval.cob".
 copy "fdoi2.cob".
 copy "wsoi.cob".
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15)    value "SL055 (3.01.06)".
 77  Exception-Msg       pic x(25)    value spaces.
*>
 copy "wsfnctn.cob".
*>
 01  error-code          pic 999.
*>
 01  ws-data.
     03  ws-reply        pic x.
     03  ws-p-flag       pic 9                value zero.
     03  save-code       pic xxx.
     03  v-exists        pic 9.
     03  ws-inv-amt      pic s9(7)v99  comp-3 value zero.
     03  work-2          pic s9(7)v99  comp-3 value zero.
     03  ws-vat-totalv   pic s9(7)v99  comp-3 value zero.
     03  ws-vatr-totalv  pic s9(7)v99  comp-3 value zero.
     03  ws-carr-totalv  pic s9(7)v99  comp-3 value zero.
     03  ws-disc-totalv  pic s9(7)v99  comp-3 value zero.
     03  work-3          pic s9(5)     comp   value zero.
     03  ws-vat-totalt   pic s9(5)     comp   value zero.
     03  ws-vatr-totalt  pic s9(5)     comp   value zero.
     03  ws-carr-totalt  pic s9(5)     comp   value zero.
     03  ws-disc-totalt  pic s9(5)     comp   value zero.
     03  b               pic 99        comp   value zero.
     03  c               pic 99        comp   value zero.
     03  ws-env-lines    pic 999       value zero.
     03  ws-lines        binary-char unsigned value zero.
     03  ws-23-lines     binary-char unsigned value zero.
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
*>       NONE
     03  SL002          pic x(31) value "SL002 Note error and hit return".
*>     03  SL003          pic x(28) value "SL003 Hit Return To Continue".
*> Module specific
     03  SL121          pic x(40) value "SL121 Error writing to Open Item 2 File ".
     03  SL122          pic x(51) value "SL122 Unprinted Invoices Exist. Correct & Run Again".
*>
linkage section.
*>**************
*>
 01  to-day              pic x(10).
 copy "wsnames.cob".
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wssys4.cob".
*>
 procedure division using ws-calling-data
                          system-record
                          system-record-4
                          to-day
                          file-defs.
*>========================================
*>
 Declaratives.
*>
 File-Error-On-OTM2 section.
*>
     use after error procedure on open-item-file-2.
 a00-OTM2-Error-1.
     if       fs-reply not = zero
              perform  Eval-Status
              display  SL121         at line ws-23-lines col 1
              display  fs-reply      at line ws-23-lines col 41
              display  Exception-Msg at line ws-23-lines col 44
              display  SL002         at line ws-lines col 01
              accept   ws-reply      at line ws-lines col 33
     end-if
     goback.
*>
 Eval-Status.
*>==========
*>
     move     spaces to exception-msg.
 copy "FileStat-Msgs.cpy"  replacing STATUS by fs-reply
                                     msg    by exception-msg.
*>
 main-exit.   exit.
*>
 end declaratives.
*>
 da000-mainline section.
*>=====================
*>
     accept   ws-env-lines   from lines.
     if       ws-env-lines < 24
              move  24 to ws-env-lines ws-lines
     else
              move  ws-env-lines   to ws-lines
     end-if
     subtract 1 from ws-lines giving ws-23-lines.
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
*>
     open     input value-file.
     if       fs-reply not = zero
              close value-file
              open  output  value-file.
     close    value-file.
*>
     if       file-status (15) not = 1			*> This should have happened in sl910 invoice create
              move 1 to ws-Process-Func ws-Sub-Function
              call "sl070" using ws-calling-data
                                 system-record
                                 to-day
                                 file-defs
              end-call
              if    File-Status (15) not = 1       *> Only if the call failed for some unknown reason
                    move 29  to  error-code
                    call "maps99" using error-code ws-calling-data
                    move 15 to error-code
                    call "maps99" using error-code ws-calling-data
                    go to da999-Menu-Exit
              end-if
     end-if
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Invoice Post Extract" at 1201  with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
     display  "Working...........Please Wait" at 1201 with foreground-color 2.
*>
     open     i-o invoice-file value-file analysis-file.
     open     extend open-item-file-2.
     if       fs-reply not = zero
              close open-item-file-2
              open output open-item-file-2.
*>
 da010-Read-Loop.
     read     invoice-file next record at end
              go to  da040-Close-Files.
*>
     if       ih-test = zero
              go to da020-Header-Analysis.
*>
     if       il-analyised
              go to da010-Read-Loop.
*>
     if       il-product (1:1) = "/"		*> comment only
              go to da010-Read-Loop.
     move     "S"   to va-system.
     move     il-pa to va-group.
     move     1     to v-exists.
*>
     read     value-file invalid key
              perform  db000-Create
              move zero to v-exists.
*>
     add      1  to  va-t-this.
     add      1  to  va-t-year.
     if       il-type not = 3			*> Cr. notes
              add il-net to  va-v-this
              add il-net to  va-v-year
     else
              subtract il-net from va-v-this
              subtract il-net from va-v-year.
*>
     if       v-exists  = zero
              write  value-record
     else
              rewrite  value-record.
*>
     if       va-second  = space
              go to da010-Read-Loop.
*>
     move     space  to  va-second.
     read     value-file  invalid key
              go to da010-Read-Loop.
*>
     add      1 to va-t-this.
     add      1 to va-t-year.
     if       il-type not = 3
              add il-net to  va-v-this
              add il-net to  va-v-year
     else
              subtract il-net from va-v-this
              subtract il-net from va-v-year.
     rewrite  value-record.
*>
     move     "Z"  to  il-update.		*> Analysied flag changed from z (1/6/13)
     rewrite  invoice-record.
*>
     go       to da010-Read-Loop.
*>
 da020-Header-Analysis.				*> Headers only
     if       ih-analyised and applied
              go to da010-Read-Loop.
*>
     if       ih-type = 4                	*> Proformas
              go to da030-Skip-Invoice.
*>
     if       pending
       or     ih-status-L not = "L"
              move 1 to ws-p-flag
              go to da030-Skip-Invoice.
*>
     perform  dd000-Extract.
*>
     if       ih-analyised
              rewrite invoice-record
              go to da010-Read-Loop.
*>
     add      ih-c-vat ih-vat ih-e-vat giving work-2.
     if       ih-type = 3
              multiply -1 by work-2.
     if       work-2 not = zero and
              ih-type not = 1
              add 1 to ws-vat-totalt
              add work-2 to ws-vat-totalv.
     if       work-2 not = zero and
              ih-type = 1
              add 1 to ws-vatr-totalt
              add work-2 to ws-vatr-totalv.
     move     ih-carriage to work-2.
     if       ih-type = 3
              multiply -1 by work-2.
     if       work-2 not = zero
              add 1 to ws-carr-totalt
              add work-2 to ws-carr-totalv.
     move     ih-deduct-amt to work-2.
     if       ih-type = 3
              multiply -1 by work-2.
     if       work-2 not = zero
              add 1 to ws-disc-totalt
              add work-2 to ws-disc-totalv.
*>
     move     "Z" to ih-update.
     rewrite  invoice-record.
     go       to da010-Read-Loop.
*>
 da030-Skip-Invoice.
     add      1 to invoice-nos.
     move     space to invoice-let.
     move     zeros to item-nos.
     start    invoice-file key not < invoice-key invalid key
              go to da040-Close-Files.
     go       to da010-Read-Loop.
*>
 da040-Close-Files.
     move     "Svo" to va-code.
     move     ws-vat-totalt to work-3.
     move     ws-vat-totalv to work-2.
     perform  dc000-Store-Specials
     move     "vp" to va-group.
     move     ws-vatr-totalt to work-3.
     move     ws-vatr-totalv to work-2.
     perform  dc000-Store-Specials
     move     "zc" to va-group.
     move     ws-carr-totalt to work-3.
     move     ws-carr-totalv to work-2.
     perform  dc000-Store-Specials
     move     "zd" to va-group.
     move     ws-disc-totalt to work-3.
     move     ws-disc-totalv to work-2.
     perform  dc000-Store-Specials
     close    invoice-file analysis-file value-file
              open-item-file-2.
*>
     move     1  to  file-status (18).
     if       ws-p-flag not = zero			*> Unprinted invoice are present
              display SL122        at line ws-23-lines col 1
              display SL002        at line ws-lines    col 1
              accept  ws-reply     at line ws-lines    col 33
              exit program.				*> Yep, I know but just in case extra code goes here!
*>
 da999-Menu-Exit.
     exit     program.
*>
*>****************************************************************
*>      P R O C E D U R E S                                      *
*>****************************************************************
*>
 db000-Create section.
*>===================
*>
     move     va-code  to  pa-code.
*>
     read     analysis-file  invalid key
              go to db010-Create-Anal.
*>
     move     analysis-record  to  value-record
     move     zero  to  va-t-this  va-t-last va-t-year
                        va-v-this  va-v-last va-v-year.
*>
     if       va-second  = space
              go to db999-Main-Exit.
*>
     move     va-code  to  save-code.
*>
     move     space    to  va-second.
     move     va-code  to  pa-code.
*>
     read     analysis-file  invalid key
              move  save-code  to  pa-code
              go to db999-Main-Exit.
*>
     move     analysis-record  to  value-record
     move     zero  to  va-t-this  va-t-last  va-t-year
                        va-v-this  va-v-last  va-v-year.
*>
     write    value-record.
*>
     move     save-code  to  va-code  pa-code.
     read     analysis-file  invalid key
              go to  db999-Main-Exit.
*>
     move     analysis-record  to  value-record
     move     zero  to  va-t-this  va-t-last  va-t-year
                        va-v-this  va-v-last  va-v-year.
*>
     go       to db999-Main-Exit.
*>
 db010-Create-Anal.
     move     va-code to pa-code.
     move     zero to pa-gl.
     move     spaces to pa-print.
     move     "Emergency Name" to pa-desc.
     write    analysis-record.
     if       pa-second not = space
              move space to pa-second
              write analysis-record.
     go       to db000-Create.
*>
 db999-Main-Exit.
     exit     section.
*>
 dc000-Store-Specials  section.
*>============================
*>
     move     1  to  v-exists.
*>
     read     value-file  invalid key
              perform  db000-Create
              move zero to v-exists.
*>
     add      work-3 to  va-t-this.
     add      work-3 to  va-t-year.
     add      work-2 to  va-v-this.
     add      work-2 to  va-v-year.
*>
     if       v-exists  = zero
              write  value-record
     else
              rewrite value-record.
*>
     move     space  to  va-second.
     read     value-file  invalid key
              go to dc999-Main-Exit.
*>
     add      work-3 to  va-t-this.
     add      work-3 to  va-t-year.
     add      work-2 to  va-v-this.
     add      work-2 to  va-v-year.
     rewrite  value-record.
*>
 dc999-Main-Exit.
     exit     section.
*>
 dd000-Extract section.
*>====================
*>
*> only process header records here, drop pro-formas.
*>  ignore records which have already been copied.
*>
     if       applied
              go to dd999-Main-Ex.
*>
     initialize oi-header.
     move     ih-p-c      to  oi-p-c.
     move     ih-invoice  to  oi-invoice.
     move     ih-customer to  oi-customer.
     move     ih-date     to  oi-date.
     move     zero        to  oi-b-nos oi-b-item.
     move     ih-order    to  oi-description.
     move     ih-net      to  oi-net.
     move     ih-extra    to  oi-extra.
     move     ih-carriage to  oi-carriage.
     move     ih-vat      to  oi-vat.
     move     ih-c-vat    to  oi-c-vat.
     move     ih-e-vat    to  oi-e-vat.
     move     ih-discount to  oi-discount.
     move     zero        to  oi-paid.
     move     ih-deduct-amt  to oi-deduct-amt.
     move     ih-deduct-vat  to oi-deduct-vat.
     move     ih-deduct-days to oi-deduct-days.
     move     zero        to  oi-status oi-date-cleared oi-days.   *> hmm, initialised, not needed but acts as a note
     move     ih-type     to  oi-type.				   *> oi-days is credit terms, status = open
     move     space to oi-applied oi-unapl oi-hold-flag.
*>
     if       ih-type  = 3                                       *>  Cr. Notes
              multiply -1  by  oi-deduct-amt
              multiply -1  by  oi-deduct-vat
              multiply -1  by  oi-net
              multiply -1  by  oi-extra
              multiply -1  by  oi-carriage
              multiply -1  by  oi-vat
              multiply -1  by  oi-c-vat
              multiply -1  by  oi-e-vat
              multiply -1  by  oi-discount.
*>
     move     ih-cr to oi-cr.
*>
     if       ih-type not = 1                                    *> not Receipts
              add ih-net ih-extra ih-carriage ih-discount ih-vat
                  ih-c-vat ih-e-vat ih-deduct-amt ih-deduct-vat
                     giving ws-inv-amt.
     if       ih-type = 2                                        *> Invoice
              add ws-inv-amt to sl-invoices-this-month.
     if       ih-type = 3                                        *> Cr. Note
              add ws-inv-amt to sl-credit-notes-this-month.
*>
     move     "Z"  to ih-status.
     move     "A"  to ih-status-A.
     write    oi-header.
*>
 dd999-Main-Ex.
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
