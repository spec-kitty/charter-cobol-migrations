*>noprint
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
 copy "envdiv.cob".
*>
 input-output section.
 file-control.
*>
*> copy "stock.CBS".
 copy "selstock.cob". *> in "../stock".
 data division.
 file section.
*>***********
*> copy "stock.CBF".
 copy "fdstock.cob". *> in "../stock".
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
 copy "wssystem.cob".
*> nolist
 copy "wsstock.cob".
*> list
 copy "wsfnctn.cob".
 copy "wsnames.cob".
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

