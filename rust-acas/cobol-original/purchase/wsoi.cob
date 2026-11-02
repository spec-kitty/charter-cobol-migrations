*>*********************************************
*>               Purchase    in purchase      *
*>  Working Storage For The Open Item Header  *
*>   & c wssoi.cob                            *
*>*********************************************
*> record size 109 bytes 26/03/09
*> 07/04/09 vbc - Clean up level nos & layout 17/5/13 again
*>
 01  oi-header.
     03  oi-key.
         04  oi-customer.
             05  oi-Supplier.
                 07  oi-nos   pic x(6).
                 07  oi-check pic 9.
     03  oi-invoice      binary-long.
     03  oi-date         binary-long.
     03  oi-batch                        comp.
         05  oi-b-nos    pic 9(5).
         05  oi-b-item   pic 999.
     03  oi-type         pic 9.
*>
*>                              ***********************************
*>                              * 1  =  Receipt                   *
*>                              * 2  =  Account Invoice           *
*>                              * 3  =  Cr. Note                  *
*>                              * 4  =  Proforma                  *
*>                              * 5  =  Payment                   *
*>                              * 6  =  Journal-Unapplied Cash    *
*>                              * 7  =  Journal Type B (Not Used) *
*>                              * 9  =  Old Payments              *
*>                              ***********************************
*>
     03  oi-ref          pic x(10).
     03  oi-order        pic x(10).
     03  oi-hold-flag    pic x.
         88  payment-held                      value "H".
     03  oi-unapl        pic x.
     03  filler                          comp-3.
         05  oi-p-c      pic s9(7)v99.
         05  oi-net      pic s9(7)v99.
         05  oi-approp redefines oi-net
                         pic s9(7)v99.
         05  oi-extra    pic s9(7)v99.
         05  oi-carriage pic s9(7)v99.
         05  oi-vat      pic s9(7)v99.
         05  oi-discount pic s9(7)v99.
         05  oi-e-vat    pic s9(7)v99.
         05  oi-c-vat    pic s9(7)v99.
         05  oi-paid     pic s9(7)v99.
     03  oi-status       pic 9.
         88  s-open                            value zero.
         88  s-closed                          value 1.
     03  oi-deduct-days  binary-char.
     03  oi-deduct-amt   pic s999v99    comp.
     03  oi-deduct-vat   pic s999v99    comp.
     03  oi-days         binary-char.
     03  oi-cr           binary-long.
     03  oi-applied      pic x.
     03  oi-date-cleared binary-long.
*>
