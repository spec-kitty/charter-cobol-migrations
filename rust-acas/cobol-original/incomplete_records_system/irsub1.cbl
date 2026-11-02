       >>source free
*>***********************************
*>                                  *
*>   Nominal Ledger File Handler    *
*>                                  *
*>***********************************
*>
 identification division.
 program-id.            irsub1.
*>
*>author.               Cobol conversion by Vincent B Coen
*>                      for Applewood Computers.
*>
*>Security.             Copyright (C) 1982-2013, Vincent Bryan Coen.
*>                      Distributed under the GNU General Public License
*>                      v2.0. Only. See the file COPYING for details.
*>
*>remarks.              Nominal Ledger File Handler.
*>
*>version.              2.00 20/07/1983.
*>                      2.01 15/01/2009
*>                      2.02 04/05/2013
*>Changes.
*> 22/01/09 vbc - Migration to Open Cobol.
*> 04/05/13 vbc - 2.02 Added in Next-3: move nl-Owning to nl-Sub-Nominal as Do not know why this was missed out
*>
*>Operation.
*> When writing records, both owning and sub nominal are written out as type "O"
*> AND another record is written with pointer = owning, owning = sub-nominal & sub-nominal = 0.
*> However it does offer a search capability on just the sub nominal key without reference
*>  to the owning account and this is usefull when posting.
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
 environment division.
 copy "envdiv.cob".
*>
 input-output section.
 file-control.
*>
*> copy "irs-nl.CBS".
     select nominal-ledger  assign       nl-file
                            organization indexed
                            access       dynamic
                            record       key-1
                            status       fs-reply.
*>
 data division.
 file section.
*>
*> copy "irs-nl.CBF".
 fd  nominal-ledger
     label records standard.
 copy "fdwsnl.cob".
 working-storage section.
*>
 01  xx-reply            pic x.
 copy "wsfsrply.cob".
*>
 01  nl-file             pic x(14).
 linkage section.
*>
 copy "wsnl.cob".
 copy  "wsfnctn.cob".
 procedure division  using  nl-record  file-access.
*>************************************************
*>
 main.
*>---
*>
     move     zero to we-error.
     move     file-1 to nl-file.
     if       not fn-open
              go to next-1.
*>
     if       fn-input
              open input nominal-ledger.
     if       fn-i-o
              open i-o nominal-ledger.
     if       fn-output
              open output nominal-ledger.
     if       fs-reply9 not = zero
              display "Failure to Open Nominal-Ledger" at 2401 with foreground-color 4
              perform display-file-error
              move 1 to we-error.
     go       to main-exit.
*>
 next-1.
*>-----
     if       fn-close
              close nominal-ledger
              go to main-exit.
     if       not fn-read-indexed
              go to next-2.
*>
 retry-1.
*>------
*>
*> if retrieve record by key set up for Owning or Sub-Nominal pointer record
*>
     move     nl-key to key-1.
     read     nominal-ledger invalid
              move 2 to we-error
              go to main-exit.
     move     record-1 to nl-record.
*>
*> Pointer has been read
*>
     if       sub
              move nl-owning  to nl-sub-nominal
              move nl-pointer to nl-owning
              go to retry-1.
     go       to main-exit.
*>
 next-2.
*>-----
*>
     if       not fn-read-next
              go to next-3.
*>
 retry-2.
*>------
*>
*> Read next record ignoring Sub-Nominal Pointers
*>
     read     nominal-ledger next record at end
              move 3 to we-error
              go to main-exit.
     move     record-1 to nl-record.
*>
*> test to see if pointer record
*>
     if       sub
              go to retry-2.
     go       to main-exit.
*>
 next-3.
*>-----
*>
*>  WRITE:  Add record to file. Sub-Nominals require two additions.
*>
     if       not fn-write
              go to next-4.
     move     nl-record to record-1.
     write    record-1 invalid
              display "Link/record exists on owning write" at 2401 with foreground-color 4
              accept xx-reply at 2438.    *> TESTING
*>  display nl-record (1:16) upon syserr.
     if       owner
              go to main-exit.
*>
*> Extra processing for sub-nominal.
*>
     move     "O" to nl-type.
     move     nl-record to record-1.
     rewrite  record-1 invalid
              display "Link/record exists on rewrite" at 2401 with foreground-color 4
              accept xx-reply at 2432.    *> TESTING
*>  display nl-record (1:16) upon syserr.
*>
     move     nl-owning      to nl-pointer.
     move     nl-sub-nominal to nl-owning.
     move     zero           to nl-sub-nominal.
     move     "S"            to nl-type.
     move     nl-record to record-1.
     write    record-1 invalid
              display "link/record exists on sub write" at 2401 with foreground-color 4
              accept xx-reply at 2435.    *> TESTING
*>  display nl-record (1:16) upon syserr.
     move     nl-Owning  to nl-Sub-Nominal.   *> Do not know why this was missed out
     move     nl-pointer to nl-owning.        *>  but restored incase used by caller
     go to    main-exit.
*>
 next-4.
*>-----
*>
     if       not fn-delete
              go to next-5.
*>
*> Delete record and pointer if neccessary
*>
     delete   nominal-ledger record.
*>
     if       owner
              go to    main-exit.
*>
*> Delete the pointer
*>
     move     nl-sub-nominal to nl-owning.
     move     zero           to nl-sub-nominal.
     move     nl-key         to key-1.
     delete   nominal-ledger record.
     go       to main-exit.
*>
 next-5.
*>-----
*>
     if       not fn-re-write
              go to next-6.
*>
*> update the record on disk
*>
     move     nl-record to record-1.
     rewrite  record-1.
     go       to main-exit.
*>
 next-6.
*>-----
*>
*> start and read next.
*>
     move     nl-key to key-1.
     move     zero to sub-nominal.
     if       not fn-equal-to
              go to jump-1.
     start    nominal-ledger key = key-1 invalid key
              move 2 to we-error
              go to main-exit.
*>
 jump-1.
*>-----
*>
     if       not fn-less-than
              go to jump-2.
     start    nominal-ledger key not < key-1  invalid key
              move 2 to we-error
              go to main-exit.
*>
 jump-2.
*>-----
*>
     if       not fn-greater-than
              go to jump-3.
     start    nominal-ledger key > key-1  invalid key
              move 2 to we-error
              go to main-exit.
*>
*> Go back and read next record.
*>
 jump-3.
*>-----
*>
     go       to retry-2.
*>
 copy "fsdispfe.cob".
*>
 main-exit.
     exit     program.
