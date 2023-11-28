* This do file replicates Figure 5 in Serrato & Zidar (2018).
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

* Generate variables
gen r_g = rev_corptax/GDP*100

* Assign explanatory variables
g x0  = corporate_rate
g x1  = FederalIncomeasStateTaxBase
g x2  = FedIncomeTaxDeductible 
g x3  = throwback 
g x4  = sales_wgt 
g x5  = Losscarryforward 
g x6  = Losscarryback 
g x7  = combined 
g x8  = investment_credit 
g x9  = rec_val
g x10 = ACRSDepreciation 
g x11 = AllowFedAccDep 
g x12 = FederalBonusDepreciation 
g x13 = FranchiseTax
g x14 = incr_ma 
g x15 = incr_fixed

* Weighted by mean state GDP across years
bysort fips_state: egen mean_GDP = mean(GDP)

tempfile data
save `data', replace


********************************************************************************
**# Panel A
********************************************************************************

* Divide the years into 6 breaks and then run a regression in each break
local i = 1
foreach break in break1 break2 break3 break4 break5 break6 {
	use `data', clear
	
	keep r_g x0-x15 mean_GDP year

	if "`break'" == "break1" {
		keep if year >= 1980 & year <= 1985
	}

	if "`break'" == "break2" {
		keep if year >= 1986 & year <= 1990
	}

	if "`break'" == "break3" {
		keep if year >= 1991 & year <= 1995
	}

	if "`break'" == "break4" {
		keep if year >= 1996 & year <= 2000
	}

	if "`break'" == "break5" {
		keep if year >= 2001 & year <= 2005
	}

	if "`break'" == "break6" {
		keep if year >= 2006 & year <= 2010
	}

	reg r_g x0-x15 [aw=mean_GDP]

	gen model = e(mss)
	gen res = e(rss)
	
	keep res model
	keep if _n == 1
	
	egen tss = rowtotal(model res)
	replace model = model/tss
	replace res = 1
	drop tss

	tempfile data`i'
	save `data`i'', replace

	local ++i
}

use `data1', clear
forvalues i = 2/6 {
	append using `data`i''
}

local new_obs = _N + 1
set obs `new_obs' // Add one more observation as starting point in plotting
gen id = _n
replace id = 0 if id == `new_obs'
sort id

foreach var in model res {
	replace `var' = `var'[2] if id == 0
	replace `var' = `var' * 100
}

* Design x axis
label define id_fig 0 "1980" 1 "1985" 2 "1990" 3 "1995" 4 "2000" 5 "2005" 6 "2010"
label values id id_fig

* Plot
label var model "Explained Variance"
label var res "Unexplained Variance"

twoway (area res id, color(maroon)) ///
	(area model id, color(dknavy)), ////
	title("A) Variance Decomposition", size(medium) position(11)) ///
	xti("") yti("Percent", height(5)) ///
	ylab(0(25)100, notick angle(90)) ///
	xlab(0/6, valuelabel notick) ///
	legend(order(2 1) row(1) size(small) span region(lc(black)) position(6)) ///
	name(panelA, replace)


********************************************************************************
**# Panel B
********************************************************************************

local i = 1
foreach break in break1 break2 break3 break4 break5 break6 {
	use `data', clear
	
	keep r_g x0-x15 mean_GDP year

	if "`break'" == "break1" {
		keep if year >= 1980 & year <= 1985
	}
	
	if "`break'" == "break2" {
		keep if year >= 1986 & year <= 1990
	}

	if "`break'" == "break3" {
		keep if year >= 1991 & year <= 1995
	}

	if "`break'" == "break4" {
		keep if year >= 1996 & year <= 2000
	}

	if "`break'" == "break5" {
		keep if year >= 2001 & year <= 2005
	}

	if "`break'" == "break6" {
		keep if year >= 2006 & year <= 2010
	}
	
	reg r_g x0-x15 [aw=mean_GDP]

	* Y = b0 + x1 b1 + ... + x15 b15 + e
	* Var(Y) = Var(x1) b1^2 + ... + var(x15) b15^2 + var(e), assuming Cov = 0
	forv j = 0/15 {
		local beta = _b[x`j']
		sum x`j'
		local var = (r(sd))^2
		gen bsqXx`j' = (`beta')^2 * `var'
	}
	
	gen ss_corprate = bsqXx0
	egen ss_base = rowtotal(bsqXx1-bsqXx15)
	gen corp = ss_corprate/(ss_base+ss_corprate)
	gen base = 1
	
	keep corp base
	keep if _n == 1
	
	tempfile data`i'
	save `data`i'', replace
	
	local ++i
}

use `data1', clear
forvalues i = 2/6 {
	append using `data`i''
}

local new_obs = _N + 1
set obs `new_obs'
gen id = _n
replace id = 0 if id == `new_obs'
sort id

foreach var in corp base {
	replace `var' = `var'[2] if id == 0
	replace `var' = `var' * 100
}

label define id_fig 0 "1980" 1 "1985" 2 "1990" 3 "1995" 4 "2000" 5 "2005" 6 "2010"
label values id id_fig

* Plot
label var corp "Corporate Tax Rate"
label var base "Corporate Tax Base Rules"

twoway (area base id, color(dknavy*.7)) ///
	(area corp id, color(dknavy)), ////
	title("B) Share of Explained Variance, Rate vs. Base", size(medium) position(11)) ///
	xti("") yti("% Explained Variance", height(5)) ///
	ylab(0(25)100, notick angle(90)) ///
	xlab(0/6, valuelabel notick) ///
	legend(order(2 1) row(1) size(small) span region(lc(black)) position(6)) ///
	name(panelB, replace)


********************************************************************************
**# Panel C
********************************************************************************

local i = 1
foreach break in break1 break2 break3 break4 break5 break6 {
	use `data', clear
	
	keep r_g x0-x15 mean_GDP year
	
	if "`break'" == "break1" {
		keep if year >= 1980 & year <= 1985
	}

	if "`break'" == "break2" {
		keep if year >= 1986 & year <= 1990
	}

	if "`break'" == "break3" {
		keep if year >= 1991 & year <= 1995
	}

	if "`break'" == "break4" {
		keep if year >= 1996 & year <= 2000
	}

	if "`break'" == "break5" {
		keep if year >= 2001 & year <= 2005
	}

	if "`break'" == "break6" {
		keep if year >= 2006 & year <= 2010
	}
	
	reg r_g x0-x15 [aw=mean_GDP]

	local tss = e(mss) + e(rss)
	gen res = e(rss)/`tss'
	gen model = e(mss)/`tss'

	forv j = 0/15 {
		local beta = _b[x`j']
		sum x`j'
		local var=(r(sd))^2
		gen bsqXx`j' = (`beta')^2 * `var'
	}

	gen ss_corprate = bsqXx0/`tss'
	gen ss_fedincbase = bsqXx1/`tss'
	gen ss_fedincded = bsqXx2/`tss'
	gen ss_throwback = bsqXx3/`tss'
	gen ss_saleswgt = bsqXx4/`tss'
	gen ss_losscarryforward = bsqXx5/`tss'
	gen ss_losscarryback = bsqXx6/`tss'
	gen ss_combined = bsqXx7/`tss'
	gen ss_investment_credit = bsqXx8/`tss'
	gen ss_rec_val = bsqXx9/`tss'
	gen ss_acrsdep = bsqXx10/`tss'
	gen ss_allowfedaccdep = bsqXx11/`tss'
	gen ss_fedbonusdep = bsqXx12/`tss'
	gen ss_frantax = bsqXx13/`tss'
	gen ss_incr_ma = bsqXx14/`tss'
	gen ss_incr_fixed = bsqXx15/`tss'
	
	keep ss_*
	keep if _n == 1
	
	egen sum_ss = rowtotal(ss_*)
	egen sum_base = rowtotal(ss_*)
	replace sum_base = sum_base - ss_corprate
	drop ss_corprate
	
	ds ss_*
	foreach var in `r(varlist)' {
		qui replace `var' = `var'/sum_base
	}
	drop sum_base

	tempfile data`i'
	save `data`i'', replace

	local ++i
}

use `data1', clear
forvalues i = 2/6 {
	append using `data`i''
}

local new_obs = _N + 1
set obs `new_obs'
gen id = _n
replace id = 0 if id == `new_obs'
sort id

ds id, not
foreach var in `r(varlist)' {
	replace `var' = `var'[2] if id == 0
}

* Generate cumulative meansure for stacked graph
gen fedincbase = ss_fedincbase
gen fedincded = fedincbase + ss_fedincded
gen throwback = fedincded + ss_throwback
gen saleswgt = throwback + ss_saleswgt
gen losscarryforward = saleswgt + ss_losscarryforward
gen losscarryback = losscarryforward + ss_losscarryback
gen combined = losscarryback + ss_combined
gen other = 1

gen investmentcredit = combined + ss_investment_credit
gen recval = investmentcredit + ss_rec_val
gen acrsdep = recval + ss_acrsdep
gen allowfedaccdep = acrsdep + ss_allowfedaccdep
gen fedbonusdep = allowfedaccdep + ss_fedbonusdep
gen frantax = fedbonusdep + ss_frantax
gen incrma = frantax + ss_incr_ma
gen incrfixed = incrma + ss_incr_fixed
assert incrfixed > .99	// verify true or not
replace incrfixed = 1

* Express as %
ds id ss_*, not
foreach var in `r(varlist)' {
	replace `var' = `var' * 100
}

* Design x-axis
label define id_fig 0 "1980" 1 "1985" 2 "1990" 3 "1995" 4 "2000" 5 "2005" 6 "2010"
label values id id_fig

* Plot
label var fedincbase "Federal Inc as State Base"
label var fedincded "Federal Inc Deductible"
label var throwback "Throwback Rules"
label var saleswgt "Sales Apportionment Wgt"
label var losscarryforward "Loss Carryforward"
label var losscarryback "Loss Carryback"
label var combined "Combined Reporting"
label var other "Other Tax Base Rules"

label var investmentcredit "Investment Tax Credit"
label var recval "R&D Credit"
label var acrsdep "ACRS Depreciation"
label var allowfedaccdep "Federal Accelerated Dep"
label var fedbonusdep "Federal Bonus Dep"
label var frantax "Franchise Tax"
label var incrma "Incr R&D, Moving Avg Base"
label var incrfixed "Incr R&D, Fixed Base"

twoway (area incrfixed id, color(emerald)) ///
	(area incrma id, color(gs11)) ///
	(area frantax id, color(navy)) ///
	(area fedbonusdep id, color(maroon)) ///
	(area allowfedaccdep id, color(forest_green)) ///
	(area acrsdep id, color(dkorange)) ///
	(area recval id, color(teal)) ///
	(area investmentcredit id, color(red)) ///
	(area combined id, color(lavender)) ///
	(area losscarryback id, color(stone)) ///
	(area losscarryforward id, color(dknavy*.8)) ///
	(area saleswgt id, color(maroon*.7)) ///
	(area throwback id, color(erose*1.5)) ///
	(area fedincded id, color(red*1.65)) ///
	(area fedincbase id, color(dknavy)), ///
	title("C) Share of Explained Variance by Base Rule", size(medium) position(11)) ///
	xti("") yti("% Explained Var Among Base Rules", height(5) size(small)) ///
	ylabel(0(25)100, notick angle(90)) ///
	xlabel(0/6, valuelabel notick) ///
	legend(order(15 14 13 12 11 10 9 8 7 6 5 4 3 2 1) cols(2) size(small) span region(lc(black))) ///
	name(panelC, replace)

* Combine and export
graph combine panelA panelB, row(1) name(set1, replace)
graph combine set1 panelC, rows(2)

graph export "Figures/Figure6.svg", replace