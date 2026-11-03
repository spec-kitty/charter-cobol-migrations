>>source free
*>  dumpoi3 — emit the INDEXED open-item-3 rows in key order.
       identification division.
       program-id. dumpoi3.
       environment division.
       input-output section.
       file-control.
           select oi3-file assign "openitm3.dat"
               organization indexed access sequential status fs-reply
               record key oi3-key.
           select flat-file assign "openitm3.flat"
               organization sequential status fs-out.
       data division.
       file section.
       fd oi3-file.
       01 oi3-record.
           05 oi3-key.
               07 oi3-customer pic x(7).
               07 oi3-invoice  binary-long.
           05 filler pic x(103).
       fd flat-file.
       01 flat-record pic x(114).
       working-storage section.
       01 fs-reply pic 99.
       01 fs-out pic 99.
       procedure division.
           open input oi3-file
           open output flat-file
           perform until fs-reply not = zero
               read oi3-file next record at end exit perform end-read
               if fs-reply = zero
                   move oi3-record to flat-record
                   write flat-record
               end-if
           end-perform
           close oi3-file flat-file
           stop run.
