>>source free
*>  dumpledger — emit the INDEXED ledger rows in key order.
       identification division.
       program-id. dumpledger.
       environment division.
       input-output section.
       file-control.
           select ledger-file assign "ledger.dat"
               organization indexed access sequential status fs-reply
               record key ledger-key.
           select flat-file assign "ledger.flat"
               organization sequential status fs-out.
       data division.
       file section.
       fd ledger-file.
       01 ledger-record.
           05 ledger-key.
               07 ledger-nos pic 9(6).
               07 ledger-pc pic 9(2).
           05 filler pic x(118).
       fd flat-file.
       01 flat-record pic x(126).
       working-storage section.
       01 fs-reply pic 99.
       01 fs-out pic 99.
       procedure division.
           open input ledger-file
           open output flat-file
           perform until fs-reply not = zero
               read ledger-file next record at end exit perform end-read
               if fs-reply = zero
                   move ledger-record to flat-record
                   write flat-record
               end-if
           end-perform
           close ledger-file flat-file
           stop run.
