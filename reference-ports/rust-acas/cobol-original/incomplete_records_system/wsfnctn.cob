*>**********************************
*>                                 *
*>  Sub-Program Control Functions  *
*>                                 *
*>**********************************

 01  file-access.
     03  file-function   pic 9.
         88  fn-open            value is 1.
         88  fn-close           value is 2.
         88  fn-read-next       value is 3.
         88  fn-read-indexed    value is 4.
         88  fn-write           value is 5.
         88  fn-spare           value is 6.
         88  fn-re-write        value is 7.
         88  fn-delete          value is 8.
         88  fn-start           value is 9.

     03  access-type     pic 9.
         88  fn-input           value is 1.
         88  fn-i-o             value is 2.
         88  fn-output          value is 3.
         88  fn-extend          value is 4.
         88  fn-equal-to        value is 5.
         88  fn-less-than       value is 6.
         88  fn-greater-than    value is 7.

     03  we-error        pic 999.
     03  file-names.
         05  file-1      pic x(9).
         05  file-2      pic x(10).
         05  file-3      pic x(8).
         05  file-4      pic x(8).
         05  file-5      pic x(12).
         05  file-6      pic x.
         05  filler      pic x.
*>
