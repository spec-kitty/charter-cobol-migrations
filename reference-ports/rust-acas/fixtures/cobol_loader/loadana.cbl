>>source free
*>*****************************************************************
*>  loadana — stream the flat fixture analysis rows into a BDB indexed
*>  analysis file. Counterpart of loadinv; see F-B007.
*>*****************************************************************
       identification division.
       program-id. loadana.
       environment division.
       input-output section.
       file-control.
           select flat-file assign "analysis.flat"
               organization sequential status fs-reply.
           select analysis-file assign "analysis.dat"
               organization indexed access dynamic status fs-reply
               record key pa-code.
       data division.
       file section.
       fd flat-file.
       01 flat-record.
           05 flat-code pic x(3).
           05 filler pic x(33).
       fd analysis-file.
       01 analysis-record.
           05 pa-code.
               07 pa-system pic x.
               07 pa-group.
                   09 pa-first  pic x.
                   09 pa-second pic x.
           05 filler pic x(33).
       working-storage section.
       01 fs-reply pic 99.
       procedure division.
           open input flat-file
           open output analysis-file
           perform until fs-reply not = zero
               read flat-file next record at end exit perform end-read
               if fs-reply = zero
                   move flat-record to analysis-record
                   write analysis-record
               end-if
           end-perform
           close flat-file analysis-file
           stop run.
