*>*******************************************
*>                                          *
*>  File Definition for irs Postings File   *
*>   within IRS                             *
*> This is NOT the same as the internal IRS *
*>   posting file                           *
*>*******************************************
*> Chg 16/01/09 money to 9M
*>  again 28/03/09 for irs-batch-item
 fd  irs-post-file.
*>
 01  irs-posting-record.
     03  irs-post-key.
       05  irs-batch         pic 9(5).
       05  irs-post-number   pic 9(5).
     03  irs-post-code       pic xx.
     03  irs-post-date       pic x(8).
     03  irs-post-dr         pic 9(5).
     03  irs-post-cr         pic 9(5).
     03  irs-post-amount     pic s9(7)v99   sign leading.
     03  irs-post-legend     pic x(32).
     03  irs-vat-ac-def      pic 99.
     03  irs-post-vat-side   pic xx.
     03  irs-vat-amount      pic s9(7)v99   sign leading.
*>
