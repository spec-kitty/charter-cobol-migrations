*>
*> Landscape
*>
 01  Print-Report.
     03  filler          pic x(117)     value
     "lpr -r -o 'orientation-requested=4 page-left=18 page-top=48 " &
     "page-right=10 sides=two-sided-long-edge cpi=12 lpi=8' -P ".
     03  PSN             pic x(48)      value "HPLJ4TCP ".  *> This is the Cups print spool, change it for yours
     03  filler          pic x(15)      value "prt-1".      *> Don't change this line
