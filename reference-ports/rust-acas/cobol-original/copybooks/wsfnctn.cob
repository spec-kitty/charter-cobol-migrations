       >>source free
*>**********************************
*>                                 *
*>  File Access Control Functions  *
*>                                 *
*>**********************************
*>
 01  File-Access.
     03  We-Error        binary-long.
     03  Rrn             binary-long.
     03  Fs-Reply        pic 99.
     03  s1              pic x.   *> not sure this is used so lets rem it out and see
*>     05  s2              pic x.  *> rem'd out MF status
*>    03  stat-bin            redefines fs-reply pic 9(4) comp.
*>    03  disply-stat.
*>     05 s1-displ        pic x.
*>     05 filler          pic xxx.
*>     05 s2-displ        pic 9999.
*>
     03  Curs            pic 9(4).
     03  filler redefines Curs.
         05  Lin         pic 99.
         05  Cole        pic 99.
     03  Curs2           pic 9(4).
     03  filler redefines Curs2.
         05  Lin2        pic 99.
         05  Col2        pic 99.
*>
     03  Fs-Action       pic x(20)  value spaces.
*> current range 1 thru 3
*> 1 = Stock-Key (or only key), 2 = Stock-Abrev-Key, 3 = Stock-Desc
     03  File-Key-No     pic 9.
     03  File-Key        pic x(32).      *> Max size of any key  NOT USED ANY WHERE SO FAR (03/04/12)
     03  SQL-Err         pic x(5).                    *> May not be needed
     03  SQL-Msg         pic x(512) value spaces.     *> May not be needed
     03  Accept-Reply    pic x      value space.
     03  DB-Schema       pic x(12)  value spaces.
     03  DB-UName        pic x(12)  value spaces.
     03  DB-UPass        pic x(12)  value spaces.
*>
*> Block for File/table access via acas000 thru acas033 for IS files and rdbms
*> Also see RDBMS-Flat-Statuses in System-Record
*>
     03  File-Function   pic 9.
         88  fn-open            value 1.
         88  fn-close           value 2.
         88  fn-read-next       value 3.
         88  fn-read-indexed    value 4.
         88  fn-write           value 5.
         88  fn-spare           value 6.
         88  fn-re-write        value 7.
         88  fn-delete          value 8.
         88  fn-start           value 9.
*>
     03  Access-Type     pic 9.                *> For rdbms 2 should cover all !!!
         88  fn-input           value 1.
         88  fn-i-o             value 2.
         88  fn-output          value 3.
         88  fn-extend          value 4.
         88  fn-equal-to        value 5.
         88  fn-less-than       value 6.
         88  fn-greater-than    value 7.
         88  fn-not-less-than   value 8.
         88  fn-not-greater-than value 9.    *> Not currently used (06/04/2012)
*>
