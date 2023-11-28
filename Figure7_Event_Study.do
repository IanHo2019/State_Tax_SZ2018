* This do file replicates Figure 7 in Serrato & Zidar (2018).
* Author: Ian Ho
* Date: Nov 16, 2023
* Stata Version: 18

clear all


********************************************************************************
**# Data Wrangling
********************************************************************************

use "Data/state_taxes_analysis.dta", clear

* Keep only 50 states in 1980-2010
drop if fips_state == 0 | fips_state == 11 | fips_state > 56
keep if inrange(year, 1980, 2010)

* Generate outcome variables
gen log_rev_corptax = 100*ln(rev_corptax)
gen log_gdp = 100*ln(GDP)
gen r_g = 100*rev_corptax/GDP

* Indicate rate changes with a threshold (i.e., 0.5)
xtset fips_state year

gen ch_corporate_rate = corporate_rate - L1.corporate_rate
replace ch_corporate_rate = 0 if abs(ch_corporate_rate) <= 0.5
gen ch_corporate_rate_ind = (ch_corporate_rate != 0 & !missing(ch_corporate_rate))
gen ch_corporate_rate_inc = (ch_corporate_rate > 0 & !missing(ch_corporate_rate))
gen ch_corporate_rate_dec = (ch_corporate_rate < 0)

* Select control variables
local baserules = "FederalIncomeasStateTaxBase sales_wgt throwback FedIncomeTaxDeductible Losscarryforward FranchiseTax"
foreach var in `baserules' {
	gen abs_`var' = abs(`var' - L1.`var')
	gen ch_`var' = (abs_`var' != 0 & abs_`var'!=.)
	drop abs_`var'
}

tempfile dataset
save `dataset', replace


********************************************************************************
**# Impacts of Decrease in Corporate Rate
********************************************************************************

use `dataset', clear

* Set up event
g e = year if ch_corporate_rate_dec == 1

sum year
scalar years = `r(max)' - `r(min)' + 1

* Determine the event time for each observation
** Fill up
local i = 0
while `i' < years {
	qui replace e = e[_n+1] if fips_state == fips_state[_n+1] & abs(year - e[_n+1]) < abs(year - e)
	local ++i
}
** Fill down 
local i = 0
while `i' < years {
	qui replace e = e[_n-1] if fips_state == fips_state[_n-1] & abs(year - e[_n-1]) < abs(year - e)
	local ++i
}

* Generate relative time dummies
gen Dn5 = year<=e-5

gen Dn4 = year==e-4
gen Dn3 = year==e-3
gen Dn2 = year==e-2
gen D0  = year==e
gen D1  = year==e+1
gen D2  = year==e+2
gen D3  = year==e+3
gen D4  = year==e+4
gen D5  = year==e+5

gen D6  = year>=e+6

* Generate adjusted control variables
local controls = "FederalIncomeasStateTaxBase sales_wgt throwback FedIncomeTaxDeductible Losscarryforward FranchiseTax"
local x = 1
foreach control in `controls' {
	g temp_e = year if ch_`control' != 0
		* Fill up
		local i = 0
		while `i' < years {
			qui replace temp_e = temp_e[_n+1] if fips_state == fips_state[_n+1] & abs(year - temp_e[_n+1]) < abs(year - temp_e)
			local ++i
		}
		
		* Fill down
		local i = 0
		while `i' < years {
			qui replace temp_e = temp_e[_n-1] if fips_state == fips_state[_n-1] & abs(year - temp_e[_n-1]) < abs(year - temp_e)
			local ++i
		}
		
		* Generate variables
		g control`x' = year <= temp_e-5
		local ++x
		g control`x' = year == temp_e-4
		local ++x
		g control`x' = year == temp_e-3
		local ++x
		g control`x' = year == temp_e-2
		local ++x
		g control`x' = year == temp_e
		local ++x
		g control`x' = year == temp_e+1
		local ++x
		g control`x' = year == temp_e+2
		local ++x
		g control`x' = year == temp_e+3
		local ++x
		g control`x' = year == temp_e+4
		local ++x
		g control`x' = year == temp_e+5
		local ++x
		g control`x' = year >= temp_e+6
		local ++x
		
		drop temp_e
}

* Run regressions
local ylist = "r_g log_rev_corptax log_gdp"
foreach y in `ylist' {
	* No controls
	qui areg `y' Dn5-D6 i.fips_state, absorb(year) cluster(fips_state)
	
	preserve
	regsave
	drop if substr(var,1,1) != "D"
	drop N r2
	export delimited "Figures/dec_`y'.csv", replace
	restore
	
	* With controls
	qui areg `y' Dn5-D6 control* i.fips_state, absorb(year) cluster(fips_state)
	
	preserve
	regsave
	drop if substr(var,1,1) != "D"
	drop N r2
	export delimited "Figures/dec_`y'_control.csv", replace
	restore
}

* Visualization
foreach y in `ylist' {
	* Construct a dataset for plotting
	import delim "Figures/dec_`y'.csv", clear
	rename (coef stderr) (b1 se1)
	gen t = 95 + _n
	replace t = t+1 if t>=100
	set obs 12
	replace t = 100 in 12
	replace b1 = 0 in 12
	replace se1 = 0 in 12
	sort t
	tempfile data
	save `data', replace
	
	import delim "Figures/dec_`y'_control.csv", clear
	rename (coef stderr) (b2 se2)
	gen t = 94.85 + _n
	replace t = t+1 if t>99.8
	set obs 12
	replace t=99.85 in 12
	replace b2=0 in 12
	replace se2=0 in 12
	sort t
	merge 1:1 t using `data', nogen
	
	gen fig_upper1 = b1+1.96*se1
	gen fig_lower1 = b1-1.96*se1
	gen fig_upper2 = b2+1.96*se2
	gen fig_lower2 = b2-1.96*se2
	gen fig_t = t-101
	rename b1 fig_b1
	rename b2 fig_b2
	
	* Plot
	if "`y'" == "r_g" {
		local panel = "A"
		local rawti = "Corp Tax Revenue Share of GDP"
		local yti = "Percentage points"
	}
	
	if "`y'" == "log_rev_corptax" {
		local panel = "B"
		local rawti = "Log Corporate Tax Revenue"
		local yti = "Percent"
	}
	
	if "`y'" == "log_gdp" {
		local panel = "C"
		local rawti = "Log State GDP"
		local yti = "Percent"
	}

	twoway (scatter fig_b1 fig_t if fig_t<=5 & fig_t>-5, c(l) lc(dknavy) mc(dknavy) msymbol(smtriangle)) ///
		(rcap fig_upper1 fig_lower1 fig_t if fig_t<=5 & fig_t>-5, c(l) lpattern(solid) lc(dknavy)) ///
		(scatter fig_b2 fig_t if fig_t<=5 & fig_t>-5, c(l) lpattern(dash) lc(maroon) mc(maroon) msymbol(smdiamond)) ///
		(rcap fig_upper2 fig_lower2 fig_t if fig_t<=5 & fig_t>-5, c(l) lpattern(dash) lc(maroon)), ///
		xline(0, lc(gs11) lp(shortdash)) ///
		yline(0, lc(gs11) lp(shortdash)) ///
		title("`panel') `rawti'", size(medium)) ///
		xtitle("Years since decrease in corprate rate", size(medsmall)) ///
		ytitle("`yti'", size(medsmall)) ///
		xlab(-4(1)5, nogrid) ///
		legend(label(1 "No Tax Base Controls") label(2 "95% CI") label(3 "Tax Base Controls") label(4 "95% CI") rows(2) position(6) span region(lc(black))) ///
		name(panel`panel', replace)
}


********************************************************************************
**# Impacts of Increase in Corporate Rate
********************************************************************************

use `dataset', clear

* Set up event
g e = year if ch_corporate_rate_inc == 1	// this is the only difference from the above

sum year
scalar years = `r(max)' - `r(min)' + 1

* Determine the event time for each observation
** Fill up
local i = 0
while `i' < years {
	qui replace e = e[_n+1] if fips_state == fips_state[_n+1] & abs(year - e[_n+1]) < abs(year - e)
	local ++i
}
** Fill down 
local i = 0
while `i' < years {
	qui replace e = e[_n-1] if fips_state == fips_state[_n-1] & abs(year - e[_n-1]) < abs(year - e)
	local ++i
}

* Generate relative time dummies
gen Dn5 = year<=e-5

gen Dn4 = year==e-4
gen Dn3 = year==e-3
gen Dn2 = year==e-2
gen D0  = year==e
gen D1  = year==e+1
gen D2  = year==e+2
gen D3  = year==e+3
gen D4  = year==e+4
gen D5  = year==e+5

gen D6  = year>=e+6

* Generate adjusted control variables
local controls = "FederalIncomeasStateTaxBase sales_wgt throwback FedIncomeTaxDeductible Losscarryforward FranchiseTax"
local x = 1
foreach control in `controls' {
	g temp_e = year if ch_`control' != 0
		* Fill up
		local i = 0
		while `i' < years {
			qui replace temp_e = temp_e[_n+1] if fips_state == fips_state[_n+1] & abs(year - temp_e[_n+1]) < abs(year - temp_e)
			local ++i
		}
		
		* Fill down
		local i = 0
		while `i' < years {
			qui replace temp_e = temp_e[_n-1] if fips_state == fips_state[_n-1] & abs(year - temp_e[_n-1]) < abs(year - temp_e)
			local ++i
		}
		
		* Generate variables
		g control`x' = year <= temp_e-5
		local ++x
		g control`x' = year == temp_e-4
		local ++x
		g control`x' = year == temp_e-3
		local ++x
		g control`x' = year == temp_e-2
		local ++x
		g control`x' = year == temp_e
		local ++x
		g control`x' = year == temp_e+1
		local ++x
		g control`x' = year == temp_e+2
		local ++x
		g control`x' = year == temp_e+3
		local ++x
		g control`x' = year == temp_e+4
		local ++x
		g control`x' = year == temp_e+5
		local ++x
		g control`x' = year >= temp_e+6
		local ++x
		
		drop temp_e
}

* Run regressions
local ylist = "r_g log_rev_corptax log_gdp"
foreach y in `ylist' {
	* No controls
	qui areg `y' Dn5-D6 i.fips_state, absorb(year) cluster(fips_state)
	
	preserve
	regsave
	drop if substr(var,1,1) != "D"
	drop N r2
	export delimited "Figures/inc_`y'.csv", replace
	restore
	
	* With controls
	qui areg `y' Dn5-D6 control* i.fips_state, absorb(year) cluster(fips_state)
	
	preserve
	regsave
	drop if substr(var,1,1) != "D"
	drop N r2
	export delimited "Figures/inc_`y'_control.csv", replace
	restore
}

* Visualization
foreach y in `ylist' {
	* Construct a dataset for plotting
	import delim "Figures/inc_`y'.csv", clear
	rename (coef stderr) (b1 se1)
	gen t = 95 + _n
	replace t = t+1 if t>=100
	set obs 12
	replace t = 100 in 12
	replace b1 = 0 in 12
	replace se1 = 0 in 12
	sort t
	tempfile data
	save `data', replace
	
	import delim "Figures/inc_`y'_control.csv", clear
	rename (coef stderr) (b2 se2)
	gen t = 94.85 + _n
	replace t = t+1 if t>99.8
	set obs 12
	replace t=99.85 in 12
	replace b2=0 in 12
	replace se2=0 in 12
	sort t
	merge 1:1 t using `data', nogen
	
	gen fig_upper1 = b1+1.96*se1
	gen fig_lower1 = b1-1.96*se1
	gen fig_upper2 = b2+1.96*se2
	gen fig_lower2 = b2-1.96*se2
	gen fig_t = t-101
	rename b1 fig_b1
	rename b2 fig_b2
	
	* Plot
	if "`y'" == "r_g" {
		local panel = "D"
		local rawti = "Corp Tax Revenue Share of GDP"
		local yti = "Percentage points"
	}
	
	if "`y'" == "log_rev_corptax" {
		local panel = "E"
		local rawti = "Log Corporate Tax Revenue"
		local yti = "Percent"
	}
	
	if "`y'" == "log_gdp" {
		local panel = "F"
		local rawti = "Log State GDP"
		local yti = "Percent"
	}

	twoway (scatter fig_b1 fig_t if fig_t<=5 & fig_t>-5, c(l) lc(dknavy) mc(dknavy) msymbol(smtriangle)) ///
		(rcap fig_upper1 fig_lower1 fig_t if fig_t<=5 & fig_t>-5, c(l) lpattern(solid) lc(dknavy)) ///
		(scatter fig_b2 fig_t if fig_t<=5 & fig_t>-5, c(l) lpattern(dash) lc(maroon) mc(maroon) msymbol(smdiamond)) ///
		(rcap fig_upper2 fig_lower2 fig_t if fig_t<=5 & fig_t>-5, c(l) lpattern(dash) lc(maroon)), ///
		xline(0, lc(gs11) lp(shortdash)) ///
		yline(0, lc(gs11) lp(shortdash)) ///
		title("`panel') `rawti'", size(medium)) ///
		xtitle("Years since increase in corprate rate", size(medsmall)) ///
		ytitle("`yti'", size(medsmall)) ///
		xlab(-4(1)5, nogrid) ///
		legend(label(1 "No Tax Base Controls") label(2 "95% CI") label(3 "Tax Base Controls") label(4 "95% CI") rows(2) position(6) span region(lc(black))) ///
		name(panel`panel', replace)
}


********************************************************************************
**# Combine Graphs and Export
********************************************************************************

grc1leg panelA panelB panelC panelD panelE panelF, col(3) iscale(0.6)
graph export "Figures/Figure7.svg", replace