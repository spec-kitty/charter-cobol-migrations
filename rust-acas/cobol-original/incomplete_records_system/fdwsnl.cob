*>
*> Chg'd 16/01/09 money to 99M
*>
 01  record-1.
     03  key-1.
         05  owning      pic 9(5).
         05  sub-nominal pic 9(5).
     03  tipe            pic x.
         88 nl-sub-ac               value "S".
     03  record-data.
         05  nl-name     pic x(24).
         05  dr          pic 9(8)v99   comp.
         05  cr          pic 9(8)v99   comp.
         05  dr-last     pic 9(8)v99   comp  occurs  4.
         05  cr-last     pic 9(8)v99   comp  occurs  4.
         05  ac          pic x.
     03  filler  redefines  record-data.
         05  rec-pointer pic 9(5).
*>
