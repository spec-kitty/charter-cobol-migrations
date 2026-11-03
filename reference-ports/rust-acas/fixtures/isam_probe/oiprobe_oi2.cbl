>>source free
       identification division.
       program-id. oiprobe.
       environment division.
       input-output section.
       file-control.
           select oi2 assign "oi2.dat" organization sequential status fs.
       data division.
       file section.
       fd oi2.
       01 open-item-record-2 pic x(114).
       working-storage section.
       01 fs pic 99.
       01 oi-header.
           02 oi-key.
               03 oi-customer.
                   05 oi-nos pic x(6).
                   05 oi-check pic 9.
               03 oi-invoice binary-long.
           02 filler.
               03 oi-date binary-long.
               03 oi-batch comp.
                   05 oi-b-nos pic 9(5).
                   05 oi-b-item pic 999.
               03 oi-type pic 9.
               03 oi-description pic x(25).
               03 oi-hold-flag pic x.
               03 oi-unapl pic x.
               03 filler comp-3.
                   05 oi-p-c pic s9(7)v99.
                   05 oi-net pic s9(7)v99.
                   05 filler pic s9(7)v99.
                   05 oi-extra pic s9(7)v99.
                   05 oi-carriage pic s9(7)v99.
                   05 oi-vat pic s9(7)v99.
                   05 oi-discount pic s9(7)v99.
                   05 oi-e-vat pic s9(7)v99.
                   05 oi-c-vat pic s9(7)v99.
                   05 oi-paid pic s9(7)v99.
               03 oi-status pic 9.
               03 oi-deduct-days binary-char.
               03 oi-deduct-amt pic s999v99 comp.
               03 oi-deduct-vat pic s999v99 comp.
               03 oi-days binary-char.
               03 oi-cr binary-long.
               03 oi-applied pic x.
               03 oi-date-cleared binary-long.
       procedure division.
           initialize oi-header
           move "CUST01" to oi-nos
           move 7 to oi-check
           move 1001 to oi-invoice
           move 155534 to oi-date
           move 11111 to oi-b-nos
           move 222 to oi-b-item
           move 3 to oi-type
           move "DESC-SENTINEL-0123456789" to oi-description
           move "H" to oi-hold-flag
           move "U" to oi-unapl
           move 1.00 to oi-p-c
           move 2.00 to oi-net
           continue
           move 4.00 to oi-extra
           move 5.00 to oi-carriage
           move 6.00 to oi-vat
           move 7.00 to oi-discount
           move 8.00 to oi-e-vat
           move 9.00 to oi-c-vat
           move 10.00 to oi-paid
           move 1 to oi-status
           move 9 to oi-deduct-days
           move 12.34 to oi-deduct-amt
           move 56.78 to oi-deduct-vat
           move 7 to oi-days
           move 155564 to oi-cr
           move "A" to oi-applied
           move 155594 to oi-date-cleared
           open output oi2
           move oi-header to open-item-record-2
           write open-item-record-2
           close oi2
           stop run.
