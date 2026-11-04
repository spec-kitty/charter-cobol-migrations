>>source free
*>  loadledger — stream flat 126-byte ledger rows into the INDEXED table.
       identification division.
       program-id. loadledger.
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
           open output ledger-file
           open input flat-file
           perform until fs-out not = zero
               read flat-file at end exit perform end-read
               move flat-record to ledger-record
               write ledger-record
           end-perform
           close ledger-file flat-file
           stop run.
