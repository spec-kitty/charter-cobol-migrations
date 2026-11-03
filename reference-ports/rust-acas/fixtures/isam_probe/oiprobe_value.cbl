>>source free
       identification division.
       program-id. valprobe.
       environment division.
       input-output section.
       file-control.
           select vf assign "v.dat" organization sequential status fs.
       data division.
       file section.
       fd vf.
       01 value-record pic x(66).
       working-storage section.
       01 fs pic 99.
       01 value-record-2.
           03 va-code.
               05 va-system pic x.
               05 va-group.
                   07 va-first pic x.
                   07 va-second pic x.
           03 va-gl pic 9(6).
           03 va-desc pic x(24).
           03 va-print pic xxx.
           03 va-t-this pic 9(5) comp.
           03 va-t-last pic 9(5) comp.
           03 va-t-year pic 9(5) comp.
           03 va-v-this pic s9(8)v99 comp-3.
           03 va-v-last pic s9(8)v99 comp-3.
           03 va-v-year pic s9(8)v99 comp-3.
       procedure division.
           initialize value-record-2
           move "S" to va-system
           move "ABC" to va-group
           move 123456 to va-gl
           move "DESC-SENTINEL-0123456789" to va-desc
           move "PRT" to va-print
           move 11111 to va-t-this
           move 22222 to va-t-last
           move 33333 to va-t-year
           move 1234567890.12 to va-v-this
           move -1234567890.12 to va-v-last
           move 9999999999.99 to va-v-year
           open output vf
           move value-record-2 to value-record
           write value-record
           close vf
           stop run.
