>>source free
*>  loadpinv — stream flat 129-byte purchase-invoice frames into the
*>  INDEXED pinvoice file. Headers are the item-nos-0 rows; the key is
*>  (invoice-nos, item-nos). Rows must already be in key order.
       identification division.
       program-id. loadpinv.
       environment division.
       input-output section.
       file-control.
           select invoice-file assign "pinvoice.dat"
               organization indexed access sequential status fs-reply
               record key invoice-key.
           select flat-file assign "pinvoice.flat"
               organization sequential status fs-out.
       data division.
       file section.
       fd invoice-file.
       01 invoice-record.
           05 invoice-key.
               07 invoice-nos pic 9(8).
               07 item-nos    pic x.
           05 filler pic x(120).
       fd flat-file.
       01 flat-record pic x(129).
       working-storage section.
       01 fs-reply pic 99.
       01 fs-out pic 99.
       procedure division.
           open output invoice-file
           open input flat-file
           perform until fs-out not = zero
               read flat-file at end exit perform end-read
               move flat-record to invoice-record
               write invoice-record
               if fs-reply not = zero
                   display "loadpinv write fs=" fs-reply
               end-if
           end-perform
           close invoice-file flat-file
           stop run.
