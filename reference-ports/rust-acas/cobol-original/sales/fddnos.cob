*>*****************************************************
*>                                                    *
*>  File Definition For The Deleted Invoice Nos File  *
*>                                                    *
*>*****************************************************
*> 19 bytes 04/04/09
 fd  del-inv-nos-file.
*>
 01  del-inv-nos-record.
     03  del-inv-nos        pic 9(8).
     03  del-inv-dat        binary-long.
     03  del-inv-cus        pic x(7).
