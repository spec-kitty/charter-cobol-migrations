*>*******************************************
*>                                          *
*>  File Definition For The Analysis File   *
*>                                          *
*>*******************************************
*> 36 bytes 25/3/09
 fd  Analysis-File.
*>
 01  analysis-record.
     03  pa-code.
         05  pa-system     pic x.
         05  pa-group.
             07  pa-first  pic x.
             07  pa-second pic x.
     03  pa-gl             pic 9(6).
     03  pa-desc           pic x(24).
     03  pa-print          pic xxx.
