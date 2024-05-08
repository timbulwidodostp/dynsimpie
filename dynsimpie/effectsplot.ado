capture program drop effectsplot
capture program define effectsplot
syntax

version 8
marksample touse

*Transforming stored macros and scalars into useful locals
local cmd = e(cmd)
local valname = e(valname_e)
local sig = e(sig_e)
if `sig' ==. {
	local sig
}
local sig2 = e(sig2_e)
if `sig2' ==. {
	local sig2
}
local dvnames = e(dvnames_e)
local signif = e(signif_e)
local signif2 = e(signif2_e)
if `signif2' == . {
	local signif2
}
local Change = e(Change)




		**Error
/*
if "`cmd'" != "dynsimpie" {
	di in r _n "User must run dynsimpie before cfbplot"
	exit 198
}
*/

*Transforming stored matrix of results into useful dataset; making graph
matrix effectsplot = e(effectsplot)
preserve
 
svmat effectsplot, names(col)


	if  "`Change'" == "Percentage Change" {    //if "`percentage'" != "" 
		if "`sig2'" != "" {
			foreach v in var_pie_ul_sr1_   var_pie_ll_sr1_ var_pie_ul_lr1_  var_pie_ll_lr1_ var_pie_ul_sr2_  var_pie_ll_sr2_   var_pie_ul_lr2_      var_pie_ll_lr2_ mid_sr mid_lr {
				replace `v' = `v'*100
			}
		}
		 else {
			foreach v in var_pie_ul_sr1_   var_pie_ll_sr1_ var_pie_ul_lr1_  var_pie_ll_lr1_  mid_sr mid_lr {
				replace `v' = `v'*100
			}
		}
	}



   if "`sig2'" != "" {
     if "`sig2'" <  "`sig'"{
     twoway rspike var_pie_ul_sr1_ var_pie_ll_sr1_ sort_sr, horizontal lcolor(black) lwidth(thin) || ///
     rspike var_pie_ul_lr1_ var_pie_ll_lr1_ sort_lr, horizontal lcolor(black) lwidth(thin) || ///
     rspike var_pie_ul_sr2_ var_pie_ll_sr2_  sort_sr, horizontal lcolor(black) lwidth(medthick) || ///
     rspike var_pie_ul_lr2_ var_pie_ll_lr2_ sort_lr, horizontal lcolor(black) lwidth(medthick) || ///
     scatter  sort_sr mid_sr, msymbol(T) mcolor("27 158 119") msize(med)   || ///
     scatter  sort_lr mid_lr, msymbol(O) mcolor("117 112 179") msize(med)  ///
    xline(0, lcolor(black) lstyle(solid)) ///
    legend(order(1 " `signif'% CI " 3  " `signif2'% CI " 5 "Short-Run"  6 "Long-Run")) ///
	ylabel(`dvnames' , nogrid angle(0) labsize(small) ) /// 
	xtitle("`valname' `Change' from Baseline") plotregion(style(none)) yscale(axis(1) noline) ///
	xlabel(, nogrid glcolor(gs15)  labsize(small) ) graphregion(fcolor(white) lcolor(white)) saving(graph, replace) 
                         }
       else {
     twoway rspike var_pie_ul_sr1_ var_pie_ll_sr1_ sort_sr, horizontal lcolor(black) lwidth(medthick) || ///
     rspike var_pie_ul_lr1_ var_pie_ll_lr1_ sort_lr, horizontal lcolor(black) lwidth(medthick) || ///
     rspike var_pie_ul_sr2_ var_pie_ll_sr2_  sort_sr, horizontal lcolor(black) lwidth(thin) || ///
     rspike var_pie_ul_lr2_ var_pie_ll_lr2_ sort_lr, horizontal lcolor(black) lwidth(thin) || ///
     scatter  sort_sr mid_sr, msymbol(T) mcolor("27 158 119") msize(med)   || ///
     scatter  sort_lr mid_lr, msymbol(O) mcolor("117 112 179") msize(med)  ///
    xline(0, lcolor(black) lstyle(solid)) ///
    legend(order(3  " `signif2'% CI "  1 " `signif'% CI "  5 "Short-Run"  6 "Long-Run")) ///
	ylabel(`dvnames' , nogrid angle(0) labsize(small) ) /// 
	xtitle("`valname' `Change' from Baseline") plotregion(style(none)) yscale(axis(1) noline) ///
	xlabel(, nogrid glcolor(gs15)  labsize(small) ) graphregion(fcolor(white) lcolor(white)) saving(graph, replace) 
                         }
       }
       else	{
     twoway rspike var_pie_ul_sr1_ var_pie_ll_sr1_ sort_sr, horizontal lcolor(black) lwidth(thin) || ///
     rspike var_pie_ul_lr1_ var_pie_ll_lr1_ sort_lr, horizontal lcolor(black) lwidth(thin) || ///
     scatter  sort_sr mid_sr, msymbol(T) mcolor("27 158 119") msize(med) || ///
     scatter  sort_lr mid_lr, msymbol(O) mcolor("117 112 179") msize(med) ///
	xline(0, lcolor(black) lstyle(solid)) legend(order(3 "Short-Run" 4 "Long-Run") ) ///
	ylabel(`dvnames' , nogrid angle(0) labsize(small) ) /// 
	xtitle("`valname' `Change' from Baseline") plotregion(style(none)) yscale(axis(1) noline) ///
	xlabel(, nogrid glcolor(gs15)  labsize(small) ) graphregion(fcolor(white) lcolor(white)) saving(graph, replace)  ///
	note("Note: `signif'% confidence intervals") 
	
       }
	   
restore
end
