*>*************************************************
*>                                                *
*>  File Definition For The Analysis Value File   *
*>                                                *
*>*************************************************
*>  record size 66 bytes ** 08/03/09
*>
 fd  value-file.
*>
 01  value-record.
     03  va-code.
         05  va-system      pic x.
         05  va-group.
             07 va-first    pic x.
             07 va-second   pic x.
     03  va-gl              pic 9(6).
     03  va-desc            pic x(24).
     03  va-print           pic xxx.
     03  va-t-this          pic 9(5)         comp.
     03  va-t-last          pic 9(5)         comp.
     03  va-t-year          pic 9(5)         comp.
     03  va-v-this          pic s9(8)v99     comp-3.
     03  va-v-last          pic s9(8)v99     comp-3.
     03  va-v-year          pic s9(8)v99     comp-3.
*>
