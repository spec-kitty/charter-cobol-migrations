*>*******************************************
*>                                          *
*>  working storage for the posting array   *
*>                                          *
*>*******************************************
*> vbc - 02/02/09 date 8 to 10 chars
*>
 01  posting-array.
     03  array-code       pic xx          occurs  11.
     03  array-date       pic x(10)       occurs  11.
     03  array-dr         pic 9(6)        occurs  11.
     03  array-dr-pc      pic 99          occurs  11.
     03  array-cr         pic 9(6)        occurs  11.
     03  array-cr-pc      pic 99          occurs  11.
     03  array-amount     pic s9(8)v99    occurs  11.
     03  array-legend     pic x(32)       occurs  11.
     03  array-vat-ac     pic 9(4)v99     occurs  11.
     03  array-vat-pc     pic 99          occurs  11.
     03  array-vat-side   pic xx          occurs  11.
     03  array-vat-amount pic s9(8)v99    occurs  11.
