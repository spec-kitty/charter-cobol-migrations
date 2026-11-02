*>*******************************************
*>                                          *
*>  Working Storage for the Posting File    *
*>                                          *
*>*******************************************
*>> Chg 16/01/09 money to 9M
*>
 01  posting-record.
     03  post-key        pic 9(5).
     03  post-code       pic xx.
     03  post-date       pic x(8).
     03  post-dr         pic 9(5).
     03  post-cr         pic 9(5).
     03  post-amount     pic s9(7)v99  sign is leading.
*>    03  post-amount     pic 9(7)v99.
     03  post-legend     pic x(32).
     03  vat-ac-def      pic 99.
     03  post-vat-side   pic xx.
     03  vat-amount      pic s9(7)v99   sign is leading.
*>    03  vat-amount      pic 9(7)v99.
*>
