*>*******************************************
*>                                          *
*>  Working Storage for the Nominal Ledger  *
*>                                          *
*>*******************************************
*> Chg'd 16/01/09 money to 99M
*>
 01  nl-record.
     03  nl-key.
         05  nl-owning      pic 9(5).
         05  nl-sub-nominal pic 9(5).
     03  nl-type            pic x.
         88  owner                   value is "O".
         88  sub                     value is "S".
     03  nl-data.
         05  nl-name        pic x(24).
         05  nl-dr          pic 9(8)v99   comp.
         05  nl-cr          pic 9(8)v99   comp.
         05  nl-dr-last     pic 9(8)v99   comp  occurs  4.
         05  nl-cr-last     pic 9(8)v99   comp  occurs  4.
         05  nl-ac          pic x.
     03  filler  redefines  nl-data.
         05  nl-pointer     pic 9(5).
*>
