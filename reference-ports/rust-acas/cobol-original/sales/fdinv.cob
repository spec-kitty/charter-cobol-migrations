*>*******************************************
*>            Sales                         *
*>  File Definition For The Invoice File    *
*>       Also See Fdinv2.Cob                *
*>*******************************************
*> record size 129 bytes 03/03/09
*>
 fd  invoice-file.
*>
 01  invoice-record.
    02  Inv-Prime.
     03  invoice-key.
         05  invoice-nos    pic 9(8).
         05  invoice-let    pic x.
         05  item-nos       binary-char.
     03  invoice-customer   pic x(7).
     03  invoice-date       binary-long.
     03  filler             pic x(10).
     03  invoice-type       pic 9.
     03  filler             pic x(10).
   02  Inv-Sub-Prime.
     03  filler             pic x(92).
