*>*******************************************
*>             Sales                        *
*>  File Definition For The Invoice File    *
*>                                          *
*>*******************************************
*> record size 129 bytes 09/03/09
*>        size 134 bytes 17/05/13 to match wsinv
*>
 fd  invoice-file.
*>
 01  invoice-record.
     03  invoice-key.
         05  invoice-nos    pic 9(8).
         05  invoice-let    pic x.
         05  item-nos       binary-char.
     03  invoice-customer   pic x(7).
     03  invoice-date       binary-long.
     03  filler             pic x(10).
     03  invoice-type       pic 9.
     03  filler             pic x(10).
     03  filler             pic x(92).
*>
 01  invoice-header.       *> 134 bytes
    02  ih-prime.          *> 42 bytes
     03  ih-invoice         pic 9(8).
     03  ih-letter          pic x.
     03  ih-test            binary-char.
     03  ih-customer.
         05  ih-nos         pic x(6).
         05  ih-check       pic 9.
     03  ih-date            binary-long.
     03  ih-order           pic x(10).
     03  ih-type            pic 9.
     03  ih-ref             pic x(10).
   02 ih-sub-prime.        *> 92 bytes
     03  ih-description     pic x(32).
     03  ih-fig                             comp-3.
         05  ih-p-c         pic s9(7)v99.
         05  ih-net         pic s9(7)v99.
         05  ih-extra       pic s9(7)v99.
         05  ih-carriage    pic s9(7)v99.
         05  ih-vat         pic s9(7)v99.
         05  ih-discount    pic s9(7)v99.
         05  ih-e-vat       pic s9(7)v99.
         05  ih-c-vat       pic s9(7)v99.
     03  ih-status          pic x.
         88  pending                            value "P".
         88  invoiced                           value "I".
         88  applied                            values "z" "Z".
     03  ih-status-P        pic x.         *> Pick list Printed           space or P/p
     03  ih-status-L        pic x.         *> Invoice Printed             space or L/l
     03  ih-status-C        pic x.         *> Invoice Cleared             space or C/c   paid or credited or cleared/cancelled etc
     03  ih-status-A        pic x.         *> Invoice Applied to a/c      space or A/a
     03  ih-status-I        pic x.         *> Invoice Item lines deleted  space or D/d
     03  ih-lines           binary-char.
     03  ih-deduct-days     binary-char.
     03  ih-deduct-amt      pic 999v99    comp.
     03  ih-deduct-vat      pic 999v99    comp.
     03  ih-days            binary-char.
     03  ih-cr              binary-long.
     03  ih-day-book-flag   pic x.
         88  day-booked                         value "B".
     03  ih-update          pic x.
         88  ih-analyised                       values "z" "Z".
*>
 01  invoice-line.    *> 80
       05  il-invoice       pic 9(8).
       05  il-letter        pic x.
       05  il-line          binary-char.
       05  il-product       pic x(13).   *> +1 17/5/13
       05  il-pa            pic xx.
       05  il-qty           binary-short.
       05  il-type          pic x.
       05  il-description   pic x(32).
       05  il-net           pic s9(7)v99   comp-3.
       05  il-unit          pic s9(7)v99   comp-3.
       05  il-discount      pic 99v99      comp.
       05  il-vat           pic s9(7)v99   comp-3.
       05  il-vat-code      pic 9.
       05  il-update        pic x.
           88 il-analyised                      values "z" "Z".
       05  filler           pic x.
*>

