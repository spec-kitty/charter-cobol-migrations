*> Standalone line-overlay probe: fills every il-* field with a sentinel and
*> writes one 80-byte line into a 134-byte frame. See F-B006.

identification division.
program-id. probel.
environment division.
configuration section.
input-output section.
file-control.
    select invoice-file assign "invl.dat"
        organization sequential
        status fs-reply.
data division.
file section.
fd invoice-file
    record 134 characters.
01 invoice-record pic x(134).
working-storage section.
01 invoice-line.
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
    05 filler pic x.
77 fs-reply pic 99.
procedure division.
    open output invoice-file.
    initialize invoice-record.
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
    move invoice-line to invoice-record
    write invoice-record
    close invoice-file.
    display "line-len=" length of invoice-line
    stop run.
