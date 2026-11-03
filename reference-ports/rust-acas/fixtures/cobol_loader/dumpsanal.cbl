>>source free
*>*****************************************************************
*>  dumpsanal — read the INDEXED analysis file in key order and emit
*>  the raw 36-byte records to a flat stream (F-B007).
*>*****************************************************************
       identification division.
       program-id. dumpsanal.
       environment division.
       input-output section.
       file-control.
           select analysis-file assign "analysis.dat"
               organization indexed access sequential status fs-reply
               record key pa-code.
           select flat-file assign "analysis.flat"
               organization sequential status fs-out.
       data division.
       file section.
       fd analysis-file.
       01 analysis-record.
           05 pa-code.
               07 pa-system pic x.
               07 pa-group.
                   09 pa-first  pic x.
                   09 pa-second pic x.
           05 filler pic x(33).
       fd flat-file.
       01 flat-record pic x(36).
       working-storage section.
       01 fs-reply pic 99.
       01 fs-out pic 99.
       procedure division.
           open input analysis-file
           open output flat-file
           perform until fs-reply not = zero
               read analysis-file next record at end exit perform end-read
               if fs-reply = zero
                   move analysis-record to flat-record
                   write flat-record
               end-if
           end-perform
           close analysis-file flat-file
           stop run.
