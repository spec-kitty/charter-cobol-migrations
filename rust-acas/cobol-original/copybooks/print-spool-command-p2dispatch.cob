*>
*>  Portrait for two printers eg, invoices and picking/delivery notes
*>
*>    if you wish to print out invoices with a sep. print for del/pick to another printer
*>    which allows you to print to first printer then second one
*>    before deleting prt-1 file.
*>    You will need to amend the spooling system command see notes in sl930
*>
*>
 01  Print-Report.                               *> print out picking/delivery notes but do NOT delete print file
     03  filler          pic x(114)     value
     "lpr -o 'orientation-requested=3 page-left=48 page-top=24 " &
     "page-right=24 cpi=12 lpi=8' -P ".
     03  PSN2            pic x(48)      value "HPLJ4TCP2 ". *> This is the Cups print spool for the dispatch Dept., change it for yours
     03  filler          pic x(15)      value "prt-1".      *> Don't change this line
*>
 01  Print-Report2.                              *> print out but now delete print file
     03  filler          pic x(117)     value
     "lpr -r -o 'orientation-requested=3 page-left=48 page-top=24 " &
     "page-right=24 cpi=12 lpi=8' -P ".
     03  PSN             pic x(48)      value "HPLJ4TCP ".   *> This is the Cups print spool, change it for yours unless set in system file
     03  filler          pic x(15)      value "prt-2".       *> Don't change this line
*>
