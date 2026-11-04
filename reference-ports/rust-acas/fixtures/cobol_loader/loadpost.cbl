>>source free
*>  loadpost — stream flat 98-byte posting rows into the RELATIVE file in RRN
*>  order; the record number is written before each WRITE (F-B009 Part 3).
       identification division.
       program-id. loadpost.
       environment division.
       input-output section.
       file-control.
           select post-file assign "posting.dat"
               organization relative access sequential status fs-reply
               relative key rrn.
           select flat-file assign "posting.flat"
               organization sequential status fs-out.
       data division.
       file section.
       fd post-file.
       01 post-record pic x(98).
       fd flat-file.
       01 flat-record pic x(98).
       working-storage section.
       01 rrn pic 9(5) comp-5.
       01 fs-reply pic 99.
       01 fs-out pic 99.
       procedure division.
           open output post-file
           open input flat-file
           perform until fs-out not = zero
               read flat-file at end exit perform end-read
               add 1 to rrn
               move flat-record to post-record
               write post-record
           end-perform
           close post-file flat-file
           stop run.
