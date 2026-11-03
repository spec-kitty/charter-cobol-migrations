*>*******************************************
*>                                          *
*>  Record Definition For System Record 4   *
*>                                          *
*>*******************************************
*>  Record size 1024 bytes to match system-record 07/11/10
*>
 01  System-Record-4.
     03  Sales-Ledger-Data                              comp-3.
         05  sl-os-bal-last-month        pic s9(8)v99.
         05  sl-os-bal-this-month        pic s9(8)v99.
         05  sl-invoices-this-month      pic s9(8)v99.
         05  sl-credit-notes-this-month  pic s9(8)v99.
         05  sl-variance                 pic s9(8)v99.
         05  sl-credit-deductions        pic s9(8)v99.
         05  sl-cn-unappl-this-month     pic s9(8)v99.
         05  sl-payments                 pic s9(8)v99.
         05  sl4-spare1                  pic s9(8)v99.
         05  sl4-spare2                  pic s9(8)v99.
     03  Purchase-Ledger-Data                           comp-3.
         05  pl-os-bal-last-month        pic s9(8)v99.
         05  pl-os-bal-this-month        pic s9(8)v99.
         05  pl-invoices-this-month      pic s9(8)v99.
         05  pl-credit-notes-this-month  pic s9(8)v99.
         05  pl-variance                 pic s9(8)v99.
         05  pl-credit-deductions        pic s9(8)v99.
         05  pl-cn-unappl-this-month     pic s9(8)v99.
         05  pl-payments                 pic s9(8)v99.
         05  sl4-spare3                  pic s9(8)v99.
         05  sl4-spare4                  pic s9(8)v99.
     03  filler                      pic x(904).
*>
