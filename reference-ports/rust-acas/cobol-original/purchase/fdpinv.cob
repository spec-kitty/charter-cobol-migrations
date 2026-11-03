*>*******************************************
*>              Purchase                    *
*>  File Definition For The Invoice File    *
*>                                          *
*>*******************************************
*> record size 100 bytes 26/03/09
*>             126 bytes 15/12/11 to match fdinv2
*>             129 bytes 22/12/11
 fd  invoice-file.
*>
 01  invoice-record.
     03  invoice-key.
       05  invoice-nos   pic 9(8).
       05  item-nos      binary-char.
     03  invoice-supplier pic x(7).
     03  invoice-date    binary-long.
     03  inv-order       pic x(10).
     03  invoice-type    pic 9.
     03  filler          pic x(10).
     03  filler          pic x(88).
*>
