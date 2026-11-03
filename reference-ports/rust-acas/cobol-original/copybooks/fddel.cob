*>*******************************************
*>                                          *
*>  File Definition For The Delivery File   *
*>                                          *
*>*******************************************
*> 133 bytes 26/03/09
 fd  delivery-file.
*>
 01  delivery-record.
     03  deliv-key.
         05  Deliv-Key-Type        pic x.
             88  Deliv-Key-Del-addr            value "D".
             88  Deliv-Key-Notes               value "N".
         05  Deliv-Sales-Key.
           07  Deliv-Purchase-key  pic x(7).
     03  deliv-name                pic x(30).
     03  deliv-address.
         05  deliv-addr1           pic x(48).
         05  deliv-addr2           pic x(48).
