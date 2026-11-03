>>source free
*>  loaddel — stream flat 134-byte delivery rows into the INDEXED delivery file.
       identification division.
       program-id. loaddel.
       environment division.
       input-output section.
       file-control.
           select delivery-file assign "delivery.dat"
               organization indexed access sequential status fs-reply
               record key deliv-key.
           select flat-file assign "delivery.flat"
               organization sequential status fs-out.
       data division.
       file section.
       fd delivery-file.
       01 delivery-record.
           05 deliv-key.
               07 deliv-key-type   pic x.
               07 deliv-sales-key  pic x(7).
           05 filler pic x(126).
       fd flat-file.
       01 flat-record pic x(134).
       working-storage section.
       01 fs-reply pic 99.
       01 fs-out pic 99.
       procedure division.
           open output delivery-file
           open input flat-file
           perform until fs-out not = zero
               read flat-file at end exit perform end-read
               move flat-record to delivery-record
               write delivery-record
           end-perform
           close delivery-file flat-file
           stop run.
