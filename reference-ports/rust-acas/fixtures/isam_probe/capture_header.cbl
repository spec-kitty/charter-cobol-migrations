identification division.
program-id. capture_header.
environment division.
configuration section.
input-output section.
file-control.
    select invoice-file assign "invoice-capture.dat"
        organization sequential
        status fs-reply.
data division.
file section.
fd invoice-file
    record 134 characters.
01 invoice-record pic x(134).
working-storage section.
01 invoice-header.
    02 ih-prime.
     03 ih-invoice pic 9(8).
     03 ih-letter pic x.
     03 ih-test binary-char.
     03 ih-customer.
         05 ih-nos pic x(6).
         05 ih-check pic 9.
     03 ih-date binary-long.
     03 ih-order pic x(10).
     03 ih-type pic 9.
     03 ih-ref pic x(10).
    02 ih-sub-prime.
     03 ih-description pic x(32).
     03 ih-fig comp-3.
         05 ih-p-c pic s9(7)v99.
         05 ih-net pic s9(7)v99.
         05 ih-extra pic s9(7)v99.
         05 ih-carriage pic s9(7)v99.
         05 ih-vat pic s9(7)v99.
         05 ih-discount pic s9(7)v99.
         05 ih-e-vat pic s9(7)v99.
         05 ih-c-vat pic s9(7)v99.
     03 ih-status pic x.
     03 ih-status-P pic x.
     03 ih-status-L pic x.
     03 ih-status-C pic x.
     03 ih-status-A pic x.
     03 ih-status-I pic x.
     03 ih-lines binary-char.
     03 ih-deduct-days binary-char.
     03 ih-deduct-amt pic 999v99 comp.
     03 ih-deduct-vat pic 999v99 comp.
     03 ih-days binary-char.
     03 ih-cr binary-long.
     03 ih-day-book-flag pic x.
     03 ih-update pic x.
01 line-pad pic x(134).
01 line-record.
    05 il-invoice pic 9(8).
    05 il-letter pic x.
    05 il-line binary-char.
    05 il-product pic x(13).
    05 il-pa pic xx.
    05 il-qty binary-short.
    05 il-type pic x.
    05 il-description pic x(32).
    05 il-net pic s9(7)v99 comp-3.
    05 il-unit pic s9(7)v99 comp-3.
    05 il-discount pic 99v99 comp.
    05 il-vat pic s9(7)v99 comp-3.
    05 il-vat-code pic 9.
    05 il-update pic x.
    05 il-filler pic x.
    05 il-tail pic x(54).
77 fs-reply pic 99.
procedure division.
    open output invoice-file.
    initialize invoice-record.
    move 42 to ih-invoice
    move "L" to ih-letter
    move 0 to ih-test
    move "CUST01" to ih-nos
    move 7 to ih-check
    move 155534 to ih-date
    move "ORDER-0001" to ih-order
    move 1 to ih-type
    move "REF-000001" to ih-ref
    move "abcdefghijklmnopqrstuvwxyz012345" to ih-description
    move 1234.56 to ih-p-c
    move -7654.32 to ih-net
    move 1.00 to ih-extra
    move 2.00 to ih-carriage
    move 3.00 to ih-vat
    move 4.00 to ih-discount
    move 5.00 to ih-e-vat
    move 6.00 to ih-c-vat
    move "P" to ih-status
    move "a" to ih-status-P
    move "b" to ih-status-L
    move "c" to ih-status-C
    move "d" to ih-status-A
    move "e" to ih-status-I
    move 7 to ih-lines
    move 9 to ih-deduct-days
    move 123.45 to ih-deduct-amt
    move 67.89 to ih-deduct-vat
    move 3 to ih-days
    move 155564 to ih-cr
    move "B" to ih-day-book-flag
    move "z" to ih-update
    move invoice-header to invoice-record
    write invoice-record.
*>  second record: line variant, fully populated, laid over the 134-B record
    move all " " to line-record
    move 42 to il-invoice
    move "L" to il-letter
    move 3 to il-line
    move "PRODUCT-00001" to il-product
    move "PA" to il-pa
    move 17 to il-qty
    move "3" to il-type
    move "abcdefghijklmnopqrstuvwxyz012345" to il-description
    move -1234.56 to il-net
    move 9999.99 to il-unit
    move 12.34 to il-discount
    move 56.78 to il-vat
    move 8 to il-vat-code
    move "z" to il-update
    move line-record to invoice-record
    write invoice-record.
    close invoice-file.
    display "header-len=" length of invoice-header
    stop run.
