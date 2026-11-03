>>source free
*>  loadsal — stream flat 300-byte sales rows into the INDEXED sales file.
       identification division.
       program-id. loadsal.
       environment division.
       input-output section.
       file-control.
           select sales-file assign "salesled.dat"
               organization indexed access sequential status fs-reply
               record key sales-key.
           select flat-file assign "sales.flat"
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
           open output sales-file
           open input flat-file
           perform until fs-out not = zero
               read flat-file at end exit perform end-read
               move flat-record to sales-record
               write sales-record
           end-perform
           close sales-file flat-file
           stop run.
