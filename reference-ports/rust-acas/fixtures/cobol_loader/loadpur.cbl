>>source free
*>  loadpur — stream flat 300-byte supplier rows into the INDEXED
*>  purchase file. Rows must already be in key order (DP-020).
       identification division.
       program-id. loadpur.
       environment division.
       input-output section.
       file-control.
           select purchase-file assign "purchled.dat"
               organization indexed access sequential status fs-reply
               record key purch-key.
           select flat-file assign "purchase.flat"
               organization sequential status fs-out.
       data division.
       file section.
       fd purchase-file.
       01 purchase-record.
           05 purch-key pic x(7).
           05 filler pic x(293).
       fd flat-file.
       01 flat-record pic x(300).
       working-storage section.
       01 fs-reply pic 99.
       01 fs-out pic 99.
       procedure division.
           open output purchase-file
           open input flat-file
           perform until fs-out not = zero
               read flat-file at end exit perform end-read
               move flat-record to purchase-record
               write purchase-record
           end-perform
           close purchase-file flat-file
           stop run.
