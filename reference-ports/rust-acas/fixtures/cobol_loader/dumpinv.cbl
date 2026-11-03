>>source free
*>  dumpinv — read the INDEXED invoice file in key order and emit the raw
*>  134-byte records to a flat stream (F-B007). Used to check that loadinv
*>  reproduced the fixture bytes, and to capture sl055's rewrites.
       identification division.
       program-id. dumpinv.
       environment division.
       input-output section.
       file-control.
           select invoice-file assign "invoice.dat"
               organization indexed access sequential status fs-reply
               record key invoice-key.
           select flat-file assign "invoice.flat"
               organization sequential status fs-out.
       data division.
       file section.
       fd invoice-file.
       01 invoice-record.
           05 invoice-key.
               07 invoice-nos pic 9(8).
               07 invoice-let pic x.
               07 item-nos    pic x.
           05 filler pic x(124).
       fd flat-file.
       01 flat-record pic x(134).
       working-storage section.
       01 fs-reply pic 99.
       01 fs-out pic 99.
       procedure division.
           open input invoice-file
           open output flat-file
           perform until fs-reply not = zero
               read invoice-file next record at end exit perform end-read
               if fs-reply = zero
                   move invoice-record to flat-record
                   write flat-record
               end-if
           end-perform
           close invoice-file flat-file
           stop run.
