       >>source free
*>***********************************************
*>                                              *
*>            Payment  Proof  Report            *
*>                                              *
*>***********************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         pl095.
*>**
*>    Author.             V B Coen FBCS, 17/04/84
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Payment Proof Report.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps04.
*>**
*>    Error messages used.
*>                        NONE
*>****
*>  Changes.
*> 22/05/84 Vbc - Support For Open Item Indexed Files.
*> 22/03/09 vbc - Migration to Open Cobol v3.00.00.
*> 10/04/09 vbc - Clean up print.
*> 29/05/09 vbc - Support for Page-Lines instead of fixed number.
*> 07/09/10 vbc - .03 Mod lpr.
*> 15/12/11 vbc - .04 Error msgs to SLnnn.Support for dates other than UK
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
*>------------------------------
*>
 file-control.
*>-----------
*>
 copy "selpl.cob".
 copy "selois.cob".
 copy "selprint.cob".
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdpl.cob".
 copy "fdois.cob".
 copy "fdprint.cob".
 working-storage section.
*>----------------------
 77  prog-name           pic x(15) value "PL095 (3.01.04)".
 copy "print-spool-command.cob".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
*>
 01  ws-data.
     03  work-1          pic 9(6)v99    comp-3  value zero.
     03  save-customer   pic x(7)               value spaces.
     03  sav-approp      pic s9(7)v99    comp-3 value zero.
     03  line-cnt        binary-char            value zero.
*>
 copy "wsoi.cob".
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
*> Module specific
*>       NONE
*>
 01  error-code          pic 999.
*>
 01  print-lines.
     03  line-1.
         05  l1-version  pic x(48).
         05  filler      pic x(76)       value "Payment and Journal Proof Report".
         05  filler      pic x(6)        value "Page  ".
         05  l1-page     pic z9.
*>
     03  line-2.
         05  l2-user     pic x(20)       value spaces.
         05  filler      pic x(60)       value spaces.
         05  filler      pic x(42)       value spaces.
         05  l2-date     pic x(10).
*>
     03  line-4.
         05  filler      pic x(61)       value "  Batch  TP Pay Date <-------------Supplier------------->".
         05  filler      pic x(71)       value "  Value    Approp.  Ded'N    <--------Payment Appropriation--------->".
*>
     03  line-5.
         05  filler      pic x(22)       value spaces.
         05  filler      pic x(70)       value "A/C               Name".
         05  filler      pic x(40)       value "Folio     Date      Approp.     Balance ".
*>
     03  line-6.
         05  l6-b-nos    pic z(4)9       blank when zero.
         05  l6-slash    pic x          value "/".
         05  l6-b-item   pic 999b        blank when zero.
         05  l6-trans    pic xx.
         05  l6-date     pic x(11).
         05  l6-ac       pic x(8).
         05  l6-name     pic x(29).
         05  l6-value    pic z(5)9.99bb  blank when zero.
         05  l6-approp   pic z(5)9.99bb  blank when zero.
         05  l6-dedn     pic z(3)9.99b   blank when zero.
         05  l6-invoice  pic z(7)9bb     blank when zero.
         05  l6-i-date   pic x(10).
         05  l6-i-approp pic z(5)9.99    blank when zero.
         05  l6-i-balance pic z(7)9.99cr blank when zero.
*>
     03  line-7.
         05  filler      pic x(30)      value spaces.
         05  l7-tit      pic x(7)       value "Payment".
         05  filler      pic x(7)       value " Totals".
*>
     03  line-8.
         05  filler      pic x(30)      value spaces.
         05  filler      pic x(14)      value "**************".
*>
     03  line-9.
         05  filler      pic x(23)      value spaces.
         05  l9-desc     pic x(17).
         05  l9-value    pic z(6)9.99.
*>
 01  report-fields.
     03  t-pay           pic s9(7)v99   comp-3 value zero.
     03  t-approp        pic s9(7)v99   comp-3 value zero.
     03  t-deducts       pic s9(7)v99   comp-3 value zero.
     03  j-pay           pic s9(7)v99   comp-3 value zero.
     03  j-approp        pic s9(7)v99   comp-3 value zero.
     03  j-deducts       pic s9(7)v99   comp-3 value zero.
     03  page-nos        pic 99                value zero.
     03  name-found      pic x.
     03  cws-pay         pic x(16)      value "Payments".
     03  cws-approp      pic x(16)      value "Appropriations".
     03  cws-unapplied   pic x(16)      value "Unapplied Cash".
     03  cws-deducts     pic x(16)      value "Deductions Taken".
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
*>
 01  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 init01 section.
     if       p-flag-p = zero
              go to menu-exit.
     move     Print-Spool-Name to PSN.
     move     prog-name to l1-version.
     move     "Y" to oi-5-flag.
     move     2  to  p-flag-p.
*>
     display  " " at 0101 with erase eos.
     display  prog-name at 0101 with foreground-color 2.
     display  "Payment Proof Report" at 0132 with foreground-color 2.
     perform  zz070-Convert-Date.
     display  ws-date at 0171 with foreground-color 2.
     display  "Printing..... Please Wait" at 1201 with foreground-color 2.
     perform  report1.
*>
 menu-exit.
     exit     program.
*>
*>*************************************
*>             Procedures             *
*>*************************************
*>
 report1      section.
*>===================
*>
     open     input open-item-file-s.
     if       fs-reply not = zero
              close open-item-file-s
              go to main-exit.
     open     input purchase-file.
     open     output  print-file.
     perform  headings.
*>
 read-loop.
*>********
*>
     read     open-item-file-s record  at end
              go to  loop-end.
*>
     move     open-item-record-s  to  oi-header.
*>
     if       oi-type  = 2
              go to  process-invoice.
     if       oi-type < 5 or > 6
        or    not s-open
              go to read-loop.
*>
*> process payment......wow.
*>
     move     oi-supplier  to  save-customer.
     move     oi-b-nos  to  l6-b-nos.
     move     "/" to l6-slash.
     move     oi-b-item to  l6-b-item.
     if       oi-type = 6
              move "J" to l6-trans
     else     move "P" to l6-trans.
*>
*> convert payment date
*>
     move     oi-date  to  u-bin.
     perform  zz060-Convert-Date.
     move     ws-date to l6-date.
*>
     move     oi-supplier  to  l6-ac purch-key.
*>
*> get customer name
*>
     move     space  to  name-found.
     read     purchase-file  record  invalid key
              move  "X"  to  name-found.
*>
     if       name-found = "X"
              move  "Supplier Unknown"  to  l6-name
         else
              move  purch-name  to  l6-name.
*>
     if       oi-type = 6
              add oi-paid       to j-pay
              add oi-approp     to j-approp
              add oi-deduct-amt to j-deducts
      else if oi-type = 5
              add oi-paid       to t-pay
              add oi-approp     to t-approp
              add oi-deduct-amt to t-deducts.
*>
     move     oi-paid  to  l6-value.
*>
     move     oi-approp  to  l6-approp sav-approp.
     move     oi-deduct-amt to l6-dedn.
     move     zero  to  l6-invoice  l6-i-approp l6-i-balance.
     move     spaces  to  l6-i-date.
*>
     if       line-cnt > Page-Lines - 2
              perform headings.
     write    print-record  from line-6 after 2.
     add      2 to line-cnt.
*>
     move     zero  to  l6-b-nos  l6-b-item l6-dedn
                        l6-value  l6-approp.
     move     spaces  to  l6-date  l6-ac  l6-name l6-trans.
     go       to read-loop.
*>
 process-invoice.
*>**************
*>
     if       oi-paid = zero
              go to  read-loop.
     if       oi-supplier  not equal  save-customer
              go to  read-loop.
*>
*> here process invoice......wow.
*>
     move     oi-invoice  to  l6-invoice.
*>
*> convert invoice date
*>
     move     oi-date  to  u-bin.
     perform  zz060-Convert-Date.
     move     ws-date to l6-i-date.
     move     spaces to l6-slash.
     if       oi-paid > sav-approp
              move sav-approp to l6-i-approp
     else
              move oi-paid  to  l6-i-approp
     end-if
     add      oi-net oi-vat oi-carriage oi-c-vat giving  work-1.
     subtract oi-paid  from  work-1  giving  l6-i-balance.
*>
     write    print-record from line-6 after 1.
     add      1 to line-cnt.
     if       line-cnt > Page-Lines
              perform headings.
     go       to read-loop.
*>
 loop-end.
*>*******
*>
     if       line-cnt > Page-Lines - 22
              perform headings.
     write    print-record  from  line-7 after 3.
     write    print-record  from  line-8 after 1.
*>
     move     cws-pay to  l9-desc.
     move     t-pay   to  l9-value.
     write    print-record  from  line-9 after 3.
*>
     move     cws-approp to  l9-desc.
     move     t-approp   to  l9-value.
     write    print-record  from  line-9 after 1.
*>
     move     cws-unapplied to  l9-desc.
     subtract t-approp  from  t-pay  giving  l9-value.
     write    print-record  from  line-9 after 1.
*>
     move     cws-deducts to l9-desc.
     move     t-deducts to l9-value.
     write    print-record from line-9 after 2.
*>
     move     "Journal" to l7-tit.
     write    print-record  from  line-7 after 3.
     write    print-record  from  line-8 after 1.
     move     cws-pay to  l9-desc.
     move     j-pay   to  l9-value.
     write    print-record  from  line-9 after 3.
*>
     move     cws-approp to  l9-desc.
     move     j-approp   to  l9-value.
     write    print-record  from  line-9 after 1.
*>
     move     cws-unapplied to  l9-desc.
     subtract j-approp  from  j-pay  giving  l9-value.
     write    print-record  from  line-9 after 1.
*>
     move     cws-deducts to l9-desc.
     move     j-deducts to l9-value.
     write    print-record from line-9 after 2.
*>
     close    open-item-file-s purchase-file print-file.
     call     "SYSTEM" using Print-Report.
     go       to main-exit.
*>
 headings.
*>*******
*>
     perform  zz070-Convert-Date.
     move     ws-date  to  l2-date.
     move     usera  to  l2-user.
     add      1  to  page-nos.
     move     page-nos  to  l1-page.
     if       page-nos not = 1
              write print-record  from  line-1 after page
              write print-record  from  line-2 after 1
              move  spaces  to  print-record
              write print-record after 1
     else
              write print-record  from  line-1 before 1
              write print-record  from  line-2 before 1
     end-if
     write    print-record  from  line-4 after 1.
     write    print-record  from  line-5 after 1.
     move     5 to line-cnt.
*>
 main-exit.   exit section.
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
