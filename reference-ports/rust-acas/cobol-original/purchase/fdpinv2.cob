*>*******************************************
*>                Purchase                  *
*>  file definition for the invoice file    *
*>   also see fdinv.cob                     *
*>*******************************************
*> record size 129 bytes 22/12/11
*>
 fd  invoice-file.
*>
 01  invoice-record.
     03  invoice-key.
         05  invoice-nos  pic 9(8).
         05  item-nos     binary-char.
     03  invoice-supplier pic x(7).
     03  invoice-date     binary-long.
     03  inv-order        pic x(10).
     03  invoice-type     pic 9.
     03  filler           pic x(10).
     03  filler           pic x(88).
*>
 01  invoice-header.   *> 129 bytes
     03  ih-invoice       pic 9(8).
     03  ih-test          binary-char.
     03  ih-supplier.
         05  ih-nos       pic x(6).
         05  ih-check     pic 9.
     03  ih-date          binary-long.
     03  ih-order         pic x(10).
     03  ih-type          pic 9.
     03  ih-ref           pic x(10).
     03  ih-fig                          comp-3.
         05  ih-p-c       pic s9(7)v99.
         05  ih-net       pic s9(7)v99.
         05  ih-extra     pic s9(7)v99.
         05  ih-carriage  pic s9(7)v99.
         05  ih-vat       pic s9(7)v99.
         05  ih-discount  pic s9(7)v99.
         05  ih-e-vat     pic s9(7)v99.
         05  ih-c-vat     pic s9(7)v99.
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
     03  ih-day-book-flag pic x.
         88  day-booked             values "b" "B".
     03  ih-update        pic x.
         88  ih-analyised           values "z" "Z".
     03  filler           pic x(30).
*>
 01  invoice-line.     *> 74 bytes 22/12/11
     03  il-invoice       pic 9(8).
     03  il-line          binary-char.
     03  il-product       pic x(13).    *> +1 18/05/13
     03  il-pa            pic xx.
     03  filler           pic xx.       *> -1 18/05/13
     03  il-qty           binary-short.
     03  il-type          pic x.
     03  il-description   pic x(24).
     03  filler           pic xx.
     03  il-net           pic s9(7)v99   comp-3.
     03  il-unit          pic s9(7)v99   comp-3.
     03  il-discount      pic 99v99      comp.
     03  il-vat           pic s9(7)v99   comp-3.
     03  il-vat-code      pic 9.
     03  il-update        pic x.
         88 il-analyised          values "z" "Z".
*>
