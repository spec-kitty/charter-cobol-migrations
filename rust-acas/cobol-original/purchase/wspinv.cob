*>*******************************************
*>          In Purchase                      *
*>  Working Storage For The Invoice Header  *
*>                                          *
*>*******************************************
*> record size 100 bytes  26/03/09
*>
 01  invoice-header.
   02  ih-prime.   *> 41 bytes
     03  ih-invoice       pic 9(8).
     03  ih-test          binary-char   value zero.
     03  ih-supplier.
       05  ih-nos         pic x(6).
       05  ih-check       pic 9.
     03  ih-date          binary-long.
     03  ih-order         pic x(10).
     03  ih-type          pic 9.
     03  ih-ref           pic x(10).
   02 ih-sub-prime.      *> 59 bytes
     03  ih-fig                          comp-3.
       05  ih-p-c         pic s9(7)v99.
       05  ih-net         pic s9(7)v99.
       05  ih-extra       pic s9(7)v99.
       05  ih-carriage    pic s9(7)v99.
       05  ih-vat         pic s9(7)v99.
       05  ih-discount    pic s9(7)v99.
       05  ih-e-vat       pic s9(7)v99.
       05  ih-c-vat       pic s9(7)v99.
     03  ih-status        pic x.
       88  pending     values "p" "P".
       88  invoiced    values "i" "I".
       88  applied     values "z" "Z".
     03  ih-lines         binary-char.
     03  ih-deduct-days   binary-char.
     03  ih-deduct-amt    pic 999v99    comp.
     03  ih-deduct-vat    pic 999v99    comp.
     03  ih-days          binary-char.
     03  ih-cr            binary-long.
     03  ih-day-book-flag pic x   value space.
       88  day-booked             values "b" "B".
     03  ih-update        pic x.
       88  ih-analyised           values "z" "Z".
     03  filler           pic x.
*> 03 filler pic x(30).  *> not used for WS as its a filler 2 match header
*>
*>******************************************
*>                                         *
*>  Working Storage For The Invoice Lines  *
*>                                         *
*>******************************************
*> 75 bytes each - 3000 bytes 02/11/10
 01  Pinvoice-lines.
     03  invoice-line                   occurs 40.
       05  il-invoice     pic 9(8).
       05  il-line        binary-char.
       05  il-product     pic x(12).
       05  il-pa          pic xx.
       05  filler         pic xxx.
       05  il-qty         binary-short.
       05  il-type        pic x.
       05  il-description pic x(24).
       05  filler         pic xx.
       05  il-net         pic s9(7)v99   comp-3.
       05  il-unit        pic s9(7)v99   comp-3.
       05  il-discount    pic 99v99      comp.
       05  il-vat         pic s9(7)v99   comp-3.
       05  il-vat-code    pic 9.
       05  il-update      pic x.
        88 il-analyised          values "z" "Z".
       05  filler         pic x.   *> rounding filler for WS only
*>
