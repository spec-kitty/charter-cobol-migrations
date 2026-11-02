       >>source free
*>********************************************************
*>                                                       *
*>               Transaction  Maintenance                *
*>                                                       *
*>********************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         gl050.
*>**
*>    author.             V.B.Coen, FBCS,
*>                        Converted For Cis December 84,
*>                        For Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2012, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Transaction Processing.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     Maps04.
*>**
*>    Error messages used.
*>                        GL010
*>                        GL107
*>                        GL108
*>                        GL109
*>                        GL110
*>**
*> Changes:
*> 27/01/09 vbc - Migration to Open Cobol.
*> 18/12/11 vbc - .03 Support for dates other than UK & clean up msgs
*>                    Error msgs to GLnnn,
*>                    Support for path+filenames.
*>
*>**
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
 copy "seledger.cob".
 copy "selbatch.cob".
 copy "selpost.cob".
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 copy "fdledger.cob".
 copy "fdbatch.cob".
 copy "fdpost.cob".
*>
 working-storage section.
*>----------------------
*>
 77  prog-name           pic x(15)  value "gl050 (3.00.03)".
*>
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
*>
 01  accept-terminator-array pic 9(4).
     copy "screenio.cpy".
 01  filler.
     03  display-acs         pic 9(4).99.
     03  display-batch       pic z(4)9.
     03  display-vat         pic z9.99.
     03  display-amt         pic 9(8).99.
     03  a                   pic 99           value zero.
     03  save-a              pic 99           value zero.
     03  v                   pic 9            value zero.
     03  w                   pic 99           value zero.
     03  y                   pic 99           value zero.
     03  z                   pic 99           value zero.
     03  ws-reply            pic x.
     03  ws-menu             pic 9.
     03  truth               pic 9       value zero.
         88  falset            value 0.
         88  truet             value 1.
     03  tran-date           pic x(8).
     03  ws-vat              pic x.
     03  ws-vat2             pic x.
     03  ws-codes            pic xx.
     03  ws-codes2           pic xx.
     03  ws-acs              pic 9(4).99.
     03  ws-legend           pic x(32).
     03  ws-vat-rate         pic 99v99   comp  value zero.
     03  vat-flag            pic 9             value zero.
     03  vat-flag-2          pic 9             value zero.
*>    03  rev-flag            pic 9             value zero.
     03  escape-code         pic x             value space.
     03  account-in          pic 9(4)v99.
     03  array-pc            pic 99.
     03  array-vat           pic x.
     03  convention2         pic xx.
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
     03  GL010          pic x(16) value "GL010 Hit Return".
*> Module specific
     03  GL107          pic x(31) value "GL107 Set Up P/C Branches First".
     03  GL108          pic x(24) value "GL108 Invalid. Too early".
     03  GL109          pic x(26) value "GL109 Invalid. Too forward".
     03  GL110          pic x(24) value "GL110 No check on items.".
*>
 01  ws-account-screen-display.
     03  ws-maind        pic 9(4).
     03  ws-period1      pic x     value ".".
     03  ws-subd         pic v99.
 01  ws-account-screen-accept redefines ws-account-screen-display.
     03  ws-main         pic 9(4).
     03  filler          pic x.
     03  ws-sub          pic v99.
*>
 01  ws-account-work.
     03  acc-wk-main     pic  9(4).
     03  acc-wk-sub      pic v99.
 01  ws-account-ok redefines ws-account-work.
     03  acc-ok          pic 9(4)v99.
*>
 01  ws-amount-screen-display8s.
     03  ws-poundsd8s    pic 9(8).
     03  ws-period8s     pic x     value ".".
     03  ws-penced8s     pic v99.
 01  ws-amount-screen-accept8s redefines ws-amount-screen-display8s.
     03  ws-pound8s      pic 9(8).
     03  filler          pic x.
     03  ws-pence8s      pic v99.
*>
 01  ws-amount-work8s.
     03  amt-wk-pds8s    pic 9(8).
     03  amt-wk-pence8s  pic v99.
 01  ws-amount-ok8s redefines ws-amount-work8s.
     03  amt-ok8s        pic 9(8)v99.
*>
 01  ws-amount-screen-display9.
     03  ws-poundsd9     pic 9(9).
     03  ws-period9      pic x     value ".".
     03  ws-penced9      pic v99.
 01  ws-amount-screen-accept9 redefines ws-amount-screen-display9.
     03  ws-pound9       pic 9(9).
     03  filler          pic x.
     03  ws-pence9       pic v99.
*>
 01  ws-amount-work9.
     03  amt-wk-pds9     pic 9(9).
     03  amt-wk-pence9   pic v99.
 01  ws-amount-ok9 redefines ws-amount-work9.
     03  amt-ok9         pic 9(9)v99.
*>
 01  display-plus-31                value all "+".
     03  display-plus-27 pic x(27).
     03  display-plus-4  pic xxxx.
*>
 01  display-star-46     pic x(46)  value all "*".
*>
 01  display-spaces.
     03  ws-space-44                value spaces.
         05  ws-space-29 pic x(29).
         05  ws-space-15 pic x(15).
*>
 copy "wspc.cob".
*>
 copy "wspint.cob".
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsdflt.cob".
 copy "wsnames.cob".
*>
 01  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record default-record to-day file-defs.
*>=====================================================================================
*>
 init01 section.
*>*************
*>
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
*>
     move     spaces to posting-array.
     open     input batch-file.
     if       fs-reply not = zero
              open output batch-file
              initialize batch-record
              move spaces to description
              move 9      to  ledger
              move 99999  to  batch-nos
              move 99     to  bcycle of batch-record
              write  batch-record.
     close    batch-file.
     open     i-o  batch-file.
*>
     open     input posting-file.
     if       fs-reply not = zero
              open output posting-file
              initialize posting-record
              write posting-record.
     close    posting-file.
*>
 menu-input.
*>*********
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Transaction Entry Functions" at 0127  with foreground-color 2.
     perform  zz070-convert-date.
     display  ws-date at 0171 with foreground-color 2.
     display  usera at 0301 with foreground-color 2.
     display  "Select one of the following by number :- [1]" at 0801 with foreground-color 2.
*>
     move     1  to  a ws-menu.
*>
     display  "(1)  Set up New Batch" at 1001  with foreground-color 2.
     display  "(9)  Exit to system menu" at 1301 with foreground-color 2.
*>
     accept   ws-menu at 0843 with foreground-color 6 update.
*>
     if       ws-menu = 9
              go to  menu-exit.
*>
     if       ws-menu = 1
              perform  get-next-batch
              go to get-default.
     go       to menu-input.
*>
 get-default.
*>**********
*>
     perform  gl050a.
     if       bdefault = zero
              go to  menu-exit.
     perform  gl050b.
     perform  write-next-batch.
     go       to menu-input.

 menu-exit.
*>********
*>
     close    batch-file.
*>
 menu-ex.
*>
     exit     program.
*>
*>*********************************************
*>                 Procedures                 *
*>*********************************************
*>
 get-next-batch.
*>*************
*>
     move     1           to  ledger.
     move     next-batch  to  batch-nos.
     add      1           to  next-batch.
*>
 write-next-batch.
*>***************
*>
     if       z = 9
              subtract  1  from  next-batch
     else
              write     batch-record.
*>
 get-batch.
*>********
*>
     open     i-o  batch-file.
     move     1 to  ledger.
*>
     display  "Enter Batch Number :- [     ]" at 1801 with foreground-color 2.
     accept   batch-nos at 1824 with foreground-color 3 update.
*>
     if       batch-nos = zero
              go to  end-get-batch.
*>
     read     batch-file  record  invalid key
              go to  get-batch.
*>
 end-get-batch.
*>************
*>
 put-batch.
*>********
*>
     rewrite  batch-record.
*>
 accept-money8s.
*>-------------
*>
     move     zero to ws-poundsd8s amt-ok8s ws-penced8s.
     display  ws-amount-screen-display8s at curs2  with foreground-color 3.
     accept   ws-amount-screen-accept8s at curs2   with foreground-color 3 update.
     move     ws-pound8s to amt-wk-pds8s.
     move     ws-pence8s to amt-wk-pence8s.
*>
 accept-money8s2.
*>--------------
*>
     move     amt-wk-pence8s to ws-pence8s.
     move     amt-wk-pds8s   to ws-pound8s.
     accept   ws-amount-screen-accept8s at curs2 with foreground-color 3 update.
     move     ws-pound8s to amt-wk-pds8s.
     move     ws-pence8s to amt-wk-pence8s.
*>
 accept-money9.
*>------------
*>
     move     zero to ws-poundsd9 amt-ok9 ws-penced9.
     display  ws-amount-screen-display9 at curs2 with foreground-color 3.
     accept   ws-amount-screen-accept9 at curs2  with foreground-color 3 update.
     move     ws-pound9 to amt-wk-pds9.
     move     ws-pence9 to amt-wk-pence9.
*>
 accept-account.
*>-------------
*>
     move     zero to ws-maind acc-ok ws-subd.
     display  ws-account-screen-display at curs2 with foreground-color 3.
     accept   ws-account-screen-accept at curs2  with foreground-color 3 update.
     move     ws-main  to acc-wk-main
     move     ws-sub   to acc-wk-sub.
*>
 gl020c-show              section.
*>*******************************
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Default Accounts Display" at 0126 with foreground-color 2.
     display  ws-date at 0171 with foreground-color 2.
     display  usera at 0301 with foreground-color 2.
*>
     perform  input-headings.
     display  "End of listing. Hit return for Menu." at 2301  with foreground-color 2.
     accept   ws-reply  at 2379 with foreground-color 6.
*>
 main-exit.   exit section.
*>--------    ----
*>
 input-headings          section.
*>******************************-
*>
     display  "A/C Nos" at 0504 with foreground-color 2.
     display  "Code Vat" at 0533 with foreground-color 2.
     display  "A/C Nos" at 0544 with foreground-color 2.
     display  "Code Vat" at 0573 with foreground-color 2.
     move     7  to  lin.
     move     1  to  w  cole.
*>
 input-loop.
*>---------
*>
     display  w at curs.
     add      2    curs giving curs2.
     display  "[       ]" at curs2 with foreground-color 2.
     add      30 to col2.
     display  "[  ] [ ]" at curs2 with foreground-color 2.
     add      1  to  w.
     if       w  >  32
              go to end-loop.
     if       w  =  17
              move 6  to  lin
              move 41 to  cole.
     add      1  to  lin.
     go       to input-loop.
*>
 end-loop.
*>-------
*>
*> now input existing defaults
*>
     move     1  to  w  cole.
     move     7  to  lin.
*>
 display-existing.
*>---------------
*>
     add      3    curs giving curs2.
     move     def-acs (w) to display-acs.
     display  display-acs  at curs2 with foreground-color 3.
     if       def-acs (w)  = zero
              go to jump-1.
*>
*> get code description.
*>
     perform  get-description.
     if       we-error = 255
              go to jump-1.
     add      12  curs giving curs2.
     display  ledger-name at curs2 with foreground-color 3.
     add      20 to col2.
     display  "[  ] " at curs2 with foreground-color 2.
*>
 jump-1.
*>-----
*>
     add      33    curs giving curs2.
     move     def-codes (w) to ws-codes.
     display  ws-codes  at curs2 with foreground-color 3.
     add      5 to col2.
     move     def-vat (w) to ws-vat.
     display  ws-vat  at curs2 with foreground-color 3.
     add      1  to  w.
     if       w  >  32
              go to display-existing-end.
     if       w  =  17
              move 41  to  cole
              move 6   to  lin.
     add      1  to  lin.
     go       to display-existing.
*>
 get-description.
*>--------------
*>
     multiply def-acs (w)  by  100  giving  ledger-nos.
     move     "00"         to  ledger-pc.
     move     zero to we-error.
*>
     read     ledger-file  record  invalid key
              move  255  to  we-error.
*>
 display-existing-end.
*>-------------------
*>
     move     1  to  w  cole.
     move     7  to  lin.
*>
 main-exit.   exit section.
*>--------    ----
*>
 gl050a section.
*>*************
*>
     open     input  ledger-file.
*>
     if       not profit-centres
       and    not branches
              go to  init-done.
*>
     move     999999 to  ledger-nos.
     move     "00"   to  ledger-pc.
*>
     read     ledger-file  record  invalid key
              display GL107 at 0101 with foreground-color 4 erase eos
              display GL010 at 0211
              accept ws-reply at 0234
              perform main-end
              go to program-exit.
*>
     move     ledger-record  to  p-c-branches.
*>
 init-done.
*>--------
*>
     display  prog-name at 0101  with foreground-color 2 erase eos.
     display  "General Ledger - Posting Set-Up"  at 0126  with foreground-color 2
     display  ws-date at 0171 with foreground-color 2.
*>
     if       preserve-batch
              perform  batch-outline  through  b-o-data.
*>
     perform  help-outline  through  h-o-data.
*>
     display  "select default number          :- [  ]" at 0401  with foreground-color 2.
     display  "select posting convention      :- [CR]" at 0701  with foreground-color 2.
*>
     if       profit-centres
              display "Select Default Profit Centre   :- [  ]" at 1001 with foreground-color 2.
     if       branches
              display "Select Default Branch          :- [  ]" at 1001 with foreground-color 2.
*>
     display  "Enter Transaction Posting Date :- [        ]"   at 1301 with foreground-color 2.
*>
 def-in.
*>*****
*>
     display  " 0 - Return to System Menu   " at 1851 with foreground-color 2.
     display  "33 - Set-up Temporary Default" at 1951 with foreground-color 2.
     display  "99 - Display current Defaults" at 2051 with foreground-color 2.
     display  " " at 2151 with erase eol.
     display  " " at 2251 with erase eol.
     accept   a at 0436 with foreground-color 6.
*>
     if       a =  99
              perform gl020c-show
              go to init-done.
*>
     if       a = zero
              move  a  to bdefault
              go to  main-end.
*>
     if       a > 33
              go to  def-in.
*>
     move     zero  to  batch-def-pc.
*>
     if       a = 33
              perform  def-set-up  through  dummy-return-1.
*>
     if       a < 33
              perform  def-val.
*>
     if       falset
              go to  def-in.
*>
     move     a  to  bdefault.
     if       def-acs (a) = def-acs (31) or def-acs (32)
              move 1 to vat-flag
     else
              move zero to vat-flag
     end-if.
*>
 post-in.
*>******
*>
     display  "Enter <DR> or <CR>           " at 1851 with foreground-color 2.
     display  "DR - Debits the A/c posted to" at 1951 with foreground-color 2.
     display  "   & Credits the default A/c " at 2051 with foreground-color 2.
     display  "<Esc> - to back-up one field " at 2151 with foreground-color 2.
*>
     move     "CR" to convention2.
     accept   convention2 at 0736 with update foreground-color 3.
     move     function upper-case (convention2) to convention.
     if       cob-crt-status = cob-scr-esc
              go to  def-in.
*>
     if       convention  not = "DR" and not = "CR"
              go to  post-in.
*>
 default-pc.
*>*********
*>
     display  " " at 1851 with erase eol.
     display  " " at 1951 with erase eol.
     display  " " at 2051 with erase eol.
     display  " " at 2151 with erase eol.
     if       not profit-centres
       and    not branches
              go to  def-date.
*>
     display  batch-def-pc at 1036 with foreground-color 3.
     accept   batch-def-pc at 1036 with foreground-color 3 update.
     if       cob-crt-status = cob-scr-esc
              go to  post-in.
*>
     perform  validate-pc.
     if       falset
              go to  default-pc.
*>
 def-date.
*>*******
*>
     perform  store-defaults.
*>
     if       not auto-vat
              go to  jump-1.
     if       batch-def-vat =  "I"
              display "Input VAT" at 0470 with foreground-color 2.
     if       batch-def-vat =  "O"
              display "Output VAT" at 0470 with foreground-color 2.
     if       batch-def-vat =  "N"
              display "No VAT" at 0470 with foreground-color 2.
*>
 jump-1.
*>-----
*>
     move     ws-date  to  tran-date.
     display  tran-date at 1336 with foreground-color 3.
     accept   tran-date at 1336 with foreground-color 3 update.
     if       cob-crt-status = cob-scr-esc
        and   not profit-centres
        and   not branches
              go to post-in.
*>
     if       cob-crt-status = cob-scr-esc
              go to  default-pc.
*>
     perform  val-date.
     if       falset
              go to  def-date.
*>
 batch-in.
*>*******
*>
     move     1  to  ledger.
     move     zero to batch-status cleared-status proofed posted
                      stored actual-gross actual-vat.
*>
     move     scycle of system-record to  bcycle of batch-record.
*>
     add      postings  1  giving   batch-start.
     move     batch-nos  to  display-batch.
*>
     display  ws-space-44 at 1703.
     display  ws-space-44 at 1803.
     display  ws-space-44 at 1903.
     display  "Assigned Batch :- {     }" at 1701 with foreground-color 2.
     display  "Enter Cycle    :- [  ]" at 1801    with foreground-color 2.
     display  "Number of Items:- [  ]" at 1901    with foreground-color 2.
     display  "Gross Amount   :- [            ]" at 2001  with foreground-color 2.
     display  "Vat   Amount   :- [            ]" at 2101  with foreground-color 2.
     display  "Batch Desc.    :- [" at 2201  with foreground-color 2.
     display  "]" at 2245 with foreground-color 2.
     display  display-batch at 1720 with foreground-color 3.
*>
 cycle-in.
*>*******
*>
     display  bcycle of batch-record at 1820 with foreground-color 3.
     accept   bcycle of batch-record at 1820 with foreground-color 3 update.
*>
     if       cob-crt-status = cob-scr-esc
              go to  def-date.
*>
     if       bcycle of batch-record < scycle of system-record
              display GL108 at 1824 with foreground-color 4
              go to cycle-in.
*>
     subtract scycle of system-record from bcycle of batch-record giving  y.
*>
     if       y  >  1
              display GL109 at 1824 with foreground-color 4
              go to cycle-in.
     display  "                    " at 1824.
*>
 items-in.
*>*******
*>
     accept   items at 1920 with foreground-color 3 update.
     if       cob-crt-status = cob-scr-esc
              go to  cycle-in.
*>
     if       items = zero
              display GL110 at 1924 with foreground-color 2.
*>
 gross-in.
*>*******
*>
     move     2020 to curs2.
     perform  accept-money9.
     if       cob-crt-status = cob-scr-esc
              go to  items-in.
     move     amt-ok9 to input-gross.
*>
 vat-in.
*>*****
*>
     if       not auto-vat
              go to  desc-in.
*>
     move     2120 to curs2.
     perform  accept-money9.
     if       cob-crt-status = cob-scr-esc
              go to  gross-in.
     move     amt-ok9 to input-vat.
*>
 desc-in.
*>******
*>
     accept   description at 2220 with foreground-color 3 update.
     if       cob-crt-status not = cob-scr-esc
              go to  main-end.
     if       auto-vat
              go to  vat-in.
     go       to  gross-in.
*>
*>*****************************************************************
*>                     P R O C E D U R E S                        *
*>*****************************************************************
*>
 batch-outline.
*>============
*>
     display  ws-space-44 at 1601.
     display  ws-space-44 at 1701.
     display  ws-space-44 at 1801.
     display  ws-space-44 at 1901.
     display  ws-space-44 at 2001.
     display  ws-space-44 at 2101.
     display  ws-space-44 at 2201.
     display  ws-space-44 at 2301.
     move     15  to  lin.
     display  display-star-46 at 1501 with foreground-color 2.
     display  display-star-46 at 2301 with foreground-color 2.
*>
 b-o-loop2.
*>
     add      1  to  lin.
     move     1 to cole.
     display  "*" at curs with foreground-color 2.
     move     46 to cole.
     display  "*" at curs with foreground-color 2.
     if       lin  <  22
              go to  b-o-loop2.
*>
 b-o-data.
*>
     display  "Batch Data" at 1618 with foreground-color 2.
*>
 help-outline.
*>===========
*>
     move     15  to  lin.
     display  display-plus-31 at 1550 with foreground-color 2.
     display  display-plus-31 at 2350 with foreground-color 2.
*>
 h-o-loop2.
*>
     add      1  to  lin.
     move     50 to cole.
     display  "+" at curs with foreground-color 2.
     move     80 to cole.
     display  "+" at curs with foreground-color 2.
     if       lin  <  22
              go to  h-o-loop2.
*>
 h-o-data.
*>
     display  "Help Data" at 1661 with foreground-color 2.
*>
 def-set-up.
*>=========
*>
     move     16  to  lin.
     move     2 to cole.
*>
 d-s-loop1.
*>
     display  ws-space-44 at curs.
     add      1  to  lin.
     if       lin  <  23
              go to  d-s-loop1.
*>
     display  "Default Set-Up" at 1716 with foreground-color 2.
     display  "A/C  - [       ]" at 1903 with foreground-color 2.
     display  "VAT  - [ ]" at 2003 with foreground-color 2.
     display  "Code - [  ]" at 2103 with foreground-color 2.
*>
 get-ac.
*>******
*>
     move     zero  to  truth.
     move     1911 to curs2.
     perform  accept-account.
     move     acc-ok to def-acs (33).
     if       acc-ok =  zero
              go to  dummy-return-1.
*>
     move     33  to  a.
     move     zero  to  batch-def-pc.
     perform  get-description.
     if       falset
              go to  get-ac.
*>
     display  ledger-name at 1920 with foreground-color 3.
*>
 get-vat.
*>
     display  "<I> - Input  VAT             " at 1851  with foreground-color 2.
     display  "<O> - Output VAT             " at 1951  with foreground-color 2.
     display  "<N> - No     VAT             " at 2051  with foreground-color 2.
*>
     move     def-vat (33) to ws-vat2.
     display  ws-vat2 at 2011 with foreground-color 3.
     accept   ws-vat2 at 2011 with update foreground-color 3.
     move     function upper-case (ws-vat2) to ws-vat.
     if       cob-crt-status = cob-scr-esc
              go to  get-ac.
*>
     if       ws-vat not = "I" and not = "O" and not = "N"
              go to  get-vat.
*>
     move     ws-vat to def-vat (33).
*>
 get-code.
*>
     display  " " at 1851 with erase eol.
     display  " " at 1951 with erase eol.
     display  " " at 2051 with erase eol.
*>
     move     def-codes (33) to ws-codes2.
     display  ws-codes2 at 2111 with foreground-color 3.
     accept   ws-codes2 at 2111 with foreground-color 3 update.
     if       cob-crt-status = cob-scr-esc
              go to  get-vat.
*>
     move     function upper-case (ws-codes2) to def-codes (33).
*>
     if       preserve-batch
              perform  batch-outline.
*>
     move     1  to  truth.
*>
 dummy-return-1.
    exit.
*>
 validate-pc.
*>==========
*>
     if       batch-def-pc = zero
              move  1  to  truth
     else
      if      p-b-codes  (batch-def-pc) = "Y" OR "E"
              move  1  to  truth
       else
              move  0  to  truth.
*>
     if       truet
              perform  get-description.
*>
     if       truet
              display ledger-name at 0441 with foreground-color 3
       else
              display "Unrecognised Account/P.C." at 0441 with foreground-color 2.
*>
 dummy-return-2.
     exit.
*>
 get-description.
*>--------------
*>
     move     zero  to  we-error.
     multiply def-acs (a)  by  100  giving  ledger-nos.
*>
     if       falset
              move zeros to  ledger-pc
     else
              move  batch-def-pc  to  ledger-pc
     end-if
     read     ledger-file  record  invalid key
              move  255  to  we-error.
*>
     if       we-error = 255
              move  0  to  truth
     else
              move  1  to  truth.
*>
 def-val.
*>======
*>
     if       def-acs (a) = zero
              move  0  to  truth
     else
              move  1  to  truth
     end-if
     perform  get-description.
*>
 store-defaults.
*>=============
*>
     multiply def-acs (a)   by  100  giving  batch-def-ac.
     move     def-vat (a)   to  batch-def-vat.
     move     def-codes (a) to  batch-def-code.
*>
 val-date.
*>=======
*>
     move     tran-date  to  ws-test-date.
     perform  zz050-Validate-Date.
     if       u-bin = zero
              move   0  to  truth
     else
              move   1  to  truth
              move   u-bin  to  entered.
*>
 dummy-return-x.
     exit.
*>
 program-exit.
     exit program.
*>
 main-end.
*>*******
*>
     close    ledger-file.
*>
 main-exit.   exit.
*>********    ****
*>
 gl050b section.
*>*************
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "General Ledger - Posting Input"  at 0126 with foreground-color 2.
     display  ws-date at 0171 with foreground-color 2.
*>
     perform  help-outline  through  h-o-data.
*>
     open     input  ledger-file.
*>
     move     zero  to  w.
     if       batch-def-vat = "O"
              move  32  to  w.
     if       batch-def-vat = "I"
              move  31  to  w.
*>
 define-vat-rate.
*>**************
*>
     if       w = zero
              go to  jump-tag.
*>
 reget-vat-rate.
*>
     move     1  to  v.
*>
     display  "VAT Rate :- [ ]" at 0401 with foreground-color 2.
     display  v at 0414 with foreground-color 3.
     accept   v at 0414 with update foreground-color 3.
*>
     if       v  <  1  or  >  3
              go to  reget-vat-rate.
*>
     move     vat-rate (v)  to  display-vat ws-vat-rate.
     display  display-vat at 0417 with foreground-color 3.
     display  "% OK (Y/N) :- [Y]" at 0422 with foreground-color 2.
*>
     move     "Y"  to  ws-reply.
     accept   ws-reply at 0437 with foreground-color 3 update.
*>
     if       ws-reply = "N"  OR  "n"
              go to  reget-vat-rate.
*>
 jump-tag.
*>
     move     batch-nos  to  display-batch.
*>
     display  "Batch      - " at 0456 with foreground-color 2.
     display  display-batch at 0469 with foreground-color 2.
     display  "/" at 0474 with foreground-color 2.
     display  "Default    - " at 0656 with foreground-color 2.
     display  bdefault at 0669 with foreground-color 2.
     display  "Contra A/C - " at 0856 with foreground-color 2.
     display  batch-def-ac at 0869 with foreground-color 2.
*>
     if       batch-def-pc  not numeric
              move  zero  to  batch-def-pc.
*>
     if       batch-def-pc  not =  zero
              display "/" at 0875 with foreground-color 2
              display batch-def-pc at 0876 with foreground-color 3.
*>
     if       w  not =  zero
              display "VAT A/C    - " at 1056 with foreground-color 2
              move def-acs (w) to ws-acs
              display ws-acs at 1069 with foreground-color 3
     else
              display "No VAT on this Batch." AT 1056 with foreground-color 2.
*>
     display  "Convention - " at 1256 with foreground-color 2.
     display  convention at 1269 with foreground-color 3.
*>
     display  "Date           [          ]" at 0601 with foreground-color 2.
     display  "Account        [       ]" at 0801    with foreground-color 2.
     if       profit-centres
              display "Profit Centre  [  ]" at 1001 with foreground-color 2.
     if       branches
              display "Branch         [  ]" at 1001 with foreground-color 2.
*>
     display  "Amount         [           ]" at 1201 with foreground-color 2.
*>
     if       auto-vat  and  w  not =  zero
              display "VAT Code       [ ]  {p or m or space}" at 1401 with foreground-color 2.
*>
     display  "VAT Amount     [           ]" at 1601  with foreground-color 2.
     display  "Narrative      [" at 1801   with foreground-color 2.
     display  "]" at 1849 with foreground-color 2.
*>
     move     entered  to  u-bin.
     call     "maps04"  using  maps03-ws.
     move     zero to save-a.
     move     1  to  a.
*>
 main-loop.
*>========
*>
     display  a at 0475 with foreground-color 3.
     display  ws-date at 0617 with foreground-color 3.
     accept   ws-date at 0617 with foreground-color 3 update.
     move     ws-date to array-date (a).
*>
*>  perform  test-escape.
*>
*> escape-code = "B"
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
         and  w not = zero
              perform reget-vat-rate
              go to main-loop.
*> escape-code = "B"  or  "F"  *> back / forward
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
           or cob-scr-esc or cob-scr-page_down or cob-scr-key-down
              go to  main-loop.
*>
     if       z  >  0
              go to  main-loop.
*>
*> escape-code = "E"  or  "Q" *> esc
     if       cob-crt-status = cob-scr-esc
              go to  main-exit.
     move     zero  to  u-bin.
     move     array-date (a)  to  ws-test-date.
     perform  zz050-Validate-Date.
     move     ws-test-date to  array-date (a).
*>
     if       u-bin = zero
              display "Invalid Date" at 0636 with foreground-color 4
              go to main-loop.
     display  ws-space-29 at 0626.
*>
 get-account.
*>----------
*>
     move     0817 to curs2.
     perform  accept-account.
     move     acc-ok to account-in.
*>
*>     perform  test-escape.
*>
*> escape-code = "B"  or  "F"
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
                       or cob-scr-page_down or cob-scr-key-down
       or     z  not =  zero
              go to  main-loop.
*>
*> escape-code = "E"  or  "Q"
     if       cob-crt-status = cob-scr-esc
              go to  main-exit.
*>
     move     zero  to  we-error.
     multiply account-in  by  100  giving  ledger-nos.
     move     array-pc    to  ledger-pc.
*>
     read     ledger-file  record  invalid key
              move  255  to  we-error.
*>
     if       we-error = zero
              display ledger-name at 0826 with foreground-color 3
     else
              display "Invalid A/C number" at 0826 with foreground-color 4
              go to get-account.
*>
     if       vat-flag = 1
       or     account-in = def-acs (31) or def-acs (32)
              move 1 to vat-flag-2
     else
              move zero to vat-flag-2.
*>
 accept-p-c.
*>---------
*>
     move     zero  to  array-pc.
*>
     if       not profit-centres
        and   not branches
              go to accept-amount.
*>
     display  array-pc at 1017 with foreground-color 3.
     accept   array-pc at 1017 with foreground-color 3 update.
*>
*>     perform  test-escape.
*>
     if       cob-crt-status = cob-scr-page_down
                            or cob-scr-key-down
*> escape-code = "F"
       or     z  not =  zero
              go to  main-loop.
*>
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
*> escape-code = "B"
              go to  get-account.
*>
     if       cob-crt-status = cob-scr-esc
*> escape-code = "E"  or  "Q"
              go to  main-exit.
*>
 accept-amount.
*>------------
*>
     move     1217 to curs2.
     if       vat-flag-2 = zero
              perform  accept-money8s
              move amt-ok8s to array-amount (a)
     else
              move zero to array-amount (a).
     move     array-amount (a) to display-amt.
     display  display-amt at 1217 with foreground-color 3.
*>     perform  test-escape.
*>
     if       cob-crt-status = cob-scr-page_down
                            or cob-scr-key-down
*> escape-code = "F"
       or     z  not =  zero
              go to  main-loop.
*>
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
*> escape-code = "B"
       and    not profit-centres  and  not branches
              go to  get-account.
*>
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
*> escape-code = "B"
              go to  accept-p-c.
*>
     if       cob-crt-status = cob-scr-esc
*> escape-code = "E"  or  "Q"
              go to  main-exit.
*>
 accept-vat.
*>---------
*>
     if       not auto-vat  or  w = zero
              move  zero  to  array-vat-amount (a)
              go to  vat-amount-input.
*>
     move     space  to  array-vat.
     if       vat-flag-2 = 1
              move zero to array-vat-amount (a)
              go to vat-amount-input.
*>
     display  array-vat at 1417 with foreground-color 3.
     accept   array-vat at 1417 with foreground-color 3 update.
     move     function upper-case (array-vat) to array-vat.
*>
*>     perform  test-escape.
*>
     if       cob-crt-status = cob-scr-page_down
                             or cob-scr-key-down
*> escape-code = "F"
       or     z  not =  zero
              go to  main-loop.
*>
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
*> escape-code = "B"
              go to  accept-amount.
*>
     if       cob-crt-status = cob-scr-esc
*> escape-code = "E"  or  "Q"
              go to  main-exit.
*>
     if       array-vat = "P"
              perform  net
              go to vat-amount-input.
*>
     if       array-vat = "M"
              perform  gross
              go to vat-amount-input.
*>
     if       array-vat  = space
              move zero to array-vat-amount (a)
              go to accept-narative.
*>
     display  "Invalid code" at 1439 with foreground-color 4.
     go       to accept-vat.
*>
 vat-amount-input.
*>***************
*>
*>   check if vat on transaction
*>
     if       w = zero
              go to  accept-narative.
*>
     move     1617 to curs2.
     move     array-vat-amount (a) to amt-ok8s.
     perform  accept-money8s2.
*>
     if       amt-ok8s not = array-vat-amount (a)
        and   array-amount (a) not = zero
        and   array-vat = "M"
              add array-vat-amount (a) to array-amount (a)
              subtract amt-ok8s from array-amount (a).
*>
*>    if       amt-ok8s < zero
*>             multiply -1 by amt-ok8s.
*>
     move     amt-ok8s to array-vat-amount (a).
*>
*>     perform  test-escape.
*>
     if       cob-crt-status = cob-scr-key-down
                            or cob-scr-page_down
*> escape-code = "F"
       or     z  not =  zero
              go to  main-loop.
*>
     if       cob-crt-status = cob-scr-key-up or cob-scr-page_up
*> escape-code = "B"
              go to  accept-vat.
*>
     if       cob-crt-status = cob-scr-esc
*> escape-code = "E"  or  "Q"
              go to  main-exit.
*>
 accept-narative.
*>
     if       array-amount (a) = zero
         and  array-vat-amount (a) = zero
              go to main-loop.
*>
     display  "            " at 1439.
     move     spaces  to ws-legend.
     accept   ws-legend at 1817 with foreground-color 3 update.
     move     ws-legend to array-legend (a).
*>
*>     perform  test-escape.
*>
     if       cob-crt-status = cob-scr-page_down
                            or cob-scr-key-down
*> escape-code = "F"
       or     z  not =  zero
              go to  main-loop.
*>
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
*> escape-code = "B"
       and    auto-vat
              go to  accept-vat.
*>
     if       cob-crt-status = cob-scr-page_up or cob-scr-key-up
*> escape-code = "B"
              go to  accept-amount.
*>
     if       cob-crt-status = cob-scr-esc
*> escape-code = "E"  or  "Q"
              go to  main-exit.
*>
 loop-end.
*>*******
*>
*>   Check for negative amount,if so reverse convention
*>
*>    if       array-amount (a) < zero
*>             multiply -1 by array-amount (a)
*>             move 1 to rev-flag.
*>
*>    if       rev-flag = 1
*>       and   convention = "CR"
*>             move "DR" to ws-convention.
*>    if       rev-flag = 1
*>       and   convention = "DR"
*>             move "CR" to ws-convention.
*>
     if       convention = "DR"
              multiply  account-in  by  100
                        giving  array-dr (a)
              move  array-pc    to  array-dr-pc (a)
              move  "DR"  to  array-vat-side (a)
     else
              multiply  account-in  by  100
                        giving  array-cr (a)
              move  array-pc    to  array-cr-pc (a)
              move  "CR"  to  array-vat-side (a).
*>
     if       convention = "DR"
              move  batch-def-ac  to  array-cr (a)
              move  batch-def-pc  to  array-cr-pc (a)
     else
              move  batch-def-ac  to  array-dr (a)
              move  batch-def-pc  to  array-dr-pc (a)
*>
     move     batch-def-code  to  array-code (a).
*>
     if       w  not =  zero
              move  def-acs (w)  to  array-vat-ac (a)
     else
              move  zero  to  array-vat-ac (a).
*>
     move     batch-def-pc       to  array-vat-pc (a).
*>
     add      1  to  a.
     if       a  >  12
              perform  write-out.
*>
*>    move     zero to rev-flag.
     go to    main-loop.
*>
 help-outline.
*>===========
*>
     move     14  to  lin.
     move     54  to  cole.
     display  display-plus-27 at 1454.
     display  display-plus-27 at 2354.
*>
 h-o-loop2.
*>
     add      1  to  lin.
     move     54 to cole.
     display  "+" at curs  with foreground-color 2.
     move     80 to cole.
     display  "+" at curs with foreground-color 2.
     if       lin  <  22
              go to  h-o-loop2.
*>
 h-o-data.
*>
     display  "Option :- [ ]" at 1656 with foreground-color 2.
     display  "B - Back-up one field" at 1856  with foreground-color 2.
     display  "E - End" at 1956 with foreground-color 2.
     display  "F - Force Write" at 2056 with foreground-color 2.
     display  "Q - Quit Batch" at 2156 with foreground-color 2.
     display  "n - Back-up n records" at 2256 with foreground-color 2.
*>
 net.
*>==
*>
     compute  array-vat-amount (a)  rounded =  array-amount (a)  *  ws-vat-rate / 100.
     move     array-vat-amount (a) to display-amt.
     display  display-amt at 1617 with foreground-color 3.
*>
 gross.
*>====
*>
     compute  array-vat-amount (a)  rounded =
              array-amount (a) - (array-amount (a) / ((ws-vat-rate  + 100) / 100)).
     subtract array-vat-amount (a)  from  array-amount (a).
     move     array-vat-amount (a) to display-amt.
     display  display-amt at 1617 with foreground-color 3.
*>
 main-exit.
*>********
*>
     close    ledger-file.
     if       cob-crt-status = cob-scr-esc
*> escape-code = "Q"
              perform  quit-batch
     else
              add save-a  to  postings.
*>
 end-routine. exit.
*>**********  ****
*>****************************************************
*>               P R O C E D U R E S                 *
*>****************************************************
 write-out                   section.
*>==================================
*>
     if       a  <  1
              go to  main-exit.
*>
     perform  open-posting.
*>
     if       escape-code  not =  "F"
              subtract  1  from  a.
*>
     perform  write-loop varying y from 1 by 1 until y  >  a.
*>
     perform  close-posting.
     add      a  to  save-a.
     move     1  to  a.
     go       to main-exit.
*>
 write-loop.
*>*********
*>
     move     batch-nos  to  batch.
     add      save-a  y  giving  post-number.
     add      batch-start  post-number  giving  rrn.
     move     batch-def-code  to  post-code in posting-record.
     move     array-date (y)   to  post-date.
     move     array-dr (y)     to  post-dr.
     move     array-dr-pc (y)  to  dr-pc.
     move     array-cr (y)     to  post-cr.
     move     array-cr-pc (y)  to  cr-pc.
     move     array-amount (y) to  post-amount.
     move     array-legend (y) to  post-legend.
     multiply array-vat-ac (y) by  100 giving  vat-ac of posting-record.
     move     array-vat-pc (y) to  vat-pc.
     move     array-vat-side (y)    to  post-vat-side.
     move     array-vat-amount (y)  to  vat-amount.
*>
     write    posting-record.
*>
 main-exit.   exit section.
*>********    ****
*>
 back-up                 section.
*>******************************
*>
     if       z  >  a
              perform  write-out
       else
              move  z  to  a
              go to  main-exit.
*>
     subtract 11  from  rrn.
     subtract z   from  save-a  giving  a.
*>
 sub-loop.
*>
     if       a  >  11
              subtract  11  from  a
              go to  sub-loop.
     perform  open-posting.
     read     posting-file.
*>
     perform  read-loop varying y from 1 by 1 until y > 11.
     perform  close-posting.
     go       to main-exit.
*>
 read-loop.
*>********
*>
     read     posting-file  next record.
*>
     move     post-date      to  array-date (y).
     move     post-dr        to  array-dr (y).
     move     dr-pc          to  array-dr-pc (y).
     move     post-cr        to  array-cr (y).
     move     cr-pc          to  array-cr-pc (y).
     move     post-amount    to  array-amount (y).
     move     post-legend    to  array-legend (y).
     move     vat-ac of posting-record to  array-vat-ac (y).
     move     vat-pc         to  array-vat-pc (y).
     move     post-vat-side  to  array-vat-side (y).
     move     vat-amount     to  array-vat-amount (y).
*>
     delete   posting-file  record.
*>
 main-exit.   exit section.
*>********    ****
*>
 open-posting                section.
*>----------------------------------
*>
     open     i-o  posting-file.
*>
 main-exit.   exit section.
*>*********    ****
*>
 close-posting               section.
*>----------------------------------
*>
     close    posting-file.
*>
 main-exit.   exit section.
*>********    ****
*>
 quit-batch                  section.
*>----------------------------------
*>
     perform  open-posting.
     move     batch-start  to  rrn.
     read     posting-file  record  invalid key
              go to  read-next.
*>
 loop.
*>***
*>
     if       batch = batch-nos
              delete  posting-file  record.
*>
 read-next.
*>********
*>
     read     posting-file  next record  at end
              go to  main-end.
*>
     go       to loop.
*>
 main-end.
*>*******
*>
     perform  close-posting.
     move     9  to  z.
*>
 main-exit.   exit section.
*>********    ****
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
     inspect  ws-test-date replacing all "." by "/".
     inspect  ws-test-date replacing all "," by "/".
     inspect  ws-test-date replacing all "-" by "/".
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
     perform  maps03.
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
     perform  maps03.
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
 maps03       section.
*>*******************
*>
     call     "maps04"  using  maps03-ws.
*>
 maps04-exit.
     exit     section.
*>
