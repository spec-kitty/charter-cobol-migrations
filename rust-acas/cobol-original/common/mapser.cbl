000010******************************************************************
000020*                                                                *
000030*     S Y S T E M   S E T - U P  &  N A M E    E N C O D E R     *
000040*     THIS PROGRAM DOES NOT FORM PART OF THE OPEN SOURCE VERSION *
000041*     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ *
000050******************************************************************
000080
000090
000100 identification          division.
000110*================================
000120*
000130***
000140     program-id.         mapser.
000150***
000160*    Author.             Cis Cobol Conversion By V B Coen 30/10/82
000180*                        For Applewood Computers.
      *
001400*Security.               Copyright (C) 1967-2009, Vincent Bryan Coen.
001500*                        Distributed under the GNU General Public License
001600*                        v2.0. Only. See the file COPYING for details.
000190***
000220     remarks.            System Set-Up & Name Encoder.
000230***
000240*    version.            see prog-name in ws.
000250*****
000260*
000270*    called modules.     maps01.
000280***  changes.
000290* 10/03/84 vbc - support system-record-4.
000291* 05/02/02 vbc - updated for y2k.
      * 29/01/09 vbc - Migration to Open Cobol.
      *                WARNING: THIS CODE IS NO LONGER MAINTAINED.
      *                         See individual sub-systems, eg, General, Sales, Purchase,
      *                             Stock, OE, Payroll, Project-x/z etc.
002300*>
002400*>*************************************************************************
002500*>
002600*> Copyright Notice.
002700*>*****************
002800*>
002900*> This file/program is part of ACAS the Applewood Computers Accounting
003000*> System and is copyright (c) Vincent B Coen. 1976-2009 and later.
003100*>
003200*> This program is free software; you can redistribute it and/or modify it
003300*> under the terms of the GNU General Public License as published by the
003400*> Free Software Foundation; version 2 ONLY.
003500*>
003600*> ACAS is distributed in the hope that it will be useful, but WITHOUT
003700*> ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
003800*> FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
003900*> for more details. If it breaks, you own both pieces but I will endevor
004000*> to fix it, providing you tell me about the problem.
004100*>
004200*> You should have received a copy of the GNU General Public License along
004300*> with ACAS; see the file COPYING.  If not, write to the Free Software
004400*> Foundation, 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
004500*>*************************************************************************
004600*>
000300 environment             division.
000310*================================
000320*
000000 copy  "envdiv.cob".
000400 input-output            section.
000410*-------------------------------
000420*
000430 file-control.
000440*------------
000450*
000000 copy "selsys.cob".
000530*
000600 data                    division.
000610*================================
000620*
000630 file section.
000640*------------
000650*
000000 copy "fdsys.cob".
002540*
000000 copy "wssys4.cob".
002860*
002870 working-storage section.
002880*-----------------------
002890 77  prog-name           pic x(16) value "mapser (3.01.00)".
002910*
000000 copy "wsmaps01.cob".
000000 copy "wsdflt.cob".
000000 copy "wsfinal.cob".
000000 copy "wsfnctn.cob".
       copy "wsnames.cob".
003550*
003560 01  ws-data.
003570     03  pass-word-input.
003580       05  ar2           pic x         occurs  4.
003590     03  pass-word-output.
003600       05  ar3           pic x         occurs  4.
003610*
003620     03  pass-name-input.
003630       05  ar4           pic x         occurs  32.
003640     03  pass-name-output.
003650       05  ar5           pic x         occurs  32.
003660*
003670     03  ws-reply        pic x.
003680     03  a               pic 99        comp.
003690     03  option-list     pic x(50).
003700     03  wsmaps-ser.
003710         05  wsmaps-ser-xx pic xx.
003720         05  wsmaps-ser-nn pic 9(4).
003730*
003740 procedure               division.
003750*================================
003760*
003770 bgn   section.
003780**************
003790 main.
003800*----
003810*
003820     display  " " at 0101 with erase eos.
003830     display  prog-name at 0101 with foreground-color 2.
003840     display  "ACAS System Set-up Routine" AT 0128
                                      with foreground-color 2.
003850*
003860	   display  "*****************************************" at 0420
                                      with foreground-color 2.
003870	   display  "* This Program is for internal use only *" at 0520
                                      with foreground-color 2.
003880	   display  "*" AT 0620 with foreground-color 2.
003890	   display  "*" AT 0660 with foreground-color 2.
003900	   display  "*              DO NOT ISSUE             *" at 0720
                                      with foreground-color 4 blink.
           display  "*" at 0720 with foreground-color 2
           display  "*" at 0760 with foreground-color 2
003910	   display  "*" AT 0820 with foreground-color 2.
003920	   display  "*" AT 0860 with foreground-color 2.
003930	   display  "*****************************************" at 0920
                                      with foreground-color 2.
003940*
003950* Now Open System File for Output (overwriting existing contents)
003960*
003970     open     output  system-file.
003980     move     spaces to system-record.
000000*
003990 loop.
004000*----
004010     display  "Enter the customer's name :- [" at 1101
                                 with foreground-color 2.
004020     display  "]" at 1163 with foreground-color 2.
004030*
004040     accept   usera at 1131 with foreground-color 3 update.
004050*
004060     display  "Please verify that name is correct (Y/N) :- [ ]"
004070		    at 1301 with foreground-color 2.
004080     move         "Y"  to  ws-reply.
004090     accept   ws-reply  at 1346 with foreground-color 6 update.
004100*
004110     if       ws-reply  equal  "Y"  OR "y"
004120              next  sentence
004130      else
004140              go to  loop.
004150*
004160     display  "Working! Please wait" at 1352
                                      with foreground-color 2.
004170*
004180     move     "N"  to  encode.
004190     move     usera to  pass-name.
004210     call     "maps01"  using  maps01-ws.
004230     move     pass-name  to  user-code.
004240*
004250     move     "P"  to  encode.
004260     move     "pass"  to  pass-word  of  maps01-ws
004270                          pass-word  of  system-record.
004280*
004290     call     "maps01"  using  maps01-ws.
004300*
004310     move     pass-word  of  maps01-ws  to
004320              pass-word  of  system-record.
004330*
004340     move     "N" to sl-own-nos.
004350     move     zero  to pass-value host bl-next-batch.
004360     move     zero to cyclea current-quarter period next-invoice
004370                      first-sl-batch first-sl-inv ledger-sec.
004380     move     zero to updates postings extra-charge-ac vat-ac
004390                      next-folio entry-level age-to-pay delivery
004400                      invoicer extra-rate pf-retention.
004410     move     zero to full-invoicing p-flag-a p-flag-p p-flag-i.
004420     perform  initialise varying a from 1 by 1 until a > 32.
004440*
004450     move     "20090101"  to  run-date.
004460*
004470     perform  level-setup.
004480*
004490     move     1  to  op-system.
004500     move     zero  to  start-date  end-date  vat-rate-1
004510                        vat-rate-2  vat-rate-3  header-level.
004520     move     zero to bl-pay-ac bl-purch-ac p-creditors
004530     move     zero to sl-days-1 sl-days-2 sl-days-3.
004540     move     1  to  sales-range.
004550     move     2  to  purchase-range.
004560     move     1  to  next-batch.
004570*
004580     if       s-l
004590              perform  sl-setup.
004600*
004610* now set record nos for actual system record to 1.
004620*
004630     move     1  to  rrn.
004650     write    system-record.
004660*
004670     perform  zeroise varying a from 1 by 1 until a > 33.
004690*
004700* now set record nos for default record to 2.
004710*
004720     add      1     to  rrn.
004740     write    system-record  from  default-record.
004750*
004760     move     spaces  to  final-record.
004770*
004780* Now set record nos for Final Record to 3.
004790*
004800     add      1       to  rrn.
004820     write    system-record  from  final-record.
004830*
004840     move     zeros to system-record-4.
004850     move     zeros to sl-os-bal-last-month sl-os-bal-this-month
004860                     sl-invoices-this-month  sl-variance
004870                     sl-credit-deductions sl-cn-unappl-this-month
004880                     sl-credit-notes-this-month sl-payments.
004890     move     zeros to pl-os-bal-last-month pl-os-bal-this-month
004900                     pl-invoices-this-month  pl-variance
004910                     pl-credit-deductions pl-cn-unappl-this-month
004920                     pl-credit-notes-this-month pl-payments,
004930     move     zeros to sl4-spare1 sl4-spare2 sl4-spare3
004940                     sl4-spare4.
004950*
004960* Now set record nos for System totals record to 4.
004970*
004980     add      1 to rrn.
005000     write    system-record-4.
005010*
005020     close    system-file.
005040     stop     run.
005050/
005060 initialise                  section.
005070************************************
005080*
005090 main.
005100*
005110*    move     spaces to  op-disk (a).
005120     move     "000"  to  op-gen (a).
005130     move     zero   to  file-status (a).
005140*
005150 main-exit.   exit.
005160**********    ****
005180*
005190 zeroise                     section.
005200************************************
005210*
005220 main.
005230*
005240     move     zero  to  def-acs (a).
005250     move     "  "  to  def-codes (a).
005260     move     " "   to  def-vat (a).
005270*
005280 main-exit.                  exit.
005290**********                   ****
005320*
005330 level-setup                 section.
005340************************************
005350*
005360 main.
005370*
005380     perform  serialise.
005390*
005410     display  "General  Ledger (Y/N) ? :- [ ]" at 1901
                                 with foreground-color 2.
005420	   display  "Purchase Ledger (Y/N) ? :- [ ]" at 2001
                                 with foreground-color 2.
005430	   display  "Sales    Ledger (Y/N) ? :- [ ]" at 2101
                                 with foreground-color 2.
005440	   display  "Invoicing       (Y/N) ? :- [ ]" at 1941
                                 with foreground-color 2.
005450*
005460     accept   ws-reply at 1929 with foreground-color 6 update.
005470*
005480     if       ws-reply  equal  "Y"  OR  "y"
005490              move  1  to  level-1
005500       else
005510              move  0  to  level-1.
005520*
005530     accept   ws-reply at 2029 with foreground-color 6 update.
005540*
005550     if       ws-reply  equal  "Y"  OR  "y"
005560              move  1  to  level-2
005570       else
005580              move  0  to  level-2.
005590*
005600     accept   ws-reply at 2129 with foreground-color 6 update.
005610*
005620     if       ws-reply  equal  "Y"  OR  "y"
005630              move  1  to  level-3
005640       else
005650              move  0  to  level-3.
005660*
005670     accept   ws-reply at 1969 with foreground-color 6 update.
005680*
005690     if       ws-reply  equal  "Y"  OR  "y"
005700              move  1  to  full-invoicing
005710       else
005720              move  0  to  full-invoicing.
005740*
005750     display  "Please confirm (Y/N) :- [ ] " at 2301
                                    with foreground-color 2.
005760*
005770     move     spaces  to  option-list.
005780     move     1  to  a.
005790*
005800     if       g-l
005810              string "General " delimited by size into option-list
005840                    with  pointer  a.
005850*
005860     if       b-l  and  g-l
005870              string "/ " delimited by size into option-list
005900                    with  pointer  a.
005910*
005920     if       b-l
005930             string "Purchase " delimited by size into option-list
005960                    with  pointer  a.
005970*
005980     if       s-l  and  g-l
005990        or    s-l  and  b-l
006000              string "/ " delimited by size into option-list
006030                    with  pointer  a.
006040*
006050     if       s-l
006060              string "Sales " delimited by size into option-list
006090                    with  pointer  a.
006100*
006110     if       s-l  and  full-invoicing  equal  1
006120              string  "/ Invoicing" delimited by size
006140                    into  option-list
006150                    with  pointer  a.
006160*
006170     display  option-list at 2330 with foreground-color 2.
006180*
006200     accept   ws-reply at 2326 with foreground-color 6.
006210*
006220     if       ws-reply  not equal  "Y"  and  not equal  "y"
006230              go to  main.
006250*
006260 main-exit.   exit.
006270**********    ****
006280*
006320 sl-setup                    section.
006330************************************
006340*
006350 main.
006360*
006370     move     1 to sl-dunning sl-charges.
006400     move     30    to  sl-credit.
006410*
006420     move     zero to sl-disc sl-min sl-max sl-limit sl-day-book
006430                      sl-stats-run sl-late-per s-flag-a s-flag-i
006440                      s-flag-p sl-pay-ac sl-sales-ac s-debtors
006450                      s-end-cycle-date.
006460*
006470     move     spaces to extra-desc extra-type.
006490     move         "\"   to  sl-delim.
006510*
006520 main-exit.   exit.
006530**********    ****
006540*
006550*
006580 serialise               section.
006590*===============================
006600*
006610 main.
006620*****
006630*
006640*
006650     display  "Enter the serial number   :- [" at 1501
                                 with foreground-color 2.
006660     display  "]" at 1537  with foreground-color 2.
006670*
006680     move     "mp0000" to wsmaps-ser.
006690     display  wsmaps-ser at 1531 with foreground-color 2.
006700     accept   wsmaps-ser at 1531 with foreground-color 3 update.
006710*
006720     if       wsmaps-ser-nn  not numeric
006730              display "Invalid Serial Number!" at 1701
                                  with foreground-color 4
006740              go to  main.
006750*
006760     display  "Please verify that serial is correct (Y/N) :- [ ]"
006770		    at 1701 with foreground-color 2.
006780     move         "Y"  to  ws-reply.
006790     accept   ws-reply at 1748 with foreground-color 6 update.
006800*
006810     if       ws-reply  equal  "Y"  or "y"
006820              next  sentence
006830       else
006840              go to  main.
006850*
006860     move     wsmaps-ser-xx to maps-ser-xx.
006870     move     wsmaps-ser-nn to maps-ser-nn.
006880*
006890 main-exit.   exit.
