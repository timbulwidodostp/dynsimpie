/******************************************************************************/
/*						       DYNSIMPIE II	    				              */
/*                       Last update: 16 Jan 2020							  */
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


capture program drop dynsimpie
capture program define dynsimpie, eclass 
syntax varlist(ts) [if] [in], dvs(varlist max = 12) [ar(numlist integer max=3) ///
shockvars(varlist ts max=3) shockvals(numlist max=3) INTERaction(varname ts) intype(string) ///
dummyshockvar(varname ts) dummy(varlist ts) dummyset(numlist) ///
Time(numlist integer >0) range(numlist integer) ///
sigs(numlist integer < 100) KILLTABle PERCENTage pv ecm]


version 8
marksample touse

tempfile original
save "`original'", replace

******************
******************
if "`ecm'" != ""	{
	if  "`ar'" != ""	{
		di in r _n "Option ar is not allowed along with ecm."
		exit 198
}
	if  "`interaction'" != ""	{
		di in r _n "Option interaction is not allowed along with ecm."
		exit 198
	}
	if  "`intype'" != ""	{
		di in r _n "Option intype is not allowed along with ecm."
		exit 198
	}
}
******************
******************

***LDV-based Dynsimpie
if "`ecm'" == "" {

if "`dvs'" == ""	{
	di in r _n "Must specify dependent compositional variables in dvs( )"
	exit 198
}

* --------------- 'Splitting'/Transferring Some Locals ------------------------

local controls `varlist'

if "`shockvars'" == ""	{
	   if "`dummyshockvar'" == ""	{
           di in r  "Failure to specify both shockvars and dummyshockvar will lead to an all baseline simulation"
         }
}
 
loc z: word count `shockvars'
loc v: word count `shockvals'

if "`z'" != "`v'"	{
	di in r _n "The number of shock variables must be equal to the number of shock values.“
	exit 198
           }
        if "`z'" > "3"	{
	di in r _n "The total number of shock variables cannot exceed 3."  
	exit 198
           }

loc i 1		   
foreach loc of local shockvars {
	local j 1
	foreach name in shockvar shockvar2 shockvar3 {
		if `i' == `j' {
			loc `name' `loc'
		}
		loc j = `j' + 1
	}
	loc i = `i' + 1
}

loc i 1		   
foreach loc of local shockvals {
	local j 1
	foreach name in shock shock2 shock3 {
		if `i' == `j' {
			loc `name' `loc'
		}	
		loc j = `j' + 1
	}
	loc i = `i' + 1
}		   

* ------------------------Other Errors ----------------------------------

loc ns: word count `sigs'
tokenize  `sigs'
local sig `1'
local sig2 `2'
di "number=`ns', sig =`sig', sig2=`sig2' "


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

   
  * if "`ns'" > "1"	{

     if "`sig2'" != ""	{					// the additional CI's signif
        if "`ns'" > "2"	{
	di in r _n "The total number of sig level cannot exceed 2"  
	exit 198
           }
       else {
        local signif2 `sig2'
        local sigl2 = (100-`signif2')/2
        local sigu2 = 100-((100-`signif2')/2)
       }
	}
 }
 
tempfile original
save "`original'", replace
* ------------------------Other Errors ----------------------------------

if "`effectsplot'" != "" & "`cfbplot'" != "" {
	di in r _n "cfbplot must not be specified with effectsplot."
	exit 198
}


if "`time'" != "" & "`range'" != "" {
	if `time' >= `range' {
		di in r _n "Must specify time smaller than range."
		exit 198
	}
}

if "`time'" != "" & "`range'" == "" {
	if `time' >= 20 {
		di in r _n "If range is not specified, must specify time smaller than 20."
		exit 198
	}
}

if "`range'" != "" & "`time'" == "" {
	if `range' <= 5 {
		di in r _n "If time is not specified, must specify range greater than 5."
		exit 198
	}
}

foreach v in local controls {
	if "`v'" == "`shockvar'" | "`v'" == "`shockvar2'" | "`v'" == "`shockvar3'" | "`v'" == "`dummyshockvar'" | "`v'" == "`interaction'" {
		di in r _n "Control variables may not also be specified as shock variables."
		exit 198
	}
}
foreach v in local dummy {
	if "`v'" == "`shockvar'" | "`v'" == "`shockvar2'" | "`v'" == "`shockvar3'" | "`v'" == "`dummyshockvar'" | "`v'" == "`interaction'" {
		di in r _n "Control variables may not also be specified as shock variables."
		exit 198
	}
}

local dummycount : word count `dummy'
local dummysetcount : word count `dummyset'

if "`dummyset'" != "" {
	if "`dummycount'" != "`dummysetcount'" {
		di in r _n "If specified, the quantity of dummyset values must match the quantity of dummy included."
		exit 198
	}
}

* ------------------------Make shockdta ----------------------------------

*Making Log-Ratios
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


loc dv_original `dvs'
loc complist
loc i 1
foreach var of varlist `dvs' {
	if "`i'" == "1" {
			loc basevar `var'
	} 
	else    {
			capture drop `var'_`basevar'
			gen `var'_`basevar' = ln(`var'/`basevar')
			loc complist `"`complist' `var'_`basevar'"'
	}
	loc i = `i' + 1 
}
loc dvs `complist'

*Cannot Time Difference and Time Lag at the Same Time
local ivs `shockvar' `shockvar2' `shockvar3' `interaction' `dummyshockvar' `dummy' `controls'
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
	
	
*Cannot Time Difference Dummy Variable
if "`interaction'" != "" | "`dummyshockvar'" != "" | "`dummy'" != "" {
local dummies `interaction' `dummyshockvar' `dummy'
foreach n of varlist `dummies' {
	if substr("`n'",1,2)=="D." | substr("`n'",1,2)=="d." { //If user inputs first difference of dummy var
		di in r _n "A dummy variable may not be time differenced."
		exit 198
	}
	 if substr("`n'",1,3)=="D1." | substr("`n'",1,3)=="d1." { //If user inputs first difference of dummy var
		di in r _n "A dummy variable may not be time differenced."
		exit 198
	}
	foreach v of numlist 2/9 {
		if substr("`n'",1,3)=="D`v'." | substr("`n'",1,3)=="d`v'." {
		di in r _n "A dummy variable may not be time differenced."
		exit 198
		}
	 }
	 foreach v of numlist 10/99 {
		if substr("`n'",1,4)=="D`v'." | substr("`n'",1,4)=="d`v'." {
		di in r _n "A dummy variable may not be time differenced."
		exit 198
		}
	 }
}
}
 * First Differences of shockvar, shockvar2, shockvar3, dummyshockvar
if "`shockvar'" != ""  | "`shockvar2'" != "" | "`shockvar3'" != "" {
	foreach n of newlist shockvar shockvar2 shockvar3 {
	  if substr("``n''",1,2)=="D." | substr("``n''",1,2)=="d." { //If user inputs first difference of `n'
		 loc diff = substr("``n''",3,.)
		 capture drop diff__`diff'
		 gen diff__`diff' = D.`diff'
		 loc `n' diff__`diff'
	 }
	 if substr("``n''",1,3)=="D1." | substr("``n''",1,3)=="d1." {
		 loc diff = substr("``n''",4,.)
		 capture drop diff__`diff'
		 gen diff__`diff' = D.`diff'
		 loc `n' diff__`diff'
	 }
	 foreach v of numlist 2/9 {
		if substr("``n''",1,3)=="D`v'." | substr("``n''",1,3)=="d`v'." {
		di in r _n "A `n' may not be time differenced multiple times."
		exit 198
		}
	 }
	 foreach v of numlist 10/99 {
		if substr("``n''",1,4)=="D`v'." | substr("``n''",1,4)=="d`v'." {
		di in r _n "A `n' may not be time differenced multiple times."
		exit 198
		}
	 }
   }
}

* Time Lags of shockvar, shockvar2, shockvar3, dummyshockvar, interaction

if "`shockvar'" != "" | "`shockvar2'" != "" | "`shockvar3'" != "" | "`dummyshockvar'" != "" | "`interaction'" != "" {
	 foreach n of newlist shockvar shockvar2 shockvar3 dummyshockvar interaction {
	 if substr("``n''",1,2)=="L." | substr("``n''",1,2)=="l." { //If user inputs first lag of `n'
		 loc lag`n' = substr("``n''",3,.)
		 capture drop lag__`lag`n''
		 gen lag__`lag`n'' = L.`lag`n''
		 loc `n' lag__`lag`n''
	 }
	  if substr("``n''",1,3)=="L1." | substr("``n''",1,3)=="l1." {
		 loc lag`n' = substr("``n''",4,.)
		 capture drop lag__`lag`n''
		 gen lag__`lag`n'' = L.`lag`n''
		 loc `n' lag__`lag`n''
		 }
		 
	  if substr("``n''",1,3)=="L2." | substr("``n''",1,3)=="l2." {
		 loc lag`n' = substr("``n''",4,.)
		 capture drop lag2__`lag`n''
		 gen lag2__`lag`n'' = L2.`lag`n''
		 loc `n' lag2__`lag`n''
		 }
		 
	  if substr("``n''",1,3)=="L3." | substr("``n''",1,3)=="l3." {
		 loc lag`n' = substr("``n''",4,.)
		 capture drop lag3__`lag`n''
		 gen lag3__`lag`n'' = L3.`lag`n''
		 loc `n' lag3__`lag`n''
		 }
	 
	  foreach v of numlist 4/9 {
		if substr("``n''",1,3)=="L`v'." | substr("``n''",1,3)=="l`v'." {
		di in r _n "A `n' may not be time lagged more than three times."
		exit 198
		}
	  }
	  foreach v of numlist 10/99 {
		if substr("``n''",1,4)=="L`v'." | substr("``n''",1,4)=="l`v'." {
		di in r _n "A `n' may not be time lagged more than three times."
		exit 198
		}
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

* Differences and Lags of dummy
if "`dummy'" != "" {
loc dummy1
foreach wx of varlist `dummy' {
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
	di in r _n "A dummycontrol may not be time lagged more than three times."
	exit 198
	}
  }
  foreach v of numlist 10/99 {
	if substr("`wx'",1,4)=="L`v'." | substr("`wx'",1,4)=="l`v'." {
	di in r _n "A dummycontrol may not be time lagged more than three times."
	exit 198
	}
  }
  loc dummy1 `dummy1' `wx'
}

loc dummy `dummy1'
}

if "`interaction'" != "" & "`intype'" == "" {
	di in r _n "An intype either (on) or (off) must be specified with interaction."
	exit 198
}

if "`interaction'" != "" { //Generating interaction variable
capture drop `shockvar'_`interaction'
qui gen `shockvar'_`interaction' = `shockvar'*`interaction'
loc Ishockvar `shockvar'_`interaction'
}
else {
}

local varlist `shockvar' `shockvar2' `shockvar3' `controls' `interaction' `dummyshockvar'  `dummy' `Ishockvar'

**** Making Shock Data Tempfile
if "`shockvar'" != "" | "`shockvar2'" != "" | "`shockvar3'" != "" {
	foreach m of varlist `shockvar' `shockvar2' `shockvar3' {
		su `m', meanonly
		local mean`m' = r(mean)
	}
}

if "`controls'" != "" {
	foreach n of varlist `controls' {
		su `n', meanonly
		local mean`n' = r(mean)
	}
}

preserve
clear

loc burnin 80								// burn-ins


if "`range'" == "" {  //If user has specified range
local range = 20
}

loc brange = `range' + `burnin'

set obs `brange'

if "`shockvar'" != "" | "`shockvar2'" != "" | "`shockvar3'" != "" {
	qui foreach m of newlist `shockvar' `shockvar2' `shockvar3' {
		if substr("`m'",1,6) == "diff__" {
			gen `m' = 0
		}
		else {
			gen `m' = `mean`m''
		}
	}
}	

if "`controls'" != "" {
	qui foreach n of newlist `controls' {
		if substr("`n'",1,6) == "diff__" {
			gen `n' = 0
		}
		else {
			gen `n' = `mean`n''
		}
	}
}

if "`interaction'" != "" | "`dummyshockvar'" != "" | "`dummy'" != "" {
	foreach o of newlist `interaction' `dummyshockvar' `dummy' `Ishockvar' {
		gen `o' = 0
	}
}

if "`dummy'" != "" {
	if "`dummyset'" != "" {
		loc counter 1
		foreach s of local dummy {
				local counter2 1
				foreach ss of local dummyset {
						if "`counter'" == "`counter2'" {
							replace `s' = `ss'
						}
					local counter2 = `counter2' + 1
				}
			loc counter = `counter' + 1
		}
	}
}
tempfile shockdta

			//Now's the time to actually shock the variable at the specified time( )
if "`time'" == "" {
		loc time = 5
	}
else {
}

loc btime = `time' + `burnin'

if "`shockvar'" != "" | "`shockvar2'" != "" | "`shockvar3'" != "" {
	loc count1 1
	qui foreach m of varlist `shockvar' `shockvar2' `shockvar3' {
		loc count2 1
		qui foreach z of numlist `shock' `shock2' `shock3' {
		if "`count1'" == "`count2'" {
			if substr("`m'",1,6) == "diff__" {
				replace `m' = `z' if _n==`btime'
			}
			if substr("`m'",1,5) == "lag__" {
				replace `m' = `z' + `mean`m'' if _n>=`btime' + 1
			}
			if substr("`m'",1,6) == "lag2__" {
				replace `m' = `z' + `mean`m'' if _n>=`btime' + 2
			}
			if substr("`m'",1,6) == "lag3__" {
				replace `m' = `z' + `mean`m'' if _n>=`btime' + 3
			}
			if substr("`m'",1,6) != "diff__" & substr("`m'",1,5) != "lag__" & substr("`m'",1,6) != "lag2__" & substr("`m'",1,6) != "lag3__" {
				replace `m' = `z' + `mean`m'' if _n>=`btime'
			}
		}
		loc count2 `count2' + 1
		}
		loc count1 `count1' + 1
	}
}		

if "`dummyshockvar'" != "" {
	if substr("`dummyshockvar'",1,5) == "lag__" {
		replace `dummyshockvar' = 1 if _n >= `btime' + 1
	}
	if substr("`dummyshockvar'",1,6) == "lag2__" {
		replace `dummyshockvar' = 1 if _n >= `btime' + 2
	}
	if substr("`dummyshockvar'",1,6) == "lag3__" {
		replace `dummyshockvar' = 1 if _n >= `btime' + 3
	}
	if substr("`dummyshockvar'",1,5) != "lag__" & substr("`dummyshockvar'",1,6) != "lag2__" & substr("`dummyshockvar'",1,6) != "lag3__"  {
		replace `dummyshockvar' = 1 if _n >= `btime'
	}
}

if "`interaction'" != "" {
	if "`intype'" == "on" {
		replace `interaction' = 1
		replace `Ishockvar' = `shockvar'
	}
	if "`intype'" == "off" {
		replace `Ishockvar' = 0
	}
}
						
mkmat `varlist', matrix(shockmatrix) //Shockdata saved in matrix
restore
*matrix list shockmatrix

* ------------------------Obtain shockdta --------------------------------
* assert that num vars match up with num vars in varlist
local varcol : word count `varlist'
local r = rowsof(shockmatrix)
local c = colsof(shockmatrix)
if "`varcol'" != "`c'" {
	di in r _n "Error in shock data!!"
	exit 198
}

*mat list shockmatrix

*preserve

* ------------------------Generate LDV & run model --------------------------------

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
foreach var of varlist `dvs'	{
	*****************************
	if "`ar_a'" != "" {
	qui gen L`ar_a'_`var' = l`ar_a'.`var'
	local l`ar_a'depvar`i' L`ar_a'_`var'
	}
	if "`ar_b'" != "" {
	qui gen L`ar_b'_`var' = l`ar_b'.`var'
	local l`ar_b'depvar`i' L`ar_b'_`var'
	}
	if "`ar_c'" != "" {
	qui gen L`ar_c'_`var' = l`ar_c'.`var'
	local l`ar_c'depvar`i' L`ar_c'_`var'
	}
	*****************************
	* get the model:
	local model `"`model' (`var' `l`ar_a'depvar`i'' `l`ar_b'depvar`i'' `l`ar_c'depvar`i'' `varlist')"'
	local i = `i' + 1
}

local maxdv = `i' - 1					// need # of compositions
qui sureg `model'       
qui keep if e(sample)
if "`killtable'" != "" {
qui estsimp sureg `model'
 }
else {
noi estsimp sureg `model'
}
* ------------------------Set Vars, t = 1 --------------------------------------
local i 1
foreach var of varlist `varlist' {
	scalar set = shockmatrix[1,`i']
	setx `var' set
	local i = `i' + 1
}

	*****************************

loc i 1
qui foreach var of varlist `dvs' {
		su `var', meanonly
		scalar m`i' = r(mean)
		loc i = `i' + 1
	}
foreach i of numlist 1/`maxdv' { //Set
	if "`ar_a'" != "" {
	setx `l`ar_a'depvar`i'' m`i'
	}
	if "`ar_b'" != "" {
	setx `l`ar_b'depvar`i'' m`i'
	}
	if "`ar_c'" != "" {
	setx `l`ar_c'depvar`i'' m`i'
	}
}

/*	
foreach i of numlist 1/`maxdv' { //Set
	if "`ar_a'" != "" {
	su `l`ar_a'depvar`i'', meanonly
	scalar m`i' = r(mean)
	setx `l`ar_a'depvar`i'' m
	}
	if "`ar_b'" != "" {
	su `l`ar_b'depvar`i'', meanonly
	scalar m`i' = r(mean)
	setx `l`ar_b'depvar`i'' m
	}
	if "`ar_c'" != "" {
	su `l`ar_c'depvar`i'', meanonly
	scalar m`i' =r(mean)
	setx `l`ar_c'depvar`i'' m
	}
}
*/
*noi setx


* ------------------------Predict t = 1 --------------------------------------
local preddv
loc i 1
qui foreach var of varlist `dvs'	{
	tempvar t`i'log1
	loc preddv `"`preddv' `t`i'log1' "'
	loc i = `i' + 1	
}

if "`pv'" != ""	{
	qui simqi, pv genev(`preddv')
}
else	{										
	qui simqi, ev genev(`preddv')
}


loc denominator1
loc i 1
qui foreach var in `dvs'	{
	su `t`i'log1', meanonly
	scalar m`i'_1 = r(mean)			// these scalars become the new LDV
	loc denominator1 `"`denominator1' + (exp(`t`i'log1'))"'
	loc i = `i' + 1
}



* ------------------------Loop Through Time --------------------------------
di ""
nois _dots 0, title(Simulation in Progress...please wait) reps(`r')
qui forv i = 2/`brange' {		// from 1 through all rows of shockmatrix
	noi _dots `i' 0 	
	
	if "`ar_a'" != "" { 
			if `i' > `ar_a' {
			local j = `i' - `ar_a'
			forv x = 1/`maxdv'	{			// set new value of LDV 
				setx `l`ar_a'depvar`x'' (m`x'_`j')		
			}
		}
	}
	if "`ar_b'" != "" { 
			if `i' > `ar_b' {
			local j = `i' - `ar_b'
			forv x = 1/`maxdv'	{			// set new value of LDV 
				setx `l`ar_b'depvar`x'' (m`x'_`j')		
			}
		}
	}
	if "`ar_c'" != "" { 
			if `i' > `ar_c' {
			local j = `i' - `ar_c'
			forv x = 1/`maxdv'	{			// set new value of LDV 
				setx `l`ar_c'depvar`x'' (m`x'_`j')		
			}
		}
	}

	loc z 1
	foreach var of varlist `varlist' {
		scalar set = shockmatrix[`i',`z']
		setx `var' set
		local z = `z' + 1
	}
*noi setx
	local preddv
	qui forv x = 1/`maxdv'	{
		tempvar t`x'log`i'
		local preddv `"`preddv' `t`x'log`i'' "'
	}
	if "`pv'" != ""	{
		qui simqi, pv genev(`preddv')
	}
	else	{										
		qui simqi, ev genev(`preddv')
	}			// get new predictions
	local denominator`i'
	qui forv x = 1/`maxdv'	{
		su `t`x'log`i'', meanonly
		scalar m`x'_`i' = r(mean)
		local denominator`i' `"`denominator`i'' + (exp(`t`x'log`i''))"' // need this for below
	}	
}	// close time loop

* ------------------------Un-Transform------------------------------------------

local keepthese
**effectsplot
preserve

		loc basetime = `burnin' + 1
		loc shocktime = `btime'
		loc endtime = `brange'
		
	* note that after untransforming compositions, starting means are subtracted and
	* percentiles drawn.
	local z = `maxdv' + 1
	qui forv m = 1/`maxdv' {
		tempvar var_pie`basetime'_`m' var_pie`shocktime'_`m' var_pie`endtime'_`m'
		* Create compositions for start time:
		gen `var_pie`basetime'_`m'' = (exp(`t`m'log`basetime''))/(1  `denominator`basetime'')
		_pctile `var_pie`basetime'_`m'', p(50)		// grab midpoint
		gen var_pie_med_`basetime'_`m' = r(r1)
		
		* create composition for shocktime:
	        if "`sig2'" != "" {
                gen `var_pie`shocktime'_`m'' = ((exp(`t`m'log`shocktime''))/(1  `denominator`shocktime'')) - var_pie_med_`basetime'_`m'
                _pctile `var_pie`shocktime'_`m'', p(`sigl',`sigu')
		gen var_pie_ll_sr1_`m' = r(r1)
		gen var_pie_ul_sr1_`m' = r(r2)
                _pctile `var_pie`shocktime'_`m'', p(`sigl2',`sigu2')
		gen var_pie_ll_sr2_`m' = r(r1)
		gen var_pie_ul_sr2_`m' = r(r2)
             }
             else {
                gen `var_pie`shocktime'_`m'' = ((exp(`t`m'log`shocktime''))/(1  `denominator`shocktime'')) - var_pie_med_`basetime'_`m'
                _pctile `var_pie`shocktime'_`m'', p(`sigl',`sigu')
		gen var_pie_ll_sr1_`m' = r(r1)
		gen var_pie_ul_sr1_`m' = r(r2)
               }
                * create composition for LR-time:
              if "`sig2'" != "" {
		gen `var_pie`endtime'_`m'' = (exp(`t`m'log`endtime''))/(1  `denominator`endtime'') -         var_pie_med_`basetime'_`m'
		_pctile `var_pie`endtime'_`m'', p(`sigl',`sigu')
		gen var_pie_ll_lr1_`m' = r(r1)
		gen var_pie_ul_lr1_`m' = r(r2)
        
                _pctile `var_pie`endtime'_`m'', p(`sigl2',`sigu2')
		gen var_pie_ll_lr2_`m' = r(r1)
		gen var_pie_ul_lr2_`m' = r(r2)
                 }
                 else {
                gen `var_pie`endtime'_`m'' = (exp(`t`m'log`endtime''))/(1  `denominator`endtime'') -         var_pie_med_`basetime'_`m'
		_pctile `var_pie`endtime'_`m'', p(`sigl',`sigu')
		gen var_pie_ll_lr1_`m' = r(r1)
		gen var_pie_ul_lr1_`m' = r(r2)
                }


              if "`sig2'" != "" {
                local keepthese `"`keepthese' var_pie_ll_sr1_`m' var_pie_ul_sr1_`m' var_pie_ll_lr1_`m' var_pie_ul_lr1_`m' var_pie_ll_sr2_`m' var_pie_ul_sr2_`m' var_pie_ll_lr2_`m' var_pie_ul_lr2_`m'  "'
                                }
             else               {
               local keepthese `"`keepthese' var_pie_ll_sr1_`m' var_pie_ul_sr1_`m' var_pie_ll_lr1_`m' var_pie_ul_lr1_`m' "'
             }
	}


		  
	tempvar var_pie`shocktime'_`z' var_pie`endtime'_`z' var_pie`basetime'_`z'  // the un-transformation baseline
	gen `var_pie`basetime'_`z'' = 1/(1  `denominator`basetime'')
	_pctile `var_pie`basetime'_`z'', p(50)		// grab midpoint
	gen var_pie_med_`basetime'_`z' = r(r1)
	
        if "`sig2'" != "" {
	           gen `var_pie`shocktime'_`z'' = (1/(1  `denominator`shocktime'')) - var_pie_med_`basetime'_`z'	
	          _pctile `var_pie`shocktime'_`z'', p(`sigl',`sigu')
	          gen var_pie_ll_sr1_`z' = r(r1)
	          gen var_pie_ul_sr1_`z' = r(r2)
           
                  _pctile `var_pie`shocktime'_`z'', p(`sigl2',`sigu2')
	          gen var_pie_ll_sr2_`z' = r(r1)
	          gen var_pie_ul_sr2_`z' = r(r2)
                    
                  gen `var_pie`endtime'_`z'' = (1/(1  `denominator`endtime'')) - var_pie_med_`basetime'_`z'
	          _pctile `var_pie`endtime'_`z'', p(`sigl',`sigu')
	          gen var_pie_ll_lr1_`z' = r(r1)
	          gen var_pie_ul_lr1_`z' = r(r2)

                   _pctile `var_pie`endtime'_`z'', p(`sigl2',`sigu2')
	           gen var_pie_ll_lr2_`z' = r(r1)
	           gen var_pie_ul_lr2_`z' = r(r2)
                }
                 else               {              
            gen `var_pie`shocktime'_`z'' = (1/(1  `denominator`shocktime'')) - var_pie_med_`basetime'_`z'	
         	_pctile `var_pie`shocktime'_`z'', p(`sigl',`sigu')
         	gen var_pie_ll_sr1_`z' = r(r1)
        	gen var_pie_ul_sr1_`z' = r(r2)
                 
            gen `var_pie`endtime'_`z'' = (1/(1  `denominator`endtime'')) - var_pie_med_`basetime'_`z'
	        _pctile `var_pie`endtime'_`z'', p(`sigl',`sigu')
	        gen var_pie_ll_lr1_`z' = r(r1)
	        gen var_pie_ul_lr1_`z' = r(r2)
                 }


        if "`sig2'" != "" {	
	local keepthese `"`keepthese' var_pie_ll_sr1_`z' var_pie_ul_sr1_`z' var_pie_ll_lr1_`z' var_pie_ul_lr1_`z' var_pie_ll_sr2_`z' var_pie_ul_sr2_`z' var_pie_ll_lr2_`z' var_pie_ul_lr2_`z' "'


keep `keepthese'
qui keep in 1

gen count = _n
reshape long var_pie_ll_sr1_ var_pie_ul_sr1_ var_pie_ll_lr1_ var_pie_ul_lr1_ var_pie_ll_sr2_ var_pie_ul_sr2_ var_pie_ll_lr2_ var_pie_ul_lr2_, j(sort) i(count)

}
else{
	local keepthese `"`keepthese' var_pie_ll_sr1_`z' var_pie_ul_sr1_`z' var_pie_ll_lr1_`z' var_pie_ul_lr1_`z' "'

keep `keepthese'
qui keep in 1

gen count = _n
reshape long var_pie_ll_sr1_ var_pie_ul_sr1_ var_pie_ll_lr1_ var_pie_ul_lr1_, j(sort) i(count)
}

gen sort_lr = sort - 0.2
gen sort_sr = sort + 0.2


* create midpoints:
gen mid_sr = (var_pie_ll_sr1_ + var_pie_ul_sr1_)/2
gen mid_lr = (var_pie_ll_lr1_ + var_pie_ul_lr1_)/2



loc z : word count `dv_original'
	forvalues i = 1/`z'{
            		
            if "`i'" == "1"	{
			loc base : word 1 of `dv_original'
		}
		loc iminus1 = `i' - 1
		else	{
			loc dvplace : word `i' of `dv_original'
			loc dvname `" `dvname' `iminus1' "`dvplace'" "'
		}
               }

loc dvnames `" `dvname' `z' "`base'"  "'


	if "`percentage'" != ""{
		loc Change "Percentage Change"
	}
	else {
		loc Change "Proportion Change"
   }


 	if "`pv'" != ""	{
		loc valname "Predicted"
	}
	else	{										
		loc valname "Expected"
	}

	*Defining scalars and locals
	ereturn local valname_e = "`valname'"
	if "`sig'" != "" {
		ereturn scalar sig_e = `sig'
	}
	if "`sig2'" != "" {
		ereturn scalar sig2_e = `sig2'
	}
	ereturn local dvnames_e = `"`dvnames'"'
	ereturn scalar signif_e = `signif'
	if "`signif2'" != ""  {
		ereturn scalar signif2_e = `signif2'
	}
	ereturn local Change = "`Change'"
	*Saving cfbplot dataset in a matrix
	mkmat _all, matrix(effectsplot)
	ereturn matrix effectsplot effectsplot
restore


	if "`effectsplot'" != "" {
		effectsplot
	}

********************************************************************************
********************************************************************************
local keepthese
**cfbplot
preserve
	loc z : word count `dv_original'		// how many DV's?
qui forv i = 1/`brange' {
	loc m 1
	qui foreach var of varlist `dvs'	{
		tempvar var`m'_pie`i'
		gen `var`m'_pie`i'' = (exp(`t`m'log`i''))/(1  `denominator`i'')
		_pctile `var`m'_pie`i'', p(`sigl',`sigu')	// grab CIs for each DV
		if "`percentage'" != ""{
			gen var`m'_pie_ll_`i' = r(r1)*100
			gen var`m'_pie_ul_`i' = r(r2)*100
			   }
			   else{
			gen var`m'_pie_ll_`i' = r(r1)
			gen var`m'_pie_ul_`i' = r(r2)
        }
		loc keepthese `"`keepthese' var`m'_pie_ll_`i' var`m'_pie_ul_`i' "'
		loc m = `m' + 1
	}			  
	tempvar var`z'_pie`i' 					// the un-transformation baseline
	gen `var`z'_pie`i'' = 1/(1  `denominator`i'')	
	_pctile `var`z'_pie`i'', p(`sigl',`sigu')
	  if "`percentage'" != ""{
		  gen var`z'_pie_ll_`i' = r(r1)*100
		  gen var`z'_pie_ul_`i' = r(r2)*100
	  }
	  else{
		  gen var`z'_pie_ll_`i' = r(r1)
		  gen var`z'_pie_ul_`i' = r(r2)
	  }
	
	loc keepthese `"`keepthese' var`z'_pie_ll_`i' var`z'_pie_ul_`i' "'
}

keep `keepthese'
qui keep in 1
tempvar count 
qui gen `count' = _n

loc reshapevar
qui forv i = 1/`z' {					// reshape across `z' vars in `dv_original'
	loc reshapevar `"`reshapevar' var`i'_pie_ll_ var`i'_pie_ul_ "'
}

qui reshape long `reshapevar', j(time) i(`count')
qui drop `count' time
qui drop in 1/`burnin'
qui gen time = _n

qui forv i = 1/`z' {					// create mid-points
	gen mid`i' = (var`i'_pie_ll_ + var`i'_pie_ul_)/2
}
order time


	loc ulll 
	loc mid "scatter mid1 time"
	loc legend
	if "`pv'" != ""	{
		loc valname "Predicted"
	}
	else	{										
		loc valname "Expected"
	}
	if "`percentage'" != ""{
		  loc proportion  "Percentage"
	}
	else  {
		  loc proportion  "Proportion"
	 }

	forv i = 1/`z'	{
		loc ulll `"`ulll' || rspike var`i'_pie_ul_ var`i'_pie_ll_ time, lcolor(black) lwidth(thin) "'	
		if "`i'" > "1"	{
			loc mid `"`mid' || scatter mid`i' time "'
		}
		if "`i'" == "1"	{
			loc base : word 1 of `dv_original'
		}
		loc iminus1 = `i' - 1
		else	{
			loc dvplace : word `i' of `dv_original'
			loc legend `" `legend' `iminus1' "`dvplace'" "'
		}
	}
	
	*Defining scalars and locals
	ereturn local proportion_c = "`proportion'" 
	ereturn local mid_c = "`mid'"
	ereturn local ulll_c = "`ulll'"
	ereturn local legend_c = `"`legend'"'
	ereturn scalar z_c = `z'
	ereturn local base_c = "`base'"
	ereturn local valname_c = "`valname'"
	ereturn scalar signif_c = `signif'

	*Saving cfbplot dataset in a matrix
	mkmat _all, matrix(cfbplot)
	ereturn matrix cfbplot cfbplot
	
restore

	if "`cfbplot'" != "" {
		cfbplot
	}
}

***ECM-based Dynsimpie

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
di "number=`ns', sig =`sig', sig2=`sig2' "


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

   
  * if "`ns'" > "1"	{

     if "`sig2'" != ""	{					// the additional CI's signif
        if "`ns'" > "2"	{
	di in r _n "The total number of sig level cannot exceed 2"  
	exit 198
           }
       else {
        local signif2 `sig2'
        local sigl2 = (100-`signif2')/2
        local sigu2 = 100-((100-`signif2')/2)
       }
 }
 }
 

if "`range'" != ""	{						// How far to simulate?
	loc range `range'
}
else	{
	loc range 20
	di ""
	di in y "No range specified; default to t=20"
}
if "`time'" != ""	{
	loc time `time'
}
else	{
	loc time 5
	di in y "No time of shock specified; default to t=5"
}
loc burnin 80								// burn-ins
loc brange = `range' + `burnin'
loc btime = `time' + `burnin'




if `time' >= `range' {
	di in r _n "The range of simulation must be longer than the shock time"
	exit 198
}


 
if "`shockvars'" == ""	{
	   if "`dummyshockvar'" == ""	{
           di in r  "Failure to specify both shockvars and dummyshockvar will lead to an all baseline simulation"
         }
}
 
loc z: word count `shockvars'
loc v: word count `shockvals'
if "`z'" != "`v'"	{
	di in r _n "The number of shock variables must be equal to the number of shock values.“
	exit 198
           }
        if "`z'" > "3"	{
	di in r _n "The total number of shock variables cannot exceed 3."  
	exit 198
           }
 
   

if "`effectsplot'" != ""{
   if "`cfbplot'" != ""{
    di in r _n "cfbplot must not be specified with effectsplot"
    exit 198
}
}



   * ------------------------Generating Variables & Run Model ---------------------
   * create compositions:
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


 
loc lagshockvariables 
loc diffshockvariables
if "`shockvars'" != ""	{
qui foreach var of varlist `shockvars'  {		// create d. and l. shock vars
	capture drop L_`var' D_`var'
	gen L_`var' = l.`var'
	gen D_`var' = d.`var' 
	loc lagshockvariables `"`lagshockvariables' L_`var'"'
	loc diffshockvariables `"`diffshockvariables' D_`var'"'
}		

 

 

   if "`dummyshockvar'" != ""	{
        capture drop L_`dummyshockvar' D_`dummyshockvar'
        qui gen L_`dummyshockvar' = l.`dummyshockvar'
        qui gen D_`dummyshockvar' = d.`dummyshockvar'
        loc lagdummyshockvariable `"L_`dummyshockvar'"'
        loc diffdummyshockvariable `"D_`dummyshockvar'"'

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
	loc model `"`model' (D_`var' L_`var' `dvars' `lvars'  `ddummyvars' `ldummyvars'  `diffshockvariables' `lagshockvariables'  `diffdummyshockvariable' `lagdummyshockvariable' )"'
	loc i = `i' + 1
}
} //dummy exists
else{   //dummy does not exists
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
	loc model `"`model' (D_`var' L_`var' `dvars' `lvars' `diffshockvariables' `lagshockvariables'  `diffdummyshockvariable' `lagdummyshockvariable' )"'
	loc i = `i' + 1
}
} 

local maxdv = `i'-1        // need the max # of compositions for effectsplot 
qui sureg `model'						// run the model and keep sample
qui keep if e(sample)
if "`killtable'"	!= ""	{
	qui estsimp sureg `model'
}
else	{
	estsimp sureg `model'					// run Clarify
}
}    //if dummyshock var exists
else{        //no dummyshock var (shock var exists)

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
	loc model `"`model' (D_`var' L_`var' `dvars' `lvars' `ddummyvars' `ldummyvars'  `diffshockvariables' `lagshockvariables' )"'
	loc i = `i' + 1
}
}   //dummy exists
else{ //no dummy exists
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
	loc model `"`model' (D_`var' L_`var' `dvars' `lvars' `diffshockvariables' `lagshockvariables'  )"'
	loc i = `i' + 1
}
}

local maxdv = `i'-1        // need the max # of compositions for effectsplot 
qui sureg `model'						// run the model and keep sample
qui keep if e(sample)
if "`killtable'"	!= ""	{
	qui estsimp sureg `model'
}
else	{
	estsimp sureg `model'					// run Clarify
}
}
}  //if shock var exists
else{

   if "`dummyshockvar'" != ""	{  //dummy shock var exists but shock var does not exists
        capture drop L_`dummyshockvar' D_`dummyshockvar'
        qui gen L_`dummyshockvar' = l.`dummyshockvar'
        qui gen D_`dummyshockvar' = d.`dummyshockvar'
        loc lagdummyshockvariable `"L_`dummyshockvar'"'
        loc diffdummyshockvariable `"D_`dummyshockvar'"'

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
	loc model `"`model' (D_`var' L_`var' `dvars' `lvars'  `ddummyvars' `ldummyvars'  `diffdummyshockvariable' `lagdummyshockvariable' )"'
	loc i = `i' + 1
}
}      //dummy exists 
else{    //no dummy exists
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
	loc model `"`model' (D_`var' L_`var' `dvars' `lvars'  `diffdummyshockvariable' `lagdummyshockvariable' )"'
	loc i = `i' + 1
}
}


local maxdv = `i'-1        // need the max # of compositions for effectsplot 
qui sureg `model'						// run the model and keep sample
qui keep if e(sample)
if "`killtable'"	!= ""	{
	qui estsimp sureg `model'
}
else	{
	estsimp sureg `model'					// run Clarify
}
}
else{  //both shock var &   dummyshock var do not exist

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
}
qui sureg `model'						// run the model and keep sample
qui keep if e(sample)
if "`killtable'"	!= ""	{
	qui estsimp sureg `model'
}
else	{
	estsimp sureg `model'					// run Clarify
}
}
}
* ------------------------ Scalars and Setx ---------------------
qui setx mean							// set everything to means to start

qui setx (`dvars') 0						// set diff indep vars to 0
qui setx (`lvars') mean                                 // set lag indep vars to mean




if "`dummy'" != "" {					// set  dummies, if they exist
	if "`dummyset'" != "" {
		qui foreach var in `dummy' {
			loc m 1
			foreach k of numlist `dummyset' {
				if `m' == `i' {
					qui setx `var' `k'
				}
				loc m = `m' + 1
			}
			loc i = `i' + 1
		}
	}
      else{
  	      qui foreach var in `dummy' {
			loc m 1
			if `m' == `i' {
				qui setx `var' 0
				}
			   loc m = `m' + 1
			}
			loc i = `i' + 1
		}
}


 

if "`dummy'" != "" {	
   if "`dummyset'" != "" {
   qui setx (`ddummyvars') 0          // set diff dummy vars to 0
   qui setx (`ldummyvars') mean       // set lagged dummy vars to mean
   }
   else{
   qui setx (`ddummyvars') 0          // set diff dummy vars to 0
   qui setx (`ldummyvars') 0      // set lagged dummy vars to mean = 0
   }
}


 
 
 
loc i 1
if "`shockvars'" != ""	{
       qui foreach var of varlist `shockvars'  {
    if "`i'" == "1"   {
       qui su L_`var', meanonly	  
       loc sv  = r(mean)
       tokenize  `shockvals'
       loc vs  = `sv' + `1'
       qui setx D_`var' 0			   // set differenced shock to 0
       qui setx L_`var' mean				 // set lag shock to mean
}
else{
       if "`i'" == "2"   {
       qui su L_`var', meanonly	  
       loc sv  = r(mean)
       tokenize  `shockvals'
       loc vs  = `sv' + `2'
       qui setx D_`var' 0			   // set differenced shock to 0
       qui setx L_`var' mean				 // set lag shock to mean
        }
     else{ 
       qui su L_`var', meanonly	  
       loc sv  = r(mean)
       tokenize  `shockvals'
       loc vs  = `sv' + `3'
       qui setx D_`var' 0			   // set differenced shock to 0
       qui setx L_`var' mean				 // set lag shock to mean
     
        }
      }
loc i = `i' + 1	

qui setx D_`var' 0					// set differenced shock to 0
qui setx L_`var' mean				       // set lag shock to mean
}
}
 
 


 
if "`shockvar'" != ""	{
qui su L_`shockvar', meanonly			// scalars for lagged shock
loc sv = r(mean)
loc vs = `sv' + `shock'
qui forv i = 2/3	{					// and the additional shocks
	if "`shockvar`i''" != "" {
		su L_`shockvar`i'', meanonly
		loc sv`i' = r(mean)
		loc vs`i' = `sv`i'' + `shock`i''
		setx L_`shockvar`i'' mean
		setx D_`shockvar`i'' 0
	}
}

qui setx D_`shockvar' 0					// set differenced shock to 0
qui setx L_`shockvar' mean				       // set lag shock to mean
}
 

loc i 1
foreach var of varlist `lcomplist'	{	// set LDVs to means
	su `mdepvar`i'', meanonly
	scalar m`i' = r(mean)
	setx `var'	m`i'
	loc i = `i' + 1
}




if "`dummyshockvar'" != ""	{                                  // always dummy shock var is 0 
qui setx D_`dummyshockvar' 0					// set differenced dummyshock var to 0
qui setx L_`dummyshockvar' 1				       // set lag  dummyshock var to 1
}





* ------------------------ Predict Values, t = 1 ----------------------------------
loc preddv
loc i 1
qui foreach var of varlist `lcomplist'	{
	tempvar td`i'log1
	loc preddv `"`preddv' `td`i'log1' "'
	loc i = `i' + 1
}
if "`pv'" != ""	{
	qui simqi, pv genpv(`preddv')				// grab our predicted values
}
else	{										// else expected values
	qui simqi, ev genev(`preddv')
}

loc denominator1
loc i 1
qui foreach var in `lcomplist' {
	su `mdepvar`i''
	scalar z = r(mean)
	tempvar t`i'log1
	gen `t`i'log1' = z + `td`i'log1'
	su `t`i'log1', meanonly
	scalar m`i' = r(mean)				// these scalars become the new LDV
	loc denominator1 `"`denominator1' + (exp(`t`i'log1'))"' // for below
	loc i = `i' + 1
}
* ------------------------Loop Through Time-------------------------------------
di ""
nois _dots 0, title(Please Wait...Simulation in Progress) reps(`range')
qui forv i = 2/`brange' {
	noi _dots `i' 0
	
	loc x 1
	foreach var of varlist `lcomplist'	{
		setx `var' (m`x')
		loc x = `x' + 1
	}
    


if "`shockvars'" != ""	{	
      * first set all shocks to mean and 0:
 	setx (`lagshockvariables') mean	
	setx (`diffshockvariables') 0

        if `i' == `btime' {			 // we experience the shock at t
         loc j 1
            foreach var of varlist `shockvars'  {
            if "`j'" == "1"   {
            tokenize  `shockvals'
            setx D_`var'  (`1')		        // shock affects at time t only
                }
            else{
             if "`j'" == "2"   {
            tokenize  `shockvals'
            setx D_`var'  (`2')	
                }
             else{ 
               tokenize  `shockvals'
               setx D_`var'  (`3')	
                  }
                }
            loc j = `j' + 1	
         }   // foreach var of varlist  ends
      }   //btime ends
     if `i' > `btime' {  
             loc j 1
              foreach var of varlist `shockvars'  {
               if "`j'" == "1"   {
               setx D_`var' 0            // diff shock back to 0
               qui su L_`var', meanonly	  
               loc sv  = r(mean)
               tokenize  `shockvals'
               loc vs  = `sv' + `1'
               setx L_`var' (`vs')      // lag shock now at (mean + shock)
                 }
               else{
               if "`j'" == "2"   {
               setx D_`var' 0            // diff shock back to 0
               qui su L_`var', meanonly	  
               loc sv  = r(mean)
               tokenize  `shockvals'
               loc vs  = `sv' + `2'
               setx L_`var' (`vs')      // lag shock now at (mean + shock)
                 }
              else{ 
               setx D_`var' 0            // diff shock back to 0
               qui su L_`var', meanonly	  
               loc sv  = r(mean)
               tokenize  `shockvals'
               loc vs  = `sv' + `3'
               setx L_`var' (`vs')      // lag shock now at (mean + shock)
                  }
                }
             loc j = `j' + 1	
           }
       }  //i>btime ends
      }   //`shockvars'" !="" ends


setx (`dvars') 0				// just to be sure
setx (`lvars') mean
 
 


if "`dummy'" != "" {	
qui setx (`ddummyvars') 0          // set diff dummy vars to 0
qui setx (`ldummyvars') mean       // set lagged dummy vars to mean
}





if "`dummyshockvar'" != ""	{
	* first set all dummyshocks to   0:
 	setx (`lagdummyshockvariable') 0	
	setx (`diffdummyshockvariable') 0
	
	if `i' == `btime' {					// we experience the shock at t
		setx D_`dummyshockvar' 1	              // shock affects at time t only

	}
	if `i' > `btime' {
		setx D_`dummyshockvar' 0			// diff dummyshock back to 0
		setx L_`dummyshockvar' 1	              // lag dummyshock now at 1

	}
	
}



	loc preddv
	loc x 1
	foreach var of varlist `lcomplist'	{
		tempvar td`x'log`i'
		loc preddv `"`preddv' `td`x'log`i'' "'
		loc x = `x' + 1
	}
	
	if "`pv'" != ""	{
		qui simqi, pv genpv(`preddv')				// grab our predicted values
	}
	else	{										// else expected values
		qui simqi, ev genev(`preddv')
	}
	
	loc denominator`i'
	loc x 1
	foreach var of varlist `lcomplist'	{
		tempvar t`x'log`i'
		gen `t`x'log`i'' = m`x' + `td`x'log`i'' // add them to old predictions
		su `t`x'log`i'', meanonly
		scalar m`x' = r(mean)
		loc denominator`i' `"`denominator`i'' + (exp(`t`x'log`i''))"' // need this for below
		loc x = `x' + 1
	}
}







* ------------------------Un-Transform----------------------------------------
* note that after untransforming compositions, starting means are subtracted and
* percentiles drawn.


**EFFECTS PLOT
local keepthese
preserve


loc basetime = `burnin'	+ 1	
loc endtime = `brange' 
loc time = `btime'


* keep only start-time, shocktime and endtime:

loc keeps
forv m = 1/`maxdv'	{
	local keeps `"`keeps' `t`m'log`basetime'' `t`m'log`time'' `t`m'log`endtime'' "'
}
keep `keeps'



local z = `maxdv' + 1
	qui forv m = 1/`maxdv' {
		tempvar var_pie`basetime'_`m' var_pie`time'_`m' var_pie`endtime'_`m'
		* Create compositions for start time:
		gen `var_pie`basetime'_`m'' = (exp(`t`m'log`basetime''))/(1  `denominator`basetime'')
		_pctile `var_pie`basetime'_`m'', p(50)		// grab midpoint
		gen var_pie_med_`basetime'_`m' = r(r1)
		
		* create composition for shocktime:
	        if "`sig2'" != "" {
                gen `var_pie`time'_`m'' = ((exp(`t`m'log`time''))/(1  `denominator`time'')) - var_pie_med_`basetime'_`m'
                _pctile `var_pie`time'_`m'', p(`sigl',`sigu')
		gen var_pie_ll_sr1_`m' = r(r1)
		gen var_pie_ul_sr1_`m' = r(r2)
                _pctile `var_pie`time'_`m'', p(`sigl2',`sigu2')
		gen var_pie_ll_sr2_`m' = r(r1)
		gen var_pie_ul_sr2_`m' = r(r2)
             }
             else {
                gen `var_pie`time'_`m'' = ((exp(`t`m'log`time''))/(1  `denominator`time'')) - var_pie_med_`basetime'_`m'
                _pctile `var_pie`time'_`m'', p(`sigl',`sigu')
		gen var_pie_ll_sr1_`m' = r(r1)
		gen var_pie_ul_sr1_`m' = r(r2)
               }
                * create composition for LR-time:
              if "`sig2'" != "" {
		gen `var_pie`endtime'_`m'' = (exp(`t`m'log`endtime''))/(1  `denominator`endtime'') -         var_pie_med_`basetime'_`m'
		_pctile `var_pie`endtime'_`m'', p(`sigl',`sigu')
		gen var_pie_ll_lr1_`m' = r(r1)
		gen var_pie_ul_lr1_`m' = r(r2)
        
                _pctile `var_pie`endtime'_`m'', p(`sigl2',`sigu2')
		gen var_pie_ll_lr2_`m' = r(r1)
		gen var_pie_ul_lr2_`m' = r(r2)
                 }
                 else {
                gen `var_pie`endtime'_`m'' = (exp(`t`m'log`endtime''))/(1  `denominator`endtime'') -         var_pie_med_`basetime'_`m'
		_pctile `var_pie`endtime'_`m'', p(`sigl',`sigu')
		gen var_pie_ll_lr1_`m' = r(r1)
		gen var_pie_ul_lr1_`m' = r(r2)
                }


              if "`sig2'" != "" {
                local keepthese `"`keepthese' var_pie_ll_sr1_`m' var_pie_ul_sr1_`m' var_pie_ll_lr1_`m' var_pie_ul_lr1_`m' var_pie_ll_sr2_`m' var_pie_ul_sr2_`m' var_pie_ll_lr2_`m' var_pie_ul_lr2_`m'  "'
                                }
             else               {
               local keepthese `"`keepthese' var_pie_ll_sr1_`m' var_pie_ul_sr1_`m' var_pie_ll_lr1_`m' var_pie_ul_lr1_`m' "'
             }
	}


		  
	tempvar var_pie`time'_`z' var_pie`endtime'_`z' var_pie`basetime'_`z'  // the un-transformation baseline
	gen `var_pie`basetime'_`z'' = 1/(1  `denominator`basetime'')
	_pctile `var_pie`basetime'_`z'', p(50)		// grab midpoint
	gen var_pie_med_`basetime'_`z' = r(r1)
	
        if "`sig2'" != "" {
	           gen `var_pie`time'_`z'' = (1/(1  `denominator`time'')) - var_pie_med_`basetime'_`z'	
	          _pctile `var_pie`time'_`z'', p(`sigl',`sigu')
	          gen var_pie_ll_sr1_`z' = r(r1)
	          gen var_pie_ul_sr1_`z' = r(r2)
           
                  _pctile `var_pie`time'_`z'', p(`sigl2',`sigu2')
	          gen var_pie_ll_sr2_`z' = r(r1)
	          gen var_pie_ul_sr2_`z' = r(r2)
                    
                  gen `var_pie`endtime'_`z'' = (1/(1  `denominator`endtime'')) - var_pie_med_`basetime'_`z'
	          _pctile `var_pie`endtime'_`z'', p(`sigl',`sigu')
	          gen var_pie_ll_lr1_`z' = r(r1)
	          gen var_pie_ul_lr1_`z' = r(r2)

                   _pctile `var_pie`endtime'_`z'', p(`sigl2',`sigu2')
	           gen var_pie_ll_lr2_`z' = r(r1)
	           gen var_pie_ul_lr2_`z' = r(r2)
                }
                 else               {              
            	gen `var_pie`time'_`z'' = (1/(1  `denominator`time'')) - var_pie_med_`basetime'_`z'	
         	_pctile `var_pie`time'_`z'', p(`sigl',`sigu')
         	gen var_pie_ll_sr1_`z' = r(r1)
        	gen var_pie_ul_sr1_`z' = r(r2)
                 
                gen `var_pie`endtime'_`z'' = (1/(1  `denominator`endtime'')) - var_pie_med_`basetime'_`z'
	        _pctile `var_pie`endtime'_`z'', p(`sigl',`sigu')
	        gen var_pie_ll_lr1_`z' = r(r1)
	        gen var_pie_ul_lr1_`z' = r(r2)
                 }


        if "`sig2'" != "" {	
	local keepthese `"`keepthese' var_pie_ll_sr1_`z' var_pie_ul_sr1_`z' var_pie_ll_lr1_`z' var_pie_ul_lr1_`z' var_pie_ll_sr2_`z' var_pie_ul_sr2_`z' var_pie_ll_lr2_`z' var_pie_ul_lr2_`z' "'


keep `keepthese'
qui keep in 1

gen count = _n
reshape long var_pie_ll_sr1_ var_pie_ul_sr1_ var_pie_ll_lr1_ var_pie_ul_lr1_ var_pie_ll_sr2_ var_pie_ul_sr2_ var_pie_ll_lr2_ var_pie_ul_lr2_, j(sort) i(count)

}
else{
	local keepthese `"`keepthese' var_pie_ll_sr1_`z' var_pie_ul_sr1_`z' var_pie_ll_lr1_`z' var_pie_ul_lr1_`z' "'

keep `keepthese'
qui keep in 1

gen count = _n
reshape long var_pie_ll_sr1_ var_pie_ul_sr1_ var_pie_ll_lr1_ var_pie_ul_lr1_, j(sort) i(count)
}

gen sort_lr = sort - 0.2
gen sort_sr = sort + 0.2


* create midpoints:
gen mid_sr = (var_pie_ll_sr1_ + var_pie_ul_sr1_)/2
gen mid_lr = (var_pie_ll_lr1_ + var_pie_ul_lr1_)/2








loc z : word count `dvs'
	forvalues i = 1/`z'{
            		
            if "`i'" == "1"	{
			loc base : word 1 of `dvs'
		}
		loc iminus1 = `i' - 1
		else	{
			loc dvplace : word `i' of `dvs'
			loc dvname `" `dvname' `iminus1' "`dvplace'" "'
		}
               }

loc dvnames `" `dvname' `z' "`base'"  "'





 if "`percentage'" != ""{
  loc Change "Percentage Change"
  }
  else {
  loc Change "Proportion Change"
   }


 	if "`pv'" != ""	{
		loc valname "Predicted"
	}
	else	{										
		loc valname "Expected"
	}

	*Defining scalars and locals
	ereturn local valname_e = "`valname'"
	if "`sig'" != "" {
		ereturn scalar sig_e = `sig'
	}
	if "`sig2'" != "" {
		ereturn scalar sig2_e = `sig2'
	}
	ereturn local dvnames_e = `"`dvnames'"'
	ereturn scalar signif_e = `signif'
	if "`signif2'" != ""  {
		ereturn scalar signif2_e = `signif2'
	}
	ereturn local Change = "`Change'"
	*Saving cfbplot dataset in a matrix
	mkmat _all, matrix(effectsplot)
	ereturn matrix effectsplot effectsplot
restore


	if "`effectsplot'" != "" {
		effectsplot
	}

* ------------------------Un-Transform------------------------------------------
**CFB PLOT
loc keepthese
preserve
loc z : word count `dvs'		// how many DV's?
qui forv i = 1/`brange' {
	loc m 1
	qui foreach var of varlist `lcomplist'	{
		tempvar var`m'_pie`i'
		gen `var`m'_pie`i'' = (exp(`t`m'log`i''))/(1  `denominator`i'')
		_pctile `var`m'_pie`i'', p(`sigl',`sigu')	// grab CIs for each DV

          if "`percentage'" != ""{
		gen var`m'_pie_ll_`i' = r(r1)*100
		gen var`m'_pie_ul_`i' = r(r2)*100
           }
           else{
		gen var`m'_pie_ll_`i' = r(r1)
		gen var`m'_pie_ul_`i' = r(r2)
           }

		loc keepthese `"`keepthese' var`m'_pie_ll_`i' var`m'_pie_ul_`i' "'
		loc m = `m' + 1
	}			  
	tempvar var`z'_pie`i' 					// the un-transformation baseline
	gen `var`z'_pie`i'' = 1/(1  `denominator`i'')	

   
      	  _pctile `var`z'_pie`i'', p(`sigl',`sigu')
       if "`percentage'" != ""{
     	  gen var`z'_pie_ll_`i' = r(r1)*100
	  gen var`z'_pie_ul_`i' = r(r2)*100
       }
       else{
          gen var`z'_pie_ll_`i' = r(r1)
	  gen var`z'_pie_ul_`i' = r(r2)
       }
 


	loc keepthese `"`keepthese' var`z'_pie_ll_`i' var`z'_pie_ul_`i' "'
}

keep `keepthese'
qui keep in 1
tempvar count 
qui gen `count' = _n

loc reshapevar
qui forv i = 1/`z' {					// reshape across `z' vars in `dvs'
	loc reshapevar `"`reshapevar' var`i'_pie_ll_ var`i'_pie_ul_ "'
}

qui reshape long `reshapevar', j(time) i(`count')
qui drop `count' time
qui drop in 1/`burnin'
qui gen time = _n

qui forv i = 1/`z' {					// create mid-points
	gen mid`i' = (var`i'_pie_ll_ + var`i'_pie_ul_)/2
}
order time

  
        loc ulll 
	loc mid "scatter mid1 time"
   

	loc legend
	if "`pv'" != ""	{
		loc valname "Predicted"
	}
	else	{										
		loc valname "Expected"
	}
       if "`percentage'" != ""{
              loc proportion  "Percentage"
        }
        else  {
              loc proportion  "Proportion"
         }

	forv i = 1/`z'	{
		loc ulll `"`ulll' || rspike var`i'_pie_ul_ var`i'_pie_ll_ time, lcolor(black) lwidth(thin) "'	
		if "`i'" > "1"	{
			loc mid `"`mid' || scatter mid`i' time "'
		}
		if "`i'" == "1"	{
			loc base : word 1 of `dvs'
		}
		loc iminus1 = `i' - 1
		else	{
			loc dvplace : word `i' of `dvs'
			loc legend `" `legend' `iminus1' "`dvplace'" "'
		}
	}
       

*Defining scalars and locals
	ereturn local proportion_c = "`proportion'" 
	ereturn local mid_c = "`mid'"
	ereturn local ulll_c = "`ulll'"
	ereturn local legend_c = `"`legend'"'
	ereturn scalar z_c = `z'
	ereturn local base_c = "`base'"
	ereturn local valname_c = "`valname'"
	ereturn scalar signif_c = `signif'

	*Saving cfbplot dataset in a matrix
	mkmat _all, matrix(cfbplot)
	ereturn matrix cfbplot cfbplot
	
restore

	if "`cfbplot'" != "" {
		cfbplot
	}
}

use "`original'", clear
	ereturn local cmd = "dynsimpie"
end
