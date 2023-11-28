* This do file replicates Figure 8 in Serrato & Zidar (2018).
* Author: Ian Ho
* Date: Nov 16, 2023
* Stata Version: 18

clear all


********************************************************************************
**# Panel A
********************************************************************************

use "Data/state_taxes_analysis.dta", clear

* Keep only 50 states in 1980-2010
drop if fips_state == 0 | fips_state == 11 | fips_state > 56
keep if inrange(year, 1980, 2010)

* Gen main variables
gen log_rev = ln(rev_corp)
gen log_corp = ln(1-corporate_rate/100)
gen r_g = rev_corptax/GDP
gen log_gdp = ln(GDP)

* Center base components around state & year FE
local base "sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit" 
foreach var in `base' {
	reg `var' i.fips_state i.year 
	predict base_hat, res
	replace `var' = base_hat 
	drop base_hat
}

* Normalization
bysort fips_state: egen mean_GDP = mean(GDP)

foreach xvar of varlist rec_val sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit incr_ma incr_fixed {
	sum `xvar' [aw=mean_GDP], detail
	replace `xvar' = (`xvar'-r(mean))/r(sd)
}

* Assign variables
local i = 1
foreach var of varlist rec_val sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit incr_ma incr_fixed {
	gen s`i' = `var'
	local ++i
}

* The ANOVA looped over r_g, log_rev, and log_gdp
local base  "c.rec_val c.sales_wgt c.Losscarryback c.Losscarryforward c.FranchiseTax c.FedIncomeTaxDeductible c.FederalIncomeasStateTaxBase c.AllowFedAccDep c.ACRSDepreciation c.FederalBonusDepreciation c.throwback c.combined c.investment_credit c.incr_ma c.incr_fixed"

foreach var in r_g log_rev log_gdp {
	preserve

	reg `var' c.log_corp i.fips_state i.year `base' c.log_corp#(c.s1 c.s2 c.s3 c.s4 c.s5 c.s6 c.s7 c.s8 c.s9 c.s10 c.s11 c.s12 c.s13 c.s14 c.s15) [aw=mean_GDP]

	gen index2_`var' = _b[c.log_corp#c.s1]*s1 +_b[c.log_corp#c.s2]*s2 + _b[c.log_corp#c.s3]*s3 + _b[c.log_corp#c.s4]*s4 + _b[c.log_corp#c.s5]*s5 + _b[c.log_corp#c.s6]*s6 + _b[c.log_corp#c.s7]*s7 + _b[c.log_corp#c.s8]*s8 + _b[c.log_corp#c.s9]*s9 + _b[c.log_corp#c.s10]*s10 + _b[c.log_corp#c.s11]*s11 + _b[c.log_corp#c.s12]*s12 + _b[c.log_corp#c.s13]*s13 + _b[c.log_corp#c.s14]*s14 + _b[c.log_corp#c.s15]*s15

	anova index2_`var' `base' [aw = mean_GDP]
	
	local tss = e(mss) + e(rss)
	gen res = e(rss)/`tss'
	gen model = e(mss)/`tss'
	gen ss_rec_val = e(ss_1)/`tss'
	gen ss_saleswgt = e(ss_2)/`tss'
	gen ss_losscarryback = e(ss_3)/`tss'
	gen ss_losscarryforward = e(ss_4)/`tss'
	gen ss_franchise = e(ss_5)/`tss'
	gen ss_fedincded = e(ss_6)/`tss'
	gen ss_fedincbase = e(ss_7)/`tss'
	gen ss_allowfedaccdep = e(ss_8)/`tss'
	gen ss_acrsdep = e(ss_9)/`tss'
	gen ss_fedbonusdep = e(ss_10)/`tss'
	gen ss_throwback = e(ss_11)/`tss'
	gen ss_combined = e(ss_12)/`tss'
	gen ss_investment_credit = e(ss_13)/`tss'
	gen ss_incr_ma = e(ss_14)/`tss'
	gen ss_incr_fixed  = e(ss_15)/`tss'
	
	egen sum_base = rowtotal(ss_*)
	
	drop res model
	
	ds ss_*
	foreach ss in `r(varlist)' {
		replace `ss' = `ss'/sum_base
	}
	drop sum_base

	keep ss*
	keep if _n == 1

	gen var = "`var'"

	tempfile vardecomp_data_`var'
	save `vardecomp_data_`var'', replace

	restore
}

* Append datasets
use `vardecomp_data_r_g', clear
append using `vardecomp_data_log_rev'
append using `vardecomp_data_log_gdp'

order var
gen order = _n

* Convert wide form to long form
local i = 1
ds ss*
foreach ss in `r(varlist)' {
	rename `ss' share_s`i'
	local ++i
}

reshape long share_s, i(var) j(s)

* Create a dataset for plotting
sort order s
gen share_s2 = share_s[_n+15]
g share_s3 = share_s[_n+30]
drop if _n > 15

* Labels
gen s_string = "R&D Tax Credit" in 1
replace s_string = "Sales Apportionment Weight" in 2
replace s_string = "Loss Carryback" in 3
replace s_string = "Loss Carryforward" in 4
replace s_string = "Franchise Tax" in 5
replace s_string = "Fed Income Tax Deductible" in 6
replace s_string = "Fed Income as State Tax Base" in 7
replace s_string = "Allow Fed Accelerated Dep" in 8
replace s_string = "ACRS Depreciation" in 9
replace s_string = "Federal Bonus Depreciation" in 10
replace s_string = "Throwback Rule" in 11
replace s_string = "Combined Reporting" in 12
replace s_string = "Investment Credit" in 13
replace s_string = "R&D Incremental Mov Avg" in 14
replace s_string = "R&D Incremental Fixed" in 15

* Plot
graph hbar share_s share_s2 share_s3, over(s_string, label(labsize(small))) ///
	bar(1, color(dknavy)) bar(2, color(maroon*.7)) bar(3, color(forest_green)) ///
	title("A) Full Decomposition of Total Effects", size(medium)) ///
	ytitle("% Explained", size(small)) ylab(, labs(small)) ///
	legend(label(1 "Rev/GDP") label(2 "Corp Rev") label(3 "GDP") col(1) size(*0.8) span region(lc(black))) ///
	name(panelA, replace)


********************************************************************************
**# Panel B
********************************************************************************

use "Data/state_taxes_analysis.dta", clear

* Keep only 50 states in four years
keep if inrange(year, 1980, 2010)
drop if fips_state == 0 | fips_state == 11 | fips_state > 56

* Gen main variables
gen log_rev = ln(rev_corp)
gen log_corp = ln(1-corporate_rate/100)
gen r_g = rev_corptax/GDP
gen log_gdp = ln(GDP)

* Center base components around state & year FE
local base "sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit" 
foreach var in `base' {
	reg `var' i.fips_state i.year 
	predict base_hat, res
	replace `var' = base_hat 
	drop base_hat
}

* Get joint interactions 
bysort fips_state: egen mean_GDP = mean(GDP)

foreach xvar of varlist rec_val sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit incr_ma incr_fixed {
	 sum `xvar' [aw=mean_GDP], detail
	 replace `xvar' = (`xvar'-r(mean))/r(sd)
}

* Assign variables
local i = 1 
foreach var of varlist rec_val sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDeductible FederalIncomeasStateTaxBase AllowFedAccDep ACRSDepreciation FederalBonusDepreciation throwback combined investment_credit incr_ma incr_fixed {
	gen s`i' = `var'
	local ++i
}

* The ANOVA looped over three outcome variables
local base "c.rec_val c.sales_wgt c.Losscarryback c.Losscarryforward c.FranchiseTax c.FedIncomeTaxDeductible c.FederalIncomeasStateTaxBase c.AllowFedAccDep c.ACRSDepreciation c.FederalBonusDepreciation c.throwback c.combined c.investment_credit c.incr_ma c.incr_fixed"

foreach var in r_g log_rev log_gdp {
	preserve
	
	reg `var' c.log_corp i.fips i.year `base' c.log_corp#(c.s1 c.s2 c.s3 c.s4 c.s5 c.s6 c.s7 c.s8 c.s9 c.s10 c.s11 c.s12 c.s13 c.s14 c.s15) [aw=mean_GDP]
	
	gen index2_`var' = _b[c.log_corp#c.s1]*s1 +_b[c.log_corp#c.s2]*s2 + _b[c.log_corp#c.s3]*s3 + _b[c.log_corp#c.s4]*s4 + _b[c.log_corp#c.s5]*s5 + _b[c.log_corp#c.s6]*s6 + _b[c.log_corp#c.s7]*s7 + _b[c.log_corp#c.s8]*s8 + _b[c.log_corp#c.s9]*s9 + _b[c.log_corp#c.s10]*s10 + _b[c.log_corp#c.s11]*s11 + _b[c.log_corp#c.s12]*s12 + _b[c.log_corp#c.s13]*s13 + _b[c.log_corp#c.s14]*s14 + _b[c.log_corp#c.s15]*s15

	anova index2_`var' `base' [aw = mean_GDP]	
	
	local tss = e(mss) + e(rss)
	gen res = e(rss)/`tss'
	gen model = e(mss)/`tss'
	gen ss_rec_val = e(ss_1)/`tss'
	gen ss_saleswgt = e(ss_2)/`tss'
	gen ss_losscarryback = e(ss_3)/`tss'
	gen ss_losscarryforward = e(ss_4)/`tss'
	gen ss_franchise = e(ss_5)/`tss'
	gen ss_fedincded = e(ss_6)/`tss'
	gen ss_fedincbase = e(ss_7)/`tss'
	gen ss_allowfedaccdep = e(ss_8)/`tss'
	gen ss_acrsdep = e(ss_9)/`tss'
	gen ss_fedbonusdep = e(ss_10)/`tss'
	gen ss_throwback = e(ss_11)/`tss'
	gen ss_combined = e(ss_12)/`tss'
	gen ss_investment_credit = e(ss_13)/`tss'
	gen ss_incr_ma = e(ss_14)/`tss'
	gen ss_incr_fixed  = e(ss_15)/`tss'
	
	egen sum_base = rowtotal(ss_*)
	
	drop res model

	ds ss_*
	foreach ss in `r(varlist)' {
		replace `ss' = `ss'/sum_base
	}
	drop sum_base

	keep ss*
	keep if _n == 1

	gen var = "`var'"

	tempfile vardecomp_data_`var'
	save `vardecomp_data_`var'', replace

	restore
}

replace log_corp = corporate_rate

* Preparing for breaks
reg r_g c.log_corp i.fips i.year `base' c.log_corp#(c.s1 c.s2 c.s3 c.s4 c.s5 c.s6 c.s7 c.s8 c.s9 c.s10 c.s11 c.s12 c.s13 c.s14 c.s15) [aw=mean_GDP]

gen index2_r_g = _b[c.log_corp#c.s1]*s1 +_b[c.log_corp#c.s2]*s2+_b[c.log_corp#c.s3]*s3 + _b[c.log_corp#c.s4]*s4+_b[c.log_corp#c.s5]*s5 + _b[c.log_corp#c.s6]*s6 + _b[c.log_corp#c.s7]*s7 + _b[c.log_corp#c.s8]*s8 + _b[c.log_corp#c.s9]*s9 + _b[c.log_corp#c.s10]*s10 + _b[c.log_corp#c.s11]*s11 + _b[c.log_corp#c.s12]*s12 + _b[c.log_corp#c.s13]*s13 + _b[c.log_corp#c.s14]*s14 + _b[c.log_corp#c.s15]*s15
			 
sum index2_r_g [aw=mean_GDP], detail
replace index2_r_g = (index2_r_g)/r(sd)

anova index2_r_g `base' [aw = mean_GDP]	

tempfile data
save `data', replace

* Break!
local i = 1
foreach break in break1 break2 break3 break4 break5 break6 {
	use `data', clear

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

	local base = "rec_val sales_wgt Losscarryback Losscarryforward FranchiseTax FedIncomeTaxDed FederalIncomeas AllowFedAcc ACRSDep FederalBonus throwback combined investment_credit incr_ma incr_fixed"
	
	reg index2_r_g `base' [aw = mean_GDP]	
	
	foreach rule in `base' {
		local beta = _b[`rule']
		sum `rule'
		local var = (r(sd))^2
		gen bsqXx`rule' = (`beta')^2 * `var'
	}	

	egen sum_base = rowtotal(bsqX*)
	foreach rule in  `base'{
		g ss_`rule' = bsqXx`rule'/sum_base
	}

	keep ss*
	keep if _n == 1

	tempfile data`i'
	save `data`i'', replace

	local ++i
}

use `data1', clear
forvalues i = 2/6 {
	append using `data`i''
}

* Add an observation as starting point in the plot
local new_obs = _N + 1
set obs `new_obs'
gen id = _n
replace id = 0 if id == `new_obs'
sort id

ds id, not
foreach var in `r(varlist)' {
	replace `var' = `var'[2] if id == 0
}
replace ss_incr_f = 0 if ss_incr_f==.

ds id ss_*, not
foreach var in `r(varlist)' {
	replace `var' = `var' * 100
}

* Design x-axis
label define id_fig 0 "1980" 1 "1985" 2 "1990" 3 "1995" 4 "2000" 5 "2005" 6 "2010"
label values id id_fig

* Calculate the cumulative portion
g fedincbase = ss_FederalIncomeas
g fedincded = fedincbase + ss_FedIncomeTaxDed
g throwback = fedincded + ss_throwback
g saleswgt = throwback + ss_sales_wgt
g losscarryforward = saleswgt + ss_Losscarryforward
g losscarryback = ss_Losscarryback + losscarryforward
g combined = losscarryback + ss_combined
g investmentcredit = combined + ss_investment_credit
g recval = investmentcredit + ss_rec_val
g acrsdep = recval + ss_ACRSDep
g allowfedaccdep = acrsdep + ss_AllowFedAcc
g fedbonusdep = allowfedaccdep + ss_FederalBonus
g frantax = fedbonusdep + ss_FranchiseTax
g incrma = ss_incr_ma + frantax
g incrfixed = incrma + ss_incr_fixed

assert incrfixed>.99
replace incrfixed = 1

* Labels
label var fedincbase "Federal Inc as State Base"
label var fedincded "Federal Inc Deductible"
label var throwback "Throwback Rules"
label var saleswgt "Sales Apportionment Wgt"
label var losscarryforward "Loss Carryforward"
label var losscarryback "Loss Carryback"
label var combined "Combined Reporting"
label var investmentcredit "Investment Tax Credit"
label var recval "R&D Credit"
label var acrsdep "ACRS Depreciation"
label var allowfedaccdep "Federal Accelerated Dep"
label var fedbonusdep "Federal Bonus Dep"
label var frantax "Franchise Tax"
label var incrma "Incr R&D, Moving Avg Base"
label var incrfixed "Incr R&D, Fixed Base"

* Plot
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
	title("B) Decomposition of Total Effect on Revenue--to-GDP over Time", size(medium)) ///
	xti("") yti("% Explained", height(5) size(small)) ///
	ylab(0(0.25)1, notick angle(90) labs(small)) ///
	xlab(0/6, valuelabel notick labs(small)) ///
	plotregion(fcolor(white) lcolor(white)) ///
	legend(order(15 14 13 12 11 10 9 8 7 6 5 4 3 2 1) size(*0.8) span cols(2) region(lc(black))) ///
	name(panelB, replace)

* Combine and export
graph combine panelA panelB, row(2) iscale(0.6)
graph export "Figures/Figure8.svg", replace