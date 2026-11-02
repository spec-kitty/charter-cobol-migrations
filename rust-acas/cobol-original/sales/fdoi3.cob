*>*******************************************
*>                                          *
*>  File Definition For The Open Item File  *
*>      Rec Size 114 Bytes                  *
*>*******************************************
*>
 fd  open-item-file-3.
*>
 01  open-item-record-3.
     03  oi3-key.
         05 oi3-customer    pic x(7).
         05 oi3-invoice     binary-long.   *> 11
     03  oi3-date           binary-long.   *> 15
     03  filler             pic x(99).     *> 114
