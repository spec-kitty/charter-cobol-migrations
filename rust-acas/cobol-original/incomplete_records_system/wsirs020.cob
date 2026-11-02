*>
 01  accounts-display.
     03 ss-client        pic x(0024) value spaces.
     03 filler           pic x(0003).
     03 irs020-00-0002   pic x(24) value "Finished Accounts SetUp".
     03 filler           pic x(0021).
     03 ss-run-date      pic x(0008) value spaces.
     03 filler           pic x(0027).
     03 filler           pic x(0024).
     03 filler           pic x(0032).
     03 irs020-00-0005   pic x(0033) value "Trading and Profit & Loss Account".
     03 filler           pic x(0017).
     03 irs020-00-0006   pic x(0013) value "Balance sheet".
     03 filler           pic x(0103).
     03 irs020-00-0007   pic x(0024) value "--------Heading---------".
     03 filler           pic x(0002).
     03 irs020-00-0008   pic x(0004) value "Sign".
     03 filler           pic x(0010).
     03 irs020-00-0009   pic x(0024) value "--------Heading---------".
     03 filler           pic x(0002).
     03 irs020-00-0010   pic x(0005) value "Sign ".
     03 irs020-00-0011   pic x(0015) value "Income Accounts".
     03 filler           pic x(0025).
     03 irs020-00-0012   pic x(0012) value "Fixed Assets".
     03 filler           pic x(0030).
     03 irs020-00-0013   pic x(0003) value "<A>".
     03 filler           pic x(0003).
     03 irs020-00-0014   pic x(0001) value "[".
     03 filler1          pic x(0024).
     03 irs020-00-0015   pic x(0003) value "] [".
     03 fxx1             pic x.
     03 fxy1             pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0016   pic x(0003) value "<O>".
     03 filler           pic x(0003).
     03 irs020-00-0017   pic x(0001) value "[".
     03 filler2          pic x(0024).
     03 irs020-00-0018   pic x(0003) value "] [".
     03 fxx2             pic x.
     03 fxy2             pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0019   pic x(0003) value "<B>".
     03 filler           pic x(0003).
     03 irs020-00-0020   pic x(0001) value "[".
     03 filler3          pic x(0024).
     03 irs020-00-0021   pic x(0003) value "] [".
     03 fxx3             pic x.
     03 fxy3             pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0022   pic x(0003) value "<P>".
     03 filler           pic x(0003).
     03 irs020-00-0023   pic x(0001) value "[".
     03 filler4          pic x(0024).
     03 irs020-00-0024   pic x(0003) value "] [".
     03 fxx4             pic x.
     03 fxy4             pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0025   pic x(0003) value "<C>".
     03 filler           pic x(0003).
     03 irs020-00-0026   pic x(0001) value "[".
     03 filler5          pic x(0024).
     03 irs020-00-0027   pic x(0003) value "] [".
     03 fxx5             pic x.
     03 fxy5             pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0028   pic x(0003) value "<Q>".
     03 filler           pic x(0003).
     03 irs020-00-0029   pic x(0001) value "[".
     03 filler6          pic x(0024).
     03 irs020-00-0030   pic x(0003) value "] [".
     03 fxx6             pic x.
     03 fxy6             pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0031   pic x(0003) value "<D>".
     03 filler           pic x(0003).
     03 irs020-00-0032   pic x(0001) value "[".
     03 filler7          pic x(0024).
     03 irs020-00-0033   pic x(0003) value "] [".
     03 fxx7             pic x.
     03 fxy7             pic x value "]".
     03 filler           pic x(0042).
     03 irs020-00-0034   pic x(0020) value "Direct Cost Accounts".
     03 filler           pic x(0020).
     03 irs020-00-0035   pic x(0014) value "Current Assets".
     03 filler           pic x(0028).
     03 irs020-00-0036   pic x(0003) value "<E>".
     03 filler           pic x(0003).
     03 irs020-00-0037   pic x(0001) value "[".
     03 filler8          pic x(0024).
     03 irs020-00-0038   pic x(0003) value "] [".
     03 fxx8             pic x.
     03 fxy8             pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0039   pic x(0003) value "<R>".
     03 filler           pic x(0003).
     03 irs020-00-0040   pic x(0001) value "[".
     03 filler9          pic x(0024).
     03 irs020-00-0041   pic x(0003) value "] [".
     03 fxx9             pic x.
     03 fxy9             pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0042   pic x(0003) value "<F>".
     03 filler           pic x(0003).
     03 irs020-00-0043   pic x(0001) value "[".
     03 filler10         pic x(0024).
     03 irs020-00-0044   pic x(0003) value "] [".
     03 fxx10            pic x.
     03 fxy10            pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0045   pic x(0003) value "<S>".
     03 filler           pic x(0003).
     03 irs020-00-0046   pic x(0001) value "[".
     03 filler11         pic x(0024).
     03 irs020-00-0047   pic x(0003) value "] [".
     03 fxx11            pic x.
     03 fxy11            pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0048   pic x(0003) value "<G>".
     03 filler           pic x(0003).
     03 irs020-00-0049   pic x(0001) value "[".
     03 filler12         pic x(0024).
     03 irs020-00-0050   pic x(0003) value "] [".
     03 fxx12            pic x.
     03 fxy12            pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0051   pic x(0003) value "<T>".
     03 filler           pic x(0003).
     03 irs020-00-0052   pic x(0001) value "[".
     03 filler13         pic x(0024).
     03 irs020-00-0053   pic x(0003) value "] [".
     03 fxx13            pic x.
     03 fxy13            pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0054   pic x(0003) value "<H>".
     03 filler           pic x(0003).
     03 irs020-00-0055   pic x(0001) value "[".
     03 filler14         pic x(0024).
     03 irs020-00-0056   pic x(0003) value "] [".
     03 fxx14            pic x.
     03 fxy14            pic x value "]".
     03 filler           pic x(0042).
     03 irs020-00-0057   pic x(22) value "Sundry Income Accounts".
     03 filler           pic x(0018).
     03 irs020-00-0058   pic x(0019) value "Current Liabilities".
     03 filler           pic x(0023).
     03 irs020-00-0059   pic x(0003) value "<I>".
     03 filler           pic x(0003).
     03 irs020-00-0060   pic x(0001) value "[".
     03 filler15         pic x(0024).
     03 irs020-00-0061   pic x(0003) value "] [".
     03 fxx15            pic x.
     03 fxy15            pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0062   pic x(0003) value "<U>".
     03 filler           pic x(0003).
     03 irs020-00-0063   pic x(0001) value "[".
     03 filler16         pic x(0024).
     03 irs020-00-0064   pic x(0003) value "] [".
     03 fxx16            pic x.
     03 fxy16            pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0065   pic x(0003) value "<J>".
     03 filler           pic x(0003).
     03 irs020-00-0066   pic x(0001) value "[".
     03 filler17         pic x(0024).
     03 irs020-00-0067   pic x(0003) value "] [".
     03 fxx17            pic x.
     03 fxy17            pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0068   pic x(0003) value "<V>".
     03 filler           pic x(0003).
     03 irs020-00-0069   pic x(0001) value "[".
     03 filler18         pic x(0024).
     03 irs020-00-0070   pic x(0003) value "] [".
     03 fxx18            pic x.
     03 fxy18            pic x value "]".
     03 filler           pic x(0002).
     03 irs020-00-0071   pic x(22) value "Indirect Cost Accounts".
     03 filler           pic x(0018).
     03 irs020-00-0072   pic x(0016) value "Capital Accounts".
     03 filler           pic x(0026).
     03 irs020-00-0073   pic x(0003) value "<K>".
     03 filler           pic x(0003).
     03 irs020-00-0074   pic x(0001) value "[".
     03 filler19         pic x(0024).
     03 irs020-00-0075   pic x(0003) value "] [".
     03 fxx19            pic x.
     03 fxy19            pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0076   pic x(0003) value "<W>".
     03 filler           pic x(0003).
     03 irs020-00-0077   pic x(0001) value "[".
     03 filler20         pic x(0024).
     03 irs020-00-0078   pic x(0003) value "] [".
     03 fxx20            pic x.
     03 fxy20            pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0079   pic x(0003) value "<L>".
     03 filler           pic x(0003).
     03 irs020-00-0080   pic x(0001) value "[".
     03 filler21         pic x(0024).
     03 irs020-00-0081   pic x(0003) value "] [".
     03 fxx21            pic x.
     03 fxy21            pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0082   pic x(0003) value "<X>".
     03 filler           pic x(0003).
     03 irs020-00-0083   pic x(0001) value "[".
     03 filler22         pic x(0024).
     03 irs020-00-0084   pic x(0003) value "] [".
     03 fxx22            pic x.
     03 fxy22            pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0085   pic x(0003) value "<M>".
     03 filler           pic x(0003).
     03 irs020-00-0086   pic x(0001) value "[".
     03 filler23         pic x(0024).
     03 irs020-00-0087   pic x(0003) value "] [".
     03 fxx23            pic x.
     03 fxy23            pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0088   pic x(0003) value "<Y>".
     03 filler           pic x(0003).
     03 irs020-00-0089   pic x(0001) value "[".
     03 filler24         pic x(0024).
     03 irs020-00-0090   pic x(0003) value "] [".
     03 fxx24            pic x.
     03 fxy24            pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0091   pic x(0003) value "<N>".
     03 filler           pic x(0003).
     03 irs020-00-0092   pic x(0001) value "[".
     03 filler25         pic x(0024).
     03 irs020-00-0093   pic x(0003) value "] [".
     03 fxx25            pic x.
     03 fxy25            pic x value "]".
     03 filler           pic x(0004).
     03 irs020-00-0094   pic x(0003) value "<Z>".
     03 filler           pic x(0003).
     03 irs020-00-0095   pic x(0001) value "[".
     03 filler26         pic x(0024).
     03 irs020-00-0096   pic x(0003) value "] [".
     03 fxx26            pic x.
     03 fxy26            pic x value "]".
     03 filler           pic x(0002).
     03 irs020-00-0097   pic x(0028) value "P&L Appropriation Account -[".
     03 filler27         pic x(0005).
     03 irs020-00-0098   pic x(0001) value "]".
 01  accounts-display2 redefines accounts-display.
     03 filler           pic x(0489).
     03 filler1b         pic x(0024).
     03 filler           pic x(0003).
     03 fxx1b            pic x.
     03 filler           pic x(0012).
     03 filler2b         pic x(0024).
     03 filler           pic x(0003).
     03 fxx2b            pic x.
     03 filler           pic x(0012).
     03 filler3b         pic x(0024).
     03 filler           pic x(0003).
     03 fxx3b            pic x.
     03 filler           pic x(0012).
     03 filler4b         pic x(0024).
     03 filler           pic x(0003).
     03 fxx4b            pic x.
     03 filler           pic x(0012).
     03 filler5b         pic x(0024).
     03 filler           pic x(0003).
     03 fxx5b            pic x.
     03 filler           pic x(0012).
     03 filler6b         pic x(0024).
     03 filler           pic x(0003).
     03 fxx6b            pic x.
     03 filler           pic x(0012).
     03 filler7b         pic x(0024).
     03 filler           pic x(0003).
     03 fxx7b            pic x.
     03 filler           pic x(0132).
     03 filler8b         pic x(0024).
     03 filler           pic x(0003).
     03 fxx8b            pic x.
     03 filler           pic x(0012).
     03 filler9b         pic x(0024).
     03 filler           pic x(0003).
     03 fxx9b            pic x.
     03 filler           pic x(0012).
     03 filler10b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx10b           pic x.
     03 filler           pic x(0012).
     03 filler11b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx11b           pic x.
     03 filler           pic x(0012).
     03 filler12b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx12b           pic x.
     03 filler           pic x(0012).
     03 filler13b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx13b           pic x.
     03 filler           pic x(0012).
     03 filler14b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx14b           pic x.
     03 filler           pic x(0132).
     03 filler15b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx15b           pic x.
     03 filler           pic x(0012).
     03 filler16b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx16b           pic x.
     03 filler           pic x(0012).
     03 filler17b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx17b           pic x.
     03 filler           pic x(0012).
     03 filler18b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx18b           pic x.
     03 filler           pic x(0092).
     03 filler19b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx19b           pic x.
     03 filler           pic x(0012).
     03 filler20b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx20b           pic x.
     03 filler           pic x(0012).
     03 filler21b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx21b           pic x.
     03 filler           pic x(0012).
     03 filler22b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx22b           pic x.
     03 filler           pic x(0012).
     03 filler23b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx23b           pic x.
     03 filler           pic x(0012).
     03 filler24b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx24b           pic x.
     03 filler           pic x(0012).
     03 filler25b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx25b           pic x.
     03 filler           pic x(0012).
     03 filler26b        pic x(0024).
     03 filler           pic x(0003).
     03 fxx26b           pic x.
     03 filler           pic x(0031).
     03 filler27b        pic x(0005).
     03 filler           pic x(0001).
 01  accounts-accept redefines accounts-display.
     03 filler           pic x(0489).
     03 ss-ar1-1         pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-1         pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-15        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-15        pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-2         pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-2         pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-16        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-16        pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-3         pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-3         pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-17        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-17        pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-4         pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-4         pic x(0001).
     03 filler           pic x(0132).
     03 ss-ar1-5         pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-5         pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-18        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-18        pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-6         pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-6         pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-19        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-19        pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-7         pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-7         pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-20        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-20        pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-8         pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-8         pic x(0001).
     03 filler           pic x(0132).
     03 ss-ar1-9         pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-9         pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-21        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-21        pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-10        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-10        pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-22        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-22        pic x(0001).
     03 filler           pic x(0092).
     03 ss-ar1-11        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-11        pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-23        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-23        pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-12        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-12        pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-24        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-24        pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-13        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-13        pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-25        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-25        pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-14        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-14        pic x(0001).
     03 filler           pic x(0012).
     03 ss-ar1-26        pic x(0024).
     03 filler           pic x(0003).
     03 ss-ar2-26        pic x(0001).
     03 filler           pic x(0031).
     03 ss-ar3           pic x(0005).
     03 filler           pic x.
