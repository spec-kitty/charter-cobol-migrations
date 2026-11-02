*>*******************************************
*>                                          *
*>  Working Storage for the Defaults Record *
*>                                          *
*>*******************************************
*> Record 231 bytes but written as 1024 (system-record size) 07/11/10
*>   Can we link this one for GL up with IRS??
*>
 01  Default-Record.
     03  Def-Acs         pic 9(4)v99 comp  occurs  33.
     03  Def-Codes       pic xx            occurs  33.
     03  Def-Vat         pic x             occurs  33.
*>
