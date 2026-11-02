*>*******************************************
*>                                          *
*>  File Definition For The Payments File   *
*>                                          *
*>*******************************************
*> 237 bytes 26/03/09
 fd  pay-file.
*>
 01  pay-record.
     03  pay-key.
         05  pay-supl-key   pic x(7).
         05  pay-nos        binary-char.
     03  pay-cont           pic x.
     03  pay-date           binary-long.
     03  pay-cheque         binary-long.
     03  pay-sortcode       binary-long.
     03  pay-account        binary-long.
     03  pay-gross          pic s9(7)v99    comp-3.
     03  filler                     occurs 9.
         05  pay-folio      binary-long.
         05  pay-period     binary-char.
         05  pay-value      pic s9(7)v99    comp-3.
         05  pay-deduct     pic s999v99     comp-3.
         05  pay-invoice    pic x(10).
*>
