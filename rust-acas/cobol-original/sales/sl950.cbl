       >>source free
*>*****************************************************************
*>                                                                *
*>            DELIVERY NOTES and PICKING LIST PRINT               *
*>                                                                *
*>       SUPPLIED IN SOURCE FOR MODIFICATION BY CUSTOMER          *
*>                                                                *
*> Applewood Computers offers a service to change this module     *
*>   to meet your invoicing requirements.                         *
*>  currently set to spool to secondary printer and assumes a     *
*>  matrix printer using preprinted stationery or a laser using   *
*>        a preloaded template                                    *
*>*****************************************************************
*> This module does NOT print amounts only products, quanities    *
*>         							  *
*>*****************************************************************
*>  WARNING:  THIS MODULE MUST BE RUN BEFORE INVOICE PRINTING     *
*>         as the invoice print updates the invoice records       *
*>*****************************************************************
*>  Adobe Reader API Code removed from this and the Invoicing     *
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
      program-id.         sl950.
*>**
*>    Author.             V B Coen, FBCS 28/10/83
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
*>**
*> Changes
*> 24/03/12 vbc - .01 Migration to Open Cobol v3.01.nn and code added to match sl930.
*> 15/05/13 vbc - .02 Changed printer to prt-2 from prt-1 and removed double sided spooling.
*> 19/05/13 vbc - .03 Removed analysis file process and amounts etc as picking dont need 'em
*>                    Inserted company headings if needed (set by flag in parameter file, well
*>                    it will be when sys002 is changed).Update invoice record after running by
*>                    setting sih-status-P true.
*> 20/05/13 vbc - .04 Tidied up headings & added time to headings.
*> 30/05/13 vbc - .05 More tidying to match sl930 invoicing along with an total Item count.
*>                    Checked that all non-free API code from Adobe Reader is removed.
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
 copy "selstock.cob".
 copy "selsl.cob".
 copy "selinv.cob".
 copy "seldel.cob".
 copy "selprint.cob" replacing "prt-1" by "prt-3".	*> Dispatch printer
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdstock.cob".
 copy "fdsl.cob".
 copy "fdinv.cob".
 copy "fddel.cob".
*>
 fd  print-file.
*>
 01  print-record            pic x(102).
 working-storage section.
*>----------------------
 77  prog-name               pic x(15) value "SL950 (3.01.05)".
*>
*> Change this to suite your requirements. This is set portrait, going to a different printer than normal
*>   and single sided
*>   see CUPS help on 'lpr' but change it within program not the copybook
*>>>>>>>>>>>>>>>               setting for TESTING
 copy "print-spool-command-p-dispatch.cob" replacing  ==PSN2== by ==PSN3==
                                                      "prt-1" by "prt-3".
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
     03  ws-Item-Count   pic 9(4)        value zero.
     03  i               pic 99.
     03  ii              pic 99.
     03  j               pic 99.
     03  k               pic 99.
     03  kk              pic 99.
     03  first-time      pic x           value "Y".
     03  ws-Time         pic 9(8)        value zero.
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
*>     03  SL200          pic x(37) value "SL200 Re-Align Invoice To Top Of Form".
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
     03  l0-type         pic x(12).
*>
*> 01  line-0-b. NOT NEEDED
*> line 2
*>     03  l0-xs           pic x(12).
*>
 01  line-0-c.
*> line 3
     03  filler          pic x(37)       value spaces.
     03  l0-desc         pic x(25).
*>
 01  line-0-d.
*> line 5
     03  filler          pic x(18)       value spaces.
     03  l3-title        pic x(21)       value "Picking/Delivery Note".
     03  filler          pic x(18)       value spaces.
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
*> line 9
     03  filler          pic x(71)       value spaces.
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
*> line 12
*>     03  filler          pic x(05)       value spaces.
     03  l3-i-line       pic x(31).
     03  filler          pic xxxx        value spaces.
     03  l3-d-line       pic x(30).
     03  filler          pic x(5)        value spaces.
     03  filler          pic x(7)        value "Order:".
     03  l6-order        pic x(11).
*>
 01  line-4.
*> line 13
*>     03  filler          pic x(05)       value spaces.
     03  l4-i-line       pic x(31).
     03  filler          pic xxxx        value spaces.
     03  l4-d-line       pic x(30).
     03  filler          pic x(5)        value spaces.
     03  filler          pic x(7)        value " Ref :".
     03  l4-ref          pic x(11).
*>
 01  line-5.
*> line 14
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
     03  filler          pic x(11)       value "  Abrev #".
     03  filler          pic x(15)       value "Product Code".
     03  filler          pic x(34)       value "Item Description".
     03  filler          pic x(12)       value "   Qty".
     03  filler          pic x(10)       value "Location".
*>
 01  line-8    value spaces.
*> line 19-33 (15)
     03  filler          pic x(2)        value spaces.
     03  l8-Abrev        pic x(7)BB.
     03  l8-Product      pic x(13)BB.
     03  l8-Desc         pic x(32)BB.
     03  l8-qty          pic z(5)9       blank when zero.
     03  filler          pic x(6).
     03  l8-Loc          pic x(10)BB.
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
     if       full-invoicing = zero              *> Hmm, not sure about this for this program
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
     move     Print-Spool-Name3 to PSN3.
     perform  zz070-Convert-Date.
     perform  zz080-Setup-Company-Details.
*>
 menu-return.
*>**********
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Delivery / Picking Note Print" at 0126 with foreground-color 2.
     display  ws-date at 0171 with foreground-color 2.
*>
     open     input Stock-File.
     open     i-o invoice-file.
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
*>**************
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
*>********
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
     if       sih-status-P = "P"		*> Pick list printed
              go to All-Print.
     if       pending				*> Invoices not yet printed but pick lists could have been !!!!
              perform  print-routine
              go to    all-print.
*>
     if       print-path = "P"
              go to  all-print.
*>
     if       sih-type > 2      *> ONLY print for invoices and receipts (prepaids)
              go to all-print.
*>
*> Also the tests below really should be skipped as inv. printing is not relevant to pick lists
*>                                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
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
*>*******
*>
     close    invoice-file sales-file delivery-file Stock-File.
     close    print-file.
     call     "SYSTEM" using print-report.
*>
*>     if       pass-value = 3
*>              move 1 to s-flag-i.
     exit     program.
*>
 print-routine           section.
*>==============================
*>
     move     zero to ws-Item-Count.
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
     move     spaces  to  line-0-a line-0-c.
*>
     subtract 1 from i giving ii.
     if       ii = 0
              move 1 to ii.
     divide   ii by  15  giving  l7-count-2.
     add      1  to  l7-count-2.
     move     1  to  l7-count-1.
*>
*>     if       sih-type = 2		*> Do not know why this here as it bypasses other if tests
*>              go to  get-customer.
*>
     if       sih-type = 1
              move  "Receipt Pick"  to l0-type
     else
      if      sih-type = 2
              move  "Invoice Pick"  to l0-type.
*>
 get-customer.
*>***********
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
     unstring sales-address delimited by sl-delim into  l3-i-line count a  pointer a.
     unstring sales-address delimited by sl-delim into  l4-i-line count a  pointer a.
     unstring sales-address delimited by sl-delim into  l5-i-line count a  pointer a.
     unstring sales-address delimited by sl-delim into  l6-i-line          pointer a.
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
*>**************
*>
     move     sih-invoice  to  l3-invoice.
*>
     move     sih-date  to  u-bin.
     perform  zz060-Convert-Date.
     move     ws-date  to  l3-date.
*>
     move     sih-customer  to l6-account.
     move     sih-ref       to l4-ref.
     move     sih-order     to l6-order.
*>
     perform  headings-1.
*>
     move     1  to k.
     move     25 to j.               *> 15  to  j.  matrix values with sub & totals etc lets try 10 more
*>					             as should fit a page  - TEST
 loop.
*>****
*>
     move     sil-product (k) to test-product.
     if       il-comment
              move spaces to line-8.
*>
     if       i-level-2
              move  sil-description (k) to l8-desc.	*> updated by stock data if linked
*>
     if       il-comment
              go to print-bypass.
*>
     if       i-level-2			                                        *> Do basics
              move  sil-qty (k)         to l8-qty
              add   sil-qty (k)         to ws-Item-Count			*> track no. of items
              move  sil-product (k)     to l8-product Stock-Key
              if    SL-Stock-Link = "Y"
                    read  Stock-File record key Stock-Key invalid key		*> now for the bonus ball !
                          move sil-product (k) to Stock-Abrev-Key
                          read Stock-File key Stock-Abrev-Key invalid key
                               move spaces to Stock-Key
                          end-read
                    end-read
                    if   Stock-Key not = spaces				*> Stock in use and rec found
                         move Stock-Key       to l8-Product
                         move Stock-Abrev-Key to l8-Abrev
                         move Stock-Location  to l8-Loc
                         move Stock-Desc      to l8-Desc
                    end-if
              end-if
     end-if.
*>
 print-bypass.
*>
     write    print-record  from  line-8 after 1.
     add      1  to  k.
*>
     if       k  >  i		                            *> End of invoice
              compute  k = ((l7-count-2 * 25)  -  i) + 2	*> was 15
              go to  total-print-2.
*>
     if       k  >  j
              move  k  to  kk
              move  2  to  k
              add  25 to j						*> 15  to  j
              add  1   to  l7-count-1
              move kk  to  k
*>              move  spaces  to  print-record				*> these 2 not need for non matrix
*>              write  print-record  after 13  lines			*> & pre-printed stationery
              perform  headings-1.
*>
     go       to loop.
*>
 total-print-2.
*>************
*>
*>  Don't need this for non matrix type printers
*>
*>     move     spaces  to  print-record.
*>     write    print-record after k  lines.
*>     write    print-record after 13.
*>
     move     spaces to Line-8.
     move     ws-Item-Count to l8-Qty.
     move     "                Total Item Count" to l8-Desc.
     write    print-record from Line-8 after 3 lines.
*>
     if       sih-status-P not = "P" and not = "p"		*> Still testing but not checking for it
              move "P" to sih-status-P				*> we have printed pick list
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
     write    print-record  from  line-7B after 1.
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
