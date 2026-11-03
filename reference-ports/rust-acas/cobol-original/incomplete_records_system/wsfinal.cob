*>**************************************************
*>                                                 *
*>   Working Storage for the Final Account File    *
*>                                                 *
*>**************************************************
*> rec 655 bytes +1 15/02/09
 01  Final-Record.
     03  ar1-fields.
       05  ar1-1         pic x(24).
       05  ar1-2         pic x(24).
       05  ar1-3         pic x(24).
       05  ar1-4         pic x(24).
       05  ar1-5         pic x(24).
       05  ar1-6         pic x(24).
       05  ar1-7         pic x(24).
       05  ar1-8         pic x(24).
       05  ar1-9         pic x(24).
       05  ar1-10        pic x(24).
       05  ar1-11        pic x(24).
       05  ar1-12        pic x(24).
       05  ar1-13        pic x(24).
       05  ar1-14        pic x(24).
       05  ar1-15        pic x(24).
       05  ar1-16        pic x(24).
       05  ar1-17        pic x(24).
       05  ar1-18        pic x(24).
       05  ar1-19        pic x(24).
       05  ar1-20        pic x(24).
       05  ar1-21        pic x(24).
       05  ar1-22        pic x(24).
       05  ar1-23        pic x(24).
       05  ar1-24        pic x(24).
       05  ar1-25        pic x(24).
       05  ar1-26        pic x(24).
     03  filler  redefines  ar1-fields.
       05  ar1           pic x(24)  occurs  26.
*>
     03  ar2-fields.
       05  ar2-1         pic x.
       05  ar2-2         pic x.
       05  ar2-3         pic x.
       05  ar2-4         pic x.
       05  ar2-5         pic x.
       05  ar2-6         pic x.
       05  ar2-7         pic x.
       05  ar2-8         pic x.
       05  ar2-9         pic x.
       05  ar2-10        pic x.
       05  ar2-11        pic x.
       05  ar2-12        pic x.
       05  ar2-13        pic x.
       05  ar2-14        pic x.
       05  ar2-15        pic x.
       05  ar2-16        pic x.
       05  ar2-17        pic x.
       05  ar2-18        pic x.
       05  ar2-19        pic x.
       05  ar2-20        pic x.
       05  ar2-21        pic x.
       05  ar2-22        pic x.
       05  ar2-23        pic x.
       05  ar2-24        pic x.
       05  ar2-25        pic x.
       05  ar2-26        pic x.
     03  filler  redefines  ar2-fields.
       05  ar2           pic x      occurs  26.
*>
     03  ar3             pic x(5).
*>
