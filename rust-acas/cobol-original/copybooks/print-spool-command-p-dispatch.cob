*>
*>  Portrait for printer in dispatch Dept eg, picking/delivery notes.
*>
*>    This code for missing program that only prints delivery notes/ picking lists
*>
*>    if you wish to print out invoices with a sep. print for del/pick to another printer see
*>    print-spool-command-p2dispatch which allow you to print to first printer then second
*>    before deleting prt-1 file. You will need to amend the spooling system command see notes
*>        in sl930
*>
 01  Print-Report.                               *> print out picking/delivery notes & delete print file
     03  filler          pic x(117)     value
     "lpr -r -o 'orientation-requested=3 page-left=36 page-top=24 " &
     "page-right=24 cpi=12 lpi=8' -P ".
     03  PSN2            pic x(48)      value "HPLJ4TCP2 ". *> This is the Cups print spool for the dispatch Dept., change it for yours
     03  filler          pic x(15)      value "prt-1".      *> Don't change this line
*>
