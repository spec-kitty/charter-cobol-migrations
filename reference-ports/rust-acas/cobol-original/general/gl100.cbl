       >>source free
*>*****************************************************************
*>                                                                *
*>           L E D G E R  P R I N T  P R E - S O R T              *
*>                                                                *
*>*****************************************************************
*> WARNING THIS uses ARCHIVING FROM a path that has a Usb memory stick
*>    or a specific directory (in which case it is up to the user
*>    to ensure that that directory is copied to a suitable medium)
*>    after processing.
*>********************************************************************
 identification          division.
*>===============================
*>
*>**
      program-id.         gl100.
*>**
*>    Author.             V.B.Coen, FBCS,
*>                        Converted For Cis January 85,
*>                        For Applewood Compuers.
*>**
*>    Security.           Copyright (C) 1976-2013, Vincent Bryan Coen.
*>                        Distributed under the GNU General Public License
*>                        v2.0. Only. See the file COPYING for details.
*>**
*>    Remarks.            Ledger Print - Pre-Sort.
*>**
*>    Version.            See Prog-Name In Ws.
*>**
*>    Called Modules.     None
*>**
*>    Error messages used.
*>                        GL114
*>                        GL115
*>**
*>  Changes:
*> 28/01/09 vbc - Migration to Open Cobol.
*> 21/12/11 vbc - .01 Support for dates other than UK & clean up msgs
*>                    Error msgs to GLnnn,
*>                    Support for path+filenames.
*>
*> NOTE TESTING Code in the  disk-change  section
*> ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
*>
*>*************************************************************************
*>
*> Copyright Notice.
*>*****************
*>
*> This file/program is part of the Applewood Computers Accounting System
*>   and is copyright (c) Vincent B Coen. 1976 - 2013 and later.
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
     select  archive    assign  file-2
                        access  sequential
                        status  fs-reply
                        organization  line sequential.
*>
     select  arch-out   assign  arc-out-name
                        access  sequential
                        status  fs-reply
                        organization  line sequential.
*>
     select  sort-file  assign file-21.
*>
 data                    division.
*>===============================
*>
 file section.
*>-----------
*>
 fd  archive.
*>
 01  arc-trans-record.
   03  arc-batch         pic 9(5).
   03  arc-post          pic 9(5).
   03  arc-code          pic xx.
   03  arc-date          pic x(8).
   03  arc-ac            pic 9(6).
   03  arc-pc            pic 99.
   03  arc-amount        pic s9(8)v99.
   03  arc-legend        pic x(32).
   03  arc-c-ac          pic 9(6).
   03  arc-c-pc          pic 99.
*>
 fd  arch-out.
*>
 01  arc-trans-out.
   03  out-batch         pic 9(5).
   03  out-post          pic 9(5).
   03  out-code          pic xx.
   03  out-date          pic x(8).
   03  out-ac            pic 9(6).
   03  out-pc            pic 99.
   03  out-amount        pic s9(8)v99.
   03  out-legend        pic x(32).
   03  out-c-ac          pic 9(6).
   03  out-c-pc          pic 99.
*>
 sd  sort-file.
*>
 01  srt-trans-srt.
   03  srt-batch         pic 9(5).
   03  srt-post          pic 9(5).
   03  srt-code          pic xx.
   03  srt-date          pic x(8).
   03  srt-ac            pic 9(6).
   03  srt-pc            pic 99.
   03  srt-amount        pic s9(8)v99.
   03  srt-legend        pic x(32).
   03  srt-c-ac          pic 9(6).
   03  srt-c-pc          pic 99.
*>
 working-storage section.
*>----------------------
*>
 77  prog-name           pic x(15)       value "gl100 (3.00.01)".
 77  a                   pic 9           value zero.
 77  keyed-reply         pic x      value space.
 77  ws-eval-msg         pic x(25)  value spaces.
*>
 01  Arg-Test            pic x(525)   value spaces.
*> 01  filler.
*> copy "file02.cob".    *>     value "archive.dat".
*>
 01  arc-out-name        pic x(532)       value "workarc.tmp".
*>
 01  Error-Messages.
*> System Wide
*>    03  GL010           pic x(16) value "GL010 Hit Return".
*>    03  GL011           pic x(25) value "GL011 Note and hit Return".
*> Module specific
    03  GL114           pic x(70) value "GL114 Enter <0> to signify change made or <9> to abort this run :- [ ]".
    03  GL115           pic x(48) value "GL115 Ensure Archive USB Memory Stick is in path".
*>
 copy "wsfnctn.cob".
*>
 linkage section.
*>**************
*>
 copy "wscall.cob".
 copy "wssystem.cob".
 copy "wsnames.cob".
*>
 77  to-day              pic x(10).
*>
 procedure division using ws-calling-data system-record to-day file-defs.
*>======================================================================
*>
 gl100 section.
     display  prog-name at 0101 with foreground-color 2 erase eos.
     display  "Ledger Print - Sort" at 0131  with foreground-color 2.
*>
     perform  disk-change.
     if       a  equal  9   *> abort procedure
              move 5 to ws-term-code
              go to menu-exit.
*>
     open     input archive.
     if       fs-reply not = zero
              move 4 to ws-term-code
              go to menu-exit.
     close    archive.
*>
     sort     sort-file
              on ascending key  srt-ac
                                srt-pc
                                srt-batch
                                srt-post
              using   archive
              giving  arch-out.
*>
 menu-exit.
     exit     program.
*>
 disk-change  section.
*>-------------------
*>     Copied from gl080
*>     *****************
*>
*> Build path for archive file/s
*>    this set up for testing but need to change to accept
*>     path to usb memory stick (full path) but will work as is
*>       assuming users changes path and the system KNOWS about
*>         the memory stick
*>
     move     space to Arg-Test.             *> this lot needs checking !!!!!
     string   file-24        delimited by space
              "archives"     delimited by size
              file-defs-os-delimiter
                             delimited by size
                file-2      delimited by space
                            into Arg-Test.
     move     Arg-Test to file-2.
*>
*>  This is for the temp file used by gl105 (the Ledger Print)
*>
     move     space to Arg-Test.
     string   file-24        delimited by space
              "archives"     delimited by size
              file-defs-os-delimiter
                             delimited by size
              arc-out-name   delimited by space
                            into Arg-Test.
     move     Arg-Test to arc-out-name.
*>
     display  GL115 at 1201 with erase eol foreground-color 2.
     display  Gl114 at 1301 with erase eol foreground-color 2.
*>
 accept-option.
     accept   a at 1369.
     if       a = 9
              go to  main-exit.
     if       a  not = zero
              go to  accept-option.
*>
*>  Hopefully can remove these after testing
*>
     display  "Current path/name is :" at 1401 with foreground-color 2 erase eol.
*>     display  file-2             at 1501 with foreground-color 2 erase eol.
     accept   file-2             at 1501 with foreground-color 2 update.
     if       file-2 (1:1) = space
              go to accept-option.
*>
 main-exit.   exit.
*>********    ****
