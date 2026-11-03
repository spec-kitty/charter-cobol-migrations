>>source free
*>*****************************************************************
*>  dumpval — read the INDEXED value file in key order and emit the
*>  raw 66-byte records to a flat stream, so the file's logical
*>  contents (not its BDB page framing) can be hashed and compared
*>  against the Rust extract's output.
*>*****************************************************************
       identification division.
       program-id. dumpval.
       environment division.
       input-output section.
       file-control.
           select value-file assign "value.dat"
               organization indexed access sequential status fs-reply
               record key va-code.
           select flat-file assign "value.flat"
               organization sequential status fs-out.
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
       fd flat-file.
       01 flat-record pic x(66).
       working-storage section.
       01 fs-reply pic 99.
       01 fs-out pic 99.
       procedure division.
           open input value-file
           open output flat-file
           perform until fs-reply not = zero
               read value-file next record at end exit perform end-read
               if fs-reply = zero
                   move value-record to flat-record
                   write flat-record
               end-if
           end-perform
           close value-file flat-file
           stop run.
