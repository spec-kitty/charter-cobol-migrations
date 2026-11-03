>>source free
*>*****************************************************************
*>  loadinv — copy the flat fixture invoice stream into a BDB indexed
*>  invoice file (key = invoice-nos, invoice-let, item-nos), so the
*>  COBOL side sees the same rows the Rust side reads from the flat
*>  fixture. Order is preserved (the fixture is already in key order).
*>*****************************************************************
       identification division.
       program-id. loadinv.
       environment division.
       input-output section.
       file-control.
           select flat-file assign "invoice.flat"
               organization sequential status fs-reply.
           select invoice-file assign "invoice.dat"
               organization indexed access dynamic status fs-reply
               record key invoice-key.
       data division.
       file section.
       fd flat-file.
       01 flat-record.
           05 flat-key.
               07 flat-nos  pic 9(8).
               07 flat-let  pic x.
               07 flat-item pic x.
           05 filler pic x(124).
       fd invoice-file.
       01 invoice-record.
           05 invoice-key.
               07 invoice-nos pic 9(8).
               07 invoice-let pic x.
               07 item-nos    pic x.
           05 filler pic x(124).
       working-storage section.
       01 fs-reply pic 99.
       procedure division.
           open input flat-file
           open output invoice-file
           perform until fs-reply not = zero
               read flat-file next record at end exit perform end-read
               if fs-reply = zero
                   move flat-record to invoice-record
                   write invoice-record
                   if fs-reply not = zero
                       display "loadinv write fs=" fs-reply
                   end-if
               end-if
           end-perform
           close flat-file invoice-file
           stop run.
