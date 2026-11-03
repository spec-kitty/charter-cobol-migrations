identification division.
program-id. gen_invoice.
environment division.
configuration section.
input-output section.
file-control.
copy "selinv.cob".
data division.
file section.
copy "fdinv2.cob".
working-storage section.
77 i pic 9.
77 fs-reply pic 99.
procedure division.
    open output invoice-file.
    perform varying i from 1 by 1 until i > 2
        move all "0" to invoice-nos
        move i to invoice-nos(8:1)
        move space to invoice-let
        move 0 to item-nos
        move "CUST01" to invoice-customer
        write invoice-record
    end-perform.
    close invoice-file.
    stop run.
