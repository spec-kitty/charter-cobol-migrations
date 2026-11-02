       >>source free
*>*****************************************************************
*>                                                                *
*>               I N V O I C E   P R I N T                        *
*>                                                                *
*>       SUPPLIED IN SOURCE FOR MODIFICATION BY CUSTOMER          *
*>                                                                *
*> Applewood Computers offers a service to change this module     *
*>   to meet your invoicing requirements.                         *
*>  currently set to spool to main printer and assumes a matrix   *
*>      printer using preprinted stationery or a laser using      *
*>        a preloaded template & produces 2 copies per invoice    *
*>        but see changes .09 for more info on this.              *
*>*****************************************************************
*>    Can be easily modified to also print to second printer in   *
*>    Dispatch Department etc for Picking Lists/Dispatch notes    *
*>    Also see sl950 that just prints Delivery/Picking notes      *
*>*****************************************************************
*>  Adobe Reader API Code removed from this and the Dispatch      *
*>  modules has been removed as they are non-free code and users  *
*>  have to purchase it and the reader/Forms programs from Adobe. *
*>  I will try and relook at this as well as links to LibreOffice *
*>  that do a similar job in producing stylised documents instead *
*>  based on template forms etc.
*>*****************************************************************
*>
 identification          division.
*>===============================
*>
      program-id.         sl930.
*>**
*>    Author.             Cis Cobol Conversion By V B Coen, FBCS 28/10/83
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Invoice Print.
*>**
*>    Version.            See Prog-Name In Ws.
*>
*>    Called Modules.     Maps04.
*>                        Maps99.
*>**
*>    Error messages used.
*>                        NONE
*>    But can use:
*>                        SL003
*>                        SL200
*>**
*> Changes
*> 03/03/09 vbc - .01 Migration to Open Cobol v3.00.00.
*> 10/03/09 vbc - .02 Minor adjustment for A4 paper after 1st page
*>                    also needs some added code for 10 point printing instead
*>                    of 12 or change laser via script prior to printing and
*>                    again afterwards.  Done, see print-spool-command.cob
*> 11/03/09 vbc - .03 Re-added extra discount/charge line in totals
*>                    for some reason missing on this version.
*> 13/03/09 vbc - .03 added extra-print flag to print or not see above.
*> 07/09/10 vbc - .04 Mod lpr.
*> 26/11/11 vbc - .05 Error msgs to SLnnn.Support for dates other than UK
*> 08/12/11 vbc - .06 Support for path+filenames.
*> 09/12/11 vbc -     Updated version to 3.01.nn, support for IS delivery file
*> 11/12/11 vbc - .07 Changed usage of Stk-Date-Form to the global field Date-Form making former redundent.
*> 24/03/12 vbc - .08 Support for printing to 2 printers but rem'd out
*> 19/05/13 vbc - .09 Added in sil-Status-L (future proofing) at total-print-4 & show 'Invoice'for same
*>                    and produces two copies of each invoice with one for filing. You will need to change
*>                    copy "print-spool-command-p.cob" from "-# 2 " to "-# 3 " for three copies etc.
*> 22/05/13 vbc - .10 Tidied up headings & added time to headings along with changes made to sl930.
*> 29/05/13 vbc - .11 More tidyup of inv heads for plain paper invoices and no doubt more needed.
*>                    Checked that all non-free API code from Adobe Reader is removed.
*> 04/06/13 vbc - .12 Using Print details from Print-Spool-Name2 with PSN2 in prt-2.
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
 input-output            section.
*>------------------------------
*>
 file-control.
*>-----------
*>
 copy "selsl.cob".
 copy "selinv.cob".
 copy "seldel.cob".
 copy "selprint.cob" replacing "prt-1" by "prt-2".	*> Invoice printer
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdsl.cob".
 copy "fdinv.cob".
 copy "fddel.cob".
*>
 fd  print-file.
*>
 01  print-record            pic x(102).
 working-storage section.
*>----------------------
 77  prog-name               pic x(15) value "SL930 (3.01.12)".
*>
*> Change this to suite your requirements. This is set portrait,
*>   see CUPS help on 'lpr' but change it within program not the copybook
*>
 copy "print-spool-command-p-dispatch.cob" replacing "prt-1" by "prt-2".
*>
*> copy "print-spool-command-p.cob" replacing " sides=two-sided-long-edge " by " sides=one-sided ".  *>  "-# 2 ". replace "" if needed
                                        *> this one or next ONLY, not both & '-# 2' means 2 copies (1 cust, 1 file).
                                        *> change it if you need to & double sided not needed for invoices!
*>    WARNING print delivery/packing slips 1st (sl950) before printing invoices.
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
 copy "wsinv.cob".
*>
 01  ws-data.
     03  test-product.
         05  filler      pic x.
             88  il-comment              value "/".
         05  filler      pic x(6).
     03  ws-reply        pic x.
     03  print-path      pic x.
     03  a               pic 99.
     03  c-check         pic 9.
         88  c-exists                    value 1.
     03  address-line    pic x(36).
     03  work-n          pic 9(6)v99.
     03  work-v          pic 9(6)v99.
     03  i               pic 99.
     03  ii              pic 99.
     03  j               pic 99.
     03  k               pic 99.
     03  kk              pic 99.
     03  ws-Time         pic 9(8)        value zero.
     03  first-time      pic x           value "Y".
     03  h1              pic 99.  *> Co name  max 32
     03  h2              pic 99.  *> Addr 1   max 24
     03  h3              pic 99.  *> Addr 2   max 24
     03  h4              pic 99.  *> Addr 3   max 24
     03  h5              pic 99.  *> Addr 4   max 24
     03  h6              pic 99.  *> Postcode max 12
     03  h7              pic 99.  *> Country  max 24
     03  h97             binary-char.
     03  h98             binary-char.
     03  h99             binary-char.
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
 *>     03  SL003          pic x(28) value "SL003 Hit Return To Continue".
*> Module specific
 *>    03  SL200          pic x(37) value "SL200 Re-Align Invoice To Top Of Form".  *> Matrix type printers only
*>
 01  error-code          pic 999.
*>
 01  line-Company-Details1 pic x(91)     value spaces.
 01  line-Company-Details2 pic x(91)     value spaces.
 01  line-Company-Details3 pic x(91)     value spaces.
 01  line-Company-Details4 pic x(91)     value spaces.
 01  line-Company-Details5 pic x(91)     value spaces.
 01  line-Company-Details6 pic x(91)     value spaces.
 01  line-Company-Details7 pic x(91)     value spaces.
*>
 01  line-0-a.
*> line 1
*>     03  filler          pic x(44)       value spaces.
     03  l0-type         pic x(14).
*>
 01  line-0-b.
*> line 2
*>     03  filler          pic x(44)       value spaces.
     03  l0-xs           pic x(14).
*>
 01  line-0-c.
*> line 3
     03  filler          pic x(37)       value spaces.
     03  l0-desc         pic x(25).			*> not a vat inv notice
*>
 01  line-0-d.
*> line 5  85 chars
     03  filler          pic x(25)       value spaces.
     03  l3-title        pic x(7)       value "INVOICE".
     03  filler          pic x(25)       value spaces.
     03  filler          pic x(5)        value "Page ".
     03  l7-count-1      pic 9.
     03  filler          pic x(4)        value " of ".
     03  l7-count-2      pic 9.
     03  filler          pic x           value space.
     03  l3-date         pic x(10).
     03  filler          pic x           value space.
     03  l3-HH           pic 99.
     03  filler          pic x           value ":".
     03  l3-MM           pic 99.
*>
 01  line-0-e.
*> line 9  85 chars
     03  filler          pic x(72)       value spaces.
     03  filler          pic x(5)        value "Inv: ".
     03  l3-invoice      pic z(7)9.
*>
 01  line-1.
*> line 10
*>     03  filler          pic x(05)       value spaces.
     03  l1-i-name       pic x(31).
     03  filler          pic x(4)        value spaces.
     03  l1-d-name       pic x(30).
*>
 01  line-2.
*> line 11
*>     03  filler          pic x(05)       value spaces.
     03  l2-i-line       pic x(31).
     03  filler          pic xxxx        value spaces.
     03  l2-d-line       pic x(30).
     03  filler          pic x(7)        value spaces.
*>
 01  line-3.
*> line 12  88 chars
*>     03  filler          pic x(05)       value spaces.
     03  l3-i-line       pic x(31).
     03  filler          pic xxxx        value spaces.
     03  l3-d-line       pic x(30).
     03  filler          pic x(5)        value spaces.
     03  filler          pic x(7)        value "Order:".
     03  l6-order        pic x(11).
*>
 01  line-4.
*> line 13  88 chars
*>     03  filler          pic x(05)       value spaces.
     03  l4-i-line       pic x(31).
     03  filler          pic xxxx        value spaces.
     03  l4-d-line       pic x(30).
     03  filler          pic x(5)        value spaces.
     03  filler          pic x(7)        value " Ref :".
     03  l4-ref          pic x(11).
*>
 01  line-5.
*> line 14  84 chars
*>     03  filler          pic x(05)       value spaces.
     03  l5-i-line       pic x(31).
     03  filler          pic xxxx        value spaces.
     03  l5-d-line       pic x(30).
     03  filler          pic x(5)        value spaces.
     03  filler          pic x(7)        value " A/C :".
     03  l6-account      pic x(7).
*>
 01  line-6.
*> line 15
*>     03  filler          pic x(05)       value spaces.
     03  l6-i-line       pic x(31).
     03  filler          pic xxxx        value spaces.
     03  l6-d-line       pic x(30).
*>
 01  line-7.
*> line 16-18 (3)
     03  filler          pic x(72)       value spaces.
*>
 01  line-7B.			*> plain invoice line heads
     03  filler          pic x(14)       value "Product Code  ".
     03  filler          pic x(30)       value "Item Description".
     03  filler          pic x(6)        value "   Qty".
     03  filler          pic x(10)       value "      Cost".
     03  l7B-Disc        pic x(7)        value "  Disc ".		*> This should be clear when no disc'
     03  filler          pic x(10)       value "      Net".
     03  filler          pic x(10)       value "      Vat".
*>
 01  line-8.
*> line 19-33 (15)  87 chars but should be 89 (desc x32)
     03  l8-product      pic x(13)B      value spaces.
     03  l8-desc         pic x(30).                          *> 44  Chopped last 2
     03  l8-qty          pic z(5)9       blank when zero.    *> 50
     03  l8-unit         pic z(6)9.99    blank when zero.    *> 60
     03  l8-discount     pic zz9.99      blank when zero.    *> 66
     03  l8-percent      pic x.				     *> 67
     03  l8-net          pic z(6)9.99  blank when zero.      *> 77
     03  l8-vat          pic z(6)9.99  blank when zero.      *> 87
*>
 01  line-9.
*> line 35,37  87 chars
     03  l9-terms        pic x(14)       value "Credit Terms: ".   *> blank when not used.
     03  l9-days         pic zz9         blank when zero.
     03  filler          pic x(24)       value spaces.		*> 41
     03  l9-desc         pic x(24).				*> 65
     03  l9-net          pic -(7)9.99  blank when zero.		*> 76
     03  l9-vat          pic -(7)9.99  blank when zero.		*> 87
*>
 01  line-10.
*> line 40
     03  filler          pic x(14)       value spaces.
     03  l10-terms       pic x(16)       value "Prompt pay time:".
     03  l10-days        pic zz9         blank when zero.
*>
 01  line-11.
*> line 41
     03  filler          pic x(13)       value spaces.
     03  l11-amount      pic zzz9.99     blank when zero.	*> 20
     03  filler          pic x(45)       value spaces.		*> 65
     03  l11-net         pic z(7)9.99  blank when zero.		*> 76
     03  l11-vat         pic z(7)9.99  blank when zero.		*> 87
*>
 01  line-12.
*> line 43
     03  filler          pic x(65)       value spaces.
     03  l10-Gross-Lit   pic x(11)       value "Total Due: ".
     03  l10-gross       pic z(7)9.99.
*>
 linkage section.
*>***************
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
     if       full-invoicing = zero
              exit program.
*>
     if       file-status (15) not = 1
              move 29  to  error-code
              call  "maps99"  using  error-code ws-calling-data
              move 15 to error-code
              call "maps99" using error-code ws-calling-data
              accept ws-reply at 2479
              exit program.
*>
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
     move     Print-Spool-Name2 to PSN2.
     perform  zz070-Convert-Date.
     perform  zz080-Setup-Company-Details.
*>
 menu-return.
*>***********
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Invoice Printing" at 0134 with foreground-color 2.
     display  ws-date at 0171 with foreground-color 2.
*>
*>     display  "You will need to manually spool 'prt-1'" at 0320 with foreground-color 2 highlight.
*>
     open     i-o    invoice-file.
     open     input  sales-file delivery-file.
     open     output print-file.
*>
     if       pass-value not = 3
              go to  all-print-start.
*>
     subtract 1  from  next-invoice  giving  invoice-nos.
     move     zero  to  item-nos.
     move     space  to  invoice-let.
*>
     read     invoice-file  record invalid key
              go to  main-end.
*>
     move     invoice-record  to  sinvoice-header.
*>
     if       pending
       or     sih-status-L not = "L"
              perform  print-routine
              go to    main-end.
*>
     display  "Invoice Number - " at 0501 with foreground-color 2.
     display  sih-invoice at 0518 with foreground-color 3.
     display  "Already Invoiced!.....Re-Print  (Y/N) ? - [Y]" at 0601 with foreground-color 2.
*>
     move     "Y"  to  ws-reply.
     accept   ws-reply at 0644 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "Y"
              perform   print-routine.
*>
     display  " " at 0501 with erase eol.
     display  " " at 0601 with erase eol.
*>
     go       to main-end.
*>
 all-print-start.
*>***************
*>
     display  "Print Or Re-Print.............  (P/R) ? - [P]" at 0701 with foreground-color 2.
     move     "P"  to  print-path
     accept   print-path at 0744 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       print-path = "R"
              go to  all-print-get-inv.
*>
 amend-request.
*>
     move     "N" to ws-reply.
     display  "Any Amended Invoices In This Batch? [N]" at 0901 with foreground-color 2.
     accept   ws-reply at 0938 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "Y"
              move zeros to first-sl-inv item-nos
              go to all-print.
     if       ws-reply not = "N"
              go to amend-request.
*>
     if       first-sl-inv = zero
              go to  all-print.
*>
     move     first-sl-inv  to  invoice-nos.
*>
 all-print-go.
*>
     move     zero  to  first-sl-inv  item-nos.
     move     space to invoice-let.
*>
     start    invoice-file  key not less than  invoice-key.
*>
 all-print.
*>*********
*>
     read     invoice-file  next  record at end
              go to  main-end.
*>
     if       item-nos not = zero	*> find headers
              go to  all-print.
*>
     move     invoice-record  to  sinvoice-header.
*>
     if       sih-lines = zero and
              sapplied
              go to all-print.
*>
     if       pending
              perform  print-routine
              go to    all-print.
*>
     if       print-path = "P"
              go to  all-print.
*>
*> Here is test to ensure that Invoices have NOT been printed before, but is rem'd out for testing
*>   and this test should go up above 'if pending' and/or that test be modified
*> Also the tests below really should be skipped as inv. printing is not relevant to pick lists
*>
*>     if       ih-status-L = "L"
*>              go to All-Print.
*>
     display  "Invoice Number - " at 1101 with foreground-color 2.
     display  sih-invoice at 1118 with foreground-color 3.
     display  "Already Invoiced!.....Re-Print  (Y/N) ? - [Y]" at 1201 with foreground-color 2.
*>
     move     "Y"  to  ws-reply.
     accept   ws-reply at 1244 with foreground-color 6.
     move     function upper-case (ws-reply) to ws-reply.
*>
     if       ws-reply = "Y"
              perform   print-routine.
*>
     display  " " at 1101 with erase eol.
     display  " " at 1201 with erase eol.
*>
 all-print-more.
*>
     display  "More To Print? [Y]" at 1101 with foreground-color 2.
     move     "Y" to ws-reply.
     accept   ws-reply at 1117 with foreground-color 6 update.
     move     function upper-case (ws-reply) to ws-reply.
     if       ws-reply = "N"
              go to main-end.
     if       ws-reply = "Y"
              go to all-print-get-inv.
*>
     go       to all-print-more.
*>
 all-print-get-inv.
*>
     display  " " at 1301 with erase eol.
     move     zero to invoice-nos.
     display  "Give Lowest Invoice No. [        ]" at 1301 with foreground-color 2.
     accept   invoice-nos at 1326 with foreground-color 3 update.
     go       to all-print-go.
*>
 main-end.
*>********
*>
     close    invoice-file sales-file delivery-file.
     close    print-file.
     call     "SYSTEM" using print-report.
*>
     if       pass-value = 3
              move 1 to s-flag-i.
     exit     program.
*>
 print-routine           section.
*>===============================
*>
     move     1  to  i.
     perform  sih-lines times
              read invoice-file  next record
                   at end exit perform
              end-read
              if   item-nos = zero
                   exit perform
              end-if
              move invoice-record to invoice-line (i)
              if   sil-type (i) = "D"
                   exit perform
              end-if
              add  1  to  i
     end-perform
*>
     subtract 1  from  i.
     move     spaces  to  line-0-a line-0-b line-0-c.
*>
     subtract 1 from i giving ii.
     if       ii = 0
              move 1 to ii.
     divide   ii by  15  giving  l7-count-2.
     add      1  to  l7-count-2.
     move     1  to  l7-count-1.
*>
*>     if       sih-type = 2                     *> Do not know why this here as it bypasses other if tests
*>              go to  get-customer.
*>
     move           "  =======" to  l0-xs.	*> for Invoices & receipts
*>
     if       sih-type = 1
              move  "  Receipt"  to  l0-type
     else
      if      sih-Type = 2
              move  "  Invoice"  to l0-Type
      else
       if     sih-type = 3
              move  "Credit Note" to  l0-type
              move  "===========" to  l0-xs
       else
              move  "  Pro-Forma" to  l0-type
              move  "  =========" to  l0-xs
              move "This is not a VAT Invoice" to l0-desc.
*>
 get-customer.
*>************
*>
     move     sih-customer  to  sales-key.
     read     sales-file  record.
*>
     if       delivery-tag  >  zero
              move  "D"       to Deliv-Key-Type
              move  Sales-Key to Deliv-Sales-Key
              read  delivery-file  record.
*>
     move     spaces to l1-i-name l1-d-name l2-i-line  l2-d-line
                        l3-i-line  l3-d-line l4-i-line  l4-d-line
                        l5-i-line  l5-d-line l6-i-line  l6-d-line.
*>
     move     sales-name  to  l1-i-name.
*>
     move     1  to  a.
     unstring sales-address delimited by sl-delim into  l2-i-line count a  pointer a.
     unstring sales-address  delimited by sl-delim into  l3-i-line count a  pointer a.
     unstring sales-address  delimited by sl-delim into  l4-i-line count a  pointer a.
     unstring sales-address  delimited by sl-delim into  l5-i-line count a  pointer a.
     unstring sales-address  delimited by sl-delim into  l6-i-line          pointer a.
*>
     if       delivery-tag = zero
              go to  heading-details.
*>
     move     deliv-name  to  l1-d-name.
*>
     move     1  to  a.
     unstring deliv-address  delimited by sl-delim into  l2-d-line  count a  pointer a.
     unstring deliv-address  delimited by sl-delim into  l3-d-line  count a  pointer a.
     unstring deliv-address  delimited by sl-delim into  l4-d-line  count a  pointer a.
     unstring deliv-address  delimited by sl-delim into  l5-d-line  count a  pointer a.
     unstring deliv-address  delimited by sl-delim into  l6-d-line           pointer a.
*>
 heading-details.
*>***************
*>
     move     sih-invoice  to  l3-invoice.
*>
     move     sih-date  to  u-bin.
     perform  zz060-Convert-Date.
     move     ws-date  to  l3-date.
*>
     move     sih-customer  to  l6-account.
     move     sih-ref       to  l4-ref.
     move     sih-order     to  l6-order.
*>
     perform  headings-1.
*>
     move     1   to  k.
     move     25  to  j.		*> 15  to  j.  matrix values with sub & totals etc lets try 10 more
*>					             as should fit a page  - TEST
     move     zero to  work-n  work-v.
*>
 loop.
*>****
*>
     move     sil-product (k) to test-product.
     if       il-comment
              move spaces to line-8.
*>
     if       i-level-2
              move  sil-description (k)  to  l8-desc.
*>
     if       il-comment
              move zero to l8-qty l8-unit l8-discount l8-vat l8-net
              go to print-bypass.
*>
     if       i-level-2
              move  sil-qty  (k)     to  l8-qty
              move  sil-unit (k)     to  l8-unit
              move  sil-product (k)  to  l8-product
              move  sil-discount (k) to  l8-discount
     else
              move  zero  to  l8-qty
              move  zero  to  l8-unit
              move  zero  to  l8-discount
              move  spaces to l8-product.
*>
     if       i-level-2
       and    sil-discount (k)  >  0
              move  "%"       to l8-percent
              move  "  Disc " to l7B-Disc
     else
              move  spaces   to l7B-Disc
              move space to  l8-percent.
*>
     move     sil-net (k)   to  l8-net.
     move     sil-vat (k)   to  l8-vat.
*>
 print-bypass.
*>
     write    print-record  from  line-8 after 1.
*>
     add      sil-net (k)   to  work-n.
     add      sil-vat (k)   to  work-v.
     add      1  to  k.
*>
     if       k  >  i
              compute  k = ((l7-count-2 * 25)  -  i) + 2	*> was 15
              go to  total-print.
*>
     if       k  >  j
              move  k  to  kk
              move  2  to  k
              add  25  to  j						*> 15  to  j
              add  1   to  l7-count-1
              perform  total-print
              move kk  to  k
              move  spaces  to  print-record
              write  print-record  after 13  lines
              perform  headings-1.
*>
     go       to loop.
*>
 total-print.
*>**********
*>
     move     spaces  to  l9-desc.
     move     work-n  to  l9-net
     move     work-v  to  l9-vat.
     move     sih-days to  l9-days.
     move     "Credit Terms: " to l9-terms.
*>
     write    print-record from line-9 after k  lines.
     move     zero   to l9-days.
     move     spaces to l9-Terms.
*>
 total-print-2.
*>************
*>
     if       zero = sih-deduct-amt and sih-deduct-vat
              write print-record from line-7 after 1
              go to total-print-3.
*>
     move     "Late Payment Surcharge" to l9-desc.
     move     spaces         to l9-Terms.
     move     sih-deduct-vat to l9-vat.
     move     sih-deduct-amt to l9-net.
*>
     write    print-record  from  line-9 after 1.
     move     spaces  to l9-desc.
*>
 total-print-3.
*>************
*>
     if       Extra-Print = "N"
         or   (zero = sih-extra and sih-e-vat)
              write print-record from line-7 after 1
              go to total-print-4.
*>
     move     spaces      to l9-Terms.
     move     extra-desc  to l9-desc.
     move     sih-e-vat   to l9-vat.
     move     sih-extra   to l9-net.
*>
     write    print-record  from  line-9 after 1.
*>
 total-print-4.
*>************
*>
     move     spaces      to l9-Terms.
     move     spaces    to  l9-desc.
     move     sih-c-vat  to l9-vat.
     move     sih-carriage to l9-net.
*>
     write    print-record  from  line-9 after 2  lines.
*>
     if       sales-credit = zero
              move  zero  to  l10-days
                              l11-amount
              move spaces to  l10-Terms
     else
              move "Prompt pay time:" to L10-Terms
              move  sih-deduct-days  to  l10-days.
*>
     if       sih-deduct-amt = zero
              move spaces to  l10-terms
              move  zero  to  l10-days.
*>
     add      sih-deduct-amt  sih-deduct-vat                   giving  l11-amount.
     add      sih-vat  sih-e-vat  sih-c-vat  sih-deduct-vat    giving  l11-vat.
     add      sih-net  sih-extra  sih-carriage  sih-deduct-amt giving  l11-net.
     add      sih-vat  sih-e-vat  sih-c-vat  sih-deduct-vat
              sih-net  sih-extra  sih-carriage  sih-deduct-amt giving  l10-gross.
*>
     write    print-record  from  line-10 after 1.
     write    print-record  from  line-11 after 1.
     write    print-record  from  line-12 after 2.
*>
     move     spaces  to  print-record.
     write    print-record after 5.
*>
     if       not sapplied
              move "I" to sih-status
              move "L" to sih-Status-L
              move sinvoice-header to invoice-record
              rewrite invoice-record.
*>
 main-exit.   exit section.
*>********    ****
*>
 headings-1                section.
*>================================
*>
*> May needs to change this first block depending on page layout/size etc.
*>  with the first-time test
*>
     accept   ws-Time from time.
     move     ws-Time (1:2) to l3-HH.
     move     ws-Time (3:2) to l3-MM.
*>
     if       SL-Comp-Pick				*> print Co. address details
      if      first-time = "Y"           		*> Don't print a blank page
              write Print-Record from line-Company-Details1 after 1
      else
              write Print-Record from line-Company-Details1 after page
      end-if
     end-if
     if       SL-Comp-Pick
              write Print-Record from line-Company-Details2 after 1
              write Print-Record from line-Company-Details3 after 1
              write Print-Record from line-Company-Details4 after 1
              write Print-Record from line-Company-Details5 after 1
              write Print-Record from line-Company-Details6 after 1
              write Print-Record from line-Company-Details7 after 1
              write print-record from line-0-a after 1
     end-if
     if       not SL-Comp-Pick
      if      first-time = "Y"
              write    print-record  from  line-0-a after 4
      else
              move spaces to print-record
              write print-record after page
              write print-record from line-0-a after 4
      end-if
     end-if
*>
     write    print-record  from  line-0-b after 1.
     write    print-record  from  line-0-c after 2.
     write    print-record  from  line-0-d after 1.
     write    print-record  from  line-0-e after 2.
     write    print-record  from  line-1 after 1.
     write    print-record  from  line-2 after 1.
     write    print-record  from  line-3 after 1.
     write    print-record  from  line-4 after 1.
     write    print-record  from  line-5 after 1.
     write    print-record  from  line-6 after 1.
     write    print-record  from  line-7 after 2.
     write    print-record  from  line-7B after 1.	*> Line heads for plain invoices
*>
     if       first-time not = "Y"
              go to  main-exit.
*>
*>  This block is not needed if you spool to a laser so just go to headings-1.
*>
*>     display  "Invoice Correctly Aligned.....  (Y/N) ? - [Y]" at 1401 with foreground-color 2.
*>
*>     move     "Y"  to  ws-reply.
*>     accept   ws-reply at 1444 with foreground-color 6 update.
*>     move     function upper-case (ws-reply) to ws-reply.
*>
*>     if       ws-reply = "Y"
*>              go to  main-end.
*>
*>     display  SL200  at 1601 with foreground-color 2.
*>     display  SL003  at 1801 with foreground-color 2.
*>
*>     accept   ws-reply at 1831.
*>     display  " " at 1401 with erase eol.
*>     display  " " at 1601 with erase eol.
*>     display  " " at 1801 with erase eol.
*>
*>     go       to headings-1.
*>
 main-end.
*>*******
*>
     move     "N"  to  first-time.
*>
 main-exit.   exit section.
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
 zz080-Setup-Company-Details section.
*>**********************************
*>
*>  First get no. of chars in each field
*>
     if       not SL-Comp-Pick			*> test if company heads are wanted
              exit section.
*>
     perform  varying h1 from 32 by -1 until h1 = 1 or     usera (h1:1) not = space
     end-perform
     perform  varying h2 from 24 by -1 until h2 = 1 or Address-1 (h2:1) not = space
     end-perform
     perform  varying h3 from 24 by -1 until h3 = 1 or Address-2 (h3:1) not = space
     end-perform
     perform  varying h4 from 24 by -1 until h4 = 1 or Address-3 (h4:1) not = space
     end-perform
     perform  varying h5 from 24 by -1 until h5 = 1 or Address-4 (h5:1) not = space
     end-perform
     perform  varying h6 from 12 by -1 until h6 = 1 or Post-Code (h6:1) not = space
     end-perform
     perform  varying h7 from 24 by -1 until h7 = 1 or Country   (h7:1) not = space
     end-perform
*>
     divide   91 by 2 giving h98.      *> size of print lines here = 45, yes I know its rounded down
*>
     divide   h1 by 2 giving h99.
     add      1  to h99.
     move     usera     (1:h1) to line-Company-Details1 (h98 - h99:h1).
     divide   h2 by 2 giving h99.
     add      1  to h99.
     move     Address-1 (1:h2) to line-Company-Details2 (h98 - h99:h2).
     divide   h3 by 2 giving h99.
     add      1  to h99.
     move     Address-2 (1:h3) to line-Company-Details3 (h98 - h99:h3).
     divide   h4 by 2 giving h99.
     add      1  to h99.
     move     Address-3 (1:h4) to line-Company-Details4 (h98 - h99:h4).
     divide   h5 by 2 giving h99.
     add      1  to h99.
     move     Address-4 (1:h5) to line-Company-Details5 (h98 - h99:h5).
     divide   h6 by 2 giving h99.
     add      1  to h99.
     move     Post-Code (1:h6) to line-Company-Details6 (h98 - h99:h6).
     divide   h7 by 2 giving h99.
     add      1  to h99.
     move     Country   (1:h7) to line-Company-Details7 (h98 - h99:h7).
*>
 zz080-Exit.  Exit Section.
*>*********
*>
 maps04       section.
*>*******************
*>
     call     "maps04"  using  maps03-ws.
*>
 maps04-exit.
     exit     section.
*>
