>>source free
*>*****************************************************************
*>  mkpldx — mint EMPTY indexed purchase-ledger tables.
*>  Same reason as mkidx (F-B007): the purchase file and its invoice
*>  file are ORGANIZATION INDEXED, so the bytes must be BDB-born.
*>  Kept separate from mkidx because the purchase invoice FD is 129
*>  bytes, not the sales 134, and BDB folds the length into the
*>  attribute block.
*>*****************************************************************
       identification division.
       program-id. mkpldx.
       environment division.
       input-output section.
       file-control.
           select purchase-file assign "purchled.dat"
               organization indexed access dynamic status fs-reply
               record key purch-key.
           select invoice-file assign "pinvoice.dat"
               organization indexed access dynamic status fs-reply
               record key invoice-key.
       data division.
       file section.
       fd purchase-file.
       01 purchase-record.
           05 purch-key pic x(7).
           05 filler pic x(293).
       fd invoice-file.
       01 invoice-record.
           05 invoice-key.
               07 invoice-nos pic 9(8).
               07 item-nos    pic x.
           05 filler pic x(120).
       working-storage section.
       01 fs-reply pic 99.
       procedure division.
           open output purchase-file
           close purchase-file
           open output invoice-file
           close invoice-file
           stop run.
