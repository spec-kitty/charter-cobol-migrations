*>*******************************************
*>         in Sales                         *
*>  Working Storage For The Invoice Header  *
*>      Also See FDinv2.Cob                 *
*>*******************************************
*>   size 129 bytes 09/03/09
*>   size 134 bytes 24/03/12                *> WARNING UPDATE all layouts for 5 byte increase (extra statuses)
*>
 01  sinvoice-header.
   02 sih-prime.          *> 42 bytes
     03  sih-invoice       pic 9(8).
     03  sih-letter        pic x.
     03  sih-test          binary-char  value zero.
     03  sih-customer.
       05  sih-nos         pic x(6).
       05  sih-check       pic 9.
     03  sih-date          binary-long.
     03  sih-order         pic x(10).
     03  sih-type          pic 9.
     03  sih-ref           pic x(10).
   02 sih-sub-prime.      *> 92 bytes
     03  sih-description   pic x(32).
     03  sih-fig                          comp-3.
       05  sih-p-c         pic s9(7)v99.
       05  sih-net         pic s9(7)v99.
       05  sih-extra       pic s9(7)v99.
       05  sih-carriage    pic s9(7)v99.
       05  sih-vat         pic s9(7)v99.
       05  sih-discount    pic s9(7)v99.
       05  sih-e-vat       pic s9(7)v99.
       05  sih-c-vat       pic s9(7)v99.
     03  sih-status        pic x.
         88  pending                           value "P".
         88  invoiced                          value "I".
         88  sapplied                          values "z" "Z".
     03  sih-status-P      pic x.         *> Pick list Printed           space or P/p
     03  sih-status-L      pic x.         *> Invoice Printed             space or L/l
     03  sih-status-C      pic x.         *> Invoice Cleared             space or C/c   paid or credited or cleared/cancelled etc
     03  sih-status-A      pic x.         *> Invoice Applied to a/c      space or A/a
     03  sih-status-I      pic x.         *> Invoice Item lines deleted  space or D/d
     03  sih-lines         binary-char.
     03  sih-deduct-days   binary-char.
     03  sih-deduct-amt    pic 999v99    comp.
     03  sih-deduct-vat    pic 999v99    comp.
     03  sih-days          binary-char.
     03  sih-cr            binary-long.
     03  sih-day-book-flag pic x               value space.
         88  day-booked                        value "B".
     03  sih-update        pic x.
       88  sih-analyised           values "z" "Z".
*>
*>*******************************************
*>                                          *
*>  Working Storage For The Invoice Lines   *
*>                                          *
*>*******************************************
*> 80 bytes each = 3200 bytes (17/05/13)
 01  sInvoice-Bodies.
     03  invoice-line                    occurs 40.
       05  sil-invoice     pic 9(8).
       05  sil-letter      pic x.
       05  sil-line        binary-char.
       05  sil-product     pic x(13).   *> +1 17/5/13
       05  sil-pa          pic xx.
       05  sil-qty         binary-short.
       05  sil-type        pic x.
       05  sil-description pic x(32).   *> +8 17/5/13
       05  sil-net         pic s9(7)v99   comp-3.
       05  sil-unit        pic s9(7)v99   comp-3.
       05  sil-discount    pic 99v99      comp.
       05  sil-vat         pic s9(7)v99   comp-3.
       05  sil-vat-code    pic 9.
       05  sil-update      pic x.
           88 sil-analyised          values "z" "Z".
       05  filler          pic x.
*>
