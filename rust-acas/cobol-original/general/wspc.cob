*>*******************************************
*>                                          *
*>  working storage for the p.c / branches  *
*>                                          *
*>*******************************************
*>
 01  p-c-branches.
     03  pc-key.
       05  pc-ledg       pic 9(6).
       05  pc-pc         pic 9(2).
     03  p-b-codes       pic x      occurs  99 indexed  by  pc.
