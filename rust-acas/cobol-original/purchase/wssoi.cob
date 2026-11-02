*>*********************************************
*>              Purchase   in purchase        *
*>  Saved   Storage For The Open Item Header  *
*>  & c wsoi.cob                              *
*>*********************************************
*> 109 bytes 26/03/09 not the same as wsoi <<<
*>
 01  si-header.
     02  si-key.
         03  si-customer.
             04  si-supplier.
                 05  si-nos   pic x(6).
                 05  si-check pic 9.
     02  filler.
         03  si-invoice       binary-long.
         03  si-date          binary-long.
         03  si-batch                        comp.
             05  si-b-nos     pic 9(5).
             05  si-b-item    pic 999.
         03  si-type          pic 9.
*>
*>                              ***********************************
*>                              * 1  =  Receipt                   *
*>                              * 2  =  Account                   *
*>                              * 3  =  Cr. Note                  *
*>                              * 4  =  Proforma                  *
*>                              * 5  =  Payment                   *
*>                              * 6  =  Journal-Unapplied Cash    *
*>                              * 7  =  Journal Type B (Not Used) *
*>                              * 9  =  Old Payments              *
*>                              ***********************************
*>
         03  si-ref           pic x(10).
         03  si-order         pic x(10).
         03  si-hold-flag     pic x.
         03  si-unapl         pic x.
         03  filler                          comp-3.
             05  si-p-c       pic s9(7)v99.
             05  si-net       pic s9(7)v99.
             05  si-approp redefines si-net
                          pic s9(7)v99.
             05  si-extra     pic s9(7)v99.
             05  si-carriage  pic s9(7)v99.
             05  si-vat       pic s9(7)v99.
             05  si-discount  pic s9(7)v99.
             05  si-e-vat     pic s9(7)v99.
             05  si-c-vat     pic s9(7)v99.
             05  si-paid      pic s9(7)v99.
        03  si-status         pic 9.
            88  si-s-open                      value zero.
            88  si-s-closed                    value 1.
        03  si-deduct-days    binary-char.
        03  si-deduct-amt     pic s999v99    comp.
        03  si-deduct-vat     pic s999v99    comp.
        03  si-days           binary-char.
        03  si-cr             binary-long.
        03  si-applied        pic x.
        03  si-date-cleared   binary-long.
*>
