>>source free
*>  dumppost — emit the RELATIVE posting file as a flat stream in RRN order.
       identification division.
       program-id. dumppost.
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
       01 rrn pic 9(5).
       01 fs-reply pic 99.
       01 fs-out pic 99.
       procedure division.
           open input post-file
           open output flat-file
           perform until fs-reply not = zero
               read post-file next record at end exit perform end-read
               if fs-reply = zero
                   move post-record to flat-record
                   write flat-record
               end-if
           end-perform
           close post-file flat-file
           stop run.
