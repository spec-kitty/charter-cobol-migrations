>>source free
*>*****************************************************************
*>  mkidx — create EMPTY indexed ACAS table files.
*>  Fixture .dat files are authored as flat frames; ACAS opens
*>  value/analysis/invoice as ORGANIZATION INDEXED, so the bytes must
*>  be BDB-born. This program lets COBOL mint the empty tables.
*>
*>  argv/env: file names come from the caller's assignment
*>  (VALUE.DAT / ANALYSIS.DAT / INVOICE.DAT in cwd).
*>*****************************************************************
       identification division.
       program-id. mkidx.
       environment division.
       input-output section.
       file-control.
           select value-file assign "value.dat"
               organization indexed access dynamic status fs-reply
               record key va-code.
           select analysis-file assign "analysis.dat"
               organization indexed access dynamic status fs-reply
               record key pa-code.
           select invoice-file assign "invoice.dat"
               organization indexed access dynamic status fs-reply
               record key invoice-key.
       data division.
       file section.
       fd value-file.
       01 value-record.
           05 va-code.
               07 va-system pic x.
               07 va-group.
                   09 va-first  pic x.
                   09 va-second pic x.
           05 filler pic x(63).
       fd analysis-file.
       01 analysis-record.
           05 pa-code.
               07 pa-system pic x.
               07 pa-group.
                   09 pa-first  pic x.
                   09 pa-second pic x.
           05 filler pic x(33).
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
           open output value-file
           close value-file
           open output analysis-file
           close analysis-file
           open output invoice-file
           close invoice-file
           stop run.
