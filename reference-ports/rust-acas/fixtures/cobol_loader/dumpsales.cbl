>>source free
*>  dumpsales — emit the INDEXED sales rows in key order as a flat stream.
       identification division.
       program-id. dumpsales.
       environment division.
       input-output section.
       file-control.
           select sales-file assign "salesled.dat"
               organization indexed access sequential status fs-reply
               record key sales-key.
           select flat-file assign "salesled.flat"
               organization sequential status fs-out.
       data division.
       file section.
       fd sales-file.
       01 sales-record.
           05 sales-key pic x(7).
           05 filler pic x(293).
       fd flat-file.
       01 flat-record pic x(300).
       working-storage section.
       01 fs-reply pic 99.
       01 fs-out pic 99.
       procedure division.
           open input sales-file
           open output flat-file
           perform until fs-reply not = zero
               read sales-file next record at end exit perform end-read
               if fs-reply = zero
                   move sales-record to flat-record
                   write flat-record
               end-if
           end-perform
           close sales-file flat-file
           stop run.
