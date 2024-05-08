capture program drop cfbplot
capture program define cfbplot
syntax


version 8
marksample touse


*Transforming stored macros and scalars into useful locals
local cmd = e(cmd)
local proportion = e(proportion_c)
local mid = e(mid_c)
local ulll = e(ulll_c)
local legend = e(legend_c)
local z = e(z_c)
local base = e(base_c)
local valname = e(valname_c)
local signif = e(signif_c)


		**Error
/*
if "`cmd'" != "dynsimpie" {
	di in r _n "User must run dynsimpie before cfbplot"
	exit 198
}
*/

*Transforming stored matrix of results into useful dataset; making graph

matrix cfbplot = e(cfbplot)
preserve

svmat cfbplot, names(col)

twoway `mid' `ulll' legend(order(`legend' `z' "`base'")) xtitle("Time")  ///
ytitle("`valname' `proportion'") graphregion(color(white))	///
note("Note: `signif'% confidence intervals")

restore
end
