       >>source free
*>***********************************************
*>                                              *
*>      Invoice  Post - Extract, Analysis       *
*>                                              *
*>***********************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl055.
*>**
*>    Author.             V B Coen FBCS, Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Invoice Proof Report Extract & Analysis.
*>**
*>    Version.            See Prog-Name & Date-Comped In Ws.
*>**
*>    Called Modules.     Maps99.
*>
*>**
*>    Error messages used.
*>                        PL006
*>                        PL201
*>                        PL202
*>**
*>    Changes.
*> 21/05/84 Vbc - Support For Indexed Open Itm File.
*> 01/10/84 Vbc - Insert Analysis Code From Pl130.
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00
*> 28/03/09 vbc - On open extend otm4 if error open as output as bug in OC.
*> 13/12/11 vbc - .03 Error msgs to SLnnn.Support for dates other than UK (Neither used here)
*>                    Support for path+filenames.
*>                    Updated version to 3.01.nn
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of the Applewood Computers Accounting System
*> and is copyright (c) Vincent B Coen. 1976-2012 and later.
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
 file-control.
*>
 copy "selanal.cob".
 copy "selval.cob".
 copy "selpinv.cob".
 copy "seloi4.cob".
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdanal.cob".
 copy "fdval.cob".
 copy "fdpinv2.cob".
 copy "fdoi4.cob".
 copy "wsoi.cob".
*>
 working-storage section.
*>----------------------
 77  prog-name           pic x(15)    value "PL055 (3.01.03)".
*>
 copy "wsfnctn.cob".
*>
 01  ws-data.
     03  ws-reply        pic x.
     03  Anal-Created    pic 9                  value zero.
     03  save-code       pic xxx.
     03  ws-inv-amt      pic s9(7)v99   comp-3  value zero.
     03  work-2          pic s9(7)v99   comp-3  value zero.
     03  work-3          pic s9(5)      comp    value zero.
     03  ws-vat-totalv   pic s9(7)v99   comp-3  value zero.
     03  ws-vatr-totalv  pic s9(7)v99   comp-3  value zero.
     03  ws-carr-totalv  pic s9(7)v99   comp-3  value zero.
     03  ws-disc-totalv  pic s9(7)v99   comp-3  value zero.
     03  ws-vat-totalt   pic s9(5)      comp    value zero.
     03  ws-vatr-totalt  pic s9(5)      comp    value zero.
     03  ws-carr-totalt  pic s9(5)      comp    value zero.
     03  ws-disc-totalt  pic s9(5)      comp    value zero.
     03  v-exists        pic 9.
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
     03  PL006          pic x(43) value "PL006 Note Details & Hit Return to continue".
*> Module specific
     03  PL201          pic x(57) value "PL201 Analyst records with desc, 'Emergency Name' created".
     03  PL202          pic x(36) value "PL202 You will need to update these".
*>
 01  error-code          pic 999.
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wssys4.cob".
 copy "wsnames.cob".
*>
 01  to-day              pic x(10).
*>
 procedure division using
           ws-calling-data system-record system-record-4 to-day file-defs.
*>=======================================================================
*>
 mainline section.
*>===============
*>
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
     if       file-status (15) = zero
              move 29  to  error-code
              call  "maps99"  using  error-code ws-calling-data
              move 15 to error-code
              call  "maps99"  using  error-code ws-calling-data
              go to menu-exit.
*>
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "Invoice Post Extract" at 0133 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
*>
     open     i-o invoice-file value-file analysis-file.
     open     extend  open-item-file-4.
     if       fs-reply not = zero
              close open-item-file-4
              open output open-item-file-4.
*>
 read-loop.
*>********
*>
     read     invoice-file next record at end
              go to  close-files.
*>
     if       ih-test = zero
              go to header-analysis.
*>
     if       il-analyised
              go to  read-loop.
*>
     move     "P" to va-system.
     move     il-pa to  va-group.
     move     1  to  v-exists.
*>
     read     value-file  invalid key
              perform  create
              move zero to v-exists.
*>
     add      1  to  va-t-this.
     add      1  to  va-t-year.
     if       il-type not = 3
              add il-net to  va-v-this va-v-year
     else
              subtract il-net from va-v-this va-v-year.
*>
     if       v-exists = zero
              write  value-record
     else
              rewrite  value-record.
*>
     if       va-second = space
              go to read-loop.
*>
     move     space  to  va-second.
     read     value-file  invalid key
              go to read-loop.
*>
     add      1  to  va-t-this.
     add      1 to va-t-year.
     if       il-type not = 3
              add il-net to  va-v-this va-v-year
     else
              subtract il-net from va-v-this va-v-year.
     rewrite  value-record.
*>
     move     "z"  to  il-update.
     rewrite  invoice-record.
     go       to read-loop.
*>
 header-analysis.
*>**************
*>
     if       ih-analyised and applied
              go to read-loop.
*>
     perform  extract.
*>
     if       ih-analyised
              rewrite invoice-record
              go to read-loop.
*>
     add      ih-c-vat ih-vat giving work-2.
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
     if       work-2 not = zero
              add 1 to ws-disc-totalt
              add work-2 to ws-disc-totalv.
*>
     move     "z" to ih-update.
     rewrite  invoice-record.
     go       to read-loop.
*>
 close-files.
*>**********
*>
     move     "P" to va-system.
     move     "vi" to va-group.
     move     ws-vat-totalt to work-3.
     move     ws-vat-totalv to work-2.
     perform  store-specials
     move     "vj" to va-group.
     move     ws-vatr-totalt to work-3.
     move     ws-vatr-totalv to work-2.
     perform  store-specials
     move     "za" to va-group.
     move     ws-carr-totalt to work-3.
     move     ws-carr-totalv to work-2.
     perform  store-specials
     move     "zb" to va-group.
     move     ws-disc-totalt to work-3.
     move     ws-disc-totalv to work-2.
     perform  store-specials
     close    invoice-file analysis-file value-file
              open-item-file-4.
*>
     move     1  to  file-status (28).
*>
     if       Anal-Created not = zero
              display PL201 at 1201 with foreground-color 2
              display PL202 at 1401 with foreground-color 2
              display PL006 at 1601 with foreground-color 2
              accept ws-reply at 1645.
*>
 menu-exit.
     exit     program.
*>
*>****************************************************
*>                   Procedures                      *
*>****************************************************
*>
 create       section.
*>===================
*>
     move     va-code  to  pa-code.
*>
     read     analysis-file  invalid key
              go to  create-anal.
*>
     move     analysis-record  to  value-record
     move     zero  to  va-t-this  va-t-last va-t-year
                        va-v-this  va-v-last va-v-year.
*>
     if       va-second = space
              go to  main-exit.
*>
     move     va-code  to  save-code.
*>
     move     space    to  va-second.
     move     va-code  to  pa-code.
*>
     read     analysis-file  invalid key
              move  save-code  to  pa-code
              go to  main-exit.
*>
     move     analysis-record  to  value-record
     move     zero  to  va-t-this  va-t-last  va-t-year
                        va-v-this  va-v-last  va-v-year.
*>
     write    value-record.
*>
     move     save-code  to  va-code  pa-code.
     read     analysis-file  invalid key
              go to  main-exit.
*>
     move     analysis-record  to  value-record
     move     zero  to  va-t-this  va-t-last  va-t-year
                        va-v-this  va-v-last  va-v-year.
*>
     go       to main-exit.
*>
 create-anal.
*>
     move     va-code to pa-code.
     move     zero to pa-gl.
     move     spaces to pa-print.
     move     "Emergency Name" to pa-desc.
     move     1 to Anal-Created.
     write    analysis-record.
     if       pa-second not = space
              move space to pa-second
              write analysis-record.
     go       to create.
*>
 main-exit.   exit section.
*>
 store-specials  section.
*>======================
*>
     move     1  to  v-exists.
*>
     read     value-file  invalid key
              perform  create
              move zero to v-exists.
*>
     add      work-3 to  va-t-this.
     add      work-3 to  va-t-year.
     add      work-2 to  va-v-this.
     add      work-2 to  va-v-year.
*>
     if       v-exists = zero
              write  value-record
     else
              rewrite value-record.
*>
     move     space  to  va-second.
     read     value-file  invalid key
              go to main-exit.
*>
     add      work-3 to  va-t-this.
     add      work-3 to  va-t-year.
     add      work-2 to  va-v-this.
     add      work-2 to  va-v-year.
     rewrite  value-record.
*>
 main-exit.   exit section.
*>
 extract section.
*>==============
*>
*> only Process header records, drop pro-formas.
*>   ignore records which have already been copied.
*>
     if       applied
              go to  main-exit.
*>
     move     zero        to  oi-p-c.
     move     ih-invoice  to  oi-invoice.
     move     ih-supplier to  oi-supplier.
     move     ih-date     to  oi-date.
     move     zero        to  oi-b-nos oi-b-item.
     move     ih-order    to  oi-order.
     move     ih-ref      to oi-ref.
     move     ih-net      to  oi-net.
     move     zero        to  oi-extra.
     move     ih-carriage to  oi-carriage.
     move     ih-vat      to  oi-vat.
     move     ih-c-vat    to  oi-c-vat.
     move     zero        to  oi-e-vat.
     move     zero        to  oi-discount.
     move     zero        to  oi-paid.
     move     ih-days      to oi-days.
     move     ih-deduct-amt  to  oi-deduct-amt.
     move     zero           to  oi-deduct-vat.
     move     ih-deduct-days to  oi-deduct-days.
     move     zero        to  oi-status oi-date-cleared.
     move     ih-type     to  oi-type.
     move     space to oi-applied oi-hold-flag.
*>
     if       ih-type = 3
              multiply  -1  by  oi-net
              multiply  -1  by  oi-carriage
              multiply  -1  by  oi-vat
              multiply  -1  by  oi-c-vat.
*>
     move     ih-cr to oi-cr.
*>
     if       ih-type not = 1
              add ih-net ih-carriage ih-vat ih-c-vat
                  giving ws-inv-amt.
     if       ih-type = 2
              add ws-inv-amt to pl-invoices-this-month.
     if       ih-type = 3
              add ws-inv-amt to pl-credit-notes-this-month.
*>
     move     "z"  to  ih-status.
     write    open-item-record-4.
*>
 main-exit.   exit.
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
