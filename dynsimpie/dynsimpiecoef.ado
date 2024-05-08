/******************************************************************************/
/*						       DYNSIMPIECOEF	    				          */
/*                       Last update: 15 Jan 2020							  */
/*																		      */
/*								Created by									  */
/*																			  */
/*							   Yoo Sun Jung									  */
/*     						 Flávio D.S. Souza								  */
/* 							 Andrew Q. Philips								  */
/*							 Amanda Rutherford								  */
/*							  Guy D. Whitten								  */
/*																		      */
/*                                                                            */
/*																		      */																  
/******************************************************************************/

capture program drop dynsimpiecoef 
capture program define dynsimpiecoef, rclass
syntax varlist(ts fv) [if] [in], [ dvs(varlist)] [ar(numlist integer max=3)] ///
[INTERaction(varname)] [dummy(varlist)] [ecm]                ///
[sigs(numlist integer < 100)] [KILLTABle]  [smooth]  ///
[row(numlist)] [xsize(numlist)] [all] [VERTical] [angle(numlist)]

version 8
marksample touse
preserve

******************
******************
if "`ecm'" != ""	{
	if  "`ar'" != ""	{
		di in r _n "Option ar is not allowed with ecm."
		exit 198
}
	if  "`interaction'" != ""	{
		di in r _n "Option interaction is not allowed along with ecm."
		exit 198
	}
}
else {
	if "`ar'" =="" {
		di in r _n "Option ar must be specified if ecm is not specified."
		exit 198
	}
}
local nosave nosave
******************
******************

if "`ecm'" == "" {
local controls `varlist'

******Making Log-Ratios******
******************************

if "`dvs'" == ""        {
        di in r _n "Must specify dependent compositional variables in dvs( )"
        exit 198
}
else    {
        tempvar checksum
        qui gen `checksum' = 0
        qui foreach var of varlist `dvs'        {
                replace `checksum' = `checksum' + `var'
        }
        qui su `checksum'
        if r(min) < .99 {
                di in r _n "The dependent variables must sum to either 1 or 100"
                exit 198
        }
        if r(max) > 1.01 & r(min) < 99  {
                di in r _n "The dependent variables must sum to either 1 or 100"
                exit 198
        }
        if r(max) > 101 {
                di in r _n "The dependent variables must sum to either 1 or 100"
                exit 198
        }
        drop `checksum'
}


loc ns: word count `sigs'
tokenize  `sigs'
local sig `1'
local sig2 `2'

if "`sigs'" == ""	{	   //default=95 
 	 loc signif 95 
         loc sigl = (100-`signif')/2
         loc sigu = 100-((100-`signif')/2) 
         }
else{         
						// getting the CI's signif
	loc signif `sig'
        loc sigl = (100-`signif')/2
        loc sigu = 100-((100-`signif')/2)

     if "`sig2'" != ""	{					// the additional CI's signif
        if "`ns'" > "2"	{
	di in r _n "The total number of sig level cannot exceed 2"  
	exit 198
           }
       else {
          if `sig' >= `sig2' {
	   di in r _n "The first sig level in sigs list must be smaller than the second one"
	   exit 198
           }
        else{
        local signif2 `sig2'
        local sigl2 = (100-`signif2')/2
        local sigu2 = 100-((100-`signif2')/2)
          }
       }
 }
 }


if "`smooth'" != ""	{						
    if "`sig'" != ""	{
      di in r _n "sig or sig2 must not be specified with smooth"
        exit 198
    }
    else{
       if "`sig2'" != ""	{
    	di in r _n "sig or sig2 must not be specified with smooth"
        exit 198
        }
        else{
         }
       }
   }



if "`all'" != ""	{						
    if "`vertical'" != ""	{
      di in r _n "all must not be specified with vertical"
        exit 198
    }
   }



if "`row'" != ""	{						// row number of graph (using graph combine)
	loc rownum `row'
}
else	{

  if "`vertical'" != "" {
	loc rownum 3   //defualt = 3 for vertical coefplots   
     }
  else{
        loc rownum 1   //defualt = 1 for regular (horizontal) coefplots
   }
}


if "`xsize'" != ""	{		// x-size of graph 
	loc xsizenum `xsize'
}
else	{
	loc xsizenum 5   //defualt = 5
}

if "`angle'" != ""	{		// angle for x labels for vertical coeofplots
       if "`vertical'" == "" { 
        di in r _n "angle must be specified with vertical"
	exit 198
    }
else{
	loc anglenum `angle'
}
}
else	{
	loc anglenum 90     //defualt = 90
}

*******************************
*******************************

if "`all'" != ""{
loc dvn  `: word count `dvs''   // `dvn'= # of dv categories
loc complist
loc j 1  
	forvalues j = 1(1)`dvn'{
		 loc i 1
		 foreach var of varlist `dvs' {
		  if `i' < `j' {
		  }
		  else {
				if `i' == `j'	{
				loc basevar `var'
						 } 
			  else	        {
				capture drop `var'_`basevar'
				gen `var'_`basevar' = ln(`var'/`basevar')
				loc complist `"`complist' `var'_`basevar'"'
						}
			}
		loc i = `i' + 1	
		 }   
	}
} //close all is chosen
else{
	if "`vertical'" != ""{
		loc dvn  `: word count `dvs''   // `dvn'= # of dv categories
		loc complist
		loc j 1  
		forvalues j = 1(1)`dvn'{
			 loc i 1
			 foreach var of varlist `dvs' {
				  if `i' < `j' {
				  }
				  else {
						if `i' == `j'	{
						loc basevar `var'
								 } 
					  else	        {
						capture drop `var'_`basevar'
						gen `var'_`basevar' = ln(`var'/`basevar')
						loc complist `"`complist' `var'_`basevar'"'
								}
					}
			loc i = `i' + 1	
			 }   
		}
	}   //if vertical is chosen
	else{
		loc complist
		loc i 1
		foreach var of varlist `dvs' {
			if "`i'" == "1"	{
				loc basevar `var'
			} 
			else	{
				capture drop `var'_`basevar'
				gen `var'_`basevar' = ln(`var'/`basevar')
				loc complist `"`complist' `var'_`basevar'"'
			}
		loc i = `i' + 1	
		}
	}  //close: vertical is not chosen 
}  //close: all is not chosen  (close: complist)

******************************
******************************

*Cannot Time Difference and Time Lag at the Same Time
local ivs `interaction' `dummy' `controls'
foreach n of varlist `ivs' {
	if substr("`n'",1,4)=="D.L." | substr("`n'",1,4)=="d.l." | substr("`n'",1,4)=="D.l." | substr("`n'",1,4)=="d.L." {
		di in r _n "Variables may not be time differenced and time lagged at the same time."
		exit 198
	}
	if substr("`n'",1,4)=="L.D." | substr("`n'",1,4)=="l.d." | substr("`n'",1,4)=="l.D." | substr("`n'",1,4)=="L.d." {
	di in r _n "Variables may not be time differenced and time lagged at the same time."
	exit 198
	}
 	foreach v of numlist 1/1 {
		if substr("`shockvar'",1,5)=="D`v'.L." | substr("`shockvar'",1,5)=="d`v'.l." | substr("`shockvar'",1,5)=="D`v'.l." | substr("`shockvar'",1,5)=="d`v'.L." {
		di in r _n "Variables may not be time differenced and time lagged at the same time."
		exit 198
		}
	 }
	 foreach v of numlist 1/3 {
		if substr("`shockvar'",1,5)=="L`v'.D." | substr("`shockvar'",1,5)=="l`v'.d." | substr("`shockvar'",1,5)=="L`v'.d." | substr("`shockvar'",1,5)=="l`v'.D." {
		di in r _n "Variables may not be time differenced and time lagged at the same time."
		exit 198
		}
	 }
	 foreach v of numlist 1/3 {
		if substr("`shockvar'",1,6)=="L`v'.D`v'." | substr("`shockvar'",1,6)=="l`v'.d`v'." | substr("`shockvar'",1,6)=="L`v'.d`v'." | substr("`shockvar'",1,6)=="l`v'.D`v'." {
		di in r _n "Variables may not be time differenced and time lagged at the same time."
		exit 198
		}
	 }
	 foreach v of numlist 1/1 {
		if substr("`shockvar'",1,6)=="D`v'.L`v'." | substr("`shockvar'",1,6)=="d`v'.l`v'." | substr("`shockvar'",1,6)=="D`v'.l`v'." | substr("`shockvar'",1,6)=="d`v'.L`v'." {
		di in r _n "Variables may not be time differenced and time lagged at the same time."
		exit 198
		}
	 }
}


* Differences and Lags of controls
if "`controls'" != "" {
loc controls1
foreach wx of varlist `controls' {

if substr("`wx'",1,2)=="D." | substr("`wx'",1,2)=="d." { //If user inputs first difference of wx
	 loc diffwx = substr("`wx'",3,.)
	 capture drop diff__`diffwx'
	 gen diff__`diffwx' = D.`diffwx'
	 loc wx diff__`diffwx'
 }
  if substr("`wx'",1,3)=="D1." | substr("`wx'",1,3)=="d1." {
	 loc diffwx = substr("`wx'",4,.)
	 capture drop diff__`diffwx'
	 gen diff__`diffwx' = D.`diffwx'
	 loc wx diff__`diffwx'
 }
	 foreach v of numlist 2/9 {
		if substr("`wx'",1,3)=="D`v'." | substr("`wx'",1,3)=="d`v'." {
		di in r _n "A wx may not be time differenced multiple times."
		exit 198
		}
	 }
	 foreach v of numlist 10/99 {
		if substr("`wx'",1,4)=="D`v'." | substr("`wx'",1,4)=="d`v'." {
		di in r _n "A control may not be time differenced multiple times."
		exit 198
		}
	 }
 
 if substr("`wx'",1,2)=="L." | substr("`wx'",1,2)=="l." { //If user inputs first lag of wx
	 loc lagwx = substr("`wx'",3,.)
	 capture drop lag__`lagwx'
	 gen lag__`lagwx' = L.`lagwx'
	 loc wx lag__`lagwx'
 }
  if substr("`wx'",1,3)=="L1." | substr("`wx'",1,3)=="l1." {
	 loc lagwx = substr("`wx'",4,.)
	 capture drop lag__`lagwx'
	 gen lag__`lagwx' = L.`lagwx'
	 loc wx lag__`lagwx'
	 }
	 
  if substr("`wx'",1,3)=="L2." | substr("`wx'",1,3)=="l2." {
	 loc lagwx = substr("`wx'",4,.)
	 capture drop lag2__`lagwx'
	 gen lag2__`lagwx' = L2.`lagwx'
	 loc wx lag2__`lagwx'
	 }
	 
  if substr("`wx'",1,3)=="L3." | substr("`wx'",1,3)=="l3." {
	 loc lagwx = substr("`wx'",4,.)
	 capture drop lag3__`lagwx'
	 gen lag3__`lagwx' = L3.`lagwx'
	 loc wx lag3__`lagwx'
	 }
 
  foreach v of numlist 4/9 {
	if substr("`wx'",1,3)=="L`v'." | substr("`wx'",1,3)=="l`v'." {
	di in r _n "A control may not be time lagged more than three times."
	exit 198
	}
  }
  foreach v of numlist 10/99 {
	if substr("`wx'",1,4)=="L`v'." | substr("`wx'",1,4)=="l`v'." {
	di in r _n "A control may not be time lagged more than three times."
	exit 198
	}
  }
  loc controls1 `controls1' `wx'
}

loc controls `controls1'
}
local ivs
if "`interaction'" != "" {
	tokenize `controls'
	local intervar `1'_`interaction'
	capture drop `intervar'
	qui gen `intervar' = `1'*`interaction'
	local ivs `controls' `dummy' `intervar' `interaction'
}
else {
	local ivs `controls' `dummy'
}
macro list
if "`ar'" != "" {
loc i 1
foreach l of local ar {
		if `i'==1 {
		local ar_a `l'
		} 
		if `i'==2 {
		local ar_b `l'
		}
		if `i'==3 {
		local ar_c `l'
		}
		loc i = `i' + 1
	}
}

loc model
local i 1
foreach var of varlist `complist'	{
	*****************************
	if "`ar_a'" != "" {
	capture drop L`ar_a'_`var'
	qui gen L`ar_a'_`var' = l`ar_a'.`var'
	local l`ar_a'depvar`i' L`ar_a'_`var'
	local lags `lags' `l`ar_a'depvar`i''
	}
	if "`ar_b'" != "" {
	capture drop L`ar_b'_`var'
	qui gen L`ar_b'_`var' = l`ar_b'.`var'
	local l`ar_b'depvar`i' L`ar_b'_`var'
	local lags `lags' `l`ar_b'depvar`i''
	}
	if "`ar_c'" != "" {
	capture drop L`ar_c'_`var'
	qui gen L`ar_c'_`var' = l`ar_c'.`var'
	local l`ar_c'depvar`i' L`ar_c'_`var'
	local lags `lags' `l`ar_c'depvar`i''
	}
	*****************************
	* get the model:
	local model `"`model' (`var' `l`ar_a'depvar`i'' `l`ar_b'depvar`i'' `l`ar_c'depvar`i'' `ivs')"'
	local i = `i' + 1
}
qui sureg `model'						// run the model and keep sample
qui keep if e(sample)
if "`killtable'"	!= ""	{
	qui estsimp sureg `model'
}
else	{
	estsimp sureg `model'					// run Clarify
}



if "`nosave'" != ""	{					// save estimates?
}
else	{
	di ""
	if "`saving'" != "" {
		noi save `saving'.dta, replace
	}
	else	{
		noi save dynsimpie_results.dta, replace
	}
}
* ------------------------ COEFFICIENT PLOT ---------------------

if "`all'" != ""{


if "`sig'" != ""	{

loc dvn  `: word count `dvs''   // `dvn'= # of dv categories
loc clist
loc j 1  
forvalues j = 1(1)`dvn'{
     loc i 1
     foreach var of varlist `dvs' {
	  if `i' < `j' {
	  }
	  else {
            if `i' == `j'	{
            loc basevar `var'
		             } 
          else	        {
                capture drop `var'_`basevar'
	        gen `var'_`basevar' = ln(`var'/`basevar')
	        loc clist `"`clist' `var'_`basevar'"'
	                }
		}
    loc i = `i' + 1	
     }   
}


if "`smooth'" != ""{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,   xline(0, lcolor(red)) ciopts(recast(rcap))  nolab coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
	           saving(g_`var', replace )  cismooth
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')   xcommon		
	 
   }   //below: sig is identified & smooth option is not identified
else{
 if "`sig2'" != "" {   //note: multiple CIs not with ciopts(recast(rcap))  option
                       //      we can use "ciopts(recast(. rcap))" but it looks ugly
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  levels(`signif2'  `signif' ) legend(order(1 "`signif2'% CI" 2 "`signif'% CI") row(1) ) ///
                xline(0, lcolor(red)) nolab coeflabel(, wrap(20)) eqstrict keep(`var': ) saving(g_`var', replace ) 
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')   xcommon	

}  //below: sig is identified, smooth is  not identified, sig2 is not identified
else{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  levels(`signif') xline(0, lcolor(red)) ciopts(recast(rcap)) nolab coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
                note("Note. `signif'% confidence interval.", span)  saving(g_`var', replace ) 
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')   xcommon	
}  //close: sig2 is not identified
}  //close: smooth is not identified 	 
} // close: sig is identified  & below: sig is not identified
else	{
loc dvn  `: word count `dvs''   // `dvn'= # of dv categories
loc clist
loc j 1  
forvalues j = 1(1)`dvn'{
     loc i 1
     foreach var of varlist `dvs' {
	  if `i' < `j' {
	  }
	  else {
            if `i' == `j'	{
            loc basevar `var'
		             } 
          else	        {
            capture drop `var'_`basevar'
	        gen `var'_`basevar' = ln(`var'/`basevar')
	        loc clist `"`clist' `var'_`basevar'"'
	                }
		}
    loc i = `i' + 1	
     }   
}


if "`smooth'" != ""{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  xline(0, lcolor(red)) ciopts(recast(rcap)) nolab coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
	           saving(g_`var', replace )   cismooth
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')   xcommon		
	 
  }  //below: if smooth is not identified

else{
if "`sig2'" != "" {
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  levels(`signif2'  `signif' ) legend(order(1  "`signif2'% CI" 2 "95% CI" ) row(1) ) ///
                xline(0 , lcolor(red)) nolab coeflabel(, wrap(20)) eqstrict keep(`var': ) saving(g_`var', replace ) 
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')   xcommon		
}   //below:  sig2 is not identified
else{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  xline(0 , lcolor(red)) ciopts(recast(rcap)) nolab coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
	        note("Note. 95% confidence interval.", span)  saving(g_`var', replace )  
     local G "`G'g_`var'.gph " 
}   
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')   xcommon	

}   //close: sig2	 
}   //close: smooth      
}   //close: sig 


} //close: if all is chosen 

else{

if "`vertical'" != ""{

loc rhs
loc i 1

qui foreach var of varlist `complist' {
	capture drop L_`var' 
	gen L_`var' = l.`var'				// gen lag DV
	loc lcomplist `"`lcomplist' L_`var'"'	// needed for future setx
	loc LDvars `"`LDvars' L_`var'"'

}

loc rhs `"`rhs' `lags' `ivs' "'

loc i 1
if "`sig'" != ""	{
if "`smooth'" != ""{
qui foreach var of varlist `rhs'{
capture rm "allg_`var'.gph"		
qui coefplot, yline(0, lcolor(red)) vertical  graphregion(fcolor(white)) nolab  xlabel(, angle(`anglenum'))   ///
          coeflabel(, labgap(1))  ytitle("Parameter estimate")  ///
          title("`var'") swapnames  noeqlabels  cismooth /// 1. swap coef & equ names. Then 2. suppress equation labels  so that we only see equa names instead of coef names
		  keep(*: `var' ) nokey ///display all equation, one variable  (no key: prevent including plot in the legend)
		  saving(allg_`var', replace ) 
local G "`G'allg_`var'.gph " 		  
 }
graph combine `G', graphregion(fcolor(white))  xsize(`xsizenum') row(`rownum') 
} //close: if smooth exists
else{
    if "`sig2'" != "" {  
     qui foreach var of varlist `rhs'{
     capture rm "allg_`var'.gph"		
     qui coefplot,  levels(`signif2'  `signif' )   ///
                      yline(0, lcolor(red)) vertical graphregion(fcolor(white)) nolab xlabel(, angle(`anglenum'))  ///
                     coeflabel(, labgap(1))  ytitle("Parameter estimate")  ///
                     title("`var'") swapnames  noeqlabels /// 1. swap coef & equ names. Then 2. suppress equation labels  so that we only see equa names instead of coef names
		  keep(*: `var' ) nokey ///display all equation, one variable  (no key: prevent including plot in the legend)
		  saving(allg_`var', replace ) 
local G "`G'allg_`var'.gph " 		  
 }
graph combine `G', graphregion(fcolor(white))  xsize(`xsizenum') row(`rownum') 
} //close:if sig2 exists
else{
qui foreach var of varlist `rhs'{
capture rm "allg_`var'.gph"		
qui coefplot , levels(`signif')  vertical yline(0, lcolor(red)) nolab ciopts(recast(rcap)) graphregion(fcolor(white))  xlabel(, angle(`anglenum'))   ///
          coeflabel(, labgap(1))  ytitle("Parameter estimate")  ///
          title("`var'") swapnames  noeqlabels /// 1. swap coef & equ names. Then 2. suppress equation labels  so that we only see equa names instead of coef names
		  keep(*: `var' ) nokey ///display all equation, one variable  (no key: prevent including plot in the legend)
		  saving(allg_`var', replace ) 
local G "`G'allg_`var'.gph " 		  
 }
graph combine `G', graphregion(fcolor(white))  xsize(`xsizenum') row(`rownum') 
}  //close:sig2 option in smooth 
}  //close:smooth option
}  //close:sig exists

else{
if "`smooth'" != ""{
qui foreach var of varlist `rhs'{
capture rm "allg_`var'.gph"		
qui coefplot, yline(0, lcolor(red)) vertical  graphregion(fcolor(white)) nolab xlabel(, angle(`anglenum'))   ///
          coeflabel(, labgap(1))  ytitle("Parameter estimate")  ///
          title("`var'") swapnames  noeqlabels  cismooth /// 1. swap coef & equ names. Then 2. suppress equation labels  so that we only see equa names instead of coef names
		  keep(*: `var' ) nokey ///display all equation, one variable  (no key: prevent including plot in the legend)
		  saving(allg_`var', replace ) 
local G "`G'allg_`var'.gph " 		  
 }
graph combine `G', graphregion(fcolor(white))  xsize(`xsizenum') row(`rownum') 
} //close: if smooth exists
else{
    if "`sig2'" != "" {  
     qui foreach var of varlist `rhs'{
     capture rm "allg_`var'.gph"		
     qui coefplot,  levels(`signif2'  `signif' )    ///
                      yline(0, lcolor(red)) vertical   graphregion(fcolor(white)) nolab xlabel(, angle(`anglenum'))   ///
                     coeflabel(, labgap(1))   ytitle("Parameter estimate")  ///
                     title("`var'") swapnames  noeqlabels /// 1. swap coef & equ names. Then 2. suppress equation labels  so that we only see equa names instead of coef names
		  keep(*: `var' ) nokey ///display all equation, one variable  (no key: prevent including plot in the legend)
		  saving(allg_`var', replace ) 
local G "`G'allg_`var'.gph " 		  
 }
graph combine `G', graphregion(fcolor(white))  xsize(`xsizenum') row(`rownum') 
} //close:if sig2 exists
else{   //none of sig, sig2, smooth is specified. by default, sig=95%
qui foreach var of varlist `rhs'{
capture rm "allg_`var'.gph"		
qui coefplot , levels(`signif')  vertical yline(0, lcolor(red)) ciopts(recast(rcap)) nolab graphregion(fcolor(white))   xlabel(, angle(`anglenum'))   ///
          coeflabel(, labgap(1))  ytitle("Parameter estimate")  ///
          title("`var'") swapnames  noeqlabels /// 1. swap coef & equ names. Then 2. suppress equation labels  so that we only see equa names instead of coef names
		  keep(*: `var' ) nokey ///display all equation, one variable  (no key: prevent including plot in the legend)
		  saving(allg_`var', replace ) 
local G "`G'allg_`var'.gph " 		  
 }
graph combine `G', graphregion(fcolor(white))  xsize(`xsizenum') row(`rownum') 
}  //close:sig2 option in smooth 
}  //close:smooth option

}  //close:sig option


}  //close: if all is not chosen  but vertical is chosen

else{

if "`sig'" != ""	{
loc clist
loc i 1
foreach var of varlist `dvs' {
if "`i'" == "1"	{
	loc basevar `var'
} 
else	{
	capture drop `var'_`basevar'
	gen `var'_`basevar' = ln(`var'/`basevar')
	loc clist `"`clist' `var'_`basevar'"'


}
loc i = `i' + 1	
}

if "`smooth'" != ""{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,   xline(0, lcolor(red)) ciopts(recast(rcap)) nolab  coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
	           saving(g_`var', replace )  cismooth
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')   xcommon		
	 
   }   //below: sig is identified & smooth option is not identified
else{
 if "`sig2'" != "" {   //note: multiple CIs not with ciopts(recast(rcap))  option
                       //      we can use "ciopts(recast(. rcap))" but it looks ugly
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  levels(`signif2' `signif' ) legend(order(1 "`signif2'% CI" 2 "`signif'% CI" ) row(1) ) ///
                xline(0, lcolor(red)) nolab coeflabel(, wrap(20)) eqstrict keep(`var': ) saving(g_`var', replace ) 
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')   xcommon	

}  //below: sig is identified, smooth is  not identified, sig2 is not identified
else{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  levels(`signif') xline(0, lcolor(red)) nolab ciopts(recast(rcap)) coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
                note("Note. `signif'% confidence interval.", span)  saving(g_`var', replace ) 
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum') xcommon	
}  //close: sig2 is not identified
}  //close: smooth is not identified 	 
} // close: sig is identified  & below: sig is not identified

else	{
loc clist
loc i 1
foreach var of varlist `dvs' {
if "`i'" == "1"	{
	loc basevar `var'
} 
else	{
	capture drop `var'_`basevar'
	gen `var'_`basevar' = ln(`var'/`basevar')
	loc clist `"`clist' `var'_`basevar'"'
}
loc i = `i' + 1	
}



if "`smooth'" != ""{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  xline(0, lcolor(red)) nolab ciopts(recast(rcap)) coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
	           saving(g_`var', replace )   cismooth
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum') xcommon		
	 
  }  //below: if smooth is not identified

else{
if "`sig2'" != "" {
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  levels(`signif2'  `signif' ) legend(order(1 "`signif2'% CI" 2 "95% CI" ) row(1) ) ///
                xline(0 , lcolor(red))  nolab coeflabel(, wrap(20)) eqstrict keep(`var': ) saving(g_`var', replace ) 
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum') xcommon		
}   //below:  sig2 is not identified
else{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  xline(0 , lcolor(red)) ciopts(recast(rcap)) nolab coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
	        note("Note. 95% confidence interval.", span)  saving(g_`var', replace )  
     local G "`G'g_`var'.gph " 
}   
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum') xcommon	

}   //close: sig2	 
}   //close: smooth      
}   //close: sig 
}   //close: vertical is chosen  
}  //close: if all is not chosen 
} //close: if ecm is not chosen
else {
* check to make sure dvs all sum to 1, or 100:
if "`dvs'" == ""	{
	di in r _n "Option dvs( ) must be specified"
	exit 198
}
else	{
	tempvar checksum
	qui gen `checksum' = 0
	qui foreach var of varlist `dvs'	{
		replace `checksum' = `checksum' + `var'
	}
	qui su `checksum'
	if r(min) < .99	{
		di in r _n "The dependent variables must sum to either 1 or 100"
		exit 198
	}
	if r(max) > 1.01 & r(min) < 99	{
		di in r _n "The dependent variables must sum to either 1 or 100"
		exit 198
	}
	if r(max) > 101 {
		di in r _n "The dependent variables must sum to either 1 or 100"
		exit 198
	}
	drop `checksum'
}



loc ns: word count `sigs'
tokenize  `sigs'
local sig `1'
local sig2 `2'

if "`sigs'" == ""	{	   //default=95 
 	 loc signif 95 
         loc sigl = (100-`signif')/2
         loc sigu = 100-((100-`signif')/2) 
         }
else{         
						// getting the CI's signif
	loc signif `sig'
        loc sigl = (100-`signif')/2
        loc sigu = 100-((100-`signif')/2)

     if "`sig2'" != ""	{					// the additional CI's signif
        if "`ns'" > "2"	{
	di in r _n "The total number of sig level cannot exceed 2"  
	exit 198
           }
       else {
          if `sig' >= `sig2' {
	   di in r _n "The first sig level in sigs list must be smaller than the second one"
	   exit 198
           }
        else{
        local signif2 `sig2'
        local sigl2 = (100-`signif2')/2
        local sigu2 = 100-((100-`signif2')/2)
          }
       }
 }
 }


if "`smooth'" != ""	{						
    if "`sig'" != ""	{
      di in r _n "sig or sig2 must not be specified with smooth"
        exit 198
    }
    else{
       if "`sig2'" != ""	{
    	di in r _n "sig or sig2 must not be specified with smooth"
        exit 198
        }
        else{
         }
       }
   }



if "`all'" != ""	{						
    if "`vertical'" != ""	{
      di in r _n "all must not be specified with vertical"
        exit 198
    }
   }



if "`row'" != ""	{						// row number of graph (using graph combine)
	loc rownum `row'
}
else	{

  if "`vertical'" != "" {
	loc rownum 3   //default = 3 for vertical coefplots   
     }
  else{
        loc rownum 1   //default = 1 for regular (horizontal) coefplots
   }
}


if "`xsize'" != ""	{		// x-size of graph 
	loc xsizenum `xsize'
}
else	{
	loc xsizenum 5   //default = 5
}

if "`angle'" != ""	{		// angle for x labels for vertical coeofplots
       if "`vertical'" == "" { 
        di in r _n "angle must be specified with vertical"
	exit 198
    }
else{
	loc anglenum `angle'
}
}
else	{
	loc anglenum 90     //default = 90
}


* ------------------------Generating Variables & Run Model ---------------------
* create compositions:

if "`all'" != ""{
loc dvn  `: word count `dvs''   // `dvn'= # of dv categories
loc complist
loc j 1  
forvalues j = 1(1)`dvn'{
     loc i 1
     foreach var of varlist `dvs' {
	  if `i' < `j' {
	  }
	  else {
            if `i' == `j'	{
            loc basevar `var'
		             } 
          else	        {
            capture drop `var'_`basevar'
	        gen `var'_`basevar' = ln(`var'/`basevar')
	        loc complist `"`complist' `var'_`basevar'"'
	                }
		}
    loc i = `i' + 1	
     }   
}
} //close all is chosen
else{
if "`vertical'" != ""{
loc dvn  `: word count `dvs''   // `dvn'= # of dv categories
loc complist
loc j 1  
forvalues j = 1(1)`dvn'{
     loc i 1
     foreach var of varlist `dvs' {
	  if `i' < `j' {
	  }
	  else {
            if `i' == `j'	{
            loc basevar `var'
		             } 
          else	        {
            capture drop `var'_`basevar'
	        gen `var'_`basevar' = ln(`var'/`basevar')
	        loc complist `"`complist' `var'_`basevar'"'
	                }
		}
    loc i = `i' + 1	
     }   
}
}   //if vertical is chosen
else{
loc complist
loc i 1
foreach var of varlist `dvs' {
if "`i'" == "1"	{
	loc basevar `var'
} 
else	{
	capture drop `var'_`basevar'
	gen `var'_`basevar' = ln(`var'/`basevar')
	loc complist `"`complist' `var'_`basevar'"'
}
loc i = `i' + 1	
}
}  //close: vertical is not chosen 
}  //close: all is not chosen  (close: complist)




loc lvars 
loc dvars
qui foreach var of varlist `varlist'  {		// create d. and l. indep vars
	capture drop L_`var' D_`var'
	gen L_`var' = l.`var'
	gen D_`var' = d.`var' 
	loc lvars `"`lvars' L_`var'"'
	loc dvars `"`dvars' D_`var'"'
}		


if "`dummy'" != ""{
loc ldummyvars 
loc ddummyvars
qui foreach var of varlist `dummy'  {		// create d. and l. dummy vars
	capture drop Ldummy_`var' Ddummy_`var'
	gen Ldummy_`var' = l.`var'
	gen Ddummy_`var' = d.`var' 
	loc ldummyvars `"`ldummyvars' Ldummy_`var'"'
	loc ddummyvars `"`ddummyvars' Ddummy_`var'"'
}		
}



if "`dummy'" != ""{ 

loc model
loc i 1
qui foreach var of varlist `complist' {
	capture drop L_`var' D_`var'
	tempvar mdepvar`i'
	gen L_`var' = l.`var'				// gen lag DV
	loc lcomplist `"`lcomplist' L_`var'"'	// needed for future setx
	gen D_`var' = d.`var'				// gen diff DV
	gen `mdepvar`i'' = `var'			// grab means
	* Get the model
	loc model `"`model' (D_`var' L_`var' `dvars' `lvars'  `ddummyvars' `ldummyvars')"'
	loc i = `i' + 1
}
}      //dummy exists 
else{   //no dummy exists 
loc model
loc i 1
qui foreach var of varlist `complist' {
	capture drop L_`var' D_`var'
	tempvar mdepvar`i'
	gen L_`var' = l.`var'				// gen lag DV
	loc lcomplist `"`lcomplist' L_`var'"'	// needed for future setx
	gen D_`var' = d.`var'				// gen diff DV
	gen `mdepvar`i'' = `var'			// grab means
	* Get the model
	loc model `"`model' (D_`var' L_`var' `dvars' `lvars')"'
	loc i = `i' + 1
}
} //close: dummy or not
 
qui sureg `model'						// run the model and keep sample
qui keep if e(sample)
if "`killtable'"	!= ""	{
	qui estsimp sureg `model'
}
else	{
	estsimp sureg `model'					// run Clarify
}



if "`nosave'" != ""	{					// save estimates?
}
else	{
	di ""
	if "`saving'" != "" {
		noi save `saving'.dta, replace
	}
	else	{
		noi save dynsimpie_results.dta, replace
	}
}



* ------------------------ COEFFICIENT PLOT ---------------------
if "`all'" != ""{


if "`sig'" != ""	{

loc dvn  `: word count `dvs''   // `dvn'= # of dv categories
loc clist
loc j 1  
forvalues j = 1(1)`dvn'{
     loc i 1
     foreach var of varlist `dvs' {
	  if `i' < `j' {
	  }
	  else {
            if `i' == `j'	{
            loc basevar `var'
		             } 
          else	        {
                capture drop D_`var'_`basevar'
	        gen D_`var'_`basevar' = ln(`var'/`basevar')
	        loc clist `"`clist' D_`var'_`basevar'"'
	                }
		}
    loc i = `i' + 1	
     }   
}




if "`smooth'" != ""{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,   xline(0, lcolor(red)) ciopts(recast(rcap))  coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
	           saving(g_`var', replace )  cismooth
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')  ycommon xcommon		
	 
   }   //below: sig is identified & smooth option is not identified
else{
 if "`sig2'" != "" {   //note: multiple CIs not with ciopts(recast(rcap))  option
                       //      we can use "ciopts(recast(. rcap))" but it looks ugly
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  levels(`signif2'  `signif' ) legend(order(1 "`signif2'% CI" 2 "`signif'% CI") row(1) ) ///
                xline(0, lcolor(red))   coeflabel(, wrap(20)) eqstrict keep(`var': ) saving(g_`var', replace ) 
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')  ycommon xcommon	

}  //below: sig is identified, smooth is  not identified, sig2 is not identified
else{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  levels(`signif') xline(0, lcolor(red)) ciopts(recast(rcap))  coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
                note("Note. `signif'% confidence interval.", span)  saving(g_`var', replace ) 
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')  ycommon xcommon	
}  //close: sig2 is not identified
}  //close: smooth is not identified 	 
} // close: sig is identified  & below: sig is not identified
else	{
loc dvn  `: word count `dvs''   // `dvn'= # of dv categories
loc clist
loc j 1  
forvalues j = 1(1)`dvn'{
     loc i 1
     foreach var of varlist `dvs' {
	  if `i' < `j' {
	  }
	  else {
            if `i' == `j'	{
            loc basevar `var'
		             } 
          else	        {
            capture drop D_`var'_`basevar'
	        gen D_`var'_`basevar' = ln(`var'/`basevar')
	        loc clist `"`clist' D_`var'_`basevar'"'
	                }
		}
    loc i = `i' + 1	
     }   
}


if "`smooth'" != ""{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  xline(0, lcolor(red)) ciopts(recast(rcap))  coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
	           saving(g_`var', replace )   cismooth
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')  ycommon xcommon		
	 
  }  //below: if smooth is not identified

else{
if "`sig2'" != "" {
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  levels(`signif2'  `signif' ) legend(order(1  "`signif2'% CI" 2 "95% CI" ) row(1) ) ///
                xline(0 , lcolor(red))  coeflabel(, wrap(20)) eqstrict keep(`var': ) saving(g_`var', replace ) 
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')  ycommon xcommon		
}   //below:  sig2 is not identified
else{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  xline(0 , lcolor(red)) ciopts(recast(rcap))  coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
	        note("Note. 95% confidence interval.", span)  saving(g_`var', replace )  
     local G "`G'g_`var'.gph " 
}   
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')  ycommon xcommon	

}   //close: sig2	 
}   //close: smooth      
}   //close: sig 


} //close: if all is chosen
else{



if "`vertical'" != ""{

loc rhs
loc i 1

qui foreach var of varlist `complist' {
	capture drop L_`var' 
	gen L_`var' = l.`var'				// gen lag DV
	loc lcomplist `"`lcomplist' L_`var'"'	// needed for future setx
	loc LDvars `"`LDvars' L_`var'"'

}


if "`shockvar'" != ""	{
   
   if "`dummyshockvar'" != ""	{

       if "`dummy'" != ""	{
         loc rhs `"`rhs' `LDvars' `dvars' `lvars' `diffshockvariables' `lagshockvariables' `ddummyvars' `ldummyvars'  `diffdummyshockvariable' `lagdummyshockvariable'  "'
            }  //close (dummy, dummyshockvar, and shockvar all exist)
          else{
     loc rhs `"`rhs' `LDvars' `dvars' `lvars' `diffshockvariables' `lagshockvariables' `diffdummyshockvariable' `lagdummyshockvariable'  "'
            } //close (dummyshockvar and shockvar  exist, no dummy)
       }  //close (dummyshockvar and shockvar  exist)
     else{        // no dummyshockvar 
         if "`dummy'" != ""	{
         loc rhs `"`rhs' `LDvars' `dvars' `lvars' `diffshockvariables' `lagshockvariables' `ddummyvars' `ldummyvars'  "'
            }  //close (dummy and shockvar exist, no dummyshockvar)
          else{
     loc rhs `"`rhs' `LDvars' `dvars' `lvars' `diffshockvariables' `lagshockvariables' "'
            } 
} //close (shockvar exists, no dummyshockvar & no dummy)
} //close shockvar exists
else{  //shockvar does not exist
   
  if "`dummyshockvar'" != ""	{
       if "`dummy'" != "" {
      loc rhs `"`rhs' `LDvars' `dvars' `lvars' `ddummyvars' `ldummyvars'  `diffdummyshockvariable' `lagdummyshockvariable'"'
            }  //close (dummy  and dummyshockvar exist, no shockvar)
        else{
     loc rhs `"`rhs' `LDvars' `dvars' `lvars' `diffdummyshockvariable' `lagdummyshockvariable'  "'
            } //close (dummyshockvar exists. no shockvar & no dummy)
       }  //close (dummyshockvar  exists)
     else{        // no dummyshockvar 
         if "`dummy'" != ""	{
         loc rhs `"`rhs' `LDvars' `dvars' `lvars'  `ddummyvars' `ldummyvars'  "'
            }  //close (dummy  exists, no dummyshockvar & no shockvar)
          else{
          loc rhs `"`rhs' `LDvars' `dvars' `lvars' "'
             } //close (no dummy, no dummyshock, no shockvar)
        } //close (dummyshockvar )
} 
loc i 1


if "`sig'" != ""	{
if "`smooth'" != ""{
qui foreach var of varlist `rhs'{
capture rm "allg_`var'.gph"		
qui coefplot, yline(0, lcolor(red)) vertical  graphregion(fcolor(white))   xlabel(, angle(`anglenum'))   ///
          coeflabel(, labgap(1))  ytitle("Parameter estimate")  ///
          title("`var'") swapnames  noeqlabels  cismooth /// 1. swap coef & equ names. Then 2. suppress equation labels  so that we only see equa names instead of coef names
		  keep(*: `var' ) nokey ///display all equation, one variable  (no key: prevent including plot in the legend)
		  saving(allg_`var', replace ) 
local G "`G'allg_`var'.gph " 		  
 }
graph combine `G', graphregion(fcolor(white))  xsize(`xsizenum') row(`rownum') 
} //close: if smooth exists
else{
    if "`sig2'" != "" {  
     qui foreach var of varlist `rhs'{
     capture rm "allg_`var'.gph"		
     qui coefplot,  levels(`signif2'  `signif' )   ///
                      yline(0, lcolor(red)) vertical graphregion(fcolor(white))   xlabel(, angle(`anglenum'))  ///
                     coeflabel(, labgap(1))  ytitle("Parameter estimate")  ///
                     title("`var'") swapnames  noeqlabels /// 1. swap coef & equ names. Then 2. suppress equation labels  so that we only see equa names instead of coef names
		  keep(*: `var' ) nokey ///display all equation, one variable  (no key: prevent including plot in the legend)
		  saving(allg_`var', replace ) 
local G "`G'allg_`var'.gph " 		  
 }
graph combine `G', graphregion(fcolor(white))  xsize(`xsizenum') row(`rownum') 
} //close:if sig2 exists
else{
qui foreach var of varlist `rhs'{
capture rm "allg_`var'.gph"		
qui coefplot , levels(`signif')  vertical yline(0, lcolor(red)) ciopts(recast(rcap))  graphregion(fcolor(white))  xlabel(, angle(`anglenum'))   ///
          coeflabel(, labgap(1))  ytitle("Parameter estimate")  ///
          title("`var'") swapnames  noeqlabels /// 1. swap coef & equ names. Then 2. suppress equation labels  so that we only see equa names instead of coef names
		  keep(*: `var' ) nokey ///display all equation, one variable  (no key: prevent including plot in the legend)
		  saving(allg_`var', replace ) 
local G "`G'allg_`var'.gph " 		  
 }
graph combine `G', graphregion(fcolor(white))  xsize(`xsizenum') row(`rownum') 
}  //close:sig2 option in smooth 
}  //close:smooth option
}  //close:sig exists

else{
if "`smooth'" != ""{
qui foreach var of varlist `rhs'{
capture rm "allg_`var'.gph"		
qui coefplot, yline(0, lcolor(red)) vertical  graphregion(fcolor(white))  xlabel(, angle(`anglenum'))   ///
          coeflabel(, labgap(1))  ytitle("Parameter estimate")  ///
          title("`var'") swapnames  noeqlabels  cismooth /// 1. swap coef & equ names. Then 2. suppress equation labels  so that we only see equa names instead of coef names
		  keep(*: `var' ) nokey ///display all equation, one variable  (no key: prevent including plot in the legend)
		  saving(allg_`var', replace ) 
local G "`G'allg_`var'.gph " 		  
 }
graph combine `G', graphregion(fcolor(white))  xsize(`xsizenum') row(`rownum') 
} //close: if smooth exists
else{
    if "`sig2'" != "" {  
     qui foreach var of varlist `rhs'{
     capture rm "allg_`var'.gph"		
     qui coefplot,  levels(`signif2'  `signif' )    ///
                      yline(0, lcolor(red)) vertical   graphregion(fcolor(white))  xlabel(, angle(`anglenum'))   ///
                     coeflabel(, labgap(1))   ytitle("Parameter estimate")  ///
                     title("`var'") swapnames  noeqlabels /// 1. swap coef & equ names. Then 2. suppress equation labels  so that we only see equa names instead of coef names
		  keep(*: `var' ) nokey ///display all equation, one variable  (no key: prevent including plot in the legend)
		  saving(allg_`var', replace ) 
local G "`G'allg_`var'.gph " 		  
 }
graph combine `G', graphregion(fcolor(white))  xsize(`xsizenum') row(`rownum') 
} //close:if sig2 exists
else{   //none of sig, sig2, smooth is specified. by default, sig=95%
qui foreach var of varlist `rhs'{
capture rm "allg_`var'.gph"		
qui coefplot , levels(`signif')  vertical yline(0, lcolor(red)) ciopts(recast(rcap))  graphregion(fcolor(white))   xlabel(, angle(`anglenum'))   ///
          coeflabel(, labgap(1))  ytitle("Parameter estimate")  ///
          title("`var'") swapnames  noeqlabels /// 1. swap coef & equ names. Then 2. suppress equation labels  so that we only see equa names instead of coef names
		  keep(*: `var' ) nokey ///display all equation, one variable  (no key: prevent including plot in the legend)
		  saving(allg_`var', replace ) 
local G "`G'allg_`var'.gph " 		  
 }
graph combine `G', graphregion(fcolor(white))  xsize(`xsizenum') row(`rownum') 
}  //close:sig2 option in smooth 
}  //close:smooth option

}  //close:sig option


}  //close: if all is not chosen  but vertical is chosen
 else{

if "`sig'" != ""	{
loc clist
loc i 1
foreach var of varlist `dvs' {
if "`i'" == "1"	{
	loc basevar `var'
} 
else	{
	capture drop D_`var'_`basevar'
	gen D_`var'_`basevar' = ln(`var'/`basevar')
	loc clist `"`clist' D_`var'_`basevar'"'


}
loc i = `i' + 1	
}

if "`smooth'" != ""{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,   xline(0, lcolor(red)) ciopts(recast(rcap))   coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
	           saving(g_`var', replace )  cismooth
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')  ycommon xcommon		
	 
   }   //below: sig is identified & smooth option is not identified
else{
 if "`sig2'" != "" {   //note: multiple CIs not with ciopts(recast(rcap))  option
                       //      we can use "ciopts(recast(. rcap))" but it looks ugly
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  levels(`signif2' `signif' ) legend(order(1 "`signif2'% CI" 2 "`signif'% CI" ) row(1) ) ///
                xline(0, lcolor(red))   coeflabel(, wrap(20)) eqstrict keep(`var': ) saving(g_`var', replace ) 
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')  ycommon xcommon	

}  //below: sig is identified, smooth is  not identified, sig2 is not identified
else{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  levels(`signif') xline(0, lcolor(red)) ciopts(recast(rcap))  coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
                note("Note. `signif'% confidence interval.", span)  saving(g_`var', replace ) 
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')  ycommon xcommon	
}  //close: sig2 is not identified
}  //close: smooth is not identified 	 
} // close: sig is identified  & below: sig is not identified

else	{
loc clist
loc i 1
foreach var of varlist `dvs' {
if "`i'" == "1"	{
	loc basevar `var'
} 
else	{
	capture drop D_`var'_`basevar'
	gen D_`var'_`basevar' = ln(`var'/`basevar')
	loc clist `"`clist' D_`var'_`basevar'"'
}
loc i = `i' + 1	
}



if "`smooth'" != ""{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  xline(0, lcolor(red)) ciopts(recast(rcap))  coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
	           saving(g_`var', replace )   cismooth
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')  ycommon xcommon		
	 
  }  //below: if smooth is not identified

else{
if "`sig2'" != "" {
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  levels(`signif2'  `signif' ) legend(order(1 "`signif2'% CI" 2 "95% CI" ) row(1) ) ///
                xline(0 , lcolor(red))  coeflabel(, wrap(20)) eqstrict keep(`var': ) saving(g_`var', replace ) 
     local G "`G'g_`var'.gph " 
}  
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')  ycommon xcommon		
}   //below:  sig2 is not identified
else{
qui foreach var of varlist `clist'	{
     capture rm "g_`var'.gph"
     coefplot,  xline(0 , lcolor(red)) ciopts(recast(rcap))  coeflabel(, wrap(20)) eqstrict keep(`var': )  ///
	        note("Note. 95% confidence interval.", span)  saving(g_`var', replace )  
     local G "`G'g_`var'.gph " 
}   
graph combine `G', graphregion(fcolor(white)) rows(`rownum') xsize(`xsizenum')  ycommon xcommon	

}   //close: sig2	 
}   //close: smooth      
}   //close: sig 
}   //close: vertical is chosen  
}  //close: if all is not chosen 
}
restore
end //End dynsimpiecoef
