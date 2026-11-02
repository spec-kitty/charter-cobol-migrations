       >>source free
*>*******************************************
*>                                          *
*>  File Definition For Stock Audit file    *
*>                                          *
*>*******************************************
*> rec size  bytes 04/06/09 (with Desc)
*> 24/05/13 vbc Added Invoice-PO rec size 96 bytes
*> 28/05/13 vbc Added Cr. Note credited no. rec size 104
*>
 fd  Stock-Audit.
*>
 01  Stock-Audit-Record.
     03  Audit-Type                pic 9.
         88  Batch-record                      value zero.
         88  Add-record                        value 1.
         88  Del-record                        value 2.
         88  SL-Del-Record                     value 3.  *> + Inv no.
         88  PL-Add-Record                     value 4.  *> + Purch no.
         88  SL-Credit-Record                  value 5.  *> + Credit note/Inv. no.
     03  Audit-Invoice-PO          pic 9(8).
     03  Audit-Cr-for-Invoice      pic 9(8).
     03  Audit-Stock-Key           pic x(13).
     03  Audit-Desc                pic x(32).
     03  Audit-Process-Date        pic x(10).
     03  Audit-Reverse-Transaction pic 9.          *> T/F (1/0)
     03  Audit-Transaction-Qty     pic s9(6).      *>         comp.
     03  Audit-Unit-Cost           pic s9(6)v9999. *>         comp-3.
     03  Audit-Stock-Value-Change  pic s9(8)v99.   *>         comp-3.  *> can be Negative
     03  Audit-No                  pic 9(5).       *>binary-char unsigned.
*>
