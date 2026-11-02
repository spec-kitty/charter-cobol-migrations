       >>source free
*>***********************************************
*>                                              *
*>          Stock File/Table Handler            *
*>                                              *
*>***********************************************
*>
 identification division.
 Program-Id.            acas011.
*>**
*> Author.              Vincent B Coen, FBCS, FIDMP, CPL
*>                      for Applewood Computers.
*>**
*> Security.            Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>**
*> Remarks.             Stock File Handler.
*>                      ******************
*>                      This and associated modules relate to ACAS versions v3.02 and later.
*>
*>                      This modules does all file handling for this file.
*>                      If Cobol Flat files are in use (via system parmater file settings) which
*>                      is passed via the wsfnctn / File-Access data block via menu modules.
*>                      It will read/write/open/close as required and requested.
*>
*>                      If RDBMS (Relational DataBase Management Systems) is in use it will call
*>                      the specific module to handle similar processing passing the equivelent
*>                      RDB (Relational DataBase) row as a Cobol file record (01 level) moving
*>                      row by row to the correct Cobol flat file fields as required.
*>
*>                      RDB DAL (Data Access Layer) modules are individually modified to handle:
*>                      MS SQL server, Mysql, DB2, Postgres and Oracle as available and tested.
*>                      These are contained in seperate directories for each RDB, eg
*>                       'MSSQL' (MS SQL Server), 'Mysql', 'DB2', 'Postgres'. 'Oracle'.
*>                       You need to compile from the correct directory for the specific
*>                       RDB you will use and have installed along with all of the development
*>                       libraries and include files etc.
*>                      In addition:
*>                        If the system has been set up to (see the System File set up via the
*>                        main menu module for each sub system), also process BOTH flat file
*>                        AND the correct rdb tables,
*>                        it will write/delete/update etc to both but read from 1=Flat and be
*>                        overwritten by the rdb access.
*>                       This will help in transferring the Cobol flat files to rdb tables.
*>
*>                      If you wish to convert a running ACAS system over from Flat files
*>                      to RDBMS see below. However it is recommended to use the Duplicate
*>                      processing of files/table as outlined above:
*>
*>                      Also included are LM's (Load Modules) to convert each ISAM
*>                      (Indexed Sequential) file to the rdb database tables if you wish to
*>                      convert the system in one hit, without using the Duplicate file/RDB
*>                      processing procedures. These will also need to be compiled from the
*>                      specific LM directory that contains the rdb DAL modules.
*>**
*> Called Modules:      stockMT - DAL (RDB Data Access Layer)
*>
*>**
*> Error Messages Used.
*>
*>**
*> Version.             1.00 29/02/2012.
*>
*> Changes.
*> 29/02/12 vbc - Created for Open Cobol v1.1 & v2.0. Code also to be tested with MF NE
*>                ** UNDER TEST **
*>
*>**
*>  Module USAGE
*>**************
*>
*>    On Entry:         Set up Linkage areas -
*>    ********              WS-Stock-Record = Contents of data record to be written/read
*>                          File-Access = File-Function as needed.
*>                                        Access-Type   as needed.
*>                          File-Defs (File-Definitions) = Paths set up.
*>
*>    On Exit:          Linkage contains:
*>    *******               Record = containing a read data record or table row
*>                          Fs-Reply = 0, 99 or other value where
*>                                     0  = operation completed successfully
*>                                     99 = Indicates an error see WE-Error for more info
*>                          WE-Error   0    = operation completed successfully
*>                                     999  =
*>                                     998* = File-Key-No Out Of Range not 1, 2 or 3.
*>                                     997* = Access-Type wrong (< 5 or > 8)
*>                                     996* = File Delete key out of range (not = 1 or 2)
*>                                     995* = During Delete SQLSTATE not '00000' investigate using MSG-Err/Msg
*>                                     994* = During Rewrite,                     ^^ see above ^^
*>                                     990* = Unknown and unexpected error, again ^^ see above ^^
*>                                     911* = Rdb Error during initializing,
*>                                            possibly can not connect to database
*>                                             Check connect data and
*>                                             see SQL-Err & SQL-MSG
*>                                     901  = File Def Record size not =< than ws record size
*>                                            Module needs ws definition changing to correct size
*>                                            FATAL, Stop using system, fix source code
*>                                            and recompile before using system again.
*>                                     Other = any other rdbms errors see specific
*>                                             (Rdbms) manual
*>                          SQL-Err  = Error code from RDBMS is set if above 2 are non zero
*>                          SQL-Msg  = Non space providing more info if SQL-Err non '00000'
*>                                     * = FS-Reply = 99
*>************
*>
*>********************************************************************************************
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
*>
*>**********************************************************************************
*>
*> WARNING:
*> *******
*> Many of the RDB handlers (DAL) are NOT covered under the above GPL but authority
*>  to use, WITHOUT the right of ANY FORM OF PAID REDISTRIBUTION is given. HOWEVER,
*>  distribution licensing can be offered on a case by case basis.
*>
*> Contact the Lead Programmer at vbcoen@gmail.com with details of your requirements.
*>
*>**********************************************************************************
*>
 environment division.
*> copy "envdiv.cob".
 configuration section.
 source-computer.      Linux.
 object-computer.      Linux.
*> special-names.
*>     console is crt.
*>
 input-output section.
 file-control.
*>
*> copy "stock.CBS".
*> copy "selstock.cob". *> in "../stock".
*>
     select  Stock-File      assign               File-11
                             access               dynamic
                             organization         indexed
                             status               Fs-Reply
                             record key           Stock-Key
                             alternate record key Stock-Abrev-Key
                             alternate record key Stock-Desc with duplicates.
 data division.
 file section.
*>***********
*> copy "stock.CBF".
*> copy "fdstock.cob". *> in "../stock".
*>*******************************************
*>                                          *
*>  File Definition For The Stock Control   *
*>                                          *
*>*******************************************
*> rec size 385 bytes (with WIP) 26/05/09
*> rec size 400 bytes (with fillers) 11/12/11
*> 02/06/09 vbc - Added PA code
*> 17/03/12 vbc - Field types chgd from bin long to comp still 400
*>
 fd  Stock-File.
*>
 01  Stock-Record.
     03  Stock-Key                pic x(13).
     03  Stock-Abrev-Key          pic x(7).
     03  Stock-Suppliers-Group.
         05  Stock-Supplier-P1    pic x(7).                          *> Primary   Supplier
         05  Stock-Supplier-P2    pic x(7).                          *> Secondary Supplier
         05  Stock-Supplier-P3    pic x(7).                          *> Back Up   Supplier
     03  filler redefines Stock-Suppliers-Group.
         05  Stock-Suppliers      pic x(7)     occurs 3.  *> 41
     03  Stock-Desc               pic x(32).              *> 73
     03  Stock-Construct-Item     pic x(13).              *> 86
     03  Stock-Location           pic x(10).
     03  Stock-PA-Code.
         05  Stock-pa-System      pic x.
         05  Stock-pa-Group.
             07  Stock-pa-First   pic x.
             07  Stock-pa-Second  pic x.
     03  Stock-SA-Code.
         05  Stock-sa-System      pic x.
         05  Stock-sa-Group.
             07  Stock-sa-First   pic x.
             07  Stock-sa-Second  pic x.
     03  Stock-Services-Flag      pic x.                  *> 103        flag for services, not product (Y/N)
     03  Stock-Last-Actual-Cost   pic 9(7)v99     comp-3. *> (5)
     03  filler                   pic x(8).               *> 116
     03  Stock-Construct-Bundle   pic s9(6)       comp.
     03  Stock-Under-Construction pic s9(6)       comp.
     03  Stock-Work-in-Progress   pic s9(6)       comp.
     03  Stock-ReOrder-Pnt        pic s9(6)       comp.
     03  Stock-Std-ReOrder        pic s9(6)       comp.
     03  Stock-Back-Ordered       pic s9(6)       comp.
     03  Stock-On-Order           pic s9(6)       comp.
     03  Stock-Held               pic s9(6)       comp.
     03  Stock-Pre-Sales          pic s9(6)       comp.   *> 36 = 152
     03  Stock-Retail             pic 9(7)v99     comp-3. *> 5    *> This 3 increased by 1 leading digit
     03  Stock-Cost               pic 9(7)v9999   comp-3. *> 6          Based on last Order Only
     03  Stock-Value              pic 9(9)v99     comp-3. *> 6 = 169
     03  Stock-Order-Due          pic 9(8)    comp.  *> binary-long unsigned.
     03  Stock-Order-Date         pic 9(8)    comp.  *> binary-long unsigned.   *> 177
     03  Stock-Mthly-Running-Totals.                 *> 16:    cleared at EOY cycle
         05  Stock-Adds           pic 9(8)    comp.  *> binary-long.
         05  Stock-Deducts        pic 9(8)    comp.  *> binary-long.
         05  Stock-Wip-Adds       pic 9(8)    comp.  *> binary-long.
         05  Stock-Wip-Deds       pic 9(8)    comp.  *> binary-long.
     03  Stock-History.
         05  Stock-History-Data              occurs 12.   *> 193:       zeroed for new year
             07  Stock-TD-Adds     pic 9(8)   comp.  *> binary-long.
             07  Stock-TD-Deds     pic 9(8)   comp.  *> binary-long.
             07  Stock-TD-Wip-Adds pic 9(8)   comp.  *> binary-long.
             07  Stock-TD-Wip-Deds pic 9(8)   comp.  *> binary-long.   *> 48 (x4) = 192 == 385
     03  filler                   pic x(15).                           *> 400  expansion
 working-storage section.
*>**********************
 77  Old-File-Function  pic 9      value zero.
*>
 01  error-code         pic 999    value zero.     *> NOT CURRENTLY IN USE
*>
 01  DAL-datablock      pic x(8192).               *> Used in DAL
*>
 01 ACAS-DAL-Common-data.
    03  A                       pic s9(4)     comp    value zero.  *> A & B used in 1st test ONLY
    03  B                       pic s9(4)     comp    value zero.  *>  in ba-Process-RDBMS
    03  Display-Blk             pic x(75)             value spaces.
*>
 Linkage Section.
*>**************
*> nolist
*> copy "wssystem.cob".
*>*******************************************
*>                                          *
*>  Record Definition For The System File   *
*>                                          *
*>*******************************************
*>  file size 1024 with fillers
*> 01/02/09 vbc - Repacked 2 reduce slack
*> 05/04/09 vbc - Light clean up
*> 07/04/09 vbc - Remove op-gen to filler (general)
*> 22/04/09 vbc - Stock control data added.
*> 29/05/09 vbc - Added 'system wide' Print-Lines for all ledgers.
*>  1/06/09 vbc - Added Stock link for PL and SL.
*> 14/09/10 vbc - Added Print-Spool-Name.
*> 15/09/10 vbc - Need to increase rec size by 128 bytes in system-data and more in the others
*>                to bring it up to 1024, the other 2 rec types will also increase to same.
*>                Epos remarked out for Open source versions.
*> 07/11/10 vbc - New fields added as above including vers & sub vers for file for auto
*>                updating of changed file layouts by system
*> 16/11/11 vbc - Added extra 88 in op-system
*> 11/12/11 vbc - Added Date-Form for all of ACAS and removed stk-Date-Form
*> 04/03/12 vbc - Added File-Duplicates-In-Use & FS-Duplicate-Processing + support for MS SQL server.
*> 09/04/12 vbc - Added Needed RDB data, DB Name, User Name and password requred for connecting
*>                 to Database tables.
*> 15/05/13 vbc - Added SL-Stock-Audit to invoicing replacing a filler. Needs adding to rdbms layouts!!!
*> 19/05/13 vbc - Added 4 fields at end of SL block for company name/address headings in
*>                Inv, Stat, Pick, Letters, Vat-prints And VAT registration number in system block
*>                  - NEEDS adding to in RDBMS layouts.
*> 04/06/13 vbc - Added fields Print-Spool-Name2 & Print-Spool-Name3 in filler areas but really need to be moved
*>                to system data block AND moving around some other fields. File size NOT changed
*> 12/06/13 vbc - Added IRS fields to main system file - Starter for 10.
*>
 01  System-Record.
*>******************
*>   System Data   *
*>******************
     03  System-Data-Block.                                  *>   384 bytes
         05  System-Record-Version-Prime      binary-char.   *>  NEW
         05  System-Record-Version-Secondary  binary-char.   *>  NEW
         05  Vat-Rates                    comp.
             07 Vat-Rate-1   pic 99v99.
             07 Vat-Rate-2   pic 99v99.
             07 Vat-Rate-3   pic 99v99.
             07 Vat-Rate-4   pic 99v99.   *> 2b used for local sales tax   Not UK  {  as of 07 Nov 2010  *> NEW setup in sys002
             07 Vat-Rate-5   pic 99v99.   *> 2b used for local sales tax   Not UK  {                     *> NEW setup in sys002
         05  Vat-Rate redefines Vat-Rates pic 99v99 comp occurs 5.
         05  Cyclea          binary-char.
         05  Scycle Redefines cyclea  binary-char.
         05  Period          binary-char.
         05  Page-Lines      binary-char  unsigned.
         05  Next-Invoice    binary-long.
         05  Run-Date        binary-long.
         05  Start-Date      binary-long.
         05  End-Date        binary-long.
         05  Suser.				*> IRS
             07  Usera       pic x(32).
         05  User-Code       pic x(32).
         05  Address-1       pic x(24).
         05  Address-2       pic x(24).
         05  Address-3       pic x(24).
         05  Address-4       pic x(24).
         05  Post-Code       pic x(12).   *> or ZipCode size should cover all countries
         05  Country         pic x(24).
         05  Print-Spool-Name pic x(48).
         05  File-Statuses.
             07  File-Status pic 9          occurs 32.
         05  Pass-Value      pic 9.
         05  Level.
             07  Level-1     pic 9.
                 88  G-L                    value 1.   *> General (Nominal) ledger
             07  Level-2     pic 9.
                 88  B-L                    value 1.   *> Purchase (Payables) ledger
             07  Level-3     pic 9.
                 88  S-L                    value 1.   *> Sales (Receivables) ledger
             07  Level-4     pic 9.
                 88  Stock                  value 1.   *> Stock Control (Inventory)
             07  Level-5     pic 9.
                 88  O-E                    value 1.   *> Order Entry
             07  Level-6     pic 9.
                 88  Payroll                value 1.   *> Payroll
         05  Pass-Word       pic x(4).                 *>
         05  Host            pic 9.
             88  Multi-User                 value 1.
         05  Op-System       pic 9.
             88  Dos                        value 1.
             88  Windows                    value 2.
             88  Mac                        value 3.
             88  Os2                        value 4.
             88  Unix                       value 5.
             88  Linux                      value 6.
             88  OS-Single                  values 1 2 4.
         05  Current-Quarter pic 9.
         05  RDBMS-Flat-Statuses.
             07  File-System-Used  pic 9.
                 88  FS-Cobol-Files-Used        value zero.
                 88  FS-RDBMS-Used              value 1.
*>                 88  FS-Oracle-Used             value 1.  *> THESE NOT IN USE
*>                 88  FS-MySql-Used              value 2.  *> ditto
*>                 88  FS-Postgres-Used           value 3.  *> ditto
*>                 88  FS-DB2-Used                value 4.  *> ditto
*>                 88  FS-MS-SQL-Used             value 5.  *> ditto
                 88  FS-Valid-Options           values 0 thru 1.    *> 5. (not in use unless 1-5)
             07  File-Duplicates-In-Use pic 9.
                 88  FS-Duplicate-Processing    value 1.
         05  Maps-Ser.      *> Not needed in OpenSource version, = 9999 (No Maintainence Contract]
             07  Maps-Ser-xx pic xx.        *> Allows for 36^2 * 100 customers
             07  Maps-Ser-nn binary-short.  *>       =  129600 - 2
         05  Date-Form       pic 9.
             88  Date-UK                    value 1.  		*> dd/mm/yyyy
             88  Date-USA                   value 2.  		*> mm/dd/yyyy
             88  Date-Intl                  value 3.  		*> yyyy/mm/dd
             88  Date-Valid-Formats         values 1 2 3.
         05  Data-Capture-Used pic 9.
             88  DC-Cobol-Standard          value zero.
             88  DC-GUI                     value 1.
             88  DC-Widget                  value 2.
         05  RDBMS-DB-Name   pic x(12)      value "ACASDB".	*> change in setup
         05  RDBMS-User      pic x(12)      value "ACAS-User".	*> change in setup
         05  RDBMS-Passwd    pic x(12)      value "PaSsWoRd".	*> change in setup
         05  VAT-Reg-Number  pic x(11)      value spaces.
         05  filler          pic x(08).          		*> change for file record sizing
*>***************
*>   G/L Data   *
*>***************
     03  General-Ledger-Block.               *> 80 bytes
         05  P-C             pic x.
             88  Profit-Centres             value "P".
             88  Branches                   value "B".
         05  P-C-Grouped     pic x.
             88  Grouped                    value "Y".
         05  P-C-Level       pic x.
             88  Revenue-Only               value "R".
         05  Comps           pic x.
             88  Comparatives               value "Y".
         05  Comps-Active    pic x.
             88  Comparatives-Active        vaLUE "Y".
         05  M-V             pic x.
             88  Minimum-Validation         vaLUE "Y".
         05  Arch            pic x.
             88  Archiving                  value "Y".
         05  Trans-Print     pic x.
             88  Mandatory                  value "Y".
         05  Trans-Printed   pic x.
             88  Trans-Done                 value "Y".
         05  Header-Level    pic 9.
         05  Sales-Range     pic 9.
         05  Purchase-Range  pic 9.
         05  Vat             pic x.
             88  Auto-Vat                   value "Y".
         05  Batch-Id        pic x.
             88  Preserve-Batch             value "Y".
         05  Ledger-2nd-Index pic x.                     	*> But file uses SINGLE INDEX only ???
             88  Index-2                    value "Y".
         05  Irs-Instead     pic x.
             88  Irs-Used                   value "Y".
         05  Ledger-Sec      binary-short.
         05  Updates         binary-short.
         05  Postings        binary-short.
         05  Next-Batch      binary-short.   		*> should be unsigned used for all ledgers
         05  Extra-Charge-Ac binary-long.
         05  Vat-Ac          binary-long.
         05  Print-Spool-Name2 pic x(48).
*>******************
*>   P(B)/L Data   *
*>******************
     03  Purchase-Ledger-Block.              *> 88 bytes
         05  Next-Folio      binary-long.
         05  BL-Pay-Ac       binary-long.
         05  P-Creditors     binary-long.
         05  BL-Purch-Ac     binary-long.
         05  BL-End-Cycle-Date binary-long.
         05  BL-Next-Batch   binary-short.   *> should be unsigned - unused ?
         05  Age-To-Pay      binary-char.    *> should be unsigned
         05  Purchase-Ledger pic x.
             88  P-L-Exists                 value "Y".
         05  PL-Delim        pic x.
         05  Entry-Level     pic 9.
         05  P-Flag-A        pic 9.
         05  P-Flag-I        pic 9.
         05  P-Flag-P        pic 9.
         05  PL-Stock-Link   pic x.
         05  Print-Spool-Name3 pic x(48).
         05  filler          pic x(10).
*>***************
*>   S/L Data   *
*>***************
     03  Sales-Ledger-Block.                 *> 128 bytes
         05  Sales-Ledger    pic x.
             88  S-L-Exists                 value "Y".
         05  SL-Delim        pic x.
         05  Oi-3-Flag       pic x.		*> 'Y' used in sl060 why?
         05  Cust-Flag       pic x.
         05  Oi-5-Flag       pic x.
         05  S-Flag-Oi-3     pic x.		*> 'z' when otm3 created, used in sl060 why? NO LONGER USED
         05  Full-Invoicing  pic 9.
         05  S-Flag-A        pic 9.		*> '1' used in sl060 why?
         05  S-Flag-I        pic 9.		*> '2' used in sl060 why?
         05  S-Flag-P        pic 9.
         05  SL-Dunning      pic 9.
         05  SL-Charges      pic 9.
         05  Sl-Own-Nos      pic x.
         05  SL-Stats-Run    pic 9.
         05  Sl-Day-Book     pic 9.
         05  invoicer        pic 9.
             88  I-Level-0                  value 0.  *> show totals only (no net & vat) not used?
             88  I-Level-1                  value 1.  *> Show net, vat
             88  I-Level-2                  value 2.  *> show Details + vat etc     *> this looks wrong in sl910 ??????   totals only (no net & vat)
             88  Not-Invoicing              value 9.  *> show totals only (no net & vat) but not found yet nor level 3 (see sl900)
         05  Extra-Desc      pic x(14).
         05  Extra-Type      pic x.
             88  Discount                   value "D".
             88  Charge                     value "C".
         05  Extra-Print     pic x.
         05  SL-Stock-Link   pic x.
         05  SL-Stock-Audit  pic x.
             88  Stock-Audit-On             value "Y".   *> Invoicing will create an audit record (15/05/13)
         05  SL-Late-Per     pic 99v99    comp.
         05  SL-Disc         pic 99v99    comp.
         05  Extra-Rate      pic 99v99    comp.
         05  SL-Days-1       binary-char.
         05  SL-Days-2       binary-char.
         05  SL-Days-3       binary-char.
         05  SL-Credit       binary-char.
         05  filler          binary-short.   *> No longer used.
         05  SL-Min          binary-short.
         05  SL-Max          binary-short.
         05  PF-Retention    binary-short.
         05  First-Sl-Batch  binary-short.   *> should be unsigned - unused ?
         05  First-Sl-Inv    binary-long.
         05  SL-Limit        binary-long.
         05  SL-Pay-Ac       binary-long.
         05  S-Debtors       binary-long.
         05  SL-Sales-Ac     binary-long.
         05  S-End-Cycle-Date binary-long.
         05  SL-Comp-Head-Pick Pic x.
             88  SL-Comp-Pick               value "Y".
         05  SL-Comp-Head-Inv  pic x.
             88  SL-Comp-Inv                value "Y".
         05  SL-Comp-Head-Stat pic x.
             88  SL-Comp-Stat               value "Y".
         05  SL-Comp-Head-Lets pic x.
             88  SL-Comp-Lets               value "Y".
         05  SL-VAT-Printed  pic x.
             88  SL-VAT-Prints              value "Y".
         05  filler          pic x(45).      *>  just in case
*>***************
*> Stock Data   *
*>***************
*>
     03  Stock-Control-Block.                *> 88 bytes
         05  Stk-Abrev-Ref   pic x(6).
         05  Stk-Debug       pic 9.          *> T/F (1/0).
         05  Stk-Manu-Used   pic 9.          *> T/F (Bomp/Wip)
         05  Stk-OE-Used     pic 9.          *> T/F.
         05  Stk-Audit-Used  pic 9.          *> T/F.
         05  Stk-Mov-Audit   pic 9.          *> T/F.
         05  Stk-Period-Cur  pic x.          *> M=Monthly, Q=Quarterly, Y=Yearly
         05  Stk-Period-dat  pic x.          *>  --  ditto  --
         05  filler          pic x.    	     *> was stk-date-form
         05  Stock-Control   pic x.
             88  Stock-Control-Exists   value "Y".
         05  Stk-Averaging   pic 9.          *> T/F.
             88  Stock-Averaging        value 1.
         05  Stk-Activity-Rep-Run pic 9.     *> T/F.  =17 bytes 0=no, 1=add, 2=del, 3=both
         05  filler          pic x.          *> slack byte
         05  Stk-Page-Lines  binary-char unsigned.  *> Taken from Print-Lines
         05  Stk-Audit-No    binary-char unsigned.  *> 20
         05  filler          pic x(68).             *> 64    (just in case)
     03  Order-Entry-Block.                         *> 128 bytes
         05  filler-Dummy    pic x(128).
     03  IRS-Data-Block.
         05  filler-dummy4   pic x(128).
     03  IRS-Entry-Block redefines IRS-Data-Block.			*> NEW 12/06/13
         05  Client             pic x(24). 	*> 		24
         05  System-Files.
             07  fn-1           pic x(9).  	*> acts  	33
             07  fn-2           pic x(10). 	*> system  	43
             07  fn-3           pic x(8).  	*> dflt  	51
             07  fn-4           pic x(8).  	*> post 	59
             07  fn-5           pic x(12). 	*> prn  	71 Needed??
             07  System-Ops     pic x.     	*> 		72
         05  Next-Post          pic 9(5).  	*> 		77
         05  Vat-Rates2.
             07  vat1           pic 99v99. 	*> 		81   *> Standard  changed from vat (11/06/13)
             07  vat2           pic 99v99. 	*> 		85   *> reduced 1 [not yet used]
             07  vat3           pic 99v99. 	*> 		89   *> reduced 2 [not yet used]
         05  Vat-Group redefines Vat-Rates2.
             07  Vat-Psent      pic 99v99    occurs 3.
         05  IRS-Pass-Value     pic 9.	 	 *>		90  (Was Pass-Value in IRS system file)
         05  save-sequ          pic 9.     	 *> 		91
         05  system-work-group  pic x(18).	 *> 		109
         05  PL-App-Created     pic x.    	 *> 		110
         05  PL-Approp-AC       pic 9(5). 	 *> 		115
         05  1st-Time-Flag      pic 9.    	 *> 		116   (was First-Time-Flag in IRS system file)
         05  filler             pic x(12).	 *>             128
*>         05  filler             pic x(12).	 *> when vat rates killed
*>     03  Payroll-Data-Block.                        *> 128 bytes
*>         05  filler-dummy2   pic x(128).		*> Content Removed
*>     03  Epos-Data-Block.
*>         05  filler-dummy3   pic x(128).		*> Content Removed
*> nolist
*> copy "wsstock.cob".
*>*******************************************
*>                                          *
*>          Stock Control record            *
*>                                          *
*>*******************************************
*> rec size 400 bytes (with fillers) 11/12/11
*> 02/06/09 vbc - Added PA code
*> 26/02/12 chngd bins to comps 4 sql still 400
*>
 01  WS-Stock-Record.
     03  WS-Stock-Key             pic x(13).
     03  WS-Stock-Abrev-Key       pic x(7).
     03  Stock-Suppliers-Group.
         05  Stock-Supplier-P1    pic x(7).                          *> Primary   Supplier
         05  Stock-Supplier-P2    pic x(7).                          *> Secondary Supplier
         05  Stock-Supplier-P3    pic x(7).                          *> Back Up   Supplier
     03  filler redefines Stock-Suppliers-Group.
         05  Stock-Suppliers      pic x(7)     occurs 3.  *> 41
     03  WS-Stock-Desc            pic x(32).              *> 73
     03  Stock-Construct-Item     pic x(13).              *> 86
     03  Stock-Location           pic x(10).
     03  Stock-PA-Code.
         05  Stock-pa-System      pic x.
         05  Stock-pa-Group.
             07  Stock-pa-First   pic x.
             07  Stock-pa-Second  pic x.
     03  Stock-SA-Code.
         05  Stock-sa-System      pic x.
         05  Stock-sa-Group.
             07  Stock-sa-First   pic x.
             07  Stock-sa-Second  pic x.
     03  Stock-Services-Flag      pic x.                  *> 103  flag 4 services, not product (Y/N)
     03  Stock-Last-Actual-Cost   pic 9(7)v99     comp-3. *> (5) +1
     03  filler                   pic x(8).               *> 116
     03  Stock-Construct-Bundle   pic s9(6)       comp.
     03  Stock-Under-Construction pic s9(6)       comp.
     03  Stock-Work-in-Progress   pic s9(6)       comp.
     03  Stock-ReOrder-Pnt        pic s9(6)       comp.
     03  Stock-Std-ReOrder        pic s9(6)       comp.
     03  Stock-Back-Ordered       pic s9(6)       comp.
     03  Stock-On-Order           pic s9(6)       comp.
     03  Stock-Held               pic s9(6)       comp.
     03  Stock-Pre-Sales          pic s9(6)       comp.   *> 36 = 152
     03  Stock-Retail             pic 9(7)v99     comp-3. *> 5
     03  Stock-Cost               pic 9(7)v9999   comp-3. *> 6          Based on last Order Only
     03  Stock-Value              pic 9(9)v99     comp-3. *> 6 = 169
     03  Stock-Order-Due          pic 9(8)    comp.  *> binary-long unsigned.
     03  Stock-Order-Date         pic 9(8)    comp.  *> binary-long unsigned.   *> 177
     03  Stock-Monthly-Running-Totals.                    *> 16:        cleared at EOY cycle
         05  Stock-Adds           pic 9(8)    comp.  *> binary-long.
         05  Stock-Deducts        pic 9(8)    comp.  *> binary-long.
         05  Stock-Wip-Adds       pic 9(8)    comp.  *> binary-long.
         05  Stock-Wip-Deds       pic 9(8)    comp.  *> binary-long.  *> 193
     03  Stock-History.
         05  Stock-History-Data                 occurs 12.            *> 192:  zeroed for new year
             07  Stock-TD-Adds     pic 9(8)   comp. *> binary-long
             07  Stock-TD-Deds     pic 9(8)   comp. *> binary-long
             07  Stock-TD-Wip-Adds pic 9(8)   comp. *> binary-long
             07  Stock-TD-Wip-Deds pic 9(8)   comp. *> binary-long     *> 48 (x4) = 192 == 385
     03  filler                   pic x(15).                          *>400  expansion
*> list
*> copy "wsfnctn.cob".
*>**********************************
*>                                 *
*>  File Access Control Functions  *
*>                                 *
*>**********************************
*>
 01  File-Access.
     03  We-Error        binary-long.
     03  Rrn             binary-long.
     03  Fs-Reply        pic 99.
     03  s1              pic x.   *> not sure this is used so lets rem it out and see
*>     05  s2              pic x.  *> rem'd out MF status
*>    03  stat-bin            redefines fs-reply pic 9(4) comp.
*>    03  disply-stat.
*>     05 s1-displ        pic x.
*>     05 filler          pic xxx.
*>     05 s2-displ        pic 9999.
*>
     03  Curs            pic 9(4).
     03  filler redefines Curs.
         05  Lin         pic 99.
         05  Cole        pic 99.
     03  Curs2           pic 9(4).
     03  filler redefines Curs2.
         05  Lin2        pic 99.
         05  Col2        pic 99.
*>
     03  Fs-Action       pic x(20)  value spaces.
*> current range 1 thru 3
*> 1 = Stock-Key (or only key), 2 = Stock-Abrev-Key, 3 = Stock-Desc
     03  File-Key-No     pic 9.
     03  File-Key        pic x(32).      *> Max size of any key  NOT USED ANY WHERE SO FAR (03/04/12)
     03  SQL-Err         pic x(5).                    *> May not be needed
     03  SQL-Msg         pic x(512) value spaces.     *> May not be needed
     03  Accept-Reply    pic x      value space.
     03  DB-Schema       pic x(12)  value spaces.
     03  DB-UName        pic x(12)  value spaces.
     03  DB-UPass        pic x(12)  value spaces.
*>
*> Block for File/table access via acas000 thru acas033 for IS files and rdbms
*> Also see RDBMS-Flat-Statuses in System-Record
*>
     03  File-Function   pic 9.
         88  fn-open            value 1.
         88  fn-close           value 2.
         88  fn-read-next       value 3.
         88  fn-read-indexed    value 4.
         88  fn-write           value 5.
         88  fn-spare           value 6.
         88  fn-re-write        value 7.
         88  fn-delete          value 8.
         88  fn-start           value 9.
*>
     03  Access-Type     pic 9.                *> For rdbms 2 should cover all !!!
         88  fn-input           value 1.
         88  fn-i-o             value 2.
         88  fn-output          value 3.
         88  fn-extend          value 4.
         88  fn-equal-to        value 5.
         88  fn-less-than       value 6.
         88  fn-greater-than    value 7.
         88  fn-not-less-than   value 8.
         88  fn-not-greater-than value 9.    *> Not currently used (06/04/2012)
*>
*> copy "wsnames.cob".
*>
*> Sales, Purchase, Stock, General
*>    for use in xl150
*>
*>  Files used in Sales, Stock, Purchase, General
*>
 01  file-defs.
     03  pre-trans-name      pic x(532)  value "pretrans.tmp". *> gl071
     03  post-trans-name     pic x(532)  value "postrans.tmp". *> gl071
*> copy "file00.cob".    *> "system"
      03  file-0          pic x(532)      value "system.dat".
*> copy "file02.cob".    *> "archive".
     03  file-2             pic x(532)       value "archive.dat".
*> copy "file03.cob".    *> "final".
     03  file-3         pic x(532)        value "final.dat".
*> copy "file05.cob".    *> "ledger".
     03  file-5         pic x(532)      value "ledger.dat".
*> copy "file06.cob".    *> "posting".
     03  file-6         pic x(532)      value "posting.dat".
*> copy "file07.cob".    *> "batch".
     03  file-7         pic x(532)      value "batch.dat".
*> copy "file09.cob".
      03  file-9        pic x(532)      value "tmp-stock.dat".
*> copy "file10.cob".
      03  file-10         pic x(532)      value "staudit.dat".
*> copy "file11.cob".
      03  file-11         pic x(532)      value "stockctl.dat".
*> copy "file12.cob".
     03  file-12        pic x(532)      value "salesled.dat".
*> copy "file13.cob".    *> "value.dat"
      03  file-13         pic x(532)       value "value.dat".
*> copy "file14.cob".    *> "delivery.dat"
     03  file-14        pic x(532)      value "delivery.dat".
*> copy "file15.cob".    *> "analysis.dat"
      03  file-15         pic x(532)       value "analysis.dat".
*> copy "file16.cob".
      03  file-16            pic x(532)      value "invoice.dat".
*> copy "file17.cob".
      03  file-17            pic x(532)      value "delinvno.dat".
*> copy "file18.cob".
      03  file-18       pic x(532)      value "openitm2.dat".
*> copy "file19.cob".
      03  file-19            pic x(532)      value "openitm3.dat".
*> copy "file20.cob".
      03  file-20            pic x(532)      value "oisort.wrk".
*> copy "file21.cob".    *> work temp file "work
     03  file-21             pic x(532)       value "work.tmp".
*> copy "file22.cob".    *> "purchled"
     03  file-22        pic x(532)      value "purchled.dat".
*> copy "file23.cob".    *> "delfolio.dat"
     03  file-23           pic x(532)    value "delfolio.dat".
*> copy "file26.cob".    *> "pinvoice"
     03  file-26           pic x(532)    value "pinvoice.dat".
*> copy "file27.cob".    *> "poisort"
     03  file-27         pic x(532)       value "poisort.wrk".
*> copy "file28.cob".    *> "openitm4"
     03  file-28         pic x(532)       value "openitm4.dat".
*> copy "file29.cob".    *> "openitm5"
     03  file-29         pic x(532)       value "openitm5.dat".
*> copy "file32.cob".    *> "pay.dat"
     03  file-32        pic x(532)        value "pay.dat".
*> copy "file33.cob".    *> "cheque.dat"
     03  file-33        pic x(532)        value "cheque.dat".
 01  filler         redefines file-defs.
     03  System-File-Names   pic x(532)    occurs 28.
 01  File-Defs-Count         binary-short  value 28.    *> MUST be the same as above occurs
*>
 01  IRS-files.
*> copy "file08.cob".
      03  file-8        pic x(532)       value "postings2irs.dat".
*>
 Procedure Division Using System-Record WS-Stock-Record File-Access File-Defs.
*>***************************************************************************
*>
 aa-Process-Flat-File Section.
*>***************************
 aa010-main.
*>
*> Check if data files or RDBMS processing or are we doing both !!
*>
     move     zero          to We-Error.
*> Save function as will be overwritten by start code but restored after
     move     File-Function to Old-File-Function.
*>
     if       not FS-Cobol-Files-Used
        and   not FS-Duplicate-Processing
              go to ba-Process-RDBMS
     end-if.
*>
*>  File paths for Cobol File has already done in main menu module
*>
*>*******************************************************************************
*>  So we are processing Cobol Flat files, as Dup processing, or by themselves. *
*>    if reading, get it but will be overwritten by rdb processing if set,      *
*>      otherwise will write/rewrite/delete etc, to both formats                *
*>*******************************************************************************
*>
 aa020-Process-Open.
     if       fn-open
     then
      if      fn-input
              open input Stock-File
      else
       if     fn-i-o
              open i-o Stock-File
       else
        if    fn-output
              open output Stock-File
        else
         if   fn-extend                                *> Should not be used for IS (indexed) files
*>              open extend Stock-File
              move 981 to WE-Error                              *> 981 Open acces type wrong for file type: ISAM
              move 99  to fs-reply
              exit program
         end-if
        end-if
       end-if
      end-if
     end-if
*>
     if       fn-open
              move  fs-reply to we-error               *> reply is in both fields and done with Open
              go    to aa999-main-exit
     end-if.
*>
 aa030-Process-Close.
     if       fn-close
              close Stock-File
              go to aa999-main-exit
     end-if.
*>
 aa040-Process-Read-Next.
*>
*>  Process READs, 1st is read next then read by key This is processed after Start code as its really Start/Read next
*>
     if       fn-read-next
              read     Stock-File next record into WS-Stock-Record at end
                       move 10 to we-error fs-reply    *> EOF
              end-read
              move Old-File-Function to File-Function  *> restore original, in case was Start called
              go to aa999-main-exit
     end-if.
*>
 aa050-Process-Read-Indexed.
     if       fn-read-indexed                          *> Check param values in range first
        and   (File-Key-No < 1 or > 3)
              move 997 to we-Error                     *> Invalid calling parameter settings
              move 99  to fs-reply
              exit program
     end-if
*>
*> copy the three possible keys to main file area
*>
     if       fn-read-indexed
              move WS-Stock-Key       to Stock-Key
              move WS-Stock-Abrev-Key to Stock-Abrev-Key
              move WS-Stock-Desc      to Stock-Desc
      if      File-Key-No = 1
              read     Stock-File into WS-Stock-Record
                       key Stock-Key    invalid key
                       move 21 to we-error fs-reply
              end-read
              go       to aa999-main-exit
      end-if
      if      File-Key-No = 2
              read     Stock-File into WS-Stock-Record
                       key Stock-Abrev-Key    invalid key
                       move 21 to we-error fs-reply
              end-read
              go       to aa999-main-exit
      end-if
      if      File-Key-No = 3                           *> can also use start, read next
              read     Stock-File into WS-Stock-Record
                       key Stock-Desc    invalid key
                       move 21 to we-error fs-reply
              end-read
              go       to aa999-main-exit
      end-if
     end-if.
*>
 aa060-Process-Start.
*>
*>  Check for Param error 1st on start
*>
     if       fn-start
        and   (access-type < 5 or > 8)                 *> NOT using 'not >'
              move 998 to WE-Error                     *> Invalid calling parameter settings
              go to aa999-main-exit
     end-if
*>
*>  Now do Start primary key before read-next
*>
     if       fn-start
        and   File-Key-No = 1                          *> primary key
        and   fn-equal-to
              start Stock-File key = Stock-Key invalid key
                    move 21 to Fs-Reply
                    go to aa999-main-exit
              end-start
     end-if
     if       fn-start
        and   File-Key-No = 1                          *> primary key
        and   fn-less-than
              start Stock-File key < Stock-Key invalid key
                    move 21 to Fs-Reply
                    go to aa999-main-exit
              end-start
     end-if
     if       fn-start
        and   File-Key-No = 1                          *> primary key
        and   fn-greater-than
              start Stock-File key > Stock-Key invalid key
                    move 21 to Fs-Reply
                    go to aa999-main-exit
              end-start
     end-if
     if       fn-start
        and   File-Key-No = 1                          *> primary key
        and   fn-not-less-than
              start Stock-File key not < Stock-Key invalid key
                    move 21 to Fs-Reply
                    go to aa999-main-exit
              end-start
     end-if
*>
*>  Now do 1st alternate key (Stock-Abrev-Key) before read-next
*>
     if       fn-start
        and   File-Key-No = 2                          *> Stock-Abrev-Key
        and   fn-equal-to
              start Stock-File key = Stock-Abrev-Key invalid key
                    move 21 to Fs-Reply
                    go to aa999-main-exit
              end-start
     end-if
     if       fn-start
        and   File-Key-No = 2                          *> Stock-Abrev-Key
        and   fn-less-than
              start Stock-File key < Stock-Abrev-Key invalid key
                    move 21 to Fs-Reply
                    go to aa999-main-exit
              end-start
     end-if
     if       fn-start
        and   File-Key-No = 2                          *> Stock-Abrev-Key
        and   fn-greater-than
              start Stock-File key > Stock-Abrev-Key invalid key
                    move 21 to Fs-Reply
                    go to aa999-main-exit
              end-start
     end-if
     if       fn-start
        and   File-Key-No = 2                          *> Stock-Abrev-Key
        and   fn-not-less-than
              start Stock-File key not < Stock-Abrev-Key invalid key
                    move 21 to Fs-Reply
                    go to aa999-main-exit
              end-start
     end-if
*>
*>  Now do 2nd alternate key (Stock-Desc) before read-next
*>
     if       fn-start
        and   File-Key-No = 3                          *> Stock-Desc
        and   fn-equal-to
              start Stock-File key = Stock-Desc invalid key
                    move 21 to Fs-Reply
                    go to aa999-main-exit
              end-start
     end-if
     if       fn-start
        and   File-Key-No = 3                          *> Stock-Desc
        and   fn-less-than
              start Stock-File key < Stock-Desc invalid key
                    move 21 to Fs-Reply
                    go to aa999-main-exit
              end-start
     end-if
     if       fn-start
        and   File-Key-No = 3                          *> Stock-Desc
        and   fn-greater-than
              start Stock-File key > Stock-Desc invalid key
                    move 21 to Fs-Reply
                    go to aa999-main-exit
              end-start
     end-if
     if       fn-start
        and   File-Key-No = 3                          *> Stock-Desc
        and   fn-not-less-than
              start Stock-File key not < Stock-Desc invalid key
                    move 21 to Fs-Reply
                    go to aa999-main-exit
              end-start
     end-if
*>
*> After Start, Now read next
*>
     if       fn-Start
              move  3 to File-Function
              go to aa040-Process-Read-Next
     end-if.
*>
 aa070-Process-Write.
     if       fn-write
              write    Stock-Record from WS-Stock-Record invalid key
                       move 21 to FS-Reply
              end-write
              go       to aa999-main-exit
     end-if.
*>
 aa080-Process-Delete.
     if       fn-delete
              move     WS-Stock-Record to Stock-Record
              delete   Stock-File record invalid key
                       move 21 to FS-Reply
              end-delete
              go       to aa999-main-exit
     end-if.
*>
 aa090-Process-Rewrite.
*>
     if       fn-re-write
              rewrite Stock-Record from WS-Stock-Record invalid key
                      move 21 to FS-Reply
              end-rewrite
              go       to aa999-main-exit
     end-if
*>
*> Houston; We have a problem
*>
     move     999 to WE-Error.
     go       to aa-main-exit.              *> BUG; Don't even try to do rdb as something is seriously wrong
*>
 aa999-main-exit.
     move     FS-Reply to WE-Error.
*>
*> Check for RDB processing ??
*>
     if       FS-Duplicate-Processing
              go to ba-Process-rdbms
     end-if.
*>
 aa-main-exit.
     exit     program.
*>
 ba-Process-RDBMS section.
*>***********************
*>
*>******************************************************************
*>  Here we call the relevent rdbms module for this file or table  *
*>   which will include processing any other joined tables         *
*>******************************************************************
*>
*> set up and do call to DAL ANY ?????
*>
 ba010-Test-WS-Rec-Size.
*>
*>     Test on very first call only  (So do NOT use var A & B again)
*>       Lets test that Data-record size is = or > than declared Rec in DAL
*>          as we can't adjust at compile/run time due to ALL Cobol compilers ?
*>
     if       A = zero             *> so it is being called first time
              move     function Length ( WS-Stock-Record ) to A
              move     function length (
                                        Stock-Record
                                                 ) to B
              if   A < B                   *> COULD LET caller module deal with these errors !!!!!!!
                   move 901 to WE-Error       *> Programming error; temp rec length is wrong caller must stop
                   move 99 to fs-reply
              end-if
      *>
      *>  So first call set up DB info
      *>
              move RDBMS-DB-Name   to DB-Schema
              move RDBMS-User      to DB-UName
              move RDBMS-Passwd    to DB-UPass
     end-if
     if       WE-Error = 901                  *> record length wrong so display error, accept and then stop run.
              move spaces to Display-Blk
              string "Program Error: Temp rec = " delimited by size
                     A                            delimited by size
                     " < "                        delimited by size
                     "Stock-Rec = "               delimited by size
                     B                            delimited by size    into Display-Blk
              display Display-Blk at 2301 with erase eol     *> BUT WILL REMIND ME TO SET IT UP correctly
              display "Note error and hit return" at 2401 with erase eol
              accept Accept-Reply at 2427
              go to ba-rdbms-exit
     end-if



     call     "stockMT" using File-Access
                              WS-Stock-Record
                              DAL-datablock
                              ACAS-DAL-Common-data
     end-call

     if       WE-Error > zero     *> need to check if specific values apply !!!
              go to ba-rdbms-exit.
*>
*>  So all proc done but if reading, we have overwritten record
*>        from Cobol proc if dup access is set
*>

*>
*>   Here any processing to convert SQL errors to regular or not otherwise just exit?
*>

 ba-rdbms-exit.
     exit     program.
*>
*> copy "stockMT.cbl".           *> Do I want to do it this way  ??    So far, NOT
*> end program acas011.

