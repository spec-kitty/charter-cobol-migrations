>>source free
*>  dumpbatch — emit the INDEXED batch rows in key order.
       identification division.
       program-id. dumpbatch.
       environment division.
       input-output section.
       file-control.
           select batch-file assign "batch.dat"
               organization indexed access sequential status fs-reply
               record key batch-key.
           select flat-file assign "batch.flat"
               organization sequential status fs-out.
       data division.
       file section.
       fd batch-file.
       01 batch-record.
           05 batch-key.
               07 ledger pic 9.
               07 batch-nos pic 9(5).
           05 filler pic x(90).
       fd flat-file.
       01 flat-record pic x(96).
       working-storage section.
       01 fs-reply pic 99.
       01 fs-out pic 99.
       procedure division.
           open input batch-file
           open output flat-file
           perform until fs-reply not = zero
               read batch-file next record at end exit perform end-read
               if fs-reply = zero
                   move batch-record to flat-record
                   write flat-record
               end-if
           end-perform
           close batch-file flat-file
           stop run.
