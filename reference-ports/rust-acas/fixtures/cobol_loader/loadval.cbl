>>source free
*>*****************************************************************
*>  loadval — stream the flat fixture value rows into a BDB indexed
*>  value file. Counterpart of loadinv; see F-B007.
*>*****************************************************************
       identification division.
       program-id. loadval.
       environment division.
       input-output section.
       file-control.
           select flat-file assign "value.flat"
               organization sequential status fs-reply.
           select value-file assign "value.dat"
               organization indexed access dynamic status fs-reply
               record key va-code.
       data division.
       file section.
       fd flat-file.
       01 flat-record.
           05 flat-code pic x(3).
           05 filler pic x(63).
       fd value-file.
       01 value-record.
           05 va-code.
               07 va-system pic x.
               07 va-group.
                   09 va-first  pic x.
                   09 va-second pic x.
           05 filler pic x(63).
       working-storage section.
       01 fs-reply pic 99.
       procedure division.
           open input flat-file
           open output value-file
           perform until fs-reply not = zero
               read flat-file next record at end exit perform end-read
               if fs-reply = zero
                   move flat-record to value-record
                   write value-record
               end-if
           end-perform
           close flat-file value-file
           stop run.
