       >>source free
*>*****************************************************************
*>                                                                *
*>       S Y S T E M   F I L E   M A I N T E N A N C E            *
*>                                                                *
*>*****************************************************************
*>
 identification          division.
*>===============================
*>
*>**
      program-id.         sys002.
*>**
*>    author.             Cis Cobol Conversion By V B Coen FBCS, 31/10/82
*>                        for Applewood Computers.
*>**
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            System File Maintenance  User Parameters.
*>**
*>    Version.            See PROG-NAME in ws.
*>**
*>    Called Modules.     maps01.
*>                        maps04
*>                        maps99.
*>**
*>    Error messages used.
*>                        SY005.
*>                        SY006.
*>                        SY007.
*>                        SY008.
*>                        SY009.
*>                        SY044.
*>                        SY045.
*>
*>                        SY101.
*>                        SY102.
*>                        SY103.
*>                        SY104.
*>                        SY105.
*>**
*>  Changes.
*> 06/01/85 vbc - Support gl workfiles as op-disk (1).
*> 07/01/85 vbc - Offer choice for print out.
*> 12/02/02 vbc - Y2K support.
*> 29/01/09 vbc - Migration to Open Cobol. Removed all security and
*>                encryption code & data as this code can go world wide.
*>                Now removed from all Accounts systems on SVN. Full copy
*>                now held on encrypt partition. Files back to flat.
*>                Removed op-disks as no longer used.
*> 29/03/09 vbc - Support for using IRS instead of GL.
*> 06/04/09 vbc - GL/IRS account capture in PL plus PL data clean up
*>                ditto SL accounts also captured. More info printed.
*> 08/04/09 vbc - Environment vars ACAS_IRS & LEDGERS reported on.
*> 02/05/09 vbc - Added Stock set up + very basic OE (in Stock params).
*> 12/05/09 vbc - Cosmetic on Stock printout.
*> 01/06/09 vbc - Added Sales and/or Purchase Stock link.
*> 02/06/09 vbc - Align P/L & S/L values and other little cleanups on report.
*> 04/06/09 vbc - .08 Fix audit no on screen to 999.
*> 06/06/09 vbc - .09 Adjust defaults for Todate period to Yearly.
*> 09/06/09 vbc - .10 Offer escape out of first screen to quit program.
*> 29/06/09 vbc - .11 Adust periods for Stock params.
*> 04/07/09 vbc - .12 Convert error msgs to ACAS std ie, SYnnn format.
*> 07/09/10 vbc - .14 Added lpi, cpi & page-top to CUPS lpr print command.
*> 14/09/10 vbc - .15 Added Cob Env variables presets
*>                    added ops-data-2 data - print-spool-name.
*> 15/09/10 vbc - .16 Force system-record initialize if not found.
*> 16/11/11 vbc - .17 Force case on accepting sl-own-nos, SL-Stock-Link, PL-Stock-Link and some others.
*>                .18 Added system wide print lines under system params after collecting company address.
*>                .19 Moved printed system wide print lines to User params.
*> 17/11/11 vbc - .20 Remove most of Payroll on Open source versions
*>                .21 In init of NEW system file, set file layout version to rec 1.
*>                .22 Page-lines not checked > 28.
*> 18/11/11 vbc - .23 If esc is entered on 1st screen, system-files was not closed
*> 19/11/11 vbc - .24 Force date format to be UK on creating new system rec 1 in case
*>                    user does not set it and open system file with lock.
*> 04/12/11 vbc - .25 Added Delivery on display and report for debugging but temp left as changeable.
*> 10/12/11 vbc - .26 Support for User Post code/Zip, Country and local tax (or vat rates 4 & 5)
*>                    Global support for date format and now set into common system data area,
*>                    raised system version to 3.01 to match across all ACAS sub systems.
*> 11/12/11 vbc - .27 Removed all proc for stk-date-form from Stock data and replaced with just Date-Form in General.
*> 26/12/11 vbc - .28 Included common code (zz010, zz020) used by All ACAS modules needed as can be called
*>                     by any of the sub-systems. Called to dummy area but creates paths etc in WS.
*> 04/03/12 vbc - .29 Added support for Duplicate file type processing + MS SQL Server rdbms.
*>                    Added screen function control but only Standard Cobol in use.
*> 09/04/12 vbc - .30 Added RDBMS screens and reporting.
*> 17/04/13 vbc - .31 Added init for final record within system.dat.
*> 20/04/13 vbc - .32 Remarked out code to rebuild file paths etc as done in menus + format issue for delivery tag
*> 26/04/13 vbc - .33 Force writes for all record types, build paths by including code in .32
*> 27/04/13 vbc - .34 Make Stk-Page-Lines same as System Page-Lines if zero. Should't we only be using system lines?
*> 15/05/13 vbc - .35 Reworded screen for Stk-Activity-Rep-Run.
*> 20/05/13 vbc - .36 Added SL screen 2 for Print co. addr info on Invoices, Statements, Delivery, & letters
*>                    etc. Also added VAT print request in exist user data screen.
*>                .37 Bug in above in print layout.
*> 04/06/13 vbc - .38 Missing Name for Print Lines in user params print, adding spool names 2 & 3,
*>                    remove stk-page-lines as using system page-lines only.
*> 30/06/13 vbc - .38 Change printed rdbms password from SECRET to 'It's SECRET' just in case someone
*>                    assumes thats the password :)
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of ACAS the Applewood Computers Accounting
*> System and is copyright (c) Vincent B Coen. 1976-2013 and later.
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
 copy "selsys.cob".
 copy "selprint.cob".
 data                    division.
 file section.
*>-----------
*>
 copy "fdsys.cob".
*>
 copy "fdprint.cob".
 working-storage section.
*>----------------------
 77  prog-name           pic x(16)    value "SYS002 (3.01.39)".
 77  error-code          pic 999.
 77  Page-Nos            pic 99       value zero.
 77  OS-Delimiter        pic x        value "/".
 77  ACAS_BIN            pic x(512)   value spaces.  *> added
 77  ACAS_IRS            pic x(500)   value spaces.
 77  ACAS_LEDGERS        pic x(500)   value spaces.
 77  Arg-Number          pic 9        value zero.
 77  z                   binary-char  value zero.
*>
*> Used For Changes In wssystem After Release
*>===========================================
*>  in case file layout upgrade is needed.
*>   Using a file update program.
*>
 77  ws-Sys-Record-Ver-Prime          binary-char value 1.
 77  ws-Sys-Record-Ver-Secondary      binary-char value 1.
*>
*>
*> Holds program parameter values from command line
*>
 01  Arg-Vals                         value spaces.
     03  Arg-Value       pic x(525)  occurs 2.
 01  Arg-Test            pic x(525)   value spaces.
*>
*>=========================================================================
*>  User changable but may also need to be done system wide
*>    CUPS lpr command to spool print output & used for Linux, Unix & Mac.
*>                   Not standard in OS/2 but if so needs to be changed in
*>                   wssystem.cob and here (sys002).
*>
 copy "print-spool-command.cob".
 01  ws-data.
     03  ws-reply        pic x.
     03  a               binary-char.
     03  b               binary-char.
     03  p-start         pic x(10)      value spaces.
     03  p-end           pic x(10)      value spaces.
     03  s-pass-word     pic x(4)       value spaces.
     03  to-day          pic x(10)      value "dd/mm/yyyy".
     03  Used-Once       pic 9          value zero.
*>
 01  filler.
     03  num-1           pic z9.99.
     03  num-1b          pic z9.99.
     03  num-2           pic z(4)9.
     03  num-3           pic 999.
     03  num-4           pic z9.
     03  num-5           pic z(6)9.
     03  num-6           pic 9(5).
     03  num-7           pic 9(8).
     03  num-8           pic 9(6).
     03  num-9           pic zz9.
     03  Temp-String     pic x(43).
     03  Temp-String2    pic x(20).
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
 copy "wsmaps01.cob".
 copy "wsmaps03.cob".
 copy "wsfnctn.cob".
*>
 copy "wsfinal.cob".
 copy "wssys4.cob".
 copy "wsdflt.cob".
*>
 01  accept-terminator-array pic 9(4)            value zero.
     copy "screenio.cpy".
*>
 01  line-1.
     03  l1-name            pic x(16).
     03  filler             pic x(34)    value  spaces.
     03  filler             pic x(33)    value "S Y S T E M   P A R A M E T E R S".
     03  filler             pic x(27)    value  spaces.
     03  line-1-date        pic x(10).
     03  filler             pic x(6)     value spaces.
     03  filler             pic x(4)     value "Page".
     03  l1-page            pic z9.
*>
 01  line-3a.
     03  filler             pic x(24)    value  spaces.
     03  filler             pic x(16)    value "User  Parameters".
     03  filler             pic x(40)    value  spaces.
     03  filler             pic x(16)    value "G/L   Parameters".
*>
 01  line-3b.
     03  filler             pic x(24)    value  spaces.
     03  filler             pic x(16)    value "ACAS  Parameters".
     03  filler             pic x(40)    value  spaces.
     03  filler             pic x(16)    value "P/L   Parameters".
*>
 01  line-3c.
     03  filler             pic x(24)    value  spaces.
     03  filler             pic x(16)    value "Inv.  Parameters".
     03  filler             pic x(40)    value spaces.
     03  filler             pic x(16)    value "S/L   Parameters".
*>
 01  line-3d.
     03  filler             pic x(24)    value  spaces.
     03  filler             pic x(16)    value "Stock Parameters".
     03  filler             pic x(40)    value spaces.
     03  filler             pic x(16)    value "O/E   Parameters".
*>
 01  line-3d2.
     03  filler             pic x(22)    value  spaces.
     03  filler             pic x(18)    value "Payroll Parameters".
     03  filler             pic x(40)    value spaces.
     03  filler             pic x(16)    value "RDMBS Parameters".
*>
 01  line-3e.
     03  filler             pic x(24)    value spaces.
     03  filler             pic x(16)    value "System Paramters".
     03  filler             pic x(56)    value spaces.
*>
 01  line-4.
     03 l4-part1.
         05  filler         pic x(24)    value  spaces.
         05  l4-part1-star  pic x(16)    value  all "*".
     03 l4-part2.
         05  filler         pic x(40)    value  spaces.
         05  l4-part2-star  pic x(16)    value  all "*".
*>
 01  line-5.
     03  filler             pic x(10)    value  spaces.
     03  l5-files.
         05 l5-name         pic x(17)    value  spaces.
         05 l5-data-1       pic x(43)    value  spaces.
         05 filler  redefines  l5-data-1.
            07  array-1     pic x        occurs  43.
         05 l5-data-2       pic x(50)    value  spaces.
         05 filler  redefines  l5-data-2.
            07  array-2     pic x        occurs  50.
*>
*> spaxx is used in space clearing for displays.
*>
 01  line-6.
     03  spaxx              pic x(51)    value  spaces.
     03  filler             pic x(30)    value  "End of System Parameter Report".
*>
 01  line-7.
     03  filler             pic x(51)    value  spaces.
     03  filler             pic x(30)    value  all "=".
*>
*> This is not used but acts as a list of files used within the system
*>   so any changes update, this block !!
*>       filler's with 'values space' can used for this purpose but
*>          could also be for SQL databases tables
*>
*>01  ws-file-names.
*>    03  file00             pic x(16)     value "system".           *> Used by all systems: Sales, Purchase, Stock, General
*>    03  filler             pic x(16)     value "glwork".   *>  DOES NOT APPEAR TO BE USED in general (maybe a temp file?)
*>    03  file02             pic x(16)     value "archive".          *> General
*>    03  file03             pic x(16)     value "final".            *> General temp file in gl120 P&L print
*>    03  filler             pic x(16)     value space.              *>  UNUSED
*>    03  file05             pic x(16)     value "ledger".           *> General
*>    03  file06             pic x(16)     value "posting".          *> General & Sales & Purchase
*>    03  file07             pic x(16)     value "batch".            *> General & Sales & Purchase
*>    03  file08             pic x(16)     value "postings2irs".     *>   Sales & Purchase
*>    03  file09             pic x(16)     value "tmp-stock".        *>  Stock temp file
*>    03  file10             pic x(16)     value "staudit".          *>  Stock
*>    03  file11             pic x(16)     value "stockctl".         *>  Stock - RDB
*>    03  file12             pic x(16)     value "salesled".         *>   Sales & Stock (used in??)
*>    03  file13             pic x(16)     value "value".            *>   Sales & Purchase
*>    03  file14             pic x(16)     value "delivery".         *>   Sales & Purchase
*>    03  file15             pic x(16)     value "analysis".         *>   Stock & Purchase
*>    03  file16             pic x(16)     value "invoice ".         *>   Sales
*>    03  file17             pic x(16)     value "delinvno".         *>   Sales
*>    03  file18             pic x(16)     value "openitm2".         *>   Sales
*>    03  file19             pic x(16)     value "openitm3".         *>   Sales
*>    03  file20             pic x(16)     value "oisort".           *>   Sales
*>    03  file21             pic x(16)     value "work".             *>   Sales, Purchase & General ( temporary file only)
*>    03  file22             pic x(16)     value "purchled".         *>    Purchase & Stock (used in??)
*>    03  file23             pic x(16)     value "delfolio".         *>    Purchase
*>    03  file24             pic x(16)     value space.              *> General - dummy for gl080
*>    03  filler             pic x(16)     value space.              *>  UNUSED
*>    03  file26             pic x(16)     value "pinvoice".         *>    Purchase
*>    03  file27             pic x(16)     value "poisort".          *>    Purchase
*>    03  file28             pic x(16)     value "openitm4".         *>    Purchase
*>    03  file29             pic x(16)     value "openitm5".         *>    Purchase
*>    03  filler             pic x(16)     value space.              *>  UNUSED
*>    03  filler             pic x(16)     value space.              *>  UNUSED
*>    03  file32             pic x(16)     value "pay     ".         *>    Purchase
*>    03  file33             pic x(16)     value "cheque.dat".       *>    Purchase

*>
*>01  filler     redefines ws-file-names.
*>    03  ws-file            pic x(16)   occurs 34.
*>
 01  Error-Messages.
*> System Wide
     03  SY005    pic x(18) value "SY005 Invalid Date".
     03  SY006    pic x(62) value "SY006 Program Arguments limited to two and you have specified ".
     03  SY007    pic x(35) value "SY007 Program arguments incorrect: ".
     03  SY008    pic x(31) value "SY008 Note message & Hit return".
     03  SY009    pic x(53) value "SY009 Environment variables not yet set up : ABORTING".
     03  SY044    pic x(67) value "SY044 The system has detected an un-authorised change of user name.".
     03  SY045    pic X(40) value "SY045 Contact your Supplier or Sys Admin".
*> Module Specific
     03  SY101    pic x(24) value "SY101 Open I-O Err = ".
     03  SY102    pic x(46) value "SY102 Read Err 1 = ".
     03  SY103    pic x(38) value "SY103 Rewrite Err 1 = ".
     03  SY104    pic x(46) value "SY104 Fix and Press Enter".
     03  SY105    pic x(16) value "SY105 Lines > 28".
*>
 copy "wsnames.cob".   *> here deliberately and a dummy in linkage
*>
 linkage section.
*>==============
*>
 copy "wscall.cob".
 01  dummy-file-defs.    *>    Dummy for the sub-system main module to call
     03  filler      pic x(532) occurs 35.
     03  Filler         binary-short  value zero.
*>
 screen section.
*>=============
*>
*> All encryption sub-systems removed, ditto all high security code
*>
 01  banner        foreground-color 2.
     03  pic x(16) from prog-name                  line  1 col  1.
     03  value "S y s t e m   S e t - U p"         line  1 col 28.
     03  from line-1-date  pic x(10)               line  1 col 71.
     03  value "++++++++++"                        line  3 col  1.
     03  value "+Screen "                          line  4 col  1.
     03  screen-nos       pic 9                    line  4 col  9.
     03                   pic x value "+"          line  4 col 10.
     03  value "++++++++++"                        line  5 col  1.
*>
 01  user-data       foreground-color 2.
     03          value "Name"                      line  7 col  1.
     03          value "- {"                               col  9.
     03  from usera       pic x(32)                        col 12.
     03          value "}"                                 col 44.
     03          value "Address - ["               line  8 col  1.
     03  using address-1  pic x(24)                        col 12.
     03          value "]"                                 col 36.
     03          value "["                         line  9 col 11.
     03  using address-2  pic x(24)                        col 12.
     03          value "]"                                 col 36.
     03          value "["                         line 10 col 11.
     03  using address-3  pic x(24)                        col 12.
     03          value "]"                                 col 36.
     03          value "["                         line 11 col 11.
     03  using address-4  pic x(24)                        col 12.
     03          value "]"                                 col 36.
     03          value "Post Code ["               line 12 col  1.
     03  using Post-Code  pic x(12)                        col 12.
     03          value "]"                                 col 24.
     03          value "Country - ["               line 13 col  1.
     03  using Country    pic x(24)                        col 12.
     03          value "]"                                 col 36.
     03          value "Date Format   "            line 14 col  1.
     03          value "- ["                               col 15.
     03  using Date-Form  pic 9                            col 18.
     03          value "]"                                 col 19.
     03          value "  (1 = UK, 2 = USA, 3 = Intl)"     col 20.
     03          value "Period :  Start Date - ["  line 15 col  1.
     03  using p-start    pic x(10)                        col 25.
     03          value "]"                                 col 35.
     03          value "End   Date - ["            line 16 col 11.
     03  using p-end      pic x(10)                        col 25.
     03          value "]"                                 col 35.
     03          value "System Print Lines   -"    line 17 col  1.
     03          value "["                                 col 24.
     03  using Page-Lines pic 999                          col 25.
     03          value "]"                                 col 28.
     03          value "  (for Laser = 048)"               col 30.
     03          value "Vat Rates : (1)"           line 18 col  1.
     03          value "- ["                               col 22.
     03  using vat-rate-1 pic 99.99                        col 25.
     03          value "]"                                 col 30.
     03          value "Local Tax : (4)"                   col 40.
     03          value "- ["                               col 57.
     03  using vat-rate-4 pic 99.99                        col 60.
     03          value "]"                                 col 65.
     03          value "(2)"                       line 19 col 13.
     03          value "- ["                               col 22.
     03  using vat-rate-2 pic 99.99                        col 25.
     03          value "]"                                 col 30.
     03          value "Local Tax : (5)"                   col 40.
     03          value "- ["                               col 57.
     03  using vat-rate-5 pic 99.99                        col 60.
     03          value "]"                                 col 65.
     03          value "(3)"                       line 20 col 13.
     03          value "- ["                               col 22.
     03  using vat-rate-3 pic 99.99                        col 25.
     03          value "]"                                 col 30.
     03          value "Current Cycle"                     col 40.
     03          value "- ["                               col 58.
     03  using cyclea     pic 99                           col 61.
     03          value "]"                                 col 63.
     03          value "VAT Reg no - ["            line 21 col  1.
     03  using VAT-Reg-Number  pic x(11)                   col 15.
     03          value "]"                                 col 26.
     03          value " Printed ["                        col 27.
     03  using SL-VAT-Printed                              col 37.
     03          value "]"                                 col 38.
     03          value "Current Quarter"           line 21 col 40.
     03          value "- ["                               col 58.
     03  using current-quarter pic 99                      col 61.
     03          value "]"                                 col 63.
     03          value "Pass-Word"                 line 22 col  1.
     03          value "- ["                               col 20.
     03  using s-pass-word pic x(4)                        col 23.
     03          value "]"                                 col 27.
     03          value "Cycle Period"                      col 40.
     03          value "- ["                               col 58.
     03  using period     pic 99                           col 61.
     03          value "]"                                 col 63.
     03          value "Data File Handling"        line 23 col  1.
     03          value "- ["                               col 22.
     03  using File-System-Used pic 9                      col 25.
     03          value "]"                                 col 26.
     03          value "(Range 0/1)"                       col 28.
*>     03          value "(Range 0/5)"                       col 28.  *> NOT IN USE
     03          value "Dual file type Flag"               col 40.
     03          value "- ["                               col 61.
     03  using File-Duplicates-In-Use pic 9                col 64.
     03          value "]"                                 col 65.
     03          value "(Range 0 / 1)"                     col 67.
*>
 01  verify-screen   foreground-color 2.
     03         value "**************************" line 11 col 54.
     03          value "*"                         line 12 col 54.
     03          value "*"                                 col 79.
     03          value "*"                         line 13 col 54.
     03  verify-message  pic x(24)                         col 55.
     03          value "*"                                 col 79.
     03          value "*"                         line 14 col 54.
     03          value "*"                                 col 79.
     03          value "* OK to file (Y/N) - ["    line 15 col 54.
     03          value "] *"                               col 77.
     03          value "*"                         line 16 col 54.
     03          value "                        "          col 55.
     03          value "*"                                 col 79.
     03         value "**************************" line 17 col 54.
*>
 01  ops-data       foreground-color 2.
     03          value "Single/Multi-User - ["     line 17 col 02.
     03  using host      pic 9                     line 17 col 23.
     03          value "]  (0=Single, 1=Multi)"    line 17 col 24.
     03          value "Operating System "         line 19 col 02.
     03          value "- ["                       line 19 col 20.
     03  using op-system  pic 9                    line 19 col 23.
     03          value "]"                         line 19 col 24.
     03          value "(1=Dos, 2=Windows," &
          " 3=Mac, 4=OS/2, 5=Unix, 6=Linux)"       line 19 col 27.
     03          value "Data capture System "      line 21 col 02.
     03          value "- ["                               col 22.
     03  using Data-Capture-Used  pic 9                    col 25.
     03          value "] 0=Std, 1=GUI, 2=Widget"          col 26.
*>
 01  ops-data-2     foreground-color 2.
     03        value "Cups Print Spooler name 1 - [" line 21 col 02.
     03  using Print-Spool-Name  pic x(48)                 col 31.
     03        value "]"                                   col 79.
     03        value "Cups Print Spooler name 2 - [" line 22 col 02.
     03  using Print-Spool-Name2 pic x(48)                 col 31.
     03        value "]"                                   col 79.
     03        value "Cups Print Spooler name 3 - [" line 23 col 02.
     03  using Print-Spool-Name3 pic x(48)                 col 31.
     03        value "]"                                   col 79.
*>
 01  ops-data-3     foreground-color 2.
     03          value "RDB Schema name - ["       line 7 col 02.
     03  using RDBMS-DB-Name   pic x(12)                  col 21.
     03          value "] (ACASDB)"                       col 33.
     03          value "DB Username - ["           line 8 col 02.
     03  using RDBMS-User      pic x(12)                  col 17.
     03          value "]"                                col 29.
     03          value "DB User Password - ["      line 9 col 02.
     03  using RDBMS-Passwd    pic x(12)                  col 22.
     03          value "] "                               col 34.
*>
 01  gl-data   foreground-color 2.
     03        value "Profit Centres/Branches - [" line  7 col  1.
     03  using p-c       pic x                     line  7 col 28.
     03          value "]"                         line  7 col 29.
     03          value "  (P, B, space)"           line  7 col 30.
     03          value "P.C./Branches Level"       line  8 col  1.
     03          value "- ["                       line  8 col 25.
     03  using p-c-level pic x                     line  8 col 28.
     03          value "]"                         line  8 col 29.
     03          value "  (R=Revenue, Space)"      line  8 col 30.
     03        value "P.C./Branches Grouped ? - [" line  9 col  1.
     03  using p-c-grouped  pic x                  line  9 col 28.
     03          value "]"                         line  9 col 29.
     03          value "  (Y=Grouped or Space)"    line  9 col 30.
     03          value "Comparatives ?"            line 10 col  1.
     03          value "- ["                       line 10 col 25.
     03  using comps     pic x                     line 10 col 28.
     03          value "]"                         line 10 col 29.
     03          value "  (Y=Yes or Space)"        line 10 col 30.
     03          value "Ledger Name Index ?"       line 11 col  1.
     03          value "- ["                       line 11 col 25.
     03  using ledger-2nd-index pic x              line 11 col 28.
     03          value "]"                         line 11 col 29.
     03          value "  (Y=Yes or Space)"        line 11 col 30.
     03          value "Minimum Validation ?"      line 12 col  1.
     03          value "- ["                       line 12 col 25.
     03  using m-v       pic x                     line 12 col 28.
     03          value "]"                         line 12 col 29.
     03          value "  (Y=Yes or Space)"        line 12 col 30.
     03          value "Archiving ?"               line 13 col  1.
     03          value "- ["                       line 13 col 25.
     03  using arch      pic x                     line 13 col 28.
     03          value "]"                         line 13 col 29.
     03          value "  (Y=Yes or Space)"        line 13 col 30.
     03          value "Sales Range"               line 14 col  1.
     03          value "- ["                       line 14 col 25.
     03  using sales-range pic 9                   line 14 col 28.
     03          value "]"                         line 14 col 29.
     03          value "Purchase Range"            line 15 col  1.
     03          value "- ["                       line 15 col 25.
     03  using purchase-range pic 9                line 15 col 28.
     03          value "]"                         line 15 col 29.
     03        value "Automatic VAT Posting ? - [" line 16 col  1.
     03  using vat       pic x                             col 28.
     03          value "]"                                 col 29.
     03          value "  (Y=Yes or Space)"                col 30.
     03          value "Next Batch Number"         line 17 col  1.
     03          value "- ["                       line 17 col 21.
     03  using num-6 pic 9(5)                      line 17 col 24.
     03          value "]"                         line 17 col 29.
     03        value "Use IRS instead of GL ? - [" line 18 col  1.
     03  using irs-instead                                 col 28.
     03          value "]"                                 col 29.
     03          value "  (Y=Yes or N=No)"                 col 30.
*>
 01  pl-data   foreground-color 2.
     03          value "Delimiter"                 line 14 col  1.
     03          value "- ["                       line 14 col 15.
     03  using PL-Delim pic x                      line 14 col 18.
     03          value "]"                         line 14 col 19.
     03          value "Purch/Stock Link  ["       line 15 col  1.
     03  using PL-Stock-Link pic x                         col 20.
     03          value "]"                                 col 21.
     03          value "Next Batch Number ["       line 17 col  1.
     03  using BL-Next-Batch  pic 9(5)             line 17 col 20.
     03          value "]"                         line 17 col 25.
     03         value "Pay Account       ["        line 18 col  1.
     03  using BL-Pay-Ac      pic 9(6)                     col 20.
     03          value "]"                                 col 26.
     03         value "Ledger Account    ["        line 19 col  1.
     03  using BL-Purch-Ac    pic 9(6)                     col 20.
     03          value "]"                                 col 26.
     03         value "Creditor Account  ["        line 20 col  1.
     03  using P-Creditors      pic 9(6)                   col 20.
     03          value "]"                                 col 26.
*>
 01  sl-data   foreground-color 2.
     03          value "Late Letters"              line  7 col  1.
     03          value "- ["                       line  7 col 15.
     03  using sl-dunning pic 9                    line  7 col 18.
     03          value "]"                         line  7 col 19.
     03          value "  (1 = Yes or 0)"          line  7 col 20.
     03          value "Late Charges"              line  8 col  1.
     03          value "- ["                       line  8 col 15.
     03  using sl-charges pic 9                    line  8 col 18.
     03          value "]"                         line  8 col 19.
     03          value "  (1 = Yes or 0)"          line  8 col 20.
     03          value "Credit Period - ["         line  9 col  1.
     03  using sl-credit pic 99                    line  9 col 18.
     03          value "]"                         line  9 col 20.
     03          value "Discount"                  line 10 col 1.
     03          value "- ["                       line 10 col 15.
     03  using sl-disc pic 99.99                   line 10 col 18.
     03          value "]"                         line 10 col 23.
     03          value "Min Late Bal"              line 11 col  1.
     03          value "- ["                       line 11 col 15.
     03  using sl-min pic 9(4)                     line 11 col 18.
     03          value "]"                         line 11 col 22.
     03          value "Max Late Charge ["         line 12 col  1.
     03  using sl-max pic 9(4)                     line 12 col 18.
     03          value "]"                         line 12 col 22.
     03          value "Credit Limit"              line 13 col  1.
     03          value "- ["                       line 13 col 15.
     03  using sl-limit pic 9(7)                   line 13 col 18.
     03          value "]"                         line 13 col 25.
     03          value "Delimiter"                 line 14 col  1.
     03          value "- ["                       line 14 col 15.
     03  using sl-delim pic x                      line 14 col 18.
     03          value "]"                         line 14 col 19.
     03          value "  (Address lines)"         line 14 col 20.
     03          value "Own Inv. Nos"              line 15 col  1.
     03          value "- ["                       line 15 col 15.
     03  using sl-own-nos pic x                    line 15 col 18.
     03          value "]"                         line 15 col 19.
     03          value "Late Charge % - ["         line 16 col  1.
     03  using sl-late-per pic 9.99                line 16 col 18.
     03          value "]"                         line 16 col 22.
     03          value "Next Batch Number ["       line 17 col  1.
     03  using first-sl-batch pic 9(5)             line 17 col 20.
     03          value "]"                         line 17 col 25.
     03          value "Sales/Stock Link  ["       line 18 col  1.
     03  using SL-Stock-Link pic x                         col 20.
     03          value "]"                                 col 21.
     03          value "Pay Account    -  ["       line 19 col  1.
     03  using SL-Pay-Ac      pic 9(6)                     col 20.
     03          value "]"                                 col 26.
     03          value "Ledger Account -  ["       line 20 col  1.
     03  using SL-Sales-Ac    pic 9(6)                     col 20.
     03          value "]"                                 col 26.
     03          value "Debtors Account - ["       line 21 col  1.
     03  using S-Debtors      pic 9(6)                     col 20.
     03          value "]"                                 col 26.
*>
 01  SL-Data-2   foreground-color 2.
     03  value "Select what report types, company details will be printed to"
                                                   line  7 col 01.
     03  value "    Invoices   - ["                line  8 col 01.
     03  using SL-Comp-Head-Inv   pic x                    col 19.
     03  value "]"                                         col 20.
     03  value "    Statements - ["                line  9 col 01.
     03  using SL-Comp-Head-Stat  pic x                    col 19.
     03  value "]"                                         col 20.
     03  value "  Late Letters - ["                line 10 col 01.
     03  using SL-Comp-Head-Lets  pic x                    col 19.
     03  value "]"                                         col 20.
     03  value "Delivery Notes - ["                line 11 col 01.
     03  using SL-Comp-Head-Pick  pic x                    col 19.
     03  value "]"                                         col 20.
*>
 01  stock-data   foreground-color 2.
     03          value "Debugging     "            line  7 col  1.
     03          value "- ["                               col 15.
     03  using stk-debug      pic 9                        col 18.
     03          value "]"                                 col 19.
     03          value "  (1 = Yes or 0)"                  col 20.
     03          value "Bomp/Wip used "            line  9 col  1.
     03          value "- ["                               col 15.
     03  using stk-Manu-Used  pic 9                        col 18.
     03          value "]"                                 col 19.
     03          value "  (1 = Yes or 0)"                  col 20.
     03          value "Order Entry   "            line 10 col  1.
     03          value "- ["                               col 15.
     03  using stk-OE-Used    pic 9                        col 18.
     03          value "]"                                 col 19.
     03          value "  (1 = Yes or 0)"                  col 20.
     03          value "Audit Used    "            line 11 col  1.
     03          value "- ["                               col 15.
     03  using stk-Audit-Used pic 9                        col 18.
     03          value "]"                                 col 19.
     03          value "  (1 = Yes or 0)"                  col 20.
     03          value "Audit Movement"            line 12 col  1.
     03          value "- ["                               col 15.
     03  using stk-Mov-Audit  pic 9                        col 18.
     03          value "]"                                 col 19.
     03          value "  (1 = Yes or 0)"                  col 20.
     03          value "Current Period"            line 13 col  1.
     03          value "- ["                               col 15.
     03  using stk-Period-Cur pic x                        col 18.
     03          value "]"                                 col 19.
     03   value "  (W=Weekly, M=Monthly, Q=Quarterly)"     col 20.
     03          value "To Date Period"            line 14 col  1.
     03          value "- ["                               col 15.
     03  using stk-Period-Dat pic x                        col 18.
     03          value "]"                                 col 19.
     03   value "  (M=Monthly, Q=Quarterly, Y=Yearly)"     col 20.
     03          value "Ave Valuation"             line 15 col  1.
     03          value "- ["                               col 15.
     03  using stk-Averaging  pic 9                        col 18.
     03          value "]"                                 col 19.
     03          value "  (1 = Yes or 0)"                  col 20.
*>     03          value "Lines per Page"            line 16 col  1.
*>     03          value "- ["                               col 15.
*>     03  using Stk-Page-Lines pic 999                      col 18.
*>     03          value "]"                                 col 21.
*>     03          value "  (for Laser = 048)"               col 22.
     03          value "Next 2, See Manual First"  line 17 col  1.
     03          value "Activity Rep "             line 18 col  1.
     03          value "- ["                               col 15.
     03  using Stk-Activity-Rep-Run pic 9                  col 18.
     03          value "]"                                 col 19.
     03          value "  (0 = No or 1) leave as 0"        col 20.
     03          value "Audit Number "             line 19 col  1.
     03          value "- ["                               col 15.
     03  using Stk-Audit-No pic 999                        col 18.
     03          value "]"                                 col 21.
     03   value "  (if 1st time = 0, else leave as is)"    col 23.
*>
 procedure division using ws-calling-data dummy-file-defs.
*>=======================================================
*>
 init01   section.
*>*****
*>     Only use file-0 third entry - system.dat
*> We need to recompute paths etc as we use files from
*>     systems other than the one that called SYS002
*>
*> Which is why a dummy file-def is in linkage and a full one is
*>    in WS
*>
     if       Used-Once = zero                 *> Make sure we only do this once per run / caller program
              move 1 to Used-Once
              perform  zz020-Get-Program-Args. *> THIS IS NOT NEEDED & WILL CAUSE PROBLEMS or will it ???
*>
*> Force Esc, PgUp, PgDown, PrtSC to be detected
     set      ENVIRONMENT "COB_SCREEN_EXCEPTIONS" to "Y".
     set      ENVIRONMENT "COB_SCREEN_ESC" to "Y".
*>
     display  prog-name at 0101 with foreground-color 2 erase eos.
     move     prog-name to l1-name.
     display  "System Parameters" at 0130 with foreground-color 2.
     open     i-o  system-file  *> [not avail 4 oc v1.1)->  with lock.
     move     SY101 to fs-action.
     perform  disk-error-display.
*>
*> If not present initialize & create records 4, 3, 2 & 1 then reread 1 (for rewrite)
*>
     move     4 to rrn.
     read     system-file record into system-record-4.
     if       fs-reply not = zero
              initialize system-record-4
              write system-record from system-record-4.
*>
     move     3 to rrn.
     read     system-file into final-record.
     if       fs-reply not = zero
              initialize final-record
              write system-record from final-record.
     move     2 to rrn.
     read     system-file record into default-record.
     if       fs-reply not = zero
              initialize default-record
              write system-record from default-record.
     move     1  to  rrn.
     read     system-file  record.
     if       fs-reply not = zero
              move zero to fs-reply
*>
*>   Set up new system file using current layout version
*>
              initialize system-record
              move ws-Sys-Record-Ver-Prime      to System-Record-Version-Prime
              move ws-Sys-Record-Ver-Secondary  to System-Record-Version-Secondary
              move 1 to date-form                                                *> default UK format
              move 1 to rrn
              write system-record
              read  system-file        *> Don't want an error on a rewrite
     end-if
*>
     move     SY102 to fs-action
     perform  disk-error-display.
     move     run-date  to  u-bin.
     perform  zz060-Convert-Date.
     move     u-date  to  to-day.
     move     ws-date to  ws-test-date
                          line-1-date.            *>  ws-date and now ws-test-date for display and printing
*>
     perform  User-Params.
     if       Cob-Crt-Status = Cob-Scr-Esc
              close system-file
              go to Main-Exit.
     perform  System-Params.
*>
     if       G-L
              perform  Gl-Params.
*>
     if       S-L
              perform  Sl-Params.
*>
     if       B-L
              perform  Pl-Params.
*>
     if       Stock
              perform  Stock-Params.
*>
*>     if       Order-Entry
*>              perform  OE-Params.
*>     if       EPOS-Entry
*>              perform  EPOS-Params.
*>     if       Payroll
*>              perform Payroll-Params.
*>     if       Project-Z
*>              perform Project-Z-Params.
*>
     perform  print-params.
*>
*>-----------------------------------------------------------------------
*> WARNING: SL data and PL data reduced print, eg Not all data is printed - Consider make full?
*>-----------------------------------------------------------------------
*>
*>  Bypass security check for Open Source version
*>
     go       to Menu-Option.
*>
*> now verify user name not changed.
*>
*>     move     usera  to  pass-name.
*>     move     "N"  to  encode.
*>     call     "maps01"  using  maps01-ws.   *> OS modified version, reduced encrypted from 1024 bytes/char to 4 simple.
*>     if       pass-name = user-code
*>              go to  menu-option.
*>
*> if here user name does not match encoded name. Possible
*> un-authorised usage.
*>
*>     display  " " at 0101 with erase eos.
*>     display  SY044 at 0501 with foreground-color 4.
*>     display  SY045 at 0601 with foreground-color 4.
*>     move     1 to error-code.
*>     call     "maps99" using error-code ws-calling-data.
*>     go       to main-exit.
*>
 Menu-Option.
*>----------
*>
     display  " " at 0101 with erase eos.
     move     1 to rrn.
     rewrite  system-record.
     move     SY103 to fs-action.
     perform  disk-error-display.
*>
     close    system-file.
     move     zero to ws-term-code.
     go       to main-exit.
*>
 Disk-Error-Display.
     if       fs-reply not = zero
              display fs-action at 0310
              display fs-reply at 0330
              display " " at 0410
              perform disk-error.
*>
 Disk-Error.
     display  SY104 at 2401.
     accept   fs-reply at 2420.
*>
 Main-Exit.
     exit     program.
*>
 User-Params      section.
*>=======================
*>
*>**************************************
*>  User Parameters Amendment Routine  *
*>**************************************
*>
 Main-User.
*>********
*>
     move     1 to screen-nos.
     display  " " at 0101 with erase eos.
     display  banner.
     display  "User Data" at 0436 with foreground-color 2.
*>
     if       start-date not = zero
              move  start-date  to  u-bin
              perform zz060-Convert-Date
              move  ws-date  to  p-start
     else
              move spaces to p-start
     end-if
     if       end-date not = zero
              move  end-date  to  u-bin
              perform zz060-Convert-Date
              move  ws-date  to  p-end
     else
              move spaces to p-end
     end-if
     move     spaces  to  pass-word of maps01-ws s-pass-word.
     display  user-data at 0101 with foreground-color 2.
*>
 User-Data-Accept.
     accept   user-data with update.
     if       Cob-Crt-Status = Cob-Scr-Esc
              go to Main-Exit.
*>
     if       Date-Form = 1
              display "    Using UK format dd/mm/ccyy" at 1420 with erase eol foreground-color 3
     else
      if      Date-Form = 2
              display "    Using USA format mm/dd/ccyy" at 1420 with erase eol foreground-color 3
      else
       if     Date-Form = 3
              display "    Using Intl format ccyy/mm/dd" at 1420 with erase eol foreground-color 3
       else
              display "    Incorectly Set. You MUST set this"
                                        at 1420 with erase eol foreground-color 4 highlight
              move 1 to Date-Form.
*>
     if       p-start not = spaces
              move  zero  to  u-bin
              move  p-start  to  ws-test-date
              perform zz050-Validate-Date
*>              call "maps04" using maps03-ws
              move  u-date  to  p-start
     end-if
     if       u-bin = zero
              display SY005 at 1540 with foreground-color 3 blink
              go to user-data-accept
     else     display " " at 1540 with erase eol
              move  u-bin   to  start-date
     end-if
     if       p-end not = spaces
              move  zero  to  u-bin
              move  p-end  to  ws-test-date
              perform zz050-Validate-Date
*>              call "maps04" using maps03-ws
              move  u-date  to  p-end
     end-if
     if       u-bin = zero
              display SY005 at 1640 with foreground-color 3 blink
              go to user-data-accept
     else     display " " at 1640 with erase eol
              move  u-bin   to  end-date
     end-if
     move     s-pass-word to pass-word in maps01-ws.
     if       pass-word of maps01-ws not = spaces
              move  "P"  to  encode
              call  "maps01"  using  maps01-ws
              move  pass-word of maps01-ws  to
                    pass-word of system-record
     end-if
     if       period = 13
              display "Weekly    " at 2270 with foreground-color 3
     else
      if      period = 6
              display "Fortnightly" at 2270 with foreground-color 3
      else
              move  3  to  period
              display "Monthly   " at 2270 with foreground-color 3
      end-if
     end-if
*>
     if       Page-Lines not > 28
              move 48 to Page-Lines
              display SY105 at 1750 with foreground-color 3 blink
              go to user-data-accept
     else     display " " at 1750 with erase eol.
*>
     if       not FS-Valid-Options
              move zero to File-System-Used
              display "Range 0 thru 1 only   "  at 2410 with foreground-color 3 blink
*>              display "Range 0 thru 5 only   "  at 2410 with foreground-color 3 blink
     else
      if      FS-Cobol-Files-Used
              display "Cobol data files used "  at 2410 with foreground-color 3
      else
       if     FS-RDBMS-Used
              display "Rdbms is used  "  at 2410 with foreground-color 3.
*>
*>       if     FS-Oracle-Used
*>              display "Oracle Rdbms used  "  at 2410 with foreground-color 3
*>       else
*>        if    FS-MySql-Used
*>              display "MySQL Rdbms used   "  at 2410 with foreground-color 3
*>        else
*>         if   FS-Postgres-Used
*>              display "Postgres Rdbms used"  at 2410 with foreground-color 3
*>         else
*>          if  FS-DB2-Used
*>              display "IBM DB2 Rdbms used "  at 2410 with foreground-color 3
*>          else
*>           if FS-MS-SQL-Used
*>              display "MS SQL Server used "  at 2410 with foreground-color 3.
*>
     if       File-Duplicates-In-Use not = zero and not = 1
              move zero to File-Duplicates-In-Use
              display "Range 0 thru 1 only   "  at 2450 with foreground-color 3 blink
     else
      if      FS-Duplicate-Processing
              display "Duplicate file processing used"      at 2441 with foreground-color 3
      else
              display "Duplicate file processing NOT used"  at 2441 with foreground-color 3.
*>
     move     function upper-case (SL-VAT-Printed) to SL-VAT-Printed.
     if       SL-VAT-Printed not = "Y" and not = "N"
              move "N" to SL-VAT-Printed
              display SL-VAT-Printed at 2137 with foreground-color 3 blink.
*>
     move     "   User Data Complete"  to verify-message.
*>
     display  verify-screen at 0101 with foreground-color 2.
*>
     move     "Y"  to  ws-reply.
     display  ws-reply at 1576 with foreground-color 6.
     accept   ws-reply at 1576 with foreground-color 6 update.
*>
     if       ws-reply = "N" or "n"
              go to  main-user.
*>
 Main-Exit.
     exit     section.
*>
 system-params           section.
*>==============================
*>
*>*****************************************
*>  System Parameters Amendment Routine   *
*>*****************************************
*>
 ops-main.
*>*******
*>
     move     2  to  screen-nos.
     display  " " at 0101 with erase eos.
     display  banner.
     display  "OPS  Data 1" at 0436 with foreground-color 2.
     display  ops-data at 0101 with foreground-color 2.
     accept   ops-data with update.
*>
     if       host not = 0 and not = 1
              move 1 to  host
              display "Multi-user system assumed" at 1823 with foreground-color 3 blink
     else
      if      host = zero
              display "Single-user system    " at 1823 with foreground-color 3 blink
      else
              display "Multi-user system     " at 1823 with foreground-color 3 blink.
*>
*> Clear long comment before overwriting
*>
     display  spaxx at 2000.
     if       host = zero  and (op-system  < 1 or > 6)
              move 1 to op-system
              display "MSDOS assumed" at 2023 with foreground-color 3 blink
      else
       if     host = 1
          and (op-system  < 2 or > 6)
              move 6 to op-system
              display "Linux assumed" at 2023 with foreground-color 3 blink
      else    if op-system = 1
              display "DOS"     at 2023 with foreground-color 3 blink
      else    if op-system = 2
              display "Windows" at 2023 with foreground-color 3 blink
      else    if op-system = 3
              display "Mac OSX" at 2023 with foreground-color 3 blink
      else    if op-system = 4
              display "OS/2"    at 2023 with foreground-color 3 blink
      else    if op-system = 5
              display "Unix"    at 2023 with foreground-color 3 blink
      else    if op-system = 6
              display "Linux"   at 2023 with foreground-color 3 blink.
*>
     if       op-system = 3 or = 5 or = 6
              if   Print-Spool-Name2 = spaces
                   move Print-Spool-Name to Print-Spool-Name2
              end-if
              if   Print-Spool-Name3 = spaces
                   move Print-Spool-Name to Print-Spool-Name3
              end-if
              display ops-data-2
              accept  ops-data-2 with update
              if Print-Spool-Name (1:1) = space
                 display " Print Spool Name must be defined" at 2402 with highlight foreground-color 3
              else
                 move Print-Spool-Name to PSN
              end-if
     end-if
*>
     if       DC-Cobol-Standard
              display "Cobol Standard Display  " at 2054 with foreground-color 3
     else
      if      DC-GUI
              display "Gui Display             " at 2054 with foreground-color 3
      else
       if     DC-Widget
              display "Widget Display          " at 2054 with foreground-color 3
       else
              display " Invalid - Std selected " at 2054 with foreground-color 3 highlight
              move zero to Data-Capture-Used.
*>
     if       Maps-Ser-xx = "mp" and Maps-Ser-nn = 9999
              display "Using (Free) Open Source Version of ACAS" at 1501 with highlight foreground-color 3
     else
              display "Using Commercial Version of ACAS"         at 1501 with highlight foreground-color 3.
*>
     move     "    OPS Data 1 Complete "  to  verify-message.
     display  verify-screen at 0101 with foreground-color 2.
*>
     move     "Y"  to  ws-reply.
     display  ws-reply at 1576 with foreground-color 6.
     accept   ws-reply at 1576 with foreground-color 6 update.
     if       ws-reply = "N" or = "n"
              go to  ops-main.
*>
     if       File-System-Used = zero
              go to main-exit.
*>
 ops-main-2.
*>
*> Requested RDB processing so get more info
*>
     move     3  to  screen-nos.
     display  " " at 0101 with erase eos.
     display  banner.
     display  "OPS  Data 2" at 0436 with foreground-color 2.
     display  ops-data-3 at 0101 with foreground-color 2.
     accept   ops-data-3 with update.
     if       RDBMS-DB-Name not = spaces
              display " DB name, set as requested" at 0746 with foreground-color 3.
     if       RDBMS-User not = spaces
              display " DB User, set as requested" at 0846 with foreground-color 3.
     if       RDBMS-Passwd not = spaces
              display " DB User pwd, set as requested" at 0946 with foreground-color 3
              display "************"                   at 0922.
*>
     move     "    OPS Data 2 Complete "  to  verify-message.
     display  verify-screen at 0101 with foreground-color 2.
*>
     move     "Y"  to  ws-reply.
     display  ws-reply at 1576 with foreground-color 6.
     accept   ws-reply at 1576 with foreground-color 6 update.
     if       ws-reply = "N" or = "n"
              go to  ops-main-2.
*>
 main-exit.
     exit section.
*>
 gl-params               section.
*>==============================
*>
*>*************************************
*>  G/L Parameters Amendment Routine  *
*>*************************************
*>
     move     4 to  screen-nos.
     display  " " at 0101 with erase eos.
     display  banner at 0101 with foreground-color 2.
     display  "G-L  Data" at 0436 with foreground-color 2.
     move     next-batch to num-6.
     display  gl-data at 0101 with foreground-color 2.
     accept   gl-data with foreground-color 3 update.
     move     num-6 to next-batch.
*>
     move     function upper-case (p-c) to p-c.
     if       profit-centres
              display "Profit centres selected" at 0732 with foreground-color 2
     else
      if      branches
              display "Branches selected" at 0732 with foreground-color 2
      else
              move  space  to  p-c
              display "Not selected  " at 0732    with foreground-color 2
*>
     move     function upper-case (p-c-level) to p-c-level.
     if       p-c = space  and
              p-c-level not = space
              move  space  to  p-c-level
     end-if
     if       p-c not = space
              and  revenue-only
              display "Revenue A/cs only " at 0832 with foreground-color 2.
     if       p-c not = space
              and  not  revenue-only
              move space  to  p-c-level
              display "All A/cs          " at 0832 with foreground-color 2
     end-if
     move     function upper-case(p-c-grouped) to p-c-grouped.
     display  "1st digit of P.C./Branch " at 0932 with foreground-color 2.
     if       grouped
              display "is the group identifier" at 0957 with foreground-color 2
     else
              display "is not significant" at 0957 with foreground-color 2
              move  space  to  p-c-grouped
     end-if
     move     function upper-case (comps) to comps.
     if       comparatives
              display "Selected        " at 1032 with foreground-color 2
     else
              move  space  to  comps
              display "Not selected    " at 1032 with foreground-color 2
     end-if
     move     function upper-case (ledger-2nd-index) to ledger-2nd-index.
     if       index-2
              display "Selected        " at 1132 with foreground-color 2
     else
              move  space  to  ledger-2nd-index
              display "Not selected    " at 1132 with foreground-color 2
     end-if
     move     function upper-case (m-v) to m-v.
     if       minimum-validation
              display "Selected        " at 1232 with foreground-color 2
     else
              display "Not selected    " at 1232 with foreground-color 2
              move  space  to  m-v
     end-if
     move     function upper-case (arch) to arch.
     if       archiving
              display "Selected        " at 1332 with foreground-color 2
     else
              move  space  to  arch
              display "Not selected    " at 1332 with foreground-color 2
     end-if
     move     function upper-case (vat) to vat.
     if       auto-vat
              display "Selected        " at 1632 with foreground-color 2
     else
              move  space  to  vat
              display "Not selected    " at 1632 with foreground-color 2
     end-if
     move     function upper-case (irs-instead) to irs-instead.
     if       irs-used
              display "Selected        " at 1832 with foreground-color 2
     else
              display "Not selected    " at 1832 with foreground-color 2
     end-if
     move     "    G-L Data Complete  "  to  verify-message.
     display  verify-screen at 0101 with foreground-color 2.
*>
     move     "Y"  to  ws-reply.
     display  ws-reply at 1576 with foreground-color 2.
     accept   ws-reply at 1576 with foreground-color 6 update.
*>
     if       ws-reply = "N" or = "n"
              go to  gl-params.
*>
 main-exit.
     exit section.
*>
 sl-params               section.
*>==============================
*>
*>*************************************
*>  S/L Parameters Amendment Routine  *
*>*************************************
*>
     move     5 to  screen-nos.
     display  " " at 0101 with erase eos.
     display  banner.
     display  "S-L  Data 1" at 0436  with foreground-color 2.
     display  sl-data.
     accept   sl-data with foreground-color 2 update.
*>
     if       sl-dunning = 1
              display "Late letters selected    " at 0722 with foreground-color 2
     else
              move  zero  to  sl-dunning
              display "Late letters not selected" at 0722 with foreground-color 2.
*>
     if       sl-charges = 1
              display "Late charges selected    " at 0822 with foreground-color 2
     else
              move  zero  to  sl-charges
              display "Late charges not selected" at 0822 with foreground-color 2.
*>
     if       sl-delim = " "
              display "Delimiter <\> assumed" at 1422
                          with foreground-color 2
              move  "\"  to  sl-delim.
*>
     move     function upper-case (sl-own-nos) to sl-own-nos.
     if       SL-own-nos = "Y"
              display "Selected & Set" at 1528 with foreground-color 2
     else
              display "Unset         " at 1528 with foreground-color 2.
     move     function upper-case (SL-Stock-Link) to SL-Stock-Link.
     if       SL-Stock-Link = "Y" and Stock
              display "Selected & Set       " at 1828 with foreground-color 2
     else
              move "N" to SL-Stock-Link
              display "Unset and/or No Stock" at 1828 with foreground-color 3 blink.
     if       sl-pay-ac not = zero
              display "Selected & Set" at 1928 with foreground-color 2
     else
              display "Unset" at 1928 with erase eol foreground-color 3 blink.
     if       sl-sales-ac not = zero
              display "Selected & Set" at 2028 with erase eol foreground-color 2
     else
              display "Unset" at 2028 with erase eol foreground-color 3 blink.
     if       S-Debtors not = zero
              display "Selected & Set" at 2128 with erase eol foreground-color 2
     else
              display "Unset" at 2128 with erase eol foreground-color 3 blink.
*>
     move     "    S-L Data Complete  "  to  verify-message.
     display  verify-screen at 0101 with foreground-color 2.
     move     "Y"  to  ws-reply.
     display  ws-reply at 1576 with foreground-color 6.
     accept   ws-reply at 1576 with foreground-color 6 update.
     if       ws-reply = "N" or = "n"
              go to  sl-params.
*>
 SL-Params-2.
     move     6 to  screen-nos.
     display  " " at 0101 with erase eos.
     display  banner.
     display  "S-L  Data 2" at 0436  with foreground-color 2.
     display  sl-data-2 with erase eos.
     accept   sl-data-2 with foreground-color 2 update.
*>
     move     function upper-case (SL-Comp-Head-Inv)  to SL-Comp-Head-Inv.
     move     function upper-case (SL-Comp-Head-Stat) to SL-Comp-Head-Stat.
     move     function upper-case (SL-Comp-Head-Lets) to SL-Comp-Head-Lets.
     move     function upper-case (SL-Comp-Head-Pick) to SL-Comp-Head-Pick.
*>
     if       SL-Comp-Head-Inv not = "Y" and not = "N"
              display "Error, set to N" at 0822 with foreground-color 4 highlight beep
              move "N" to SL-Comp-Head-Inv.
     if       SL-Comp-Head-Stat not = "Y" and not = "N"
              display "Error, set to N" at 0922 with foreground-color 4 highlight beep
              move "N" to SL-Comp-Head-Stat.
     if       SL-Comp-Head-Lets not = "Y" and not = "N"
              display "Error, set to N" at 1022 with foreground-color 4 highlight beep
              move "N" to SL-Comp-Head-Lets.
     if       SL-Comp-Head-Pick not = "Y" and not = "N"
              display "Error, set to N" at 1122 with foreground-color 4 highlight beep
              move "N" to SL-Comp-Head-Pick.
*>
     move     "  S-L Data 2 Complete  "  to  verify-message.
     display  verify-screen at 0101 with foreground-color 2.
     move     "Y"  to  ws-reply.
     display  ws-reply at 1576 with foreground-color 6.
     accept   ws-reply at 1576 with foreground-color 6 update.
     if       ws-reply = "N" or = "n"
              go to  sl-params-2.
*>
 main-exit.
     exit section.
*>
 pl-params               section.
*>==============================
*>
*>*************************************
*>  P/L Parameters Amendment Routine  *
*>*************************************
*>
     move     7 to  screen-nos.
     display  " " at 0101 with erase eos.
     display  banner.
     display  "P-L  Data" AT 0436 with foreground-color 2.
     display  pl-data.
     accept   pl-data with foreground-color 2 update.
*>
     if       pl-delim = space
              display "Delimiter <\> assumed" at 1422 with foreground-color 2
              move  "\"  to  pl-delim
     end-if
*>
     move     function upper-case (PL-Stock-Link) to PL-Stock-Link.
     if       PL-Stock-Link = "Y" and Stock
              display "Selected & Set" at 1528 with erase eol foreground-color 2
     else
              move "N" to PL-Stock-Link
              display "Unset and/or No Stock" at 1528 with erase eol foreground-color 3 blink.
*>
     if       BL-Pay-ac not = zero
              display "Selected & Set" at 1828 with erase eol foreground-color 2
     else
              display "Unset" at 1828 with erase eol foreground-color 3 blink.
     if       BL-Purch-ac not = zero
              display "Selected & Set" at 1928 with erase eol foreground-color 2
     else
              display "Unset" at 1928 with erase eol foreground-color 3 blink.
     if       P-Creditors not = zero
              display "Selected & Set" at 2028 with erase eol foreground-color 2
     else
              display "Unset" at 2028 with erase eol foreground-color 3 blink.
*>
     move     "    P-L Data Complete"  to  verify-message.
     display  verify-screen at 0101 with foreground-color 2.
*>
     move     "Y"  to  ws-reply.
     display  ws-reply at 1576 with foreground-color 6.
     accept   ws-reply at 1576 with foreground-color 6 update.
*>
     if       ws-reply = "N" or = "n"
              go to  pl-params.
*>
 main-exit.
     exit section.
*>
 Stock-Params            section.
*>==============================
*>
*>***************************************
*>  Stock Parameters Amendment Routine  *
*>***************************************
*>
     move     8 to  screen-nos.
     display  " " at 0101 with erase eos.
     display  banner.
     display  "Stock Data" AT 0436 with foreground-color 2.
     display  Stock-data.
     accept   Stock-data with foreground-color 2 update.
*>
     if       Stk-Debug = 1
              display "    Set" at 0720 with erase eol   foreground-color 3
     else
              move zero to Stk-Debug
              display "    UnSet" at 0720 with erase eol foreground-color 3
     end-if
     if       Stk-Manu-Used = 1
              display "    Set" at 0920 with erase eol foreground-color 3
     else
              move zero to Stk-Manu-Used
              display "    UnSet" at 0920 with erase eol foreground-color 3
     end-if
     if       Stk-OE-Used = 1
              display "    Set" at 1020 with erase eol foreground-color 3
     else
              move zero to Stk-OE-Used
              display "    UnSet" at 1020 with erase eol foreground-color 3
     end-if
     if       Stk-Audit-Used = 1
              display "    Set" at 1120 with erase eol foreground-color 3
     else
              move zero to Stk-Audit-Used
              display "    UnSet" at 1120 with erase eol foreground-color 3
     end-if
     if       Stk-Mov-Audit = 1
              display "    Set" at 1220 with erase eol foreground-color 3
     else
              move zero to Stk-Mov-Audit
              display "    UnSet" at 1220 with erase eol foreground-color 3
     end-if
     move     function upper-case (Stk-Period-Cur) to Stk-Period-Cur.
     if       Stk-Period-Cur = "M"
              display "    Set to Monthly" at 1320 with erase eol foreground-color 3
     else
      if      Stk-Period-Cur = "Q"
              display "    Set to Quarterly" at 1320 with erase eol foreground-color 3
      else
       if     Stk-Period-Cur = "W"
              display "    Set to Weekly" at 1320 with erase eol foreground-color 3
       else
              move "M" to Stk-Period-Cur
              display "    Unset: Has been set to Monthly" at 1320
                   with erase eol foreground-color 3 highlight.
*>
     move     function upper-case (Stk-Period-Dat) to Stk-Period-Dat.
     if       Stk-Period-Dat = "M"
              display "    Set to Monthly" at 1420 with erase eol foreground-color 3
     else
      if      Stk-Period-Dat = "Q"
              display "    Set to Quarterly" at 1420 with erase eol foreground-color 3
      else
       if     Stk-Period-Dat = "Y"
              display "    Set to Yearly" at 1420 with erase eol foreground-color 3
       else
              move "Y" to Stk-Period-Dat
              display "    Unset: Has been set to Yearly" at 1420
                                      with erase eol foreground-color 3 highlight.
*>
     if       Stk-Averaging = 1
              display "    Set" at 1520 with erase eol foreground-color 3
     else
              move zero to Stk-Averaging
              display "    UnSet" at 1520 with erase eol foreground-color 3
     end-if
*>
*> Stk-Page-Lines discontinued in favor of system global Page-Lines but leave in for the moment
*>
*>     if       Stk-Page-Lines = zero          *> Should both be the same anyway unless someone know differently!!
*>              move Page-Lines to Stk-Page-Lines.
*>     if       Stk-Page-Lines > 29
*>              display "  Set" at 1622 with erase eol foreground-color 3
*>     else
*>              move 48 to Stk-Page-Lines
*>              display "  Set to 48" at 1622 with erase eol foreground-color 3
*>     end-if
     if       Stk-Activity-Rep-Run = 1
              display "    Set" at 1820 with erase eol foreground-color 3
     else
              move zero to Stk-Activity-Rep-Run
              display "    UnSet" at 1820 with erase eol foreground-color 3
     end-if
     if       Stk-Audit-No  > 0 and < 99999
              display "  Set" at 1922 with erase eol foreground-color 3
     else
              move zero to Stk-Audit-No
              display "  Set to zero" at 1922 with erase eol foreground-color 4 highlight
     end-if
*>
     move     "  Stock Data Complete"  to  verify-message.
     display  verify-screen at 0101 with foreground-color 2.
*>
     move     "Y"  to  ws-reply.
     display  ws-reply at 1576 with foreground-color 6.
     accept   ws-reply at 1576 with foreground-color 6 update.
*>
     if       ws-reply = "N" or = "n"
              go to  Stock-Params.
*>
 main-exit.
     exit section.
*>
 print-params            section.
*>==============================
*>
*>**********************************
*>  File Parameters Print Routine  *
*>**********************************
*>
     display  " " at 0101 with erase eos.
     display  "Do you want printed copy (Y/N) [ ]" at 1201  with foreground-color 2.
     move     "Y" to ws-reply.
     accept   ws-reply at 1233 with foreground-color 4 update.
     if       ws-reply = "N" or = "n"
              go to main-exit.
*>
     open     output  print-file.
     move     prog-name to l1-name.
     move     1 to page-nos.
     move     page-nos to l1-page.
     write    print-record  from  line-1 before 1.
     write    print-record  from  line-3a after 1.
     write    print-record  from  line-4 after 1.
*>
     move     "Name"  to  l5-name.
     move     usera   to  l5-data-1.
*>
     if       profit-centres
              move  "Profit-Centres Selected"  to  l5-data-2
     else
      if      branches
              move "Branches Selected"   to  l5-data-2
      else
              move "Neither P/C or Branches Selected" to  l5-data-2.
     write    print-record  from  line-5 after 2.
*>
     move     "Address"  to  l5-name.
     move     address-1  to  l5-data-1.
*>
     if       not  profit-centres
        and   not  branches
              move spaces  to  l5-data-2
              go to  jump-1.
*>
     if       revenue-only
              move  "Only for Revenue Accounts"  to  l5-data-2
     else
              move  "For all Accounts"  to  l5-data-2.
*>
 jump-1.
*>
     write    print-record  from  line-5 after 1.
*>
     move     spaces     to  l5-name  l5-data-2.
     move     address-2  to  l5-data-1.
*>
     if       not  profit-centres
        and   not  branches
              move spaces  to  l5-data-2
              go to  jump-2.
*>
     if       grouped
              move  "P-C / Branches Grouped on 1st Digit" to  l5-data-2
     else
              move  "P-C / Branches not Grouped" to  l5-data-2.
*>
 jump-2.
*>
     write    print-record  from  line-5 after 1.
*>
     move     address-3  to  l5-data-1.
     if       comparatives
              move  "Comparative Figures Required" to  l5-data-2
     else
              move "Comparative Figures not Required" to l5-data-2.
     write    print-record  from  line-5 after 1.
*>
     string   address-4      delimited by "  "
              ","            delimited by size
              Post-Code      delimited by "  "
              ","            delimited by size
              Country        delimited by "  " into l5-data-1.
*>
     if       index-2
              move "Alphabetic Ledger Index Selected" to l5-data-2
     else
              move "Alphabetic Ledger Index not Selected" to l5-data-2.
     write    print-record  from  line-5 after 1.
*>
     move     "Date Format" to l5-name.
     if       Date-Form = 0 or 1
              move "UK Format" to l5-data-1
              move 1 to Date-Form
     else
      if      Date-Form = 2
              move "USA Format" to l5-data-1
      else    move "Intl Format" to l5-data-1.
     move     spaces to l5-data-2.
*>
     write    print-record from line-5 after 1.
*>
     move     start-date  to  u-bin.
     perform  zz060-Convert-Date.
     move     ws-date  to  l5-data-1.
     move     "Period Start"  to  l5-name.
*>
     if       minimum-validation
              move  "Min. Validation During Data Entry" to  l5-data-2
     else
              move  "Full Validation During Data Entry" to  l5-data-2.
     write    print-record  from  line-5 after 1.
*>
     move     end-date  to  u-bin.
     perform  zz060-Convert-Date.
     move     ws-date  to  l5-data-1.
     move     "       End"  to  l5-name.
*>
     if       archiving
              move "Transaction Archiving Selected" to l5-data-2
     else
              move "Transactions Deleted at End of Cycle" to l5-data-2.
     write    print-record  from  line-5 after 1.
*>
     move     spaces to line-5.
     move     vat-rate-1 to  num-1.
     move     vat-rate-4 to  num-1b.
     move     spaces     to l5-data-1.
     string   num-1          delimited by size
              " / "          delimited by size
              num-1b         delimited by size
              "  VAT Reg: "  delimited by size
              VAT-Reg-Number delimited by size
                                 into l5-data-1.
     move     "VAT    Rate 1/4."  to  l5-name.
*>
     if       sales-range = zero
              move  "No Reserved Sales Range"  to  l5-data-2
     else
              move  "Sales Range most Significant Digit is - " to  l5-data-2
              move  sales-range  to  array-2 (41).
     write    print-record  from  line-5 after 1.
*>
     move     spaces to l5-data-1.
     move     vat-rate-2  to  num-1.
     move     vat-rate-5  to  num-1b.
     string   num-1   delimited by size
              " / "   delimited by size
              num-1b  delimited by size into l5-data-1.
*>     move     num-1  to  l5-data-1.
     move     "       Rate 2/5."  to  l5-name.
*>
     if       purchase-range = zero
              move  "No Reserved Purchase Range" to  l5-data-2
     else
              move  "Purchase Range Most Signif.  Digit is - " to  l5-data-2
              move  purchase-range  to  array-2 (41).
     write    print-record  from  line-5 after 1.
*>
     move     vat-rate-3  to  num-1.
     move     num-1  to  l5-data-1.
     move     "       Rate 3."  to  l5-name.
*>
     if       auto-vat
              move  "Auto VAT Posting Selected" to  l5-data-2
     else
              move  "Manual VAT Posting Selected" to l5-data-2
     end-if
     write    print-record  from  line-5 after 1.
*>
     move     spaces  to  l5-name  l5-data-1.
     move     spaces  to  l5-data-2.
     move     period  to  num-2.
     move     1  to  num-3.
     string   "Cycles per Quarter - "  delimited by size into  l5-data-2  with  pointer  num-3.
     string   num-2  delimited by size into  l5-data-2  with  pointer  num-3.
*>
     move     current-quarter  to  num-4.
     move     1  to  num-3.
     move     "Current Quarter " to l5-name.
     string   num-4  delimited by size into  l5-data-1  with  pointer  num-3.
     write    print-record  from  line-5 after 1.
*>
     move     spaces  to  l5-data-2 l5-data-1.
     move     next-batch  to  num-2.
     move     1  to  num-3.
     string   "Next Batch Number  - "  delimited by size into  l5-data-2  with  pointer  num-3.
     string   num-2  delimited by size into  l5-data-2  with  pointer  num-3.
*>
     move     "Current Cycle" to l5-name.
     move     cyclea to num-4.
     move     1 to num-3.
     string   num-4 delimited by size into l5-data-1 with pointer num-3.
     write    print-record  from  line-5 after 1  lines.
*>
     move     spaces  to  line-5.
     move     1 to num-3.
     string   "Using IRS instead of GL - " delimited by size into l5-data-2 pointer num-3.
     if       irs-used
              string "Yes" delimited by size into l5-data-2  pointer num-3
              end-string
     else
              string "No" delimited by size into l5-data-2   pointer num-3
              end-string
     end-if
     move     "Print Lines" to l5-Name.
     move     Page-Lines to Num-9.
     move     Num-9 to l5-data-1.
     write    print-record from line-5 after 1.
*>
*> End of User / G/L params, now ACAS & P/L params
*>
     move     spaces to l5-data-2.
     write    print-record  from  line-3b after 2.
     move     l4-part1 to print-record.
     write    print-record  from  line-4  after 1.
*>
     move     "Address Delimiter" to l5-data-2.
     move     pl-delim to array-2 (29).
*>
     move     "Environment"  to  l5-name.
     if       multi-user
              move  "Multi-User"  to  l5-data-1
     else
              move  "Single User"  to  l5-data-1
     end-if
     write    print-record  from  line-5 after 2.
*>
     move     "Op. System"  to  l5-name.
     move     spaces to Temp-String
                        Temp-String2.
     if       windows  move "Windows"   to  Temp-String
     else if  Dos      move "Dos"       to  Temp-String
     else if  os2      move "OS/2"      to  Temp-String
     else if  unix     move "Unix"      to  Temp-String
     else if  linux    move "Linux"     to  Temp-String.
     if       DC-Cobol-Standard
              move " & Cobol Standard" to Temp-String2
     else
      if      DC-GUI
              move " & Gui Display" to Temp-String2
      else
       if     DC-Widget
              move " & Widget Display" to Temp-String2.
*>
     string   Temp-String        delimited by space
              Temp-String2       delimited by space into l5-Data-1.
*>
     move     "Next Batch Number" to l5-data-2.
     move     25 to num-3.
     move     bl-next-batch to num-6.
     string   num-6 delimited by size into l5-data-2
                   with pointer num-3.
     write    print-record from line-5 after 1.
     move     "System version"  to  l5-name.
     if       Maps-Ser-xx = "mp"
        and   Maps-Ser-nn = 9999
              move "Using (Free) Open Source Version of ACAS" to l5-data-1
     else
              move "Using Commercial Version of ACAS"         to l5-data-1
     end-if
     move     1 to num-3.
     string   "Next Folio Number " delimited by size into l5-data-2 pointer num-3.
     move     next-folio  to num-7.
     add      3 to num-3.
     string   num-7 delimited by size into l5-data-2 pointer num-3.
     write    print-record from line-5 after 1.
*>
     move     spaces to line-5 Temp-String.
     if       not FS-Valid-Options
              move zero to File-System-Used.
     if       FS-Cobol-Files-Used
              move "Cobol Data Files Used"           to Temp-String
     else
      if      FS-RDBMS-Used
              move "Rdbms is used  "                 to Temp-String.
*>
*>      if      FS-Oracle-Used
*>              move "Oracle Database Used"            to Temp-String
*>      else
*>       if     FS-MySql-Used
*>              move "MySQL Database Used"             to Temp-String
*>       else
*>        if    FS-Postgres-Used
*>              move "Postgres Database Used"          to Temp-String
*>        else
*>         if   FS-DB2-Used
*>              move "IBM DB2 Database Used"           to Temp-String
*>         else
*>          if  FS-MS-SQL-Used
*>              move "MS SQL Server Used"              to Temp-String.
*>
     if       File-Duplicates-In-Use not = zero and not = 1
              move zero to File-Duplicates-In-Use
     end-if
     if       FS-Duplicate-Processing
              string Temp-String            delimited by space
                     "/Dup Mode Used"       delimited by size into l5-data-1
     else
              string Temp-String            delimited by space
                     "/Dup Mode Not Used"   delimited by size into l5-data-1
     end-if
*>
     move     1 to num-3.
     string   "Pay      Account " delimited by size into l5-data-2 pointer num-3.
     move     BL-Pay-Ac to num-8.
     add      6 to num-3.
     string   num-8 delimited by size into l5-data-2 pointer num-3.
     write    print-record from line-5 after 1.
*>
     move     spaces to line-5.
     move     "Path to IRS" to l5-name.
     move     ACAS_IRS  to l5-data-1.
     if       l5-data-1 = spaces
              move "UNSET Environment Variable" to l5-data-1.
     move     1 to num-3.
     string   "Ledger   Account " delimited by size into l5-data-2 pointer num-3.
     move     BL-Purch-Ac to num-8.
     add      6 to num-3.
     string   num-8 delimited by size into l5-data-2 pointer num-3.
     write    print-record from line-5 after 1.
*>
     move     spaces to line-5.
     move     "Path to Ledgers" to l5-name.
     move     ACAS_LEDGERS  to l5-data-1.
     if       l5-data-1 = spaces
              move "UNSET Environment Variable" to l5-data-1.
     move     1 to num-3.
     string   "Creditor Account " delimited by size into l5-data-2 pointer num-3.
     move     P-Creditors to num-8.
     add      6 to num-3.
     string   num-8 delimited by size into l5-data-2 pointer num-3.
     write    print-record from line-5 after 1.
*>
     move     spaces to line-5.
     move     "Prt Spool Name 1" to l5-name.
     if       not OS-Single
              move Print-Spool-Name to l5-data-1
     else
              move "Not Used"       to l5-data-1
     end-if
     move     1 to num-3.
     string   "Stock Control Link " delimited by size into l5-data-2 pointer num-3.
     add      7 to num-3.
     if       PL-Stock-Link = "Y" and Stock
              string "Yes" delimited by size into l5-data-2 pointer num-3
     else
              string "No" delimited by size into l5-data-2 pointer num-3
     end-if
     write    print-record from line-5 after 1.
*>
     move     spaces to line-5.
     move     "Prt Spool Name 2"     to l5-name.
     if       not OS-Single
              move Print-Spool-Name2 to l5-data-1
     else
              move "Not Used"        to l5-data-1
     end-if
     write    print-record from line-5 after 1.
*>
     move     spaces to line-5.
     move     "Prt Spool Name 3"     to l5-name.
     if       not OS-Single
              move Print-Spool-Name3 to l5-data-1
     else
              move "Not Used"        to l5-data-1
     end-if
     write    print-record from line-5 after 1.
*>
*> end of ACAS Params now for S/L and Invoicing (if present)
*>
     write    print-record from line-3c after 2.
     write    print-record from line-4 after 1.
*>
     move     spaces to print-record.
     write    print-record after 1.
     move     3 to a.
     perform  sl-print.
     write    print-record from line-5 after 1.
     move     1 to a.
     perform  sl-print.
     write    print-record from line-5 after 1.
     move     2 to a.
     perform  sl-print.
     write    print-record from line-5 after 1.
     move     4 to a.
     perform  sl-print.
     write    print-record from line-5 after 1.
     move     5 to a.
     perform  sl-print.
     write    print-record from line-5 after 1.
     move     6 to a.
     perform  sl-print.
     write    print-record from line-5 after 1.
     move     7 to a.
     perform  sl-print.
     write    print-record from line-5 after 1.
     move     8 to a.
     perform  sl-print.
     write    print-record from line-5 after 1.
     move     9 to a.
     perform  sl-print.
     write    print-record from line-5 after 1.
     move     10 to a.
     perform  sl-print.
     write    print-record from line-5 after 1.
     move     11 to a.
     perform  sl-print.
     write    print-record from line-5 after 1.
*>
     move     spaces to line-5.
     move     "Company Heads Pri" to l5-name.
     string   "nt on Delivery notes: " delimited by size
              SL-Comp-Head-Pick        delimited by size
                                              into l5-data-1.
     move     1 to num-3,
     string   "Stock Control Link " delimited by size into l5-data-2 pointer num-3.
     add      7 to num-3.
     if       SL-Stock-Link = "Y" and Stock
              string "Yes" delimited by size into l5-data-2 pointer num-3
     else
              string "No" delimited by size into l5-data-2 pointer num-3.
     write    print-record from line-5 after 1.
*>
     string   "nt on Invoices      : " delimited by size
              SL-Comp-Head-Inv         delimited by size
                                              into l5-data-1.
     move     spaces to l5-data-2.
     move     1 to num-3.
     string   "Pay      Account " delimited by size into l5-data-2 pointer num-3.
     move     SL-Pay-Ac to num-8.
     add      6 to num-3.
     string   num-8 delimited by size into l5-data-2 pointer num-3.
     write    print-record from line-5 after 1.
*>
     string   "nt on Statements    : " delimited by size
              SL-Comp-Head-Stat        delimited by size
                                              into l5-data-1.
     move     spaces to l5-data-2.
     move     1 to num-3.
     string   "Ledger   Account " delimited by size into l5-data-2 pointer num-3.
     move     SL-Sales-Ac to num-8.
     add      6 to num-3.
     string   num-8 delimited by size into l5-data-2 pointer num-3.
     write    print-record from line-5 after 1.
*>
     string   "nt on Late Letters  : " delimited by size
              SL-Comp-Head-Lets        delimited by size
                                              into l5-data-1.
     move     spaces to l5-data-2.
     move     1 to num-3.
     string   "Debtors  Account " delimited by size into l5-data-2 pointer num-3.
     move     S-Debtors to num-8.
     add      6 to num-3.
     string   num-8 delimited by size into l5-data-2 pointer num-3.
     write    print-record from line-5 after 1.
*>
*> Delivery now redundant as done in another way, within customer record.
*>
*>     move     spaces to l5-data-2.
*>     move     1 to num-3.
*>     string   "Delivery Tag     " delimited by size into l5-data-2 pointer num-3.
*>     move     Delivery  to num-8.
*>     add      6 to num-3.
*>     string   num-8 delimited by size into l5-data-2 pointer num-3.
*>     write    print-record from line-5 after 1.
*>
*> Now for Stock & O/E so New page
*>
     move     2 to page-nos.
     move     page-nos to l1-page.
     write    print-record  from  line-1 after page.
     write    print-record  from  line-3d after 2.
     write    print-record  from  line-4 after 1.
*>
     move     spaces to line-5.
     move     "Debug Mode" to l5-name.
     if       stk-debug = 1
              move "Yes" to l5-data-1
     else
              move "No" to l5-data-1.
*>
     move     1 to num-3.
     string   "O/Entry in Use   " delimited by size into l5-data-2 pointer num-3.
     add      7 to num-3.
     if       Stk-OE-Used = 1
              string "Yes" delimited by size into l5-data-2 pointer num-3
     else
              string "No" delimited by size into l5-data-2  pointer num-3.
     write    print-record from line-5 after 2.
*>
     move     spaces to line-5.
     move     "Manufacturing" to l5-name.
     if       Stk-Manu-Used = 1
              move "Yes" to l5-data-1
     else
              move "No" to l5-data-1.
     write    print-record from line-5 after 1.
*>
     move     "Audit in Use" to l5-name.
     if       Stk-Audit-Used = 1
              move "Yes" to l5-data-1
     else
              move "No" to l5-data-1.
     write    print-record from line-5 after 1.
*>
     move     "Movement Audits" to l5-name.
     if       Stk-Mov-Audit = 1
              move "Yes" to l5-data-1
     else
              move "No" to l5-data-1.
     write    print-record from line-5 after 1.
*>
     move     "Current Period" to l5-name.
     if       Stk-Period-Cur = "M"
              move "Monthly"   to l5-data-1
     else if  Stk-Period-Cur = "Q"
              move "Quarterly" to l5-data-1
     else if  Stk-Period-Cur = "Y"
              move "Yearly"    to l5-data-1
     else     move "NOT SET"   to l5-data-1.
     write    print-record from line-5 after 1.
*>
     move     "To Date Period" to l5-name.
     if       Stk-Period-Dat = "M"
              move "Monthly"   to l5-data-1
     else if  Stk-Period-Dat = "Q"
              move "Quarterly" to l5-data-1
     else if  Stk-Period-Dat = "Y"
              move "Yearly"    to l5-data-1
     else     move "NOT SET"   to l5-data-1.
     write    print-record from line-5 after 1.
*>
     move     "Stock Averaging" to l5-name.
     if       Stock-Averaging
              move "Yes" to l5-data-1
     else     move "No"  to l5-data-1.
     write    print-record from line-5 after 1.
*>
     move     "Current Audit No" to l5-name.
     move     Stk-Audit-No to Num-7.
     move     Num-7 to l5-data-1.
     write    print-record from line-5 after 1.
*>
*>  Payroll
*>
     write    print-record  from  line-3d2 after 2.
     move     "                      ******************" to l4-part1.
     write    print-record  from  line-4 after 1.
*>
*>   No Payroll for Open Source version
*>
     move     spaces to line-5.
     move     "Payroll in Use   " to l5-name.
*>     if       Payroll-Used = 1
*>              move "Yes" to l5-data-1
*>     else
              move "No" to l5-data-1.
*>
     if       FS-RDBMS-Used
              move "RDBMS DB Schema " to l5-data-2
              move RDBMS-DB-Name      to l5-data-2 (21:12).
     write    print-record from line-5 after 2.
*>
     if       FS-RDBMS-Used
              move spaces to l5-data-1    l5-name
              move "RDB User Name   " to l5-data-2
              move RDBMS-User         to l5-data-2 (21:12)
              write print-record  from  line-5 after 1
              move "RDB User Passwd " to l5-data-2         *> Could remove these 4 lines
              move "It's SECRET"      to l5-data-2 (21:12)
              move line-3e (1:40)     to line-5 (1:40)
              write print-record  from  line-5 after 1
     else
              write    print-record  from  line-3e after 2. *> and leave this freestanding
*>                                                             Below
*>  System wide data ie file-statuses, simple dump of data       Mostly used for debugging
*>
     move     "                        ****************" to l4-part1.
     move     spaces to l4-Part2.  *> clears righthand ******
     write    print-record  from  line-4 after 1.
     move     all "*" to l4-part2-star
                         l4-part1-star.           *> in case it get run again
*>
     move     spaces to line-5.
     move     "File Statuses" to l5-name.
     move     file-statuses   to l5-data-1.
     write    print-record from line-5 after 2.
*>
*> End of params EOP.
*>
     write    print-record  from  line-6 after 2.
     write    print-record  from  line-7 after 1.
     close    print-file.
     call     "SYSTEM" using Print-Report.
*>
 main-exit.
     exit section.
*>
 sl-print         section.
*>***********************
*>
     if       a < 1 or > 11
              go to main-exit.
     move     spaces to line-5.
*>
     go       to aa1 aa2 aa3 aa4 aa5 aa6 aa7 aa8 aa9 aa10 aa11  depending on a.
*>
 aa1.
     if       sl-dunning = zero
              move "Dunning Letters not Selected" to l5-data-2
     else
              move "Dunning Letters Selected" to l5-data-2.
*>
     if       extra-type = "C"
              move "Ext. Charge Desc" to l5-name
              move extra-desc to l5-data-1.
     if       extra-type = "D"
              move "Extra Disc. Desc" to l5-name
              move extra-desc to l5-data-1.
     go       to main-exit.
*>
 aa2.
     if       sl-charges = zero
              move "Late Charges not Selected" to l5-data-2
     else
              move "Late Charges Selected" to l5-data-2.
*>
     move     extra-rate to num-1.
     if       extra-type = "C"
              move "Ext. Charge Rate" to l5-name
              move num-1 to l5-data-1.
     if       extra-type = "D"
              move "Ext. Disc. Rate" to l5-name
              move num-1 to l5-data-1.
     go       to main-exit.
*>
 aa3.
     if       sl-own-nos = "N"
              move "Computer Generated Invoice Numbers Selected" to l5-data-2
     else
              move "Manually Entered Invoice Numbers Selected"   to l5-data-2.
*>
     move     "Next Inv. Number" to l5-name.
     move     next-invoice to num-7.
     move     num-7 to l5-data-1.
     go       to main-exit.
*>
 aa4.
     move     "Credit Period nn Days" to l5-data-2.
     move     sl-credit  to  num-4.
     move     15 to num-3.
     string   num-4 delimited by size into l5-data-2 with pointer num-3.
*>
     move     "Inv. Data Level" to l5-name.
     move     invoicer to l5-data-1.
     go       to main-exit.
*>
 aa5.
     move     "Standard Credit Limit" to l5-data-2.
     move     sl-limit to num-5.
     move     23 to num-3.
     string   num-5 delimited by size into l5-data-2 with pointer num-3.
*>
     move     extra-charge-ac to num-8.
     if       extra-type = "C"
              move "Extra Charge A/C" to l5-name
              move num-8 to l5-data-1.
*>
     if       extra-type = "D"
              move "Extra Disc. A/C" to l5-name
              move num-8 to l5-data-1.
     go       to main-exit.
*>
 aa6.
     move     "Standard Discount is   nn.nn%" to l5-data-2.
     move     sl-disc to num-1.
     move     24 to num-3.
     string   num-1 delimited by size into l5-data-2 with pointer num-3.
*>
     move     "VAT Account" to l5-name.
     move     vat-ac to num-8.
     move     num-8 to l5-data-1.
     go       to main-exit.
*>
 aa7.
     move     "Min. Late Balance" to l5-data-2.
     move     sl-min to num-2.
     move     25 to num-3.
     string   num-2 delimited by size into l5-data-2 with pointer num-3.
*>
     move     "Print VAT Nunber" to l5-name.
     if       SL-VAT-Prints
              move     "Yes"     to l5-data-1
     else
              move     "No "     to l5-data-1.
     go       to main-exit.
*>
 aa8.
*>
     move     "Max. Late Charge" to l5-data-2.
     move     sl-max to num-2.
     move     25 to num-3.
     string   num-2 delimited by size into l5-data-2 with pointer num-3.
     go       to main-exit.
*>
 aa9.
*>
     move     "Late Charge Rate       nn.nn%" to l5-data-2.
     move     sl-late-per to num-1.
     move     24 to num-3.
     string   num-1 delimited by size into l5-data-2 with pointer num-3.
     go       to main-exit.
*>
 aa10.
*>
*> Note these are S/L and P/L params
*>
     move     "Address Delimiter" to l5-data-2.
     move     sl-delim to array-2 (29).
     go       to main-exit.
*>
 aa11.
     move     "Next Batch Number" to l5-data-2.
     move     25 to num-3.
     move     first-sl-batch to num-6.
     string   num-6 delimited by size into l5-data-2 with pointer num-3.
     move     "Proforma Retent." to l5-name.
     move     pf-retention to num-9.
     move     num-9 to l5-data-1.
     go       to main-exit.
*>
 main-exit.
     exit     section.
*>
 zz010-Get-Env-Set-Files section.
*>******************************
*>
     accept   ACAS_LEDGERS from Environment "ACAS_LEDGERS".
     accept   ACAS_IRS     from Environment "ACAS_IRS".
     accept   ACAS_BIN     from Environment "ACAS_BIN".
*>
     if       ACAS_IRS (1:1) = space
           or ACAS_LEDGERS (1:1) = spaces
           or ACAS_BIN (1:1) = spaces
              display SY009        at 0505 with erase eos highlight
              display SY008        at 1210 with           foreground-color 3 highlight
              accept ws-reply      at 1243
              stop run
     end-if
     if       ACAS_LEDGERS (1:1) = "/"   *> Its Linux/Unix
              move "/" to OS-Delimiter.
     if       ACAS_LEDGERS (1:1) = "\"   *> Its Windoz
              move "\" to OS-Delimiter.
*>
 zz010-GESF-Exit.
     exit     section.
*>
 zz020-Get-Program-Args      section.
*>**********************************
*>
     perform  zz010-Get-Env-Set-Files.          *> This must be set so get it 1st + need os-delimiter
*>
*> See if we have temporary overrides that have ben supplied whwn calling program
*>
     accept   Arg-Number from argument-number.
     if       Arg-Number = zero
              go to zz020-Set-the-Paths.
*>
     if       Arg-Number > 2
              display SY006        at 0101 with erase eos foreground-color 3
              display Arg-Number   at 0164 with           foreground-color 3
              display SY008        at 1210 with           foreground-color 3 highlight
              accept ws-reply      at 1243
              stop run.
*>
     move     zero to z.
     perform  Arg-Number times
              add      1 to z
              accept   Arg-Value (z) from argument-value
              move     Arg-Value (z) to Arg-Test
              if       Arg-Test (1:13) not = "ACAS_LEDGERS="
                 and   Arg-Test (1:9)  not = "ACAS_IRS="
                       display SY007   at 0101 with erase eos foreground-color 3
                       display SY008   at 1210 with           foreground-color 3 highlight
                       accept ws-reply at 1243
                       stop run
              end-if
              if       Arg-Test (1:13) = "ACAS_LEDGERS="
                       move Arg-Test (14:512) to ACAS_LEDGERS
              else
                 if    Arg-Test (1:9) = "ACAS_IRS="
                       move Arg-Test (10:512) to ACAS_IRS
                 end-if
              end-if
     end-perform
     if       ACAS_LEDGERS (1:1) = "/"   *> Its Linux/Unix
              move "/" to OS-Delimiter.
     if       ACAS_LEDGERS (1:1) = "\"   *> Its Windoz
              move "\" to OS-Delimiter.
*>
*>  Put absolute path with file names into the file-id areas over-writing filename.
*>    Note that count in perform is equal to number of files used in system & wsnames.cob held
*>       in File-Defs-Count
*>
 zz020-Set-the-Paths.
     move     zero to z.
     perform  File-Defs-Count times
              add 1 to z
              move space to Arg-Test
              string ACAS_LEDGERS          delimited by space
                     OS-Delimiter          delimited by size
                     System-File-Names (z) delimited by space into Arg-Test
              end-string
              move     Arg-Test to System-File-Names (z)
     end-perform
     move     zero to z.
*>
 zz020-Exit.
     exit   section.
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
*>          u-date = UK date format, if not spaces
*>
     perform  maps04.
     if       u-date = spaces
              move spaces to ws-Date
              go to zz060-Exit.
     move     u-date to ws-date.
*>
     if       Date-Form = zero or > 3
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
 maps04       section.
*>*******************
*>
     call     "maps04"  using  maps03-ws.
*>
 maps04-exit.
     exit     section.
*>
